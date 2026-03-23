# alias o="fts"
alias ww="w ~/workspaces/main/..code-workspace"
alias npx="bunx"
# TODO: should not be there. just have it under `unite` which is j. but keeping for now
# alias n="frs"
alias fs="f s"
alias pi="pnpm i"
# alias js="just s" # TODO: do with watch like bun --watch
alias a="eza -I 'license'" # list files (without license)
alias af="type" # <cmd> - view definition of <cmd>
alias dF="cd ~/src/pause && eza"
alias gl="git pull"
alias wr="cursor readme.md"
alias da="cd ~/src && eza"
# alias dj="cd ~/src/ts && eza"
# alias rr="rm -rf"
alias dj="cd ~/try && eza"
alias dw="cd ~/try/wip && eza"
alias dv="cd ~/try/src && eza"
alias ds="cd ~/test && eza"
alias pip="pip3"
alias oo="codex"
# alias dv="cd ~/src/nikiv.dev && eza"
alias doing="cd ~/doing && eza"
alias dn="cd ~/src/py && eza"
alias dm="cd ~/src/go && eza"
# alias dl="cd ~/src/org/la/la && eza"
alias dl="cd ~/r && eza"
alias dL="cd ~/src/org/la/x && eza"
alias dz="cd ~/try && eza"
alias dZ="cd ~/try/z && eza"
alias de="cd ~/new && eza"
# alias db="cd ~/src/base && eza"
alias dq="cd ~/Documents && eza"
alias dp="cd ~/past && eza"
alias dg="cd ~/src/other && eza"
alias dP="cd ~/past/private && eza"
alias dd="cd ~/try/tmp/day && eza"
# alias dd="cd ~/data && eza"
# alias dD="cd ~/data/private && eza"
alias dk="cd ~/src/org/solbond/solbond && eza"
alias dt="cd ~/desktop && eza"
alias df="cd ~/org && eza"
# alias dv="cd ~/src/nikiv.dev && eza"
alias di="cd ~/i && eza"
alias aa="eza -la" # list files (with hidden)
# alias r="ronin"
# alias npm="bun"
alias v="mv" # move files/folders or rename
alias dc="cd ~/config && eza"
alias pr="gh pr checkout"
alias nb="nix-build"

function __flow_bin
    for candidate in "$HOME/bin/f-bin" "$HOME/.flow/bin/f" "$HOME/bin/f" "$HOME/.local/bin/f"
        if test -x "$candidate"
            echo "$candidate"
            return 0
        end
    end

    set -l resolved (type -p f-bin 2>/dev/null)
    if test -n "$resolved"
        echo "$resolved"
        return 0
    end

    set resolved (type -p f 2>/dev/null)
    if test -n "$resolved"
        echo "$resolved"
        return 0
    end

    echo "flow binary not found" >&2
    return 1
end

function __flow_cli
    set -l bin (__flow_bin)
    or return 1
    $bin $argv
end

function __flow_codex
    __flow_cli codex $argv
end

function __kit_bin
    if test -x "$HOME/repos/mark3labs/kit/output/kit"
        echo "$HOME/repos/mark3labs/kit/output/kit"
        return 0
    end

    set -l resolved (type -p kit 2>/dev/null)
    if test -n "$resolved"
        echo "$resolved"
        return 0
    end

    echo "kit binary not found" >&2
    return 1
end

function __codex_is_explicit_subcommand
    if test (count $argv) -eq 0
        return 1
    end

    switch $argv[1]
        case '-*' list ls latest latest-id sessions sess continue new resume connect home open resolve doctor enable-global daemon memory skill-eval skill-source runtime find findAndCopy copy context show recover help save notes remove import init copy-codex copy-claude cx cc
            return 0
    end

    return 1
end

function __codex_is_passthrough_l_subcommand
    if test (count $argv) -eq 0
        return 1
    end

    switch $argv[1]
        case '-*' list ls latest latest-id sessions sess resume connect home open resolve doctor enable-global daemon memory skill-eval skill-source runtime find findAndCopy copy context show recover help save notes remove import init copy-codex copy-claude cx cc
            return 0
    end

    return 1
end

function __codex_arg_looks_like_session_id
    if test (count $argv) -ne 1
        return 1
    end

    set -l token (string lower -- "$argv[1]")

    # Keep this conservative so normal `k <query>` behavior does not regress.
    # Accept canonical UUIDs and obvious hyphenated prefixes first.
    if string match -qr '^[0-9a-f]{8}-[0-9a-f-]{1,28}$' -- "$token"
        return 0
    end

    # Also allow longer hex-only prefixes, but avoid short accidental matches.
    if string match -qr '^[0-9a-f]{16,36}$' -- "$token"
        return 0
    end

    return 1
end

function ee
    __flow_cli agents $argv
end

function er
    forge review --dev-cmd "npm run dev" $argv
end

function run_ts_script
    set script_name $argv[1]
    set script_path ~/src/ts/scripts/$script_name.ts

    if test -f $script_path
        set -e argv[1]
        bun $script_path $argv
    else
        echo "Script not found: $script_path"
        return 1
    end
end
for script in ~/src/ts/scripts/*.ts
    set script_name (basename $script .ts)
    alias $script_name "run_ts_script $script_name"
end

# _functions
# TODO: make completions for `: ` so it gets the scripts found in package.json
# below is maybe hacky way to do it but it has to by dynamic
# function :
#     if not set -q argv[1]
#         bun dev
#     # if ` <port-number>`, run `bun dev --port 300<port-number>`
#     else if string match -qr '^[0-9]+$' $argv[1]
#         set -l port_suffix $argv[1]
#         set -l full_port "300$port_suffix"
#         bun dev --port $full_port
#     else
#         bun $argv
#     end
# end

function j
    if __codex_is_explicit_subcommand $argv
        __flow_codex $argv
        return $status
    end

    set -l cwd (pwd -P)
    if test (count $argv) -eq 0
        __flow_codex open --path "$cwd" --exact-cwd
        return $status
    end

    set -l query (string join " " $argv)
    __flow_codex open --path "$cwd" --exact-cwd "$query"
end

function :p
    bun dev --port $argv
end

# TODO: move
# function r
#     if not set -q argv[1]
#         encore run
#     else
#         encore $argv
#     end
# end

# function i
#     if not set -q argv[1]
#         bun i
#     else
#         bun i $argv
#     end
# end

function p
    amp
end

# function p
#     realpath $argv | pbcopy
# end

# function p
#     if not set -q argv[1]
#         pnpm i
#     else
#         pnpm add $argv
#     end
# end

function pd
    if not set -q argv[1]
        pnpm dev
    else
        # pnpm add $argv
    end
end

# TODO: should not be needed if you do `i` command through fast ai check to auto get what should go into `dev`
# install dev dependencies
function idev
    if not set -q argv[1]
        pnpm i
    else
        pnpm add -d $argv
    end
end

# function ::
#     if not set -q argv[1]
#         deno repl # TODO: change
#     else
#         deno $argv
#     end
# end

function :se
    bun seed $argv
end

# function ,
#     if not set -q argv[1]
#         cursor .
#     else
#         cursor $argv
#     end
# end

function W
    if not set -q argv[1]
        open -a /Applications/Cursor.app .
    else
        # Check if any of the arguments are files that don't exist
        set -l missing_files
        for arg in $argv
            # Skip if it's a directory or a flag/option (starts with -)
            if not string match -q -- "-*" $arg; and not test -d $arg; and not test -e $arg
                set -a missing_files $arg
            end
        end

        if test (count $missing_files) -gt 0
            echo "Creating missing files: $missing_files"
            for file in $missing_files
                # Create parent directories if they don't exist
                set -l dir (dirname $file)
                if test "$dir" != "."
                    mkdir -p $dir
                end
                touch $file
            end
        end

        open -a /Applications/Cursor.app $argv
    end
end

function q
    if test (count $argv) -eq 0
        W (pwd -P)
        return $status
    end

    set -l resolved
    for arg in $argv
        switch $arg
            case .
                set -a resolved (pwd -P)
            case '*'
                set -a resolved $arg
        end
    end

    W $resolved
end

# function w
#     if not set -q argv[1]
#         open -a /Applications/Zed.app .
#     else
#         # Check if any of the arguments are files that don't exist
#         set -l missing_files
#         for arg in $argv
#             # Skip if it's a directory or a flag/option (starts with -)
#             if not string match -q -- "-*" $arg; and not test -d $arg; and not test -e $arg
#                 set -a missing_files $arg
#             end
#         end

#         if test (count $missing_files) -gt 0
#             echo "Creating missing files: $missing_files"
#             for file in $missing_files
#                 # Create parent directories if they don't exist
#                 set -l dir (dirname $file)
#                 if test "$dir" != "."
#                     mkdir -p $dir
#                 end
#                 touch $file
#             end
#         end

#         set -l should_stop_live 0
#         for arg in $argv
#             if string match -q -- "-*" $arg
#                 continue
#             end
#             set -l base (basename -- $arg)
#             if string match -q -- ".env*" $base
#                 set should_stop_live 1
#                 break
#             end
#         end

#         if test $should_stop_live -eq 1
#             open -g "lin://stream?stop=true"
#             sleep 0.2
#         end

#         open -a /Applications/Zed.app $argv
#     end
# end

# tunnels local telegram mini app (usually on port 5173 with the `tma.internal` domain)
function ngTelegram
    set -l port 5173
    set -l domain "tma.internal"
    ngrok http "https://$domain:$port" --host-header="$domain:$port"
end

function ng
    ngrok http 3000
end

# g. - commit all with `.` as message
function g.
    git add .
    git commit -m "."
    git push
end

function prettierAll
    bunx prettier --write "**/*.{js,json,css,tsx,ts}"
