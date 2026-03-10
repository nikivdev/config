#!/usr/bin/env bun

import { spawn, spawnSync, type ChildProcessWithoutNullStreams } from "node:child_process";
import { once } from "node:events";
import { existsSync, realpathSync } from "node:fs";
import process from "node:process";
import readline from "node:readline";

type JsonValue = null | boolean | number | string | JsonValue[] | { [key: string]: JsonValue };
type JsonObject = { [key: string]: JsonValue };

type Thread = {
  id: string;
  preview: string;
  name: string | null;
  cwd: string;
  updatedAt: number;
  createdAt: number;
  ephemeral: boolean;
  gitInfo?: {
    branch?: string | null;
    sha?: string | null;
  } | null;
};

type PendingRequest = {
  resolve: (value: JsonObject) => void;
  reject: (error: Error) => void;
  timeoutId: ReturnType<typeof setTimeout>;
};

type RankedThread = {
  thread: Thread;
  score: number;
};

type ThreadTextSignals = {
  userText: string;
  agentText: string;
  combinedText: string;
};

const DEFAULT_REPO = `${process.env.HOME}/repos/openai/codex`;
const DEFAULT_LIMIT = 100;
const REQUEST_TIMEOUT_MS = 8_000;
const SECOND_PASS_CANDIDATE_LIMIT = 3;
const FLOW_BIN = existsSync(`${process.env.HOME}/bin/f`) ? `${process.env.HOME}/bin/f` : "f";

const ORDINAL_INDEX_PATTERNS: Array<[RegExp, number]> = [
  [/\b(?:1st|first|one)\b/, 0],
  [/\b(?:2nd|second|two)\b/, 1],
  [/\b(?:3rd|third|three)\b/, 2],
  [/\b(?:4th|fourth|four)\b/, 3],
  [/\b(?:5th|fifth|five)\b/, 4],
  [/\b(?:6th|sixth|six)\b/, 5],
  [/\b(?:7th|seventh|seven)\b/, 6],
  [/\b(?:8th|eighth|eight)\b/, 7],
  [/\b(?:9th|ninth|nine)\b/, 8],
  [/\b(?:10th|tenth|ten)\b/, 9],
];

class CodexAppServerClient {
  private readonly child: ChildProcessWithoutNullStreams;
  private readonly pending = new Map<number, PendingRequest>();
  private readonly stderrChunks: string[] = [];
  private readonly threadTextCache = new Map<string, ThreadTextSignals>();
  private nextId = 1;

  constructor(private readonly repoPath: string) {
    this.child = spawn("codex", ["app-server"], {
      cwd: repoPath,
      stdio: ["pipe", "pipe", "pipe"],
    });

    const rl = readline.createInterface({ input: this.child.stdout });
    rl.on("line", (line) => {
      const trimmed = line.trim();
      if (!trimmed) return;

      let payload: JsonObject;
      try {
        payload = JSON.parse(trimmed) as JsonObject;
      } catch (error) {
        this.rejectAll(new Error(`failed to parse codex app-server output: ${String(error)}`));
        return;
      }

      const id = typeof payload.id === "number" ? payload.id : null;
      if (id === null) return;

      const pending = this.pending.get(id);
      if (!pending) return;
      this.pending.delete(id);
      clearTimeout(pending.timeoutId);

      if (payload.error && typeof payload.error === "object") {
        const message =
          typeof (payload.error as JsonObject).message === "string"
            ? String((payload.error as JsonObject).message)
            : JSON.stringify(payload.error);
        pending.reject(new Error(message));
        return;
      }

      pending.resolve(payload);
    });

    this.child.stderr.on("data", (chunk) => {
      this.stderrChunks.push(chunk.toString());
      if (this.stderrChunks.length > 8) this.stderrChunks.shift();
    });

    this.child.on("error", (error) => {
      this.rejectAll(new Error(`failed to start codex app-server: ${error.message}`));
    });

    this.child.on("close", (code, signal) => {
      const detail = this.stderrChunks.join("").trim();
      const suffix = detail ? `: ${detail.slice(0, 400)}` : "";
      this.rejectAll(
        new Error(`codex app-server exited unexpectedly (${code ?? "null"}:${signal ?? "none"})${suffix}`),
      );
    });
  }

