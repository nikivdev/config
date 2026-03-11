# Minimal pure override:
# keep pure prompt exactly as-is, but make branch display aware of the
# local home-branch / JJ-workspace workflow and collapse diverged git state
# (ahead + behind) into one symbol so we avoid "⇡⇣" noise.

# Restore pure internals in case this shell still has older custom overrides.
set _pure_fn_root "$HOME/repos/pure-fish/pure/functions"
if test -f "$_pure_fn_root/_pure_prompt_first_line.fish"
    source "$_pure_fn_root/_pure_prompt_first_line.fish"
end
if test -f "$_pure_fn_root/_pure_prompt_git.fish"
    source "$_pure_fn_root/_pure_prompt_git.fish"
end

function _prompt_parallel_workspace_name
    set --local cwd_real (pwd -P)
    set --local prefix (path normalize "$HOME/.jj/workspaces")
    set --local escaped_prefix (string escape --style=regex -- "$prefix")

    set --local captures (string match --regex "^$escaped_prefix/[^/]+/([^/]+)(/.*)?\$" -- "$cwd_real")
    if test (count $captures) -gt 0
        echo "$captures[2]"
    end
end

function _prompt_parallel_workspace_branch
    set --local workspace (_prompt_parallel_workspace_name)
    if test -z "$workspace"
        return
    end

    if string match --quiet --regex '^(review|codex)-' -- "$workspace"
        echo (string replace --regex '^([^-]+)-' '$1/' -- "$workspace")
        return
    end

    echo "$workspace"
end