end

# TODO: might be buggy
function gitSetSshOrigin
    set -l repo_url $argv[1]
    # Extract username and repo name from the URL
    set -l repo_path (echo $repo_url | sed -E 's/.*github\.com[:/]([^/]+\/[^/]+)(\.git)?$/\1/')
    # Construct the SSH URL
    set -l ssh_url "git@github.com:$repo_path.git"
    # Remove existing origin if it exists
    git remote remove origin 2>/dev/null
    # Add new origin with SSH URL
    git remote add origin $ssh_url
    # Get current branch name
    set -l current_branch (git rev-parse --abbrev-ref HEAD)

    # Check if this is a new repository
    if test (git rev-parse HEAD 2>/dev/null)
        # If repository has commits, try to set upstream
        git push -u origin $current_branch
    else
        echo "New repository detected. Please make an initial commit first, then run:"
        echo "git push -u origin $current_branch"
    end

    echo "Remote origin set to: $ssh_url"
end


function deleteNodeModules
    find . -type d -name node_modules -prune -print | xargs rm -rf
end

# full `bun i` reset
function :d
    find . -type d -name node_modules -prune -print | xargs rm -rf
    test -f bun.lock && rm bun.lock
    test -f bun.lockb && rm bun.lockb
    bun i
end

# find .env files
function f.
    for env_file in (find . -type d -name node_modules -prune -o -type f -name ".env" -print)
        bat $env_file
    end
end

# function fg
#     if not set -q argv[1]
#         # cd ~/
#         # flox list
#     else
#         # cd ~/
#         # flox install $argv
#     end
# end

# function fi
#     if not set -q argv[1]
#         # flox init TODO:
#     else
#         flox install $argv
#     end
# end


function fse
    if not set -q argv[1]
        # flox TODO:
    else
        flox search $argv
    end
end

function fsa
    if not set -q argv[1]
        # flox TODO:
    else
        flox search $argv --all
    end
end

function w.
    cursor .env
end

function e.
    bat .env
end

# function n
#     if not set -q argv[1]
#         python3
#     else
#         uv run -m $argv
#     end
# end


function nw
    if test -z "$argv[1]"
        echo "Usage: nw <script_name>"
        return 1
    end
    watchexec --no-vcs-ignore --restart --exts py --clear --project-origin . "tput reset && uv run -m scripts.$argv"
end

function c
    if not set -q argv[1]
        open .
    else
        open $argv
    end
end

# function z
#     if not set -q argv[1]
#         zed .
#     else
#         zed $argv
#     end
# end

function z
    if not set -q argv[1]
        ctx .
    else
        set -l flags --optimized
        set -l task_parts
        for arg in $argv
            if string match -q -- '--*' $arg
                set -a flags $arg
            else
                set -a task_parts $arg
            end
        end
        ctx gather . $flags (string join " " $task_parts)
    end
end

function md
    mkdir -p $argv[1] && cd $argv[1]
end

function :i
    bun i $argv
end

function :id
    bun i -d $argv
end

function :g
    bun i -g $argv
end

# set env vars in current shell
# function x
#     if test (count $argv) -eq 1
#         set -x $argv[1]
#     else if test (count $argv) -ge 2
#         set -x $argv[1] $argv[2..-1]
#     else
#         echo "Usage: x VARIABLE [VALUE]"
#         return 1
#     end
# end

function x
    if not set -q argv[1]
        ctx -O .
    else
        ctx -O $argv
    end
end

# nix eval file (with watch)
function ne
    if test -z "$argv[1]"
        echo "Usage: ne <nix_file>"
        return 1
    end
    set -l file $argv[1]
    watchexec --no-vcs-ignore --restart --exts nix --clear --project-origin . "tput reset && nix-instantiate --eval --strict --json $file | jq"
end

# unstable, but does work for https://github.com/nikivdev/cpp
function cpp
    watchexec --no-vcs-ignore --restart --exts cpp --clear --project-origin . "tput reset && make -C build && src/main"
end

# function m
#     watchexec --no-vcs-ignore --restart --exts mbt --clear --project-origin . -q "tput reset && moon run $argv"
# end

function nv
    if not set -q argv[1]
        nvim .
    else
        nvim $argv
    end
end

# TODO: change
# function gh
#     git fetch --unshallow
#     juxta .
# end

function g
    if not set -q argv[1]
        smerge .
    else
        git $argv
    end
end

# run `cargo run` when rust files change | <query> - run with query
# function i
#     if not set -q argv[1]
#         cargo watch -q -- sh -c "tput reset && cargo run -q"
#     else
#         cargo watch -q -- sh -c "tput reset && cargo run -q -- $argv"
#         # TODO: test below, supposedly it's better and safer (per https://matrix.to/#/!YLTeaulxSDauOOxBoR:matrix.org/$mM0QC4VSo5BmI1o3qfKg5vjDs6sok1FwBtKy2UlI4Xs?via=gitter.im&via=matrix.org&via=tchncs.de)
#         # cargo watch -q -- sh -c 'tput reset && cargo run -q -- "$@"' watchscript $argv
#     end
# end

# R - run tests with cargo and watch
function R
    if not set -q argv[1]
        cargo watch -q -- sh -c "tput reset && cargo test -q --lib"
    else
        cargo watch -q -- sh -c "tput reset && cargo test -q --lib -- $argv --nocapture"
        # TODO: prob move it to separate cmd as there is use case of running specific test and not see logs as is usual
        # cargo watch -q -- sh -c "tput reset && cargo test -q --lib -- $argv"
    end
end

# rs - run rust test code for quick edits
function rs
    cargo watch -q -- sh -c "tput reset && cargo test -q --lib -- run --nocapture"
end

# function :c
#     if not set -q argv[1]
#         set cli_file (fd -t f -p "cli.ts" | head -n 1)
#         if test -n "$cli_file"
#             cursor "$cli_file"
#             bun cli
#         else
#             # TODO:
#             # bun cli
#         end
#     else
#         # TODO:
#     end
# end

function :s
    # set run_file (fd -t f -p "scripts/run.ts" | head -n 1)
    # if test -n "$run_file"
    #     cursor "$run_file"
    # end
    bun s
end

function :sr
    set run_file (find . -name "p-run.ts" -path "*/scripts/*" | head -n 1)
    if test -n "$run_file"
        cursor "$run_file"
    end
    bun sr
end

function find.git
    find . -type d -name ".git"
end

