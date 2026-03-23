source ~/config/fish/fn.fish
if test -f ~/config/i/fish/i.fish
    source ~/config/i/fish/i.fish
end

# Pure prompt (enforced from local repo checkout)
set -l _pure_root "$HOME/repos/pure-fish/pure"
if test -f "$_pure_root/conf.d/pure.fish"
    set -g fish_function_path "$_pure_root/functions" $fish_function_path
    source "$_pure_root/conf.d/pure.fish"
    set -g pure_symbol_prompt ">"
    set -g pure_symbol_reverse_prompt "<"
    source ~/config/fish/prompt_parallel_workspaces.fish
end

# Default editor (Zed Preview)
set -gx EDITOR "zed"
set -gx VISUAL "zed"

# Avoid fish terminal query warning in incompatible terminals.
if not contains -- no-query-term $fish_features
    set -Ua fish_features no-query-term
end

if test -f ~/.local/state/nix/profiles/profile/etc/profile.d/nix.fish
    source ~/.local/state/nix/profiles/profile/etc/profile.d/nix.fish # use latest version of nix
end
set -x NIX_SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt # needed for flox/nix (some ssl bug or something) TODO: still needed?
# TODO: how to use latest version of nix daemon too with flox?

# direnv hook fish | source # direnv (cd into folder, will get the `.env` etc.)
# set -x DIRENV_LOG_FORMAT "" # hide direnv unloading messages

if test -d $HOME/.flox/run/aarch64-darwin.default.dev/bin
    fish_add_path --global --prepend $HOME/.flox/run/aarch64-darwin.default.dev/bin
end
if test -d $HOME/go/bin
    fish_add_path --global --prepend $HOME/go/bin
end
if test -d /opt/homebrew/bin
    fish_add_path --global --prepend /opt/homebrew/bin
end
if test -d "$HOME/.bun/bin"
    fish_add_path --global --prepend $HOME/.bun/bin
end
if test -d "$HOME/.cargo/bin"
    fish_add_path --global --prepend $HOME/.cargo/bin
end
if test -d "$HOME/bin"
    fish_add_path --global --prepend $HOME/bin
end

# solana https://solana.com/docs/intro/installation
if test -d /Users/nikiv/.local/share/solana/install/active_release/bin
    fish_add_path --global --prepend /Users/nikiv/.local/share/solana/install/active_release/bin
end

# Added by Windsurf
if test -d /Users/nikiv/.codeium/windsurf/bin
    fish_add_path --global --prepend /Users/nikiv/.codeium/windsurf/bin
end

# Added by LM Studio CLI (lms)
if test -d /Users/nikiv/.cache/lm-studio/bin
    fish_add_path --global --append /Users/nikiv/.cache/lm-studio/bin
end

# fnm
if command -sq fnm
    set -gx FNM_VERSION_FILE_STRATEGY "local"
    set -gx FNM_DIR "$HOME/.local/share/fnm"
    set -gx FNM_LOGLEVEL "info"
    set -gx FNM_NODE_DIST_MIRROR "https://nodejs.org/dist"
    set -gx FNM_COREPACK_ENABLED "false"
    set -gx FNM_RESOLVE_ENGINES "true"
    set -gx FNM_ARCH "arm64"
    fnm env --use-on-cd --shell fish | source
end

# moonbit
if test -d "$HOME/.moon/bin"
    fish_add_path --global --prepend $HOME/.moon/bin
end

if command -sq atuin
    atuin init fish --disable-up-arrow | source
end

# TODO: get bug here with google sdk when this line is on
# jumpy completions fish | source

# for pg_dump
if test -d /opt/homebrew/opt/libpq/bin
    fish_add_path --global --prepend /opt/homebrew/opt/libpq/bin
end

if test -d /Users/nikiv/.modular/bin
    fish_add_path --global --prepend /Users/nikiv/.modular/bin
end

# if test -e "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
#     fish_add_path --global --prepend "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin"
#     test -f "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc" && source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc"
#     test -f "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.fish.inc" && source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.fish.inc"
# end

source ~/.orbstack/shell/init2.fish 2>/dev/null || true

# pnpm
set -gx PNPM_HOME "$HOME/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
if test -d /Users/nikiv/.pixi/bin
    fish_add_path --global --prepend /Users/nikiv/.pixi/bin
end
if test -d $HOME/config/sh
    fish_add_path --global --prepend $HOME/config/sh
end
# Added by zv setup
if test -f "$HOME/.zv/env.fish"
    source "$HOME/.zv/env.fish"
end

fish_add_path /opt/homebrew/opt/ruby/bin

# opencode
fish_add_path /Users/nikiv/.opencode/bin

if command -sq frum
    set -gx PATH "/var/folders/69/jnm2pqrx12103z_f8hh3_d1w0000gn/T/frum_80955_1763308433288/bin" $PATH
    set -gx FRUM_MULTISHELL_PATH "/var/folders/69/jnm2pqrx12103z_f8hh3_d1w0000gn/T/frum_80955_1763308433288"
    set -gx FRUM_DIR "$HOME/.frum"
    set -gx FRUM_LOGLEVEL "info"
    set -gx FRUM_RUBY_BUILD_MIRROR "https://cache.ruby-lang.org/pub/ruby"
    if test -d "$FRUM_DIR"
        function _frum_autoload_hook --on-variable PWD --description 'Change Ruby version on directory change'
            status --is-command-substitution; and return
            frum --log-level quiet local >/dev/null 2>&1
        end
    else if functions -q _frum_autoload_hook
        functions -e _frum_autoload_hook
    end
else if functions -q _frum_autoload_hook
    functions -e _frum_autoload_hook
end

# Added by Antigravity
fish_add_path /Users/nikiv/.antigravity/antigravity/bin

# set -l _mise_bin "$HOME/.local/bin/mise"
# if test -x $_mise_bin
#     $_mise_bin activate fish | source
# end


# Ensure /Users/nikiv/.local/bin takes precedence over Python 3.14 system framework bin in PATH
if string match -q "/Library/Frameworks/Python.framework/Versions/3.14/bin*" $PATH
    set PATH (string match -rv "/Users/nikiv/.local/bin*" $PATH)
    set PATH /Users/nikiv/.local/bin $PATH
else
    fish_add_path --global --prepend /Users/nikiv/.local/bin
end

# Amp CLI
export PATH="/Users/nikiv/.amp/bin:$PATH"

set -g fish_greeting
# flow:start
function f
    set -l bin (__flow_bin)
    or return 1

    if test -z "$argv[1]"
        $bin
        return $status
    end

    set -l first $argv[1]
    set -l passthrough \
        ? search global hub init shell-init shell new home archive doctor health invariants \
        tasks fast up down ai-test-new run last-cmd last-cmd-full fish-last fish-last-full \
        fish-install rerun ps kill logs trace traces analytics projects sessions active \
        server web match ask branches commit commit-queue reviews-todo pr gitignore recipe \
        review commitSimple commitWithCheck undo fix fixup changes diff hash daemon supervisor \
        ai codex cursor claude secrets otp db env auth services deps status info latest \
        storage setup todo init-agent skills code migrate parallel docs upgrade release install \
        registry proxy domains sync checkout switch push deploy prod publish clone repos agents \
        hive

    if string match -qr '^-' -- "$first"; or contains -- "$first" $passthrough
        $bin $argv
    else
        $bin match $argv
    end
end
# flow:end