  async initialize(): Promise<void> {
    await this.request("initialize", {
      clientInfo: {
        name: "fish-L-session-resolver",
        version: "0.1.0",
      },
      capabilities: {
        experimentalApi: true,
      },
    });
    this.write({
      method: "initialized",
    });
  }

  async listThreads(limit: number, searchTerm?: string): Promise<Thread[]> {
    const threads: Thread[] = [];
    let cursor: string | null = null;

    while (threads.length < limit) {
      const response = await this.request("thread/list", {
        cwd: this.repoPath,
        archived: false,
        sortKey: "updated_at",
        limit: Math.min(100, limit - threads.length),
        ...(searchTerm ? { searchTerm } : {}),
        ...(cursor ? { cursor } : {}),
      });

      const result = asObject(response.result);
      const data = Array.isArray(result?.data) ? result.data : [];
      for (const value of data) {
        const thread = toThread(value);
        if (!thread || thread.ephemeral) continue;
        threads.push(thread);
      }

      cursor = typeof result?.nextCursor === "string" ? result.nextCursor : null;
      if (!cursor) break;
    }

    return threads;
  }

  async readThreadTextSignals(threadId: string): Promise<ThreadTextSignals> {
    const cached = this.threadTextCache.get(threadId);
    if (cached) return cached;

    const response = await this.request("thread/read", {
      threadId,
      includeTurns: true,
    });
    const signals = toThreadTextSignals(response.result);
    this.threadTextCache.set(threadId, signals);
    return signals;
  }

  async close(): Promise<void> {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timeoutId);
      pending.reject(new Error("codex app-server closed"));
    }
    this.pending.clear();

    if (this.child.exitCode !== null || this.child.killed) return;

    this.child.kill("SIGTERM");
    await Promise.race([once(this.child, "close"), sleep(500)]);
  }

  private request(method: string, params: JsonObject): Promise<JsonObject> {
    const id = this.nextId;
    this.nextId += 1;

    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`codex app-server request timed out: ${method}`));
      }, REQUEST_TIMEOUT_MS);

      this.pending.set(id, { resolve, reject, timeoutId });
      this.write({ id, method, params });
    });
  }

  private write(payload: JsonObject): void {
    this.child.stdin.write(`${JSON.stringify(payload)}\n`);
  }

  private rejectAll(error: Error): void {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timeoutId);
      pending.reject(error);
    }
    this.pending.clear();
  }
}

function main(): Promise<void> {
  return run(process.argv.slice(2));
}

async function run(argv: string[]): Promise<void> {
  const options = parseArgs(argv);
  const repoPath = realpathSync(options.repoPath);

  if (!existsSync(repoPath)) {
    throw new Error(`repo not found: ${repoPath}`);
  }

  const client = new CodexAppServerClient(repoPath);
  try {
    await client.initialize();
    const primaryLimit = estimatePrimaryLimit(options.query, options.limit);
    const searchTerm = deriveSearchTerm(options.query);
    let threads = sortThreads(await client.listThreads(primaryLimit, searchTerm));
    let selected = await selectThread(client, threads, options.query);

    if (!selected && (primaryLimit < options.limit || searchTerm)) {
      threads = sortThreads(await client.listThreads(options.limit));
      selected = await selectThread(client, threads, options.query);
    }

    if (threads.length === 0) {
      throw new Error(`no stored Codex sessions found for ${repoPath}`);
    }

    if (!selected) {
      throw new Error(buildNoMatchMessage(threads, options.query));
    }

    if (options.printOnly) {
      process.stdout.write(
        `${JSON.stringify(
          {
            id: selected.id,
            updatedAt: selected.updatedAt,
            name: selected.name,
            preview: selected.preview,
            cwd: selected.cwd,
          },
          null,
          2,
        )}\n`,
      );
      return;
    }

    const resume = spawnSync(FLOW_BIN, ["ai", "codex", "resume", selected.id], {
      cwd: repoPath,
      stdio: "inherit",
      env: process.env,
    });

    if (typeof resume.status === "number") {
      process.exitCode = resume.status;
      return;
    }

    if (resume.error) throw resume.error;
    throw new Error("failed to resume Codex session");
  } finally {
    await client.close();
  }
}