function rmGitFoldersInsideThisFolder --description "Find and delete all nested .git directories except the one at current root"
    # Find all .git directories
    set -l git_dirs (find . -type d -name ".git")

    # Separate root .git from nested ones
    set -l to_delete

    for dir in $git_dirs
        # Only add to deletion list if it's not the root .git
        if test "$dir" != "./.git"
            set -a to_delete $dir
        end
    end

    # Display what will be deleted
    echo "Found root .git directory (will be kept):"
    echo "  ./.git"

    if test (count $to_delete) -eq 0
        echo "No nested .git directories to delete."
        return 0
    end

    echo "The following nested .git directories will be deleted:"
    for dir in $to_delete
        echo "  $dir"
    end

    # Ask for confirmation
    read -l -P "Are you sure you want to delete these directories? (y/N) " confirm
    if test "$confirm" != "y" -a "$confirm" != "Y"
        echo "Operation cancelled."
        return 1
    end

    # Perform deletion
    for dir in $to_delete
        echo "Deleting $dir"
        rm -rf "$dir"
    end
    echo "Deletion complete."
end

function find.DS_Store
    find . -type f -name ".DS_Store"
end


# function m
#     if not set -q argv[1]
#         watchexec --no-vcs-ignore --restart --quiet --exts go --clear --project-origin . "go run ."
#     else
#         go $argv
#     end
# end


# oi = go install ..
function mi
    if not set -q argv[1]
        echo "Usage: oi <github-user/repo>"
        return 1
    else
        # TODO: turn this into ts script
        # example cmd: go install github.com/no-src/gofs/...@latest
        go install github.com/$argv[1]/...@latest
    end
end

function re
    if not set -q argv[1]
        repopack .
    else
        repopack $argv
    end
end

# function fs
#     flox activate -s
# end

function :u
    bun update --latest
end

function fl
   flox services logs --follow
end

function fr
   flox services restart
end


# TODO: replace with own tool
# function e
#     if not set -q argv[1]
#         code2prompt .
#     else
#         code2prompt $argv
#     end
# end

# function c
#     if not set -q argv[1]
#     else
#         bat $argv
#     end
# end

# function l
#     if test (count $argv) -eq 0
#         pwd | pbcopy
#     else
#         bat --paging=never -- $argv
#         cat -- $argv | pbcopy
#     end
# end

function changeRemoteToFork
    set -l repo_url $argv[1]

    # Extract the repo name from the URL
    set -l repo_name (string split '/' $repo_url | tail -n 1)

    # Set the GitHub username directly in the function
    set -l github_username "nikivdev"

    # Construct the new URL
    set -l new_url "https://github.com/$github_username/$repo_name"

    # Change the remote URL
    git remote set-url origin $new_url

    if test $status -eq 0
        echo "Remote URL changed successfully to: $new_url"
        echo "Current remotes:"
        git remote -v
    else
        echo "Error: Failed to change remote URL"
    end
end

function d
    if not set -q argv[1]
        /Users/nikitavoloboev/.cargo/bin/dev
    else
        if cd $argv 2>/dev/null
            eza
        else
            z $argv
            if test $status -eq 0
                eza
            else
                return 1
            end
        end
    end
end

function :w
    bun --watch $argv
end

# TODO: prob no need for this, can just get active path and pass it to bun --watch
# function :ws
#     if test -n "$argv[1]"
#         if test -f "$argv[1]"
#             bun --watch "$argv[1]"
#         else if test -f "scripts/$argv[1]"
#             bun --watch "scripts/$argv[1]"
#         else
#             echo "Could not find file: $argv[1] or scripts/$argv[1]"
#             return 1
#         end
#     else
#         bun --watch
#     end
# end

function ..
    cd ..
    eza
end

function tsgo
    bunx tsgo
end

# function l
#     ollama $argv
# end

# function l
#     if not set -q argv[1]
#         pnpm dev
#     else
#         pnpm i $argv
#     end
# end

# TODO: move
# function s
#     if not set -q argv[1]
#     else
#         watchexec --no-vcs-ignore --restart --exts swift --clear --project-origin . "tput reset && swift $argv"
#     end
# end

function :ts
    bun --watch ~/src/ts/lib/ts-utils/scripts/run.ts
end

function :r
    bun --watch ~/test/ts/scripts/run.ts
end

