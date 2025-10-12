alias cwd="pwd | pbcopy"
alias pi="pnpm i"
# alias js="just s" # TODO: do with watch like bun --watch
alias a="eza -I 'license'" # list files (without license)
alias af="type" # <cmd> - view definition of <cmd>
alias dF="cd ~/src/pause && eza"
alias gl="git pull"
alias rr="rm -rf"
alias wr="cursor readme.md"
alias da="cd ~/src && eza"
# alias dj="cd ~/src/ts && eza"
alias dj="cd ~/try && eza"
alias dw="cd ~/try/wip && eza"
alias dv="cd ~/try/src && eza"
alias ds="cd ~/test && eza"
alias pip="pip3"
alias oo="codex"
# alias dv="cd ~/src/nikiv.dev && eza"
alias do="cd ~/doing && eza"
alias dn="cd ~/src/py && eza"
alias dm="cd ~/src/go && eza"
alias dl="cd ~/src/org/la/la && eza"
alias dL="cd ~/src/org/la/x && eza"
alias dz="cd ~/try && eza"
alias dZ="cd ~/try/z && eza"
alias de="cd ~/new && eza"
alias db="cd ~/src/base && eza"
alias dq="cd ~/Documents && eza"
alias dp="cd ~/past && eza"
alias dg="cd ~/src/other && eza"
alias dP="cd ~/past/private && eza"
alias dd="cd ~/try/tmp/day && eza"
# alias dd="cd ~/data && eza"
# alias dD="cd ~/data/private && eza"
alias dk="cd ~/src/org/solbond/solbond && eza"
alias dt="cd ~/desktop && eza"
alias df="cd ~/src/org && eza"
# alias dv="cd ~/src/nikiv.dev && eza"
alias di="cd ~/i && eza"
alias aa="eza -la" # list files (with hidden)
# alias r="ronin"
# alias npm="bun"
alias v="mv" # move files/folders or rename
alias dc="cd ~/config && eza"
alias pr="gh pr checkout"
alias nb="nix-build"

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

# TODO: move to another key
# function j
#     if not set -q argv[1]
#         just dev
#     else
#         just $argv
#     end
# end

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

function i
    if not set -q argv[1]
        bun i
    else
        bun i $argv
    end
end

function p
    if not set -q argv[1]
        pnpm i
    else
        pnpm add $argv
    end
end

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

function ::
    if not set -q argv[1]
        deno repl # TODO: change
    else
        deno $argv
    end
end

function :se
    bun seed $argv
end

function u
    if not set -q argv[1]
        cursor .
    else
        cursor $argv
    end
end

function w
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

function fg
    if not set -q argv[1]
        # cd ~/
        # flox list
    else
        # cd ~/
        # flox install $argv
    end
end

function fi
    if not set -q argv[1]
        # flox init TODO:
    else
        flox install $argv
    end
end


function fs
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

function n
    if not set -q argv[1]
        open .
    else
        open $argv
    end
end

function md
    mkdir -p $argv[1] && cd $argv[1]
end

function :i
    if not set -q argv[1]
        bun i
    else
        bun i $argv
    end
end

function :id
    bun i -d $argv
end

function :g
    bun i -g $argv
end

# set env vars in current shell
function x
    if test (count $argv) -eq 1
        set -x $argv[1]
    else if test (count $argv) -ge 2
        set -x $argv[1] $argv[2..-1]
    else
        echo "Usage: x VARIABLE [VALUE]"
        return 1
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

# unstable, but does work for https://github.com/nikitavoloboev/cpp
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

function fa
    flox activate -s
end

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

function l
    if test (count $argv) -eq 0
        pwd | pbcopy
    else
        bat --paging=never -- $argv
        cat -- $argv | pbcopy
    end
end

function changeRemoteToFork
    set -l repo_url $argv[1]

    # Extract the repo name from the URL
    set -l repo_name (string split '/' $repo_url | tail -n 1)

    # Set the GitHub username directly in the function
    set -l github_username "nikitavoloboev"

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
        cd
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
    cd ~/rust && eza