function parseArgs(argv: string[]): { repoPath: string; query: string; limit: number; printOnly: boolean } {
  let repoPath = DEFAULT_REPO;
  let limit = DEFAULT_LIMIT;
  let printOnly = false;
  const queryParts: string[] = [];

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--repo") {
      index += 1;
      if (index >= argv.length) throw new Error("missing value for --repo");
      repoPath = argv[index]!;
      continue;
    }
    if (arg === "--limit") {
      index += 1;
      if (index >= argv.length) throw new Error("missing value for --limit");
      const parsed = Number.parseInt(argv[index]!, 10);
      if (!Number.isFinite(parsed) || parsed <= 0) throw new Error(`invalid --limit: ${argv[index]}`);
      limit = parsed;
      continue;
    }
    if (arg === "--print") {
      printOnly = true;
      continue;
    }
    queryParts.push(arg);
  }

  const query = queryParts.join(" ").trim();
  if (!query) throw new Error("usage: codex-openai-session.ts [--print] [--repo <path>] <query>");

  return { repoPath, query, limit, printOnly };
}

async function selectThread(client: CodexAppServerClient, threads: Thread[], query: string): Promise<Thread | null> {
  const normalizedQuery = normalize(query);
  const idMatch = findIdMatch(threads, normalizedQuery);
  if (idMatch) return idMatch;

  const directional = await resolveDirectionalThread(client, threads, normalizedQuery);
  if (directional.matched) return directional.thread;

  const rankedMatches = await rerankTextualMatches(client, threads, stripControlPhrases(normalizedQuery));
  const ordinalIndex = parseOrdinalIndex(normalizedQuery);
  if (ordinalIndex !== null) {
    const candidates = rankedMatches.length > 0 ? rankedMatches : threads;
    return candidates[ordinalIndex] ?? null;
  }

  if (rankedMatches.length > 0) return rankedMatches[0] ?? null;

  if (looksLikeLatestQuery(normalizedQuery)) return threads[0] ?? null;

  return null;
}

async function resolveDirectionalThread(
  client: CodexAppServerClient,
  threads: Thread[],
  query: string,
): Promise<{ matched: boolean; thread: Thread | null }> {
  const directionMatch = query.match(/\b(after|before)\b/);
  if (!directionMatch) return { matched: false, thread: null };

  const direction = directionMatch[1] === "after" ? 1 : -1;
  const anchorText = query.slice(directionMatch.index! + directionMatch[0].length).trim();

  const anchorOrdinal = parseOrdinalIndex(anchorText);
  let anchor = anchorOrdinal !== null ? threads[anchorOrdinal] ?? null : null;
  if (!anchor && (looksLikeLatestQuery(anchorText) || anchorText.length === 0)) {
    anchor = threads[0] ?? null;
  }
  if (!anchor) {
    const anchorMatches = await rerankTextualMatches(client, threads, stripControlPhrases(anchorText));
    anchor = anchorMatches[0] ?? null;
  }
  if (!anchor) return { matched: true, thread: null };

  const anchorIndex = threads.findIndex((thread) => thread.id === anchor.id);
  if (anchorIndex === -1) return { matched: true, thread: null };

  return { matched: true, thread: threads[anchorIndex + direction] ?? null };
}

function findIdMatch(threads: Thread[], query: string): Thread | null {
  const tokens = query.split(/\s+/).filter(Boolean);
  for (const token of tokens) {
    if (!/^[0-9a-f-]{8,}$/i.test(token)) continue;
    const matches = threads.filter((thread) => thread.id.startsWith(token));
    if (matches.length === 1) return matches[0] ?? null;
  }
  return null;
}