# TODO: make into proper tool with completions etc.
# TODO: do I miss anything by taking over `.` builtin?
function `
    bun ~/src/ts/scripts/new.ts $argv
    eza
    # TODO: only do it if its folder, the script should return something in that case, check for the return
    cd $argv
end

function gitRemoteOpen
    git remote get-url origin | sed -e 's/git@github.com:/https:\/\/github.com\//' | xargs open
end

function gitPrOpen
    gh pr view --web
end

function gitChangeRemote
    if not set -q argv[1]
        echo "Please provide a new repository URL"
        return 1
    end

    # Extract username and repo name from the URL
    set -l repo_path (echo $argv[1] | sed -E 's/.*github\.com[:/]([^/]+\/[^/]+)(\.git)?$/\1/')

    # Construct the SSH URL
    set -l ssh_url "git@github.com:$repo_path.git"

    git remote remove origin
    git remote add origin $ssh_url

    echo "Remote origin set to: $ssh_url"
end

function co
    if not set -q argv[1]
        cody --help
    else
        cody $argv
    end
end

function d:
    cd ~/gh && eza
end

function d.
    cd
end

# function d.
#     cd ~/rust && eza
# end

# TODO: moved to :
# function k
#     if not set -q argv[1]
#         # TODO: what is equivalent to `bun dev` in uv
#         # uv run main.py
#         watchexec --no-vcs-ignore --restart --exts py --clear --project-origin . "tput reset && uv run main.py"
#     else
#         uv $argv
#     end
# end


# function dk
#     if not set -q argv[1]
#         # bunx drizzle-kit generate && bunx drizzle-kit migrate
#         bunx drizzle-kit generate
#     else
#         bunx drizzle-kit $argv
#     end
# end

function dkm
    if not set -q argv[1]
        bunx drizzle-kit migrate
    else
        bunx drizzle-kit $argv
    end
end

function .a
    set bike_file (find . -name "*.bike" | head -n 1)
    if test -n "$bike_file"
        open -a "Bike" "$bike_file"
    else
        pwd | pbcopy
        open -a "Bike"
        # TODO: maybe run KM macro and automate creating the file via the `new file` thing in bike
        # https://support.hogbaysoftware.com/t/why-is-it-when-i-create-a-bike-file-from-shell-it-will-show-extension-in-app/6020 due to this issue
    end
end

# TODO: not used until https://support.hogbaysoftware.com/t/why-is-it-when-i-create-a-bike-file-from-shell-it-will-show-extension-in-app/6020 is fixed
# function .a
#     set bike_file (find . -name "*.bike" | head -n 1)
#     if test -n "$bike_file"
#         open -a "Bike" "$bike_file"
#     else
#         set dir_name (basename (pwd))
#         set new_file "$dir_name.bike"
#         touch "$new_file"
#         open -a "Bike" "$new_file"
#     end
# end

function replace
    if test (count $argv) -ne 2
        echo "Usage: replace <from> <to>"
        echo "Example: replace '~' '~~'"
        return 1
    end

    for file in *
        set newname (string replace -a "$argv[1]" "$argv[2]" "$file")
        if test "$file" != "$newname"
            mv "$file" "$newname"
        end
    end
end

# function :a
#     bun run deploy
# end

function :c
    find . -type d -name node_modules -prune -print | xargs rm -rf
    bun i
end

# clone using SSH URL format
function gcRaw
    if not set -q argv[1]
        echo "Usage: gc <github-url>"
        return 1
    end
    # extract repo path from the URL
    set repo_path (string replace -r 'https://github.com/' '' $argv[1])
    # clone using SSH URL format
    git clone "git@github.com:$repo_path.git"
end

function h
    if not set -q argv[1]
        __flow_cli repos
    else
        __flow_cli repos clone $argv[1]
    end
end

# function .
#     ~/bin/f rerun
# end

function repoCleanup
    find . -type f -name "README.md" -not -path "*/node_modules/*" -exec sh -c '
        tmp="$1.tmp"
        mv "$1" "$tmp" && mv "$tmp" "$(dirname "$1")/readme.md"
    ' _ {} \;
    find . -type f -name "LICENSE" -not -path "*/node_modules/*" -exec sh -c '
        tmp="$1.tmp"
        mv "$1" "$tmp" && mv "$tmp" "$(dirname "$1")/license"
    ' _ {} \;
    find . -type f -name "CHANGELOG.md" -not -path "*/node_modules/*" -exec sh -c '
        tmp="$1.tmp"
        mv "$1" "$tmp" && mv "$tmp" "$(dirname "$1")/changelog.md"
    ' _ {} \;
    find . -type f -name "CODE_OF_CONDUCT.md" -not -path "*/node_modules/*" -exec sh -c '
        tmp="$1.tmp"
        mv "$1" "$tmp" && mv "$tmp" "$(dirname "$1")/code-of-conduct.md"
    ' _ {} \;
    find . -type f -name "CONTRIBUTING.md" -not -path "*/node_modules/*" -exec sh -c '
        tmp="$1.tmp"
        mv "$1" "$tmp" && mv "$tmp" "$(dirname "$1")/contributing.md"
    ' _ {} \;
end

# sync local .git folder with remote repo
function gs
    set current_folder (basename $PWD)
    if string match -rq '(.+)--(.+)' $current_folder
        set -l original_author (string match -r '(.+)--(.+)' $current_folder)[2]
        set -l repo_name (string match -r '(.+)--(.+)' $current_folder)[3]
        gh repo sync "nikivdev/$repo_name" --source "git@github.com:$original_author/$repo_name"
        git pull
    else
        echo "Error: Could not parse repository info from directory name"
        echo "Directory should be in format: author--repo"
        return 1
    end
end

# git sync
function gsync
    # Save current branch to return to it later
    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Make sure we have upstream set
    if not git remote | grep -q upstream
        echo "No upstream remote found. Please add it first with:"
        echo "git remote add upstream git@github.com:original-owner/repository.git"
        return 1
    end

    # Fetch all from upstream
    echo "Fetching all branches from upstream..."
    git fetch upstream --prune

    # Get list of all upstream branches
    set upstream_branches (git branch -r | grep upstream/ | grep -v HEAD | sed 's/  upstream\///')

    echo "Syncing branches from upstream..."

    # For each upstream branch
    for branch in $upstream_branches
        # Skip if it's the same as our local test branch
        if test "$branch" = "test"
            echo "Skipping 'test' branch as you have a local branch with this name"
            continue
        end

        # Check if we already have this branch locally
        if git show-ref --verify --quiet refs/heads/$branch
            # Branch exists, update it
            echo "Updating existing branch: $branch"
            git checkout $branch
            git merge upstream/$branch
        else
            # Branch doesn't exist, create it
            echo "Creating new branch: $branch"
            git checkout -b $branch upstream/$branch
        end
    end

    # Return to the original branch
    echo "Returning to '$current_branch' branch"
    git checkout $current_branch

    echo "All branches have been synced with upstream"
end

function gsyncMain
    # Save current branch to return to it later
    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Make sure we have upstream set
    if not git remote | grep -q upstream
        echo "No upstream remote found. Please add it first with:"
        echo "git remote add upstream git@github.com:original-owner/repository.git"
        return 1
    end

    # Fetch all from upstream
    echo "Fetching from upstream..."
    git fetch upstream --prune

    # Check if main branch exists locally
    if git show-ref --verify --quiet refs/heads/main
        # Branch exists, update it
        echo "Updating main branch"
        git checkout main
        git merge upstream/main
    else
        # Branch doesn't exist, create it
        echo "Creating main branch"
        git checkout -b main upstream/main
    end

    # Return to the original branch
    echo "Returning to '$current_branch' branch"
    git checkout $current_branch

    echo "Main branch has been synced with upstream"
end


# TODO: does it work
# used as catch all for fast scripts
# function ,
#     for dir in *=*
#         set newdir (string replace --all "=" "__" "$dir")
#         mv "$dir" "$newdir"
#     end
# end


function triggerBuildWithNoCommit
    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Validate git state
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository"; return 1
    end
    if not git diff --quiet HEAD
        echo "Error: Working directory not clean"; return 1
    end

    # Push empty commit
    git commit --allow-empty -m "temp: trigger build"
    if not git push origin $current_branch
        git reset HEAD~1; return 1
    end

    # Cleanup immediately
    git reset HEAD~1
    git push --force origin $current_branch || begin
        echo "Error: Failed to cleanup. Run: git reset HEAD~1 && git push --force"
        return 1
    end

    echo "✓ Build triggered"
end


# TODO: move to sf key
# TODO: use chrome driver. get around cloudflare. index proper
function sfOld
    if test -z "$argv[1]"
        echo "Usage: sf <url>"
        return 1
    end

    # Extract domain from URL (remove protocol if present and path)
    set domain (echo $argv[1] | sed -E 's|^https?://||' | cut -d'/' -f1)
    # Create filename from domain
    set filename "$HOME/sites/$domain.txt"

    # Check if URL already starts with http(s)://
    if string match -q 'http*://*' $argv[1]
        sitefetch "$argv[1]" -o $filename
    else
        sitefetch "https://$argv[1]" -o $filename
    end

    # Copy content to clipboard
    cat $filename | pbcopy
    echo "Saved to $filename (content copied to clipboard)"
end

# TODO: add back
# function s
#     if test -z "$argv[1]"
#         echo "Usage: sf <url>"
#         return 1
#     end

#     # Extract domain and path from URL
#     set url (echo $argv[1] | sed -E 's|^https?://||')
#     set domain (echo $url | cut -d'/' -f1)
#     set path (echo $url | grep -o '/.*$' || echo '/')

#     # Create filename from domain
#     set filename "$HOME/sites/$domain.txt"

#     # Build the sitefetch command with exact path matching
#     if string match -q 'http*://*' $argv[1]
#         sitefetch "$argv[1]" -o $filename -m "$path"
#     else
#         sitefetch "https://$argv[1]" -o $filename -m "$path"
#     end

#     # Copy content to clipboard
#     cat $filename | pbcopy
#     echo "Saved to $filename (content copied to clipboard)"
# end


function killPort
    if test -z "$argv[1]"
        echo "Usage: killPort <port_number>"
        return 1
    end

    set port_processes (lsof -ti:$argv[1])
    if test -z "$port_processes"
        echo "No processes found on port $argv[1]"
        return 0
    end

    kill $port_processes
    echo "Killed process(es) on port $argv[1]"
end


function portCheck
    if test -z "$argv[1]"
        echo "Usage: portCheck <port_number>"
        return 1
    end
    lsof -i :$argv[1]
end

# TODO: find how to do smth like `tree-layout | tee /dev/tty | pbcopy` but preserve colors
# print folder/file layout deeply + copy to clipboard
function tr
    tree-layout
    tree-layout | pbcopy
end

function T
    set current_path (string replace -r "^$HOME" "~" (pwd))
    echo $current_path
    tree-layout
    begin
        echo $current_path
        tree-layout
    end | pbcopy
end


function :b
    bun run build
end

# function c
#     set -l last_output (eval "echo (history --max=1)")
#     if test -n "$last_output"
#         echo "$last_output" | pbcopy
#         echo "Last command output copied to clipboard"
#     else
#         echo "No output from last command to copy"
#     end
# end

# TODO: this should be automatic. paste all command outputs to some sqlite file
# copy last command output to clipboard (including the command that was executed)
# function .
#     # Get the last command from history
#     set -l last_cmd (history --max=1)
#     # For display purposes, try to get a clean name
#     set -l cmd_name (string split ' ' $last_cmd)[1]
#     set -l display_cmd $last_cmd
#     # If the command is an alias or function, try to display a nicer version
#     if functions -q $cmd_name
#         # Look for the first line with actual command execution
#         set -l actual_cmd (functions $cmd_name | grep -E '^\s+\w+' | head -n1 | string trim)
#         if test -n "$actual_cmd"
#             # Get just the command without the $argv
#             set display_cmd (string replace -r '\s+\$argv.*$' '' $actual_cmd)
#             # Add any arguments
#             set -l args (string split ' ' $last_cmd | tail -n +2 | string join ' ')
#             if test -n "$args"
#                 set display_cmd "$display_cmd $args"
#             end
#         end
#     end

#     # useful addition my personal use (not to confuse llms)
#     # hard-code replacement of eza -I 'license' with ls
#     set display_cmd (string replace "eza -I 'license'" "ls" $display_cmd)
#     set display_cmd (string replace "eza -la" "ls -la" $display_cmd)

#     # Create a temporary file to store command output
#     set -l temp_file (mktemp)
#     # Add the command line with $ prefix
#     echo "\$ $display_cmd" >$temp_file
#     # Re-run the last command and capture output
#     eval $last_cmd >>$temp_file 2>&1
#     # Copy to clipboard
#     cat $temp_file | pbcopy
#     # Clean up
#     rm $temp_file
# end

# TODO: bind & use this
# symlink a file to ~/bin with a specified name
# function b
#     # Check if exactly two arguments are provided
#     if test (count $argv) -ne 2
#         echo "Usage: bin <source_file> <target_name>"
#         echo "Example: bin dist/cli.js sitefetch"
#         return 1
#     end

#     set -l source_file $argv[1]
#     set -l target_name $argv[2]
#     set -l bin_dir "$HOME/bin"

#     # Ensure the source file exists
#     if not test -f $source_file
#         echo "Error: Source file '$source_file' does not exist"
#         return 1
#     end

#     # Make the source file executable
#     chmod +x $source_file
#     if test $status -ne 0
#         echo "Error: Failed to make '$source_file' executable"
#         return 1
#     end

#     # Create ~/bin if it doesn't exist
#     if not test -d $bin_dir
#         mkdir -p $bin_dir
#         if test $status -ne 0
#             echo "Error: Failed to create '$bin_dir'"
#             return 1
#         end
#     end

#     # Ensure ~/bin is in PATH
#     if not contains $bin_dir $PATH
#         set -U fish_user_paths $bin_dir $fish_user_paths
#         echo "Added '$bin_dir' to PATH"
#     end

#     # Resolve the absolute path of the source file
#     set -l abs_source (realpath $source_file)
#     if test $status -ne 0
#         echo "Error: Failed to resolve absolute path of '$source_file'"
#         return 1
#     end

#     # Create or update the symlink
#     set -l target_path "$bin_dir/$target_name"
#     if test -e $target_path
#         echo "Removing existing '$target_path'"
#         rm $target_path
#         if test $status -ne 0
#             echo "Error: Failed to remove existing '$target_path'"
#             return 1
#         end
#     end

#     ln -s $abs_source $target_path
#     if test $status -eq 0
#         echo "Symlinked '$abs_source' to '$target_path'"
#     else
#         echo "Error: Failed to create symlink"
#         return 1
#     end
# end

# function mc --description "go build and install a binary"
#     set -l binary_name

#     # Check if an argument is provided
#     if test (count $argv) -eq 0
#         # No argument provided, check for directories in cmd/
#         set -l cmd_dirs (path filter -d cmd/*)
#         set -l num_dirs (count $cmd_dirs)

#         if test $num_dirs -eq 1
#             # Exactly one directory found, use it as the binary name
#             set binary_name (basename $cmd_dirs[1])
#         else
#             # Zero or multiple directories found, prompt for binary name
#             echo "Error: Please specify the binary name. Found $num_dirs directories in cmd/."
#             return 1
#         end
#     else
#         # Use the provided argument as the binary name
#         set binary_name $argv[1]
#     end

#     set -l gopath (go env GOPATH)

#     # Build the binary locally
#     # echo "Building $binary_name locally..."
#     go build -o $binary_name ./cmd/$binary_name
#     if test $status -ne 0
#         echo "Build failed"
#         return 1
#     end

#     # Install the binary to $GOPATH/bin
#     # echo "Installing $binary_name..."
#     go install ./cmd/$binary_name
#     if test $status -ne 0
#         echo "Failed to install $binary_name"
#         return 1
#     end
#     echo "✔ $binary_name installed"
# end


function fn --description "Find directories matching a pattern and exclude node_modules"
    if test (count $argv) -eq 0
        echo "Error: Please provide a search pattern"
        return 1
    end
    fd -td $argv[1] -E node_modules
end

function C
    claude $argv
end

function s
    if test -z "$argv[1]"
        set -l path (string replace -r "^$HOME" "~" (pwd))
        echo -n $path | pbcopy
    else
        set -l path (string replace -r "^$HOME" "~" (realpath $argv[1]))
        echo -n $path | pbcopy
    end
end

# function fa
#     ~/bin/f deploy-and-run
# end

# todo: wrap with fn
# glide index-single-url $argv

function sf
    if test -z "$argv[1]"
        # TODO: change
        pwd | pbcopy
    else
        glide index-full $argv
    end
end

function k
    if __codex_is_passthrough_l_subcommand $argv
        __flow_codex $argv
        return $status
    end

    set -l cwd (pwd -P)
    if __codex_arg_looks_like_session_id $argv
        __flow_codex continue --path "$cwd" $argv[1]
        return $status
    end

    __flow_codex connect --path "$cwd" --exact-cwd $argv
end

function ks
    set -l cwd (pwd -P)
    __flow_codex sessions --path "$cwd" $argv
end

function jj
    __flow_cli ai copy-codex $argv
end

function K
    __flow_cli ai claude new
end

function gb --description "create git branch"
    if test (count $argv) -eq 0
        echo "Error: Please provide a branch name"
        return 1
    end

    # Check if we're in a git repository
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Error: Not in a git repository"
        return 1
    end

    # Create and checkout the new branch
    git checkout -b $argv[1]

    if test $status -eq 0
        echo "✔ Created and switched to branch '$argv[1]'"
    else
        echo "Failed to create branch '$argv[1]'"
        return 1
    end
end

function gRebaseMain \
    --description "Replay current branch on top of origin/main"

    # Detect current branch (abort if detached HEAD)
    set -l branch (git symbolic-ref --quiet --short HEAD)
    if test -z "$branch"
        echo "❌ Not on a branch (detached HEAD?)"
        return 1
    end

    # 1. Get the latest origin/main (and prune deleted refs)
    git fetch --prune origin main; or begin
        echo "❌ Failed to fetch origin/main"
        return 1
    end

    # 2. Re-apply your commits on top of it
    git rebase --autostash origin/main; or begin
        echo "❌ Rebase failed — fix conflicts or run 'git rebase --abort'"
        return 1
    end

    echo "✔ '$branch' now contains everything from origin/main."
    echo "   Verify things work, then push with:"
    echo "     git push --force-with-lease origin $branch"
end

# function l
#     codex --yolo --sandbox danger-full-access
# end

function __prom_codex_is_leaf_branch
    set -l value $argv[1]
    string match -rq -- '^(codex|review)/' "$value"
end

function __prom_codex_supports_leaf_sessions
    set -l cwd (pwd -P)
    if string match -q -- "$HOME/code/prom*" "$cwd"
        return 0
    end
    if string match -q -- "$HOME/.jj/workspaces/prom*" "$cwd"
        return 0
    end
    return 1
end

function __prom_codex_prompt_text
    string lower -- (string join " " $argv)
end

function __codex_flow_bin
    for candidate in "$HOME/bin/flow-bin" "$HOME/.flow/bin/flow" "$HOME/bin/flow" "$HOME/.local/bin/flow"
        if test -x "$candidate"
            echo "$candidate"
            return 0
        end
    end

    set -l resolved (type -p flow-bin 2>/dev/null)
    if test -n "$resolved"
        echo "$resolved"
        return 0
    end

    echo "flow"
end

function __codex_fast_bin
    set -l resolved (type -p codex 2>/dev/null)
    if test -n "$resolved"
        echo "$resolved"
        return 0
    end

    echo "codex"
end

function __codex_fast_trust_config
    set -l cwd (pwd -P)
    set -l paths "$cwd"
    set -l git_root (command git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    if test -n "$git_root"
        if not contains -- "$git_root" $paths
            set paths $paths "$git_root"
        end
    end

    set -l entries
    for path in $paths
        set -l escaped (string replace -a '\\' '\\\\' -- "$path")
        set escaped (string replace -a '"' '\\"' -- "$escaped")
        set -a entries "\"$escaped\"={ trust_level=\"trusted\" }"
    end

    if test (count $entries) -eq 0
        return 1
    end

    echo "projects={ "(string join ", " $entries)" }"
end

function __codex_fast_touch_launch
    set -l mode $argv[1]
    set -l flow_bin (__flow_bin)
    set -l cwd (pwd -P)
    "$flow_bin" codex touch-launch --mode "$mode" --cwd "$cwd" >/dev/null 2>&1 &
end

function __codex_fast_launch
    set -l mode $argv[1]
    set -e argv[1]
    __codex_fast_touch_launch "$mode"
    set -l codex_bin (__codex_fast_bin)
    set -l trust_config (__codex_fast_trust_config)
    if test -n "$trust_config"
        "$codex_bin" --config "$trust_config" $argv
    else
        "$codex_bin" $argv
    end
end

function __codex_prompt_targets_recovery
    set -l prompt (__prom_codex_prompt_text $argv)
    if test -z "$prompt"
        return 1
    end

    if string match -rq -- '(see this (convo|session) in|what was i doing( here| in)?|recover recent context|recover context|recover .* session|continue the .* work|resume the .* work|what happened in pr #[0-9]+|continue .*pr #[0-9]+|resume .*pr #[0-9]+)' "$prompt"
        return 0
    end

    return 1
end

function __codex_recover_target_path
    set -l prompt (__prom_codex_prompt_text $argv)

    for token in $argv
        set -l cleaned (string trim -c "'\"`()[]{}.,:;" -- $token)
        if string match -rq -- '^~/' "$cleaned"
            set -l expanded (string replace -r '^~' "$HOME" -- $cleaned)
            if test -f "$expanded"
                dirname "$expanded"
            else
                echo "$expanded"
            end
            return 0
        end
        if string match -rq -- '^/Users/|^/users/' "$cleaned"
            if test -f "$cleaned"
                dirname "$cleaned"
            else
                echo "$cleaned"
            end
            return 0
        end
    end

    if __prom_codex_prompt_targets_prom $argv
        if __prom_codex_prompt_targets_designer_integration $argv
            echo "$HOME/code/prom/ide/designer"
            return 0
        end
        if __prom_codex_prompt_targets_designer_deps $argv
            echo "$HOME/code/prom/x/nikiv/reactron-rs"
            return 0
        end
        if string match -rq -- '(ide/rev|x/nikiv/rev|move rev|rev dashboard|review-ui)' "$prompt"
            echo "$HOME/code/prom/x/nikiv/rev"
            return 0
        end
        echo "$HOME/code/prom"
        return 0
    end

    if string match -rq -- '(~/repos/openai/codex|/users/nikitavoloboev/repos/openai/codex|codex repo|session-recovery|history.jsonl|thread/list|thread/read)' "$prompt"
        echo "$HOME/repos/openai/codex"
        return 0
    end

    pwd -P