function _prompt_parallel_git_root
    set --local git_root (command git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$git_root"
        echo "$git_root"
        return
    end

    if type --query --no-functions jj
        set --local jj_root (command jj git root 2>/dev/null)
        if test -n "$jj_root"
            if string match --quiet --regex '/\\.git$' -- "$jj_root"
                path dirname "$jj_root"
            else
                echo "$jj_root"
            end
        end
    end
end

function _prompt_parallel_jj_bookmark
    if not type --query --no-functions jj
        return
    end

    set --local root (command jj root 2>/dev/null)
    if test -z "$root"
        return
    end

    set --local bookmarks (
        command jj log -r '@ | @-' --no-graph \
            -T 'local_bookmarks.map(|b| b.name()).join("\n") ++ "\n"' 2>/dev/null
    )

    for bookmark in (string split \n -- "$bookmarks")
        set bookmark (string trim -- "$bookmark")
        if test -n "$bookmark"
            echo "$bookmark"
            return
        end
    end
end

function _prompt_parallel_git_branch_fallback
    set --local local_refs (
        command git for-each-ref --contains HEAD --format='%(refname:short)' refs/heads 2>/dev/null
    )
    for ref in $local_refs
        if string match --quiet --regex '^(backup|tmp|wip)/' -- "$ref"
            continue
        end
        echo "$ref"
        return
    end

    set --local remote_refs (
        command git for-each-ref --contains HEAD --format='%(refname:short)' refs/remotes 2>/dev/null
    )
    for ref in $remote_refs
        set ref (string replace --regex '^remotes/' '' -- "$ref")
        if test -n "$ref"
            echo "$ref"
            return
        end
    end
end

function _prompt_parallel_logical_branch
    set --local symbolic (command git symbolic-ref --short HEAD 2>/dev/null)
    if test -n "$symbolic"
        echo "$symbolic"
        return
    end

    set --local workspace_branch (_prompt_parallel_workspace_branch)
    if test -n "$workspace_branch"
        echo "$workspace_branch"
        return
    end

    set --local jj_bookmark (_prompt_parallel_jj_bookmark)
    if test -n "$jj_bookmark"
        echo "$jj_bookmark"
        return
    end

    set --local fallback (_prompt_parallel_git_branch_fallback)
    if test -n "$fallback"
        echo "$fallback"
        return
    end

    _pure_parse_git_branch
end

function _prompt_parallel_home_branch
    set --local git_root (_prompt_parallel_git_root)
    if test -z "$git_root"
        return
    end

    set --local flow_toml_candidates \
        "$git_root/flow.toml" \
        "$git_root/x/nikiv/flow.toml"

    set --local flow_toml
    for candidate in $flow_toml_candidates
        if test -f "$candidate"
            set flow_toml "$candidate"
            break
        end
    end

    if test -z "$flow_toml"
        return
    end

    set --local in_jj false
    while read --line line
        set line (string trim -- "$line")

        if string match --quiet --regex '^\[[^]]+\]$' -- "$line"
            if test "$line" = "[jj]"
                set in_jj true
            else
                set in_jj false
            end
            continue
        end

        if test "$in_jj" = true
            if string match --quiet --regex '^home_branch\\s*=' -- "$line"
                set --local value (string replace --regex '^home_branch\\s*=\\s*' '' -- "$line")
                set value (string replace --regex '\\s+#.*$' '' -- "$value")
                set value (string replace --all '"' '' -- "$value")
                set value (string replace --all "'" '' -- "$value")
                if test -n "$value"
                    echo "$value"
                end
                return
            end
        end
    end <"$flow_toml"
end

function _prompt_parallel_branch_role --argument branch
    if string match --quiet --regex '^review/' -- "$branch"
        echo review
        return
    end

    if string match --quiet --regex '^codex/' -- "$branch"
        echo codex
        return
    end

    set --local home_branch (_prompt_parallel_home_branch)
    if test -z "$home_branch"
        return
    end

    if test "$branch" = "$home_branch"
        echo home
    end
end

function _prompt_parallel_branch_display --argument branch
    set --local display "$branch"
    set --local home_branch (_prompt_parallel_home_branch)
    if test -n "$home_branch"
        set display (string replace "review/$home_branch-" "review/" -- "$display")
        set display (string replace "codex/$home_branch-" "codex/" -- "$display")
    end

    set --local role (_prompt_parallel_branch_role "$branch")
    set --local workspace (_prompt_parallel_workspace_name)

    switch "$role"
        case home
            echo "$display"
            return
        case review
            if test -n "$workspace"
                echo "$display⧉"
            else
                echo "$display!"
            end
            return
        case codex
            if test -n "$workspace"
                echo "$display⧉"
            else
                echo "$display!"
            end
            return
    end

    echo "$display"
end

function _prompt_parallel_is_prom_app_dir
    set --local cwd_real (pwd -P)
    if string match --quiet "$HOME/code/prom/ide/*" -- "$cwd_real"
        return 0
    end

    set --local workspace_prefix (path normalize "$HOME/.jj/workspaces/prom")
    if string match --quiet "$workspace_prefix/*/ide/*" -- "$cwd_real"
        return 0
    end

    return 1
end

function _prompt_parallel_task_badge --argument branch
    if not _prompt_parallel_is_prom_app_dir
        return
    end

    set --local state_file "$HOME/.local/state/prom-codex/task-state-branches.tsv"
    if not test -f "$state_file"
        return
    end

    set --local row (command awk -F '\t' -v branch="$branch" '$1 == branch { print $2 "\t" $3 "\t" $4; exit }' "$state_file")
    if test -z "$row"
        return
    end

    set --local fields (string split \t -- "$row")
    set --local badge $fields[1]
    if test "$fields[2]" = "stale"
        set badge "$badge stale+$fields[3]"
    end

    echo " [$badge]"
end

function _pure_prompt_git_branch
    set --local git_branch (_prompt_parallel_logical_branch)
    set --local git_branch_color (_pure_set_color $pure_color_git_branch)
    set --local git_branch_display (_prompt_parallel_branch_display "$git_branch")
    set --local git_branch_badge (_prompt_parallel_task_badge "$git_branch")

    echo "$git_branch_color$git_branch_display$git_branch_badge"
end

function _pure_prompt_git_dirty
    if _prompt_parallel_is_prom_app_dir
        echo ""
        return
    end

    set --local git_dirty_symbol
    set --local git_dirty_color

    set --local is_git_dirty (
        if command git rev-list --max-count=1 HEAD -- >/dev/null 2>&1;
            not command git diff-index --ignore-submodules --cached --quiet HEAD -- >/dev/null 2>&1;
        else;
            not command git diff --staged --ignore-submodules --no-ext-diff --quiet --exit-code >/dev/null 2>&1;
        end
        or not command git diff --ignore-submodules --no-ext-diff --quiet --exit-code >/dev/null 2>&1
        or command git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>&1
        and echo "true"
    )
    if test -n "$is_git_dirty"
        set git_dirty_symbol "$pure_symbol_git_dirty"
        set git_dirty_color (_pure_set_color $pure_color_git_dirty)
    end

    echo "$git_dirty_color$git_dirty_symbol"
end

function _pure_prompt_git_stash
    if _prompt_parallel_is_prom_app_dir
        echo ""
        return
    end

    set --local git_stash_symbol
    set --local git_stash_color
    set --local git_stash_number

    set --local git_stash_count (
        command git rev-list --walk-reflogs --count refs/stash 2> /dev/null
        or echo "0"
    )
    if test "$git_stash_count" -gt 0
        set git_stash_symbol " $pure_symbol_git_stash"
        set git_stash_color (_pure_set_color $pure_color_git_stash)
        if test "$pure_show_numbered_git_indicator" = true
            set git_stash_number "$git_stash_count"
        end
    end

    echo "$git_stash_color$git_stash_symbol$git_stash_number"
end

function _pure_prompt_git_pending_commits
    if _prompt_parallel_is_prom_app_dir
        echo ""
        return
    end

    set --local git_unpushed_commits
    set --local git_unpulled_commits

    set --local has_upstream (command git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if test -n "$has_upstream"
        and test "$has_upstream" != '@{upstream}'
        command git rev-list --left-right --count 'HEAD...@{upstream}' \
        | read --local --array git_status
        set --local commit_to_push $git_status[1]
        set --local commit_to_pull $git_status[2]

        if test "$commit_to_push" -gt 0; and test "$commit_to_pull" -gt 0
            set --local color (_pure_set_color $pure_color_git_unpushed_commits)
            set --local diverged "$color⇅"
            if test "$pure_show_numbered_git_indicator" = true
                set diverged "$diverged$commit_to_push/$commit_to_pull"
            end
            echo "$diverged"
            return
        end

        if test "$commit_to_push" -gt 0
            set --local git_unpushed_commits_color (_pure_set_color $pure_color_git_unpushed_commits)
            set git_unpushed_commits "$git_unpushed_commits_color$pure_symbol_git_unpushed_commits"
            if test "$pure_show_numbered_git_indicator" = true
                set git_unpushed_commits "$git_unpushed_commits$commit_to_push"
            end
        end

        if test "$commit_to_pull" -gt 0
            set --local git_unpulled_commits_color (_pure_set_color $pure_color_git_unpulled_commits)
            set git_unpulled_commits "$git_unpulled_commits_color$pure_symbol_git_unpulled_commits"
            if test "$pure_show_numbered_git_indicator" = true
                set git_unpulled_commits "$git_unpulled_commits$commit_to_pull"
            end
        end
    end

    echo "$git_unpushed_commits$git_unpulled_commits"
end