function parseOrdinalIndex(query: string): number | null {
  const stripped = stripControlPhrases(query);
  if (/^\d+$/.test(stripped)) {
    const value = Number.parseInt(stripped, 10);
    if (Number.isFinite(value) && value > 0) return value - 1;
  }

  for (const [pattern, index] of ORDINAL_INDEX_PATTERNS) {
    if (pattern.test(query) && stripped.length === 0) return index;
  }

  if (looksLikeLatestQuery(query)) return 0;
  return null;
}

function looksLikeLatestQuery(query: string): boolean {
  return /\b(?:most recent|latest|newest|last)\b/.test(query) && stripControlPhrases(query).length === 0;
}

function rankThreads(threads: Thread[], query: string): Thread[] {
  return rankThreadEntries(threads, query).map((entry) => entry.thread);
}

function rankThreadEntries(threads: Thread[], query: string): RankedThread[] {
  if (!query) return [];

  const terms = query.split(/\s+/).filter((term) => term.length >= 2);
  if (terms.length === 0) return [];

  const phrase = terms.join(" ");
  return [...threads]
    .map((thread) => ({ thread, score: scoreThread(thread, phrase, terms) }))
    .filter((entry) => entry.score > 0)
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score;
      if (right.thread.updatedAt !== left.thread.updatedAt) return right.thread.updatedAt - left.thread.updatedAt;
      return right.thread.createdAt - left.thread.createdAt;
    })
}

function scoreThread(thread: Thread, phrase: string, terms: string[]): number {
  const title = normalize(thread.name ?? "");
  const preview = normalize(thread.preview);
  const branch = normalize(thread.gitInfo?.branch ?? "");
  const sha = normalize(thread.gitInfo?.sha ?? "");
  const combined = [title, preview, branch, sha, thread.id.toLowerCase()].filter(Boolean).join(" ");
  let score = 0;

  if (phrase.length >= 3 && combined.includes(phrase)) score += 40;
  if (title.startsWith(phrase)) score += 30;
  if (preview.startsWith(phrase)) score += 20;

  for (const term of terms) {
    if (thread.id.startsWith(term)) score += 60;
    if (sha.startsWith(term)) score += 20;
    if (title.includes(term)) score += 18;
    if (preview.includes(term)) score += 10;
    if (branch.includes(term)) score += 8;
  }

  return score;
}

async function rerankTextualMatches(
  client: CodexAppServerClient,
  threads: Thread[],
  strippedQuery: string,
): Promise<Thread[]> {
  if (!strippedQuery) return [];

  const rankedEntries = rankThreadEntries(threads, strippedQuery);
  if (rankedEntries.length === 0) {
    return await rankRecentThreadsByTranscript(client, threads.slice(0, SECOND_PASS_CANDIDATE_LIMIT), strippedQuery);
  }
  if (!shouldUseThreadReadSecondPass(rankedEntries)) return rankedEntries.map((entry) => entry.thread);

  const topCandidates = rankedEntries.slice(0, SECOND_PASS_CANDIDATE_LIMIT);
  const rerankedTop = await rerankTopCandidatesWithThreadRead(client, topCandidates, strippedQuery);
  const topIds = new Set(topCandidates.map((entry) => entry.thread.id));
  const remaining = rankedEntries.filter((entry) => !topIds.has(entry.thread.id));
  return [...rerankedTop, ...remaining.map((entry) => entry.thread)];
}

async function rankRecentThreadsByTranscript(
  client: CodexAppServerClient,
  threads: Thread[],
  query: string,
): Promise<Thread[]> {
  const terms = query.split(/\s+/).filter((term) => term.length >= 2);
  const phrase = terms.join(" ");
  const results = await Promise.allSettled(
    threads.map(async (thread) => {
      const signals = await client.readThreadTextSignals(thread.id);
      return {
        thread,
        score: scoreThreadTranscript(signals, phrase, terms),
      };
    }),
  );

  return results
    .flatMap((result, index) => {
      if (result.status === "fulfilled" && result.value.score > 0) return [result.value];
      return [];
    })
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score;
      if (right.thread.updatedAt !== left.thread.updatedAt) return right.thread.updatedAt - left.thread.updatedAt;
      return right.thread.createdAt - left.thread.createdAt;
    })
    .map((entry) => entry.thread);
}