end

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

function :a
    bun run deploy
end

function :c
    find . -type d -name node_modules -prune -print | xargs rm -rf
    bun i
end

# clone using SSH URL format
function gc
    if not set -q argv[1]
        echo "Usage: gc <github-url>"
        return 1
    end
    # extract repo path from the URL
    set repo_path (string replace -r 'https://github.com/' '' $argv[1])
    # clone using SSH URL format
    git clone "git@github.com:$repo_path.git"
end

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
        gh repo sync "nikitavoloboev/$repo_name" --source "git@github.com:$original_author/$repo_name"
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


# used as catch all for fast scripts
function ,
    for dir in *=*
        set newdir (string replace --all "=" "__" "$dir")
        mv "$dir" "$newdir"
    end
end


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


function sf
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

function s
    if test -z "$argv[1]"
        echo "Usage: sf <url>"
        return 1
    end

    # Extract domain and path from URL
    set url (echo $argv[1] | sed -E 's|^https?://||')
    set domain (echo $url | cut -d'/' -f1)
    set path (echo $url | grep -o '/.*$' || echo '/')

    # Create filename from domain
    set filename "$HOME/sites/$domain.txt"

    # Build the sitefetch command with exact path matching
    if string match -q 'http*://*' $argv[1]
        sitefetch "$argv[1]" -o $filename -m "$path"
    else
        sitefetch "https://$argv[1]" -o $filename -m "$path"
    end

    # Copy content to clipboard
    cat $filename | pbcopy
    echo "Saved to $filename (content copied to clipboard)"
end


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
function t
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

function mc --description "go build and install a binary"
    set -l binary_name

    # Check if an argument is provided
    if test (count $argv) -eq 0
        # No argument provided, check for directories in cmd/
        set -l cmd_dirs (path filter -d cmd/*)
        set -l num_dirs (count $cmd_dirs)

        if test $num_dirs -eq 1
            # Exactly one directory found, use it as the binary name
            set binary_name (basename $cmd_dirs[1])
        else
            # Zero or multiple directories found, prompt for binary name
            echo "Error: Please specify the binary name. Found $num_dirs directories in cmd/."
            return 1
        end
    else
        # Use the provided argument as the binary name
        set binary_name $argv[1]
    end

    set -l gopath (go env GOPATH)

    # Build the binary locally
    # echo "Building $binary_name locally..."
    go build -o $binary_name ./cmd/$binary_name
    if test $status -ne 0
        echo "Build failed"
        return 1
    end

    # Install the binary to $GOPATH/bin
    # echo "Installing $binary_name..."
    go install ./cmd/$binary_name
    if test $status -ne 0
        echo "Failed to install $binary_name"
        return 1
    end
    echo "✔ $binary_name installed"
end


function fn --description "Find directories matching a pattern and exclude node_modules"
    if test (count $argv) -eq 0
        echo "Error: Please provide a search pattern"
        return 1
    end
    fd -td $argv[1] -E node_modules
end

function C
    if test -z "$argv[1]"
        claude
    else
        claude $argv
    end
end

function c
    if test -z "$argv[1]"
        claude --dangerously-skip-permissions
    else
        claude --dangerously-skip-permissions $argv
    end
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

# from https://x.com/_xjdr/status/1970694098454798338
function o
    codex --search --model=gpt-5-codex -c model_reasoning_effort="high" --sandbox workspace-write -c sandbox_workspace_write.network_access=true
end

function ve
    bunx convex $argv
end

function .
    if test (count $argv) -eq 0
        f deploy
    else
        bunx $argv
    end
end

# TODO: fzf list all commands
# `k <thing> create thing in Taskfile & exec it instantly`
function j
    if test (count $argv) -eq 0
        task
    else
        task $argv
    end
end

function jd
   task dev
end

function je
   task deploy
end

function js
   task setup
end

function jf
   task flow -- $argv
end


# TODO: improve, snapshot, allow to pass command to do `j <command>`
function :
    f commitPush
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