end

function __codex_build_recovery_prompt
    set -l prompt (string join " " $argv)
    if not __codex_prompt_targets_recovery $argv
        echo "$prompt"
        return 0
    end

    set -l target_path (__codex_recover_target_path $argv)
    set -l flow_bin (__codex_flow_bin)
    set -l summary_lines ($flow_bin ai codex recover --summary-only --path "$target_path" $argv 2>/dev/null)

    if test $status -ne 0
        or test (count $summary_lines) -eq 0
        echo "$prompt"
        return 0
    end

    set -l summary (printf "%s\n" $summary_lines | string collect)

    printf "Recovered recent context:\n%s\n\nCurrent task:\n%s\n" "$summary" "$prompt"
end

function __codex_open_recovery_session
    set -l prompt (__codex_build_recovery_prompt $argv)

    if __prom_codex_prompt_targets_prom $argv
        set -lx PROM_CODEX_PROMPT_OVERRIDE "$prompt"
        __prom_codex_open_dispatched_session new $argv
        return $status
    end

    set -l target_path (__codex_recover_target_path $argv)
    env CODEX_RECOVER_TARGET="$target_path" CODEX_RECOVER_PROMPT="$prompt" \
        bash -lc 'cd "$CODEX_RECOVER_TARGET" && exec codex --yolo --sandbox danger-full-access "$CODEX_RECOVER_PROMPT"'