function shouldUseThreadReadSecondPass(rankedEntries: RankedThread[]): boolean {
  if (rankedEntries.length === 0) return false;
  if (rankedEntries.length === 1) return rankedEntries[0]!.score < 80;
  return rankedEntries[0]!.score - rankedEntries[1]!.score < 25 || rankedEntries[0]!.score < 90;
}

async function rerankTopCandidatesWithThreadRead(
  client: CodexAppServerClient,
  rankedEntries: RankedThread[],
  query: string,
): Promise<Thread[]> {
  const terms = query.split(/\s+/).filter((term) => term.length >= 2);
  const phrase = terms.join(" ");
  const results = await Promise.allSettled(
    rankedEntries.map(async (entry) => {
      const signals = await client.readThreadTextSignals(entry.thread.id);
      return {
        thread: entry.thread,
        score: entry.score + scoreThreadTranscript(signals, phrase, terms),
      };
    }),
  );

  const reranked = results.map((result, index) => {
    if (result.status === "fulfilled") return result.value;
    return rankedEntries[index]!;
  });

  return reranked
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score;
      if (right.thread.updatedAt !== left.thread.updatedAt) return right.thread.updatedAt - left.thread.updatedAt;
      return right.thread.createdAt - left.thread.createdAt;
    })
    .map((entry) => entry.thread);
}

function scoreThreadTranscript(signals: ThreadTextSignals, phrase: string, terms: string[]): number {
  let score = 0;

  if (phrase.length >= 3) {
    if (signals.userText.includes(phrase)) score += 120;
    if (signals.agentText.includes(phrase)) score += 40;
    if (signals.combinedText.includes(phrase)) score += 15;
  }

  for (const term of terms) {
    if (signals.userText.includes(term)) score += 28;
    if (signals.agentText.includes(term)) score += 8;
    if (signals.combinedText.includes(term)) score += 3;
  }

  return score;
}

function stripControlPhrases(query: string): string {
  return stripControlPhrasesWithFlags(query, "g");
}

function deriveSearchTerm(query: string): string | undefined {
  const stripped = stripControlPhrasesWithFlags(query, "gi");
  return stripped.length >= 3 ? stripped : undefined;
}

function estimatePrimaryLimit(query: string, maxLimit: number): number {
  const normalizedQuery = normalize(query);
  const directionalMatch = normalizedQuery.match(/\b(after|before)\b/);
  if (directionalMatch) {
    const anchorText = normalizedQuery.slice(directionalMatch.index! + directionalMatch[0].length).trim();
    const anchorOrdinal = parseOrdinalIndex(anchorText);
    if (anchorOrdinal !== null) return Math.min(maxLimit, anchorOrdinal + 2);
    if (looksLikeLatestQuery(anchorText) || anchorText.length === 0) return Math.min(maxLimit, 2);
    return Math.min(maxLimit, 25);
  }

  const ordinalIndex = parseOrdinalIndex(normalizedQuery);
  if (ordinalIndex !== null) return Math.min(maxLimit, ordinalIndex + 1);

  if (deriveSearchTerm(query)) return Math.min(maxLimit, 25);

  return maxLimit;
}

function stripControlPhrasesWithFlags(query: string, flags: string): string {
  return query
    .replace(new RegExp("\\b(connect|open|resume|continue|session|sessions)\\b", flags), " ")
    .replace(new RegExp("\\b(after|before)\\b", flags), " ")
    .replace(new RegExp("\\b(most recent|latest|newest|last)\\b", flags), " ")
    .replace(new RegExp("\\b(active|the|a|an|to|from|for|please)\\b", flags), " ")
    .replace(new RegExp("\\b(?:\\d+)(?:st|nd|rd|th)\\b", flags), " ")
    .replace(
      new RegExp(
        "\\b(first|one|second|two|third|three|fourth|four|fifth|five|sixth|six|seventh|seven|eighth|eight|ninth|nine|tenth|ten)\\b",
        flags,
      ),
      " ",
    )
    .replace(/\s+/g, " ")
    .trim();
}

