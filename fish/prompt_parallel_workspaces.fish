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

function _prompt_parallel_home_branch
    set --local git_root (_prompt_parallel_git_root)
    if test -z "$git_root"
        return
    end

    set --local flow_toml "$git_root/flow.toml"
    if not test -f "$flow_toml"
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
    set --local home_branch (_prompt_parallel_home_branch)
    if test -z "$home_branch"
        return
    end

    if test "$branch" = "$home_branch"
        echo home
        return
    end

    if string match --quiet --regex '^review/' -- "$branch"
        echo review
        return
    end

    if string match --quiet --regex '^codex/' -- "$branch"
        echo codex
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

function _pure_prompt_git_branch
    set --local git_branch (_pure_parse_git_branch)
    set --local git_branch_color (_pure_set_color $pure_color_git_branch)

    echo "$git_branch_color"(_prompt_parallel_branch_display "$git_branch")
end

function _pure_prompt_git_pending_commits
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