end

function __prom_codex_prompt_targets_prom
    set -l prompt (__prom_codex_prompt_text $argv)
    if test -z "$prompt"
        return 1
    end

    if __prom_codex_prompt_mentions_sync_action $argv
        and string match -rq -- '(~/code/prom|/users/nikitavoloboev/code/prom|origin/main|main@origin|review/nikiv|ide/designer|ide/rev|x/nikiv/reactron-rs|x/nikiv/rev|reactron-rs|reactron rs|reactron/|nikiv)' "$prompt"
        return 0
    end

    if string match -rq -- '(^|[^[:alnum:]_])(~/code/prom|/users/nikitavoloboev/code/prom|review/nikiv|designer-stack|designer-stack-seal|designer-pr-open|designer-session|designer-deps-session|designer-restack|designer-sync-home-deps|prom-codex-sessions|ide/designer|ide/rev|x/nikiv/reactron-rs|x/nikiv/rev|reactron-rs|reactron rs|pr #2572)([^[:alnum:]_]|$)' "$prompt"
        return 0
    end

    if string match -rq -- '(^|[^[:alnum:]_])nikiv([^[:alnum:]_]|$)' "$prompt"
        and string match -rq -- '(origin/main|review/|ide/designer|ide/rev|designer|reactron-rs|reactron rs|x/nikiv/rev|home branch|workspace|designer-stack|designer-pr-open|designer-session|designer-deps-session|prom-codex-sessions)' "$prompt"
        return 0
    end

    return 1
end

function __prom_codex_prompt_mentions_sync_action
    set -l prompt (__prom_codex_prompt_text $argv)
    if test -z "$prompt"
        return 1
    end

    if string match -rq -- '(pull|sync|update|get latest|up to date|rebase|restack|bring .* into|port .* into|bring in)' "$prompt"
        return 0
    end

    return 1
end

function __prom_codex_prompt_targets_designer_deps
    set -l prompt (__prom_codex_prompt_text $argv)
    if test -z "$prompt"
        return 1
    end

    if __prom_codex_prompt_mentions_sync_action $argv
        and string match -rq -- '(reactron-rs|reactron rs|x/nikiv/reactron-rs)' "$prompt"
        and string match -rq -- '(reactron/|reactron|origin/main|main@origin|nikiv)' "$prompt"
        return 0
    end

    if string match -rq -- 'review/nikiv-reactron-rs-designer-support|designer-deps-session|shared reactron|shared reactron-rs|dependency branch|designer deps|x/nikiv/reactron-rs' "$prompt"
        return 0
    end

    if string match -rq -- '(designer|ide/designer)' "$prompt"
        and string match -rq -- '(reactron-rs|reactron rs|reactron/)' "$prompt"
        and string match -rq -- '(deps|dependency|shared|support|base branch|base pr)' "$prompt"
        return 0
    end

    return 1
end

function __prom_codex_prompt_targets_designer_integration
    set -l prompt (__prom_codex_prompt_text $argv)
    if test -z "$prompt"
        return 1
    end

    if string match -rq -- 'review/nikiv-designer-dev-deploy|designer-session|designer-pr-open|designer-stack|bootstrap designer dev with reactron-rs|pr #2572' "$prompt"
        return 0
    end

    if string match -rq -- '(designer|ide/designer)' "$prompt"
        and string match -rq -- '(reactron-rs|reactron rs|npm run dev|f deploy|bootstrap|setup|release|deploy|review|pr)' "$prompt"
        return 0
    end

    return 1
end