function sortThreads(threads: Thread[]): Thread[] {
  return [...threads].sort((left, right) => {
    if (right.updatedAt !== left.updatedAt) return right.updatedAt - left.updatedAt;
    return right.createdAt - left.createdAt;
  });
}

function buildNoMatchMessage(threads: Thread[], query: string): string {
  const preview = threads
    .slice(0, 5)
    .map((thread, index) => `${index + 1}. ${thread.id.slice(0, 8)} ${formatPreview(thread)}`)
    .join("\n");
  return [`no Codex session matched query: ${query}`, "recent sessions:", preview].join("\n");
}

function formatPreview(thread: Thread): string {
  const text = thread.name ?? thread.preview;
  const cleaned = text.replace(/\s+/g, " ").trim();
  const trimmed = cleaned.length > 80 ? `${cleaned.slice(0, 77)}...` : cleaned;
  return `[${formatTimestamp(thread.updatedAt)}] ${trimmed}`;
}

function formatTimestamp(unixSeconds: number): string {
  return new Date(unixSeconds * 1000).toISOString().replace("T", " ").slice(0, 16);
}

function toThread(value: JsonValue): Thread | null {
  const object = asObject(value);
  const id = typeof object?.id === "string" ? object.id : null;
  const preview = typeof object?.preview === "string" ? object.preview : "";
  const cwd = typeof object?.cwd === "string" ? object.cwd : null;
  const updatedAt = typeof object?.updatedAt === "number" ? object.updatedAt : null;
  const createdAt = typeof object?.createdAt === "number" ? object.createdAt : null;
  const ephemeral = typeof object?.ephemeral === "boolean" ? object.ephemeral : null;

  if (!id || !cwd || updatedAt === null || createdAt === null || ephemeral === null) return null;

  return {
    id,
    preview,
    name: typeof object?.name === "string" ? object.name : null,
    cwd,
    updatedAt,
    createdAt,
    ephemeral,
    gitInfo: asObject(object?.gitInfo) as Thread["gitInfo"],
  };
}

function toThreadTextSignals(value: JsonValue | undefined): ThreadTextSignals {
  const result = asObject(value);
  const thread = asObject(result?.thread);
  const turns = Array.isArray(thread?.turns) ? thread.turns : [];
  const userParts: string[] = [];
  const agentParts: string[] = [];

  for (const turnValue of turns) {
    const turn = asObject(turnValue);
    const items = Array.isArray(turn?.items) ? turn.items : [];
    for (const itemValue of items) {
      const item = asObject(itemValue);
      const type = typeof item?.type === "string" ? item.type : "";
      if (type === "userMessage") {
        const text = extractUserMessageText(item);
        if (text) userParts.push(text);
        continue;
      }
      if (type === "agentMessage") {
        const text = typeof item?.text === "string" ? item.text : "";
        if (text) agentParts.push(text);
      }
    }
  }

  const userText = normalize(userParts.join(" "));
  const agentText = normalize(agentParts.join(" "));
  return {
    userText,
    agentText,
    combinedText: normalize([userText, agentText].filter(Boolean).join(" ")),
  };
}

function extractUserMessageText(item: JsonObject): string {
  const content = Array.isArray(item.content) ? item.content : [];
  const parts: string[] = [];

  for (const partValue of content) {
    const part = asObject(partValue);
    const type = typeof part?.type === "string" ? part.type : "";
    if (type === "text" && typeof part?.text === "string") {
      parts.push(part.text);
      continue;
    }
    if (type === "selection") {
      if (typeof part?.path === "string") parts.push(part.path);
      if (typeof part?.content === "string") parts.push(part.content);
      continue;
    }
    if (type === "fileRef" && typeof part?.path === "string") {
      parts.push(part.path);
    }
  }

  return parts.join(" ");
}

function asObject(value: JsonValue | undefined): JsonObject | null {
  if (!value || Array.isArray(value) || typeof value !== "object") return null;
  return value as JsonObject;
}

function normalize(value: string): string {
  return value.toLowerCase().replace(/\s+/g, " ").trim();
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`${message}\n`);
  process.exit(1);
});