function __prom_codex_invocation_targets_prom
    if __prom_codex_supports_leaf_sessions
        return 0
    end

    if test (count $argv) -eq 0
        return 1
    end

    switch $argv[1]
        case continue
            if test (count $argv) -ge 2
                if __prom_codex_is_leaf_branch $argv[2]
                    return 0
                end
                if __prom_codex_prompt_targets_prom $argv[2..-1]
                    return 0
                end
            end
        case new
            if test (count $argv) -ge 2
                if __prom_codex_is_leaf_branch $argv[2]
                    return 0
                end
                if __prom_codex_prompt_targets_prom $argv[2..-1]
                    return 0
                end
            end
        case branch attach
            if test (count $argv) -ge 2
                if __prom_codex_is_leaf_branch $argv[2]
                    return 0
                end
            end
        case '-*' list ls sessions sess resume copy context save notes remove import init copy-codex copy-claude cx cc
            return 1
        case '*'
            if __prom_codex_is_leaf_branch $argv[1]
                return 0
            end
            if __prom_codex_prompt_targets_prom $argv
                return 0
            end
    end

    return 1
end

function __prom_codex_open_dispatched_session
    set -l action $argv[1]
    set -e argv[1]
    set -l prompt_override $PROM_CODEX_PROMPT_OVERRIDE
    set -l prompt
    if test -n "$prompt_override"
        set prompt $prompt_override
    else
        set prompt (string join " " $argv)
    end

    if test (count $argv) -ge 1
        switch $argv[1]
            case review/nikiv-reactron-rs-designer-support
                if test "$action" = continue
                    env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-deps-session.sh" --continue
                else
                    env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-deps-session.sh"
                end
                return $status
            case review/nikiv-designer-dev-deploy
                if test "$action" = continue
                    env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-dev-deploy-session.sh" --continue
                else
                    env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-dev-deploy-session.sh"
                end
                return $status
        end
    end

    if test "$action" = continue
        if test (count $argv) -ge 1
            if __prom_codex_is_leaf_branch $argv[1]
                __prom_codex_open_leaf_session --continue --exact $argv[1]
                return $status
            end
        end
    end

    if test (count $argv) -ge 1
        if __prom_codex_is_leaf_branch $argv[1]
            __prom_codex_open_leaf_session --exact $argv[1]
            return $status
        end
    end

    if __prom_codex_prompt_targets_designer_deps $argv
        if test "$action" = continue
            env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-deps-session.sh" --continue
        else
            env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-deps-session.sh" --prompt "$prompt"
        end
        return $status
    end

    if __prom_codex_prompt_targets_designer_integration $argv
        if test "$action" = continue
            env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-dev-deploy-session.sh" --continue
        else
            env START_CWD=(pwd -P) "$HOME/code/prom/x/nikiv/forge/scripts/designer-dev-deploy-session.sh" --prompt "$prompt"
        end
        return $status
    end

    switch $action
        case new
            __prom_codex_open_leaf_session --new $argv
        case continue
            __prom_codex_open_leaf_session --continue $argv
        case '*'
            __prom_codex_open_leaf_session $argv
    end
end

function __prom_codex_open_leaf_session
    set -l start_cwd (pwd -P)
    env START_CWD="$start_cwd" "$HOME/run/i/prom/scripts/open-prom-codex-leaf-session.sh" $argv
end

function l
    set -l kit_dir "$HOME/repos/mark3labs/kit"
    set -l kit_bin (__kit_bin)
    or return 1

    if test (count $argv) -eq 0
        env KIT_DIR="$kit_dir" KIT_BIN="$kit_bin" \
            bash -lc 'cd "$KIT_DIR" && exec "$KIT_BIN" --continue'
        return $status
    end

    set -l query (string join " " $argv)
    env KIT_DIR="$kit_dir" KIT_BIN="$kit_bin" KIT_PROMPT="$query" \
        bash -lc 'cd "$KIT_DIR" && exec "$KIT_BIN" --continue --no-exit "$KIT_PROMPT"'
end

function ll
    echo "ll retired"
    return 1
end

function o
    __flow_cli ai copy-claude $argv
end

# from https://x.com/_xjdr/status/1970694098454798338 (outdated)
# codex --search --model=gpt-5.1-codex-max -c model_reasoning_effort="high" --sandbox workspace-write -c sandbox_workspace_write.network_access=true

function ve
    bunx convex $argv
end

# function .
#     if test (count $argv) -eq 0
#         f deploy
#     else
#         bunx $argv
#     end
# end

# TODO: fzf list all commands
# `k <thing> create thing in Taskfile & exec it instantly`
# function j
#     if test (count $argv) -eq 0
#         task
#     else
#         task $argv
#     end
# end

# function jd
#    task dev
# end

# function je
#    task deploy
# end

# function jb
#    task build
# end

# function ja
#    task publish
# end

# function js
#    task setup
# end

# function jf
#    task flow -- $argv
# end

# TODO: pass context from the session so this is more accurate
# function :
#     if test (count $argv) -gt 0
#         ~/bin/f commitWithCheck --claude --no-hub -m "$argv"
#     else
#         # ~/bin/f commitWithCheck --claude (when its reliable, for now testing below)
#         ~/bin/f commitWithCheck --claude --no-hub
#     end
# end

#  function :
#     if test (count $argv) -gt 0
#         # TODO: move to codex when richer
#         # ~/bin/f commitWithCheck (codex is usully default for reviews)
#         # ~/bin/f commitWithCheck --claude -t 1000 -m "$argv"
#         ~/bin/f commitWithCheck --claude --no-context -m "$argv"
#     else
#         # ~/bin/f commitWithCheck --claude --no-hub -t 1000
#         # ~/bin/f commitWithCheck --claude -t 1000
#         ~/bin/f commitWithCheck --claude --no-context -t 1000
#     end
# end

#  function :
#     if test (count $argv) -gt 0
#         __flow_cli commit -m "$argv"
#     else
#         __flow_cli commit
#     end
# end

function ::
    if test (count $argv) -gt 0
        __flow_cli commitSimple -m "$argv"
    else
        __flow_cli commitSimple
    end
end

# TODO: improve, snapshot, allow to pass command to do `j <command>`
function ,
    __flow_cli commit
end

function ma
    git checkout main
end

# function m
#     git checkout -
# end

function gitOverwrite
    rm -rf .git
    git add .
    git commit -m "."
    gitSetSshOrigin
    git push --force
end

function gcb
    if not set -q argv[1]
        echo "Usage: gcb <github-url>"
        return 1
    end

    # Extract repo path from the URL (strip https://github.com/)
    set repo_path (string replace -r 'https://github.com/' '' $argv[1])

    # Clone with shallow history using SSH URL format
    git clone --depth=1 "git@github.com:$repo_path.git"
end


function org
    if test (count $argv) -lt 1
        echo "Usage: org <organization-name-or-url> [destination-directory]"
        return 1
    end

    set -l input $argv[1]
    set -l org_name

    # Check if input is a URL and extract org name, otherwise use input as-is
    if string match -r '^https://github\.com/[^/]+$' $input >/dev/null
        # Extract the org name from the URL (e.g., "Effect-TS" from "https://github.com/Effect-TS")
        set org_name (string replace -r '^https://github\.com/' '' $input)
    else
        set org_name $input
    end

    set -l dest_dir ~/deps/$org_name
    if test (count $argv) -gt 1
        set dest_dir $argv[2]
    end

    set -l github_token $GITHUB_TOKEN_PERSONAL
    if test -z "$github_token"
        echo "Error: GITHUB_TOKEN environment variable not set"
        return 1
    end

    rm -rf $dest_dir
    clone-org -t $github_token -o $org_name -d $dest_dir --no-tui
    if test $status -ne 0
        echo "Failed to clone repositories for $org_name"
        return 1
    end
end

function find.git
    find . -type d -name ".git"
end

function ts.
    bunx tsc --noEmit
end

# function m --description "Run repomix and copy the output"
#     repomix --copy $argv
# end

function changeRemoteToSsh
    if test (count $argv) -ne 1
        echo "Usage: change-remote-to-ssh <git-ssh-url>"
        return 1
    end
    set -l remote_url $argv[1]
    set -l current_remote (git remote)
    if test -z "$current_remote"
        set current_remote origin
    end
    git remote set-url $current_remote $remote_url
    if test $status -eq 0
        echo "Remote '$current_remote' URL changed to $remote_url"
    else
        echo "Failed to change remote URL"
        return 1
    end
end

# function j
#     if test (count $argv) -eq 0
#         bun --watch run.ts
#     else
#         bun run $argv
#     end
# end

# function f
#     bunx @1focus/1f@latest
# end

# TODO: temp thing
# function k
#     bun dev
# end

function pd
    pnpm dev
end

function blade
    bunx blade
end

function ee
  tree -a -I node_modules | pbcopy
end

function sqliteDump
   sqlite3 $argv[1] '.dump'
end

function fe
    f deploy
end

function fes
    __flow_cli deploy-with-hub-reload
end

function fs
    f setup $argv
end

function fi
    f scripts
end

function f:
    f r
end


# function .
#     f dev
# end

# function c
#     lin last-cmd
# end

function fw
    f dev
end

# function fw
#     f s
# end

# todo: improve this
# todo: move
# function b
#     if test -z "$argv[1]"
#         fgo
#     else
#         claude-rs run -b (string join " " $argv)
#     end
# end

function cs
    claude-sdk $argv
end

# TODO: not sure how useful
# function e
#     if test -z "$argv[1]"
#         ~/bin/f rerun
#     else
#         ~/bin/f $argv
#     end
# end

# sync up
# running the env by name will do the sync up
# no args env will just go to base env and sync up
# function e
#     if test -z "$argv[1]"
#         ~/bin/f sessions
#     else
#         ~/bin/f $argv
#     end
# end

function m
    if test (count $argv) -eq 0
        opencode $argv
        return $status
    end

    set -l query (string join " " $argv)
    ~/.local/bin/hive explore "$query"
end

function mc
    __flow_cli migrate code $argv
end

# TODO: turn this into a fn
# TODO: move to native rust allow to pass in tasks arbitrary through lin
# bun ~/org/1f/ai/cli/src/index.ts $argv


function flow
    __flow_cli $argv
end

function i
    if test -z "$argv[1]"
        # TODO: not sure yet
        infra deploy
    else
        infra $argv
    end
end

# function r
#     ~/bin/f ai
# end

function gg
    osascript -e 'quit app "Lin"'
end

# todo: remap
function oo
    localcode $argv
end

function t
    set -l path (~/bin/t $argv)
    if test -n "$path" -a -d "$path"
        cd $path
    end
end

function ts
    t ts
end

function web
    t web
end

function r
    if test -z "$argv[1]"
        forge review
    else
        # rm -rf $argv
        ~/bin/trash $argv
    end
end

function rr
    ~/bin/trash $argv
end

function n
    if test -z "$argv[1]"
        hive --paste env
    else
        hive env $argv
    end
end

function b
    db $argv
end

# function j
#     if test (count $argv) -eq 0
#         ~/bin/f install $argv
#     else
#         hive note $argv
#     end
# end

function ar
    if test (count $argv) -eq 0
        echo "Usage: ar <message>"
        return 1
    end
    set -l msg (string join " " $argv)
    __flow_cli archive "$msg"
end

function fa --wraps=fishy --description "fishy - fish wrapper helper"
     fishy $argv
     and source /Users/nikiv/config/fish/fn.fish
 end
 complete -c fa -w fishy
function hf --description "hive fish agent helper"
    hive agent fish $argv
    and source /Users/nikiv/config/fish/fn.fish
    and source /Users/nikiv/config/fish/config.fish
end
complete -c hf -w hive
complete -c w -w zed-open
complete -c we -w zed-open
function we --wraps=zed-open --description "zed-open - smart Zed opener"
    zed-open code $argv
end
complete -c we -w zed-open
complete -c w -w zed-open
function sk --wraps=hive --description "Hive - Natural language command generation & knowledge base"
    hive agent skim $argv
end
complete -c sk -w hive

function __electron_descendant_pids --description "Expand PID roots to include child processes"
    if test (count $argv) -eq 0
        return 0
    end

    set -l pending $argv
    set -l all $argv

    while test (count $pending) -gt 0
        set -l next
        for pid in $pending
            set -l children (pgrep -P $pid 2>/dev/null)
            for child in $children
                if not contains -- $child $all
                    set -a all $child
                    set -a next $child
                end
            end
        end
        set pending $next
    end

    printf '%s\n' $all | sort -u
end

function __kill_matching_processes --description "Kill matching processes and their descendants"
    set -l label $argv[1]
    set -l patterns $argv[2..-1]
    set -l root_pids (begin
        for pattern in $patterns
            pgrep -f -- "$pattern"
        end
    end | sort -u)

    if test (count $root_pids) -eq 0
        echo "No $label processes found."
        return 0
    end

    set -l pids (__electron_descendant_pids $root_pids)

    echo "Killing $label processes:"
    ps -o pid=,ppid=,command= -p $pids

    command kill -TERM $pids 2>/dev/null
    sleep 0.5

    set -l survivors
    for pid in $pids
        if kill -0 $pid 2>/dev/null
            set -a survivors $pid
        end
    end

    if test (count $survivors) -gt 0
        echo "Force-killing remaining processes: $survivors"
        command kill -KILL $survivors 2>/dev/null
        sleep 0.2
    end

    set -l remaining
    for pid in $pids
        if kill -0 $pid 2>/dev/null
            set -a remaining $pid
        end
    end

    if test (count $remaining) -gt 0
        echo "Some $label processes are still alive: $remaining"
        ps -o pid=,ppid=,command= -p $remaining
        return 1
    end

    echo "$label processes cleared."
end

function killStaleElectron --description "Kill Prom-owned Designer/rev Electron dev processes"
    set -l patterns \
        '/Users/nikitavoloboev/\.jj/workspaces/prom/.*/ide/designer/' \
        '/Users/nikitavoloboev/code/prom/ide/designer/' \
        '/Users/nikitavoloboev/Library/Caches/reactron-rs/electron-dist-overrides/rev-dev/dist/rev-dev\.app/' \
        'run-reactron-rs\.sh dev /Users/nikitavoloboev/code/prom/ide/rev([[:space:]]|$)' \
        'reactron/dist/cli/index\.js dev /Users/nikitavoloboev/code/prom/ide/rev([[:space:]]|$)' \
        'reactron dev /Users/nikitavoloboev/code/prom/ide/rev([[:space:]]|$)' \
        '/Users/nikitavoloboev/code/prom/ide/rev/node_modules/\.bin/electron ' \
        '/Users/nikitavoloboev/code/prom/ide/rev/\.reactron/'

    __kill_matching_processes "Prom-owned Electron" $patterns
end

function cleanElectron --description "Kill local Electron dev processes and helpers"
    set -l patterns \
        '/Users/nikitavoloboev/\.jj/workspaces/.*/ide/(designer|rev)/' \
        '/Users/nikitavoloboev/code/.*/ide/(designer|rev)/' \
        '/Users/nikitavoloboev/code/.*/node_modules/\.bin/electron([[:space:]]|$)' \
        '/Users/nikitavoloboev/repos/.*/node_modules/\.bin/electron([[:space:]]|$)' \
        '/Users/nikitavoloboev/Library/Caches/reactron-rs/electron-dist-overrides/.*/dist/.*\.app/' \
        'run-reactron-rs\.sh dev ' \
        'reactron/dist/cli/index\.js dev ' \
        'reactron dev .*(ide/designer|ide/rev|/Users/nikitavoloboev/(code|repos)/)' \
        '/Users/nikitavoloboev/(code|repos)/.*/\.reactron([/[:space:]]|$)' \
        'electronmon([[:space:]]|$)'

    __kill_matching_processes "Electron dev" $patterns
end

# unpush but keep changes
function unpush
    set branch (git rev-parse --abbrev-ref HEAD)
    git reset HEAD^
    git push --force-with-lease origin $branch
end

# . -> dot (AI TUI)
abbr -a -g . dot
