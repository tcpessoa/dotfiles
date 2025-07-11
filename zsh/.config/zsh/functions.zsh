# FUNCTIONS
## Function to measure startup time of shell
timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

generateqr ()
{
printf "$@" | curl -F-=\<- qrenco.de
}

# GIT yolo sync
gsync() {
    git add . && \
    if ! git diff --quiet HEAD; then
        git commit -m "sync" && \
        git push origin HEAD
    else
        echo "No changes to commit"
    fi
}

# proj fzf tools
## [f]ind [p]roject
fp() {
    # find only directories at depth 1 for ~/Documents/repos_work/
    local project=$(fd --type d --max-depth 1 . ~/Documents/repos_work --exec basename {} | fzf --height 40% --reverse --prompt 'Select a project: ' | awk -F'/' '{print $NF}')
    if [[ -n $project ]]; then
        cd ~/Documents/repos_work/$project
    else
        echo "No project selected."
    fi
}

## [f]ind [pp]roject
fpp() {
    local project=$(fd --type d --max-depth 1 . ~/code --exec basename {} | fzf --height 40% --reverse --prompt 'Select a project: ' | awk -F'/' '{print $NF}')
    if [[ -n $project ]]; then
        cd ~/code/$project
    else
        echo "No project selected."
    fi
}

# git fzf tools
# [g]it [diff]
gdiff() {
    local commits=$(git log --pretty=format:"%C(yellow)%h%Creset -%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit | fzf --height 40% --reverse --multi --bind 'ctrl-s:toggle-sort' --header 'Select two commits to diff (use TAB to select).' --prompt 'Git Diff> ' --preview 'git show --color {1}' --preview-window right:50%:wrap | awk '{print $1}')
    
    local selected_commits=("${(@f)commits}")

    if [[ ${#selected_commits[@]} -eq 2 ]]; then
        git diff "${selected_commits[1]}".."${selected_commits[2]}"
    else
        echo "You need to select exactly two commits."
    fi
}

## [g]it [f]ile [hist]ory
gfhist() {
    while true; do
        local file=$(git ls-files | fzf --height 40% --reverse --prompt 'Select a file: ' --preview 'bat --color=always --line-range :500 {}')
        if [[ -z $file ]]; then
            echo "No file selected."
            return
        fi

        while true; do
            # Display commits that modified the selected file
            local commit=$(git log --pretty=format:"%C(yellow)%h%Creset - %C(green)%cr%Creset %C(blue)%cn%Creset - %C(white)%s%Creset" -- $file | fzf --height 40% --reverse --prompt "Select a commit for $file: " --preview 'git show --color {1}')

            if [[ -z $commit ]]; then
                echo "No commit selected. Going back to file selection."
                break
            fi

            # Extract the commit hash
            local commit_hash=$(echo "$commit" | awk '{print $1}')
            git diff $commit_hash^! -- $file

            # Offer to go back to the commit selection or exit
            echo "Press 'q' to go back to commit selection or any other key to choose another file."
            read -r -k1 key
            if [[ "$key" != 'q' ]]; then
                break
            fi
        done
    done
}

gbdiff() {
    local current_branch=$(git branch --show-current)

            # --preview 'git log --oneline --graph --color=always --abbrev-commit {1}' \
    local target_branch=$(git branch --format='%(refname:short)' | \
        grep -v "^${current_branch}$" | \
        fzf --height 100% \
            --header "Select branch to compare against ${current_branch}" \
            --preview 'git log --graph --color=always --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat {1}' \
            --preview-window right:50%:wrap)

    if [[ -n "$target_branch" ]]; then
        git diff --name-only "${target_branch}".."${current_branch}" | \
        fzf --height 100% \
            --preview "git diff ${target_branch}..${current_branch} -- {} | delta --paging=always" \
            --preview-window=right:65%:wrap \
            --bind "j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up" \
            --bind 'ctrl-d:preview-half-page-down' \
            --bind 'ctrl-u:preview-half-page-up' \
            --bind "enter:execute(git diff ${target_branch}..${current_branch} -- {} | delta --paging=always)" \
            --header "Enter: full diff, Ctrl-J/K: preview, J/K: scroll, Ctrl-U/D: half page"
    fi
}

## --- k8s fzf tools
## [k]ubectl [logs]
klogs() {
    if ! kubectl version --request-timeout='3s' &>/dev/null; then
        echo "Failed to connect to the Kubernetes cluster."
        return
    fi

    local pod=$(kubectl get pods --no-headers | fzf --height 40% --reverse --prompt 'Select a pod: ' | awk '{print $1}')

    if [[ -n $pod ]]; then
        kubectl logs -f $pod
    else
        echo "No pod selected."
    fi
}

## [k]ubectl [exec]
## Execute a shell or a specified command in a running pod
kexec() {
    if ! kubectl version --request-timeout='3s' &>/dev/null; then
        echo "Failed to connect to the Kubernetes cluster."
        return
    fi

    local pod=$(kubectl get pods --no-headers | fzf --height 40% --reverse --prompt 'Select a pod: ' | awk '{print $1}')

    if [[ -n $pod ]]; then
        if [[ -n $1 ]]; then
            # If a command argument is provided, execute it
            kubectl exec -it $pod -- $1
        else
            # Default to opening an interactive shell
            kubectl exec -it $pod -- /bin/bash
        fi
    else
        echo "No pod selected."
    fi
}

stern_logs() {
    if ! kubectl version --request-timeout='3s' &>/dev/null; then
        echo "Failed to connect to the Kubernetes cluster."
        return
    fi
    local deployment=$(kubectl get deployments --no-headers | fzf --height 40% --reverse --prompt 'Select a deployment: ' | awk '{print $1}')

    if [[ -z $deployment ]]; then
        echo "No deployment selected."
        return
    fi

    stern "$deployment"
}

## docker fzf tools
select_docker_container() {
    docker ps --format "table {{.ID}}\t{{.Names}}" | tail -n +2 | fzf --height 40% --reverse --prompt 'Select a container: ' | awk '{print $1}'
}

check_docker_daemon() {
    if ! docker version &>/dev/null; then
        echo "Failed to connect to the Docker daemon."
        return 1
    fi
    return 0
}

## [d]ocker [logs]
dlogs() {
    check_docker_daemon || return
    local container=$(select_docker_container)

    if [[ -n $container ]]; then
        docker logs -f $container
    else
        echo "No container selected."
    fi
}

## [d]ocker [exec]
## Execute a shell or a specified command in a running container
## Usage: dexec [command]
dexec() {
    check_docker_daemon || return
    local container=$(select_docker_container)

    if [[ -n $container ]]; then
        if [[ -n $1 ]]; then
            # If a command argument is provided, execute it
            docker exec -it $container $1
        else
            # Default to opening an interactive shell
            docker exec -it $container /bin/bash
        fi
    else
        echo "No container selected."
    fi
}

## [d]ocker [stop]
## Stop a running container
dstop() {
    check_docker_daemon || return
    local container=$(select_docker_container)

    if [[ -n $container ]]; then
        docker stop $container
    else
        echo "No container selected."
    fi
}

function _print_all_panes() {
  for pane_id in $(tmux list-panes -F '#{pane_id}'); do
    # Full scrollback history (-S -), From the top of the current viewport (-S 0)
    tmux capture-pane -p -J -S - -E - -t "$pane_id" | tr ' ' '\n' | sort -u | rg '[a-zA-Z0-9]+'
  done
}

_tmux_pane_words() {
  local current_word="${LBUFFER##* }"
  local new_rbuffer="${RBUFFER/#[^ ]##/}"
  local prompt="${LBUFFER% *} ␣ $new_rbuffer "

  local selected_word=$(_print_all_panes | fzf --query="$current_word" --prompt="$prompt" --height=20 --layout=reverse --no-sort --print-query | tail -n1)
  local new_lbuffer="${LBUFFER% *} $selected_word"
  BUFFER="$new_lbuffer$new_rbuffer"
  CURSOR="${#${new_lbuffer}}"

  zle redisplay
}

zle -N _tmux_pane_words
bindkey '^U' _tmux_pane_words


nvim_jump() {
    # Get current tmux pane content including full scrollback history (-S -)
    local content=$(tmux capture-pane -Jp -S -)
    
    local locations=""
    
    # Pattern 1: Files with line:col (file.ext:123:45)
    local with_lines=$(echo "$content" | grep -oE '[^[:space:]]+\.(rs|py|js|ts|go|java|cpp|c|h|sh|zsh|lua|vim|md|txt|json|yaml|yml|toml|conf|tsx|jsx):[0-9]+:?[0-9]*')
    
    # Pattern 2: Just filenames (file.ext)
    local just_files=$(echo "$content" | grep -oE '[^[:space:]]+\.(rs|py|js|ts|go|java|cpp|c|h|sh|zsh|lua|vim|md|txt|json|yaml|yml|toml|conf|tsx|jsx)')
    
    if [[ -n "$with_lines" ]]; then
        locations="$with_lines"
    fi
    if [[ -n "$just_files" ]]; then
        if [[ -n "$locations" ]]; then
            locations="$locations"$'\n'"$just_files"
        else
            locations="$just_files"
        fi
    fi
    
    # Remove duplicates
    locations=$(echo "$locations" | sort -u)
    
    if [[ -z "$locations" ]]; then
        echo "No file locations found in current tmux pane"
        return 1
    fi
    
    local selected=$(echo "$locations" | fzf \
        --prompt="Select file to open: " \
        --height=20 \
        --layout=reverse \
        --preview='echo "Will open: {}"')
    
    [[ -z "$selected" ]] && return 0
    
    local file line col
    
    if [[ "$selected" == *:*:* ]]; then
        # Format: file:line:col
        file=$(echo "$selected" | cut -d: -f1)
        line=$(echo "$selected" | cut -d: -f2)
        col=$(echo "$selected" | cut -d: -f3)
    elif [[ "$selected" == *:* ]]; then
        # Format: file:line
        file=$(echo "$selected" | cut -d: -f1)
        line=$(echo "$selected" | cut -d: -f2)
        col="1"
    else
        # Just filename
        file="$selected"
        line="1"
        col="1"
    fi
    
    # Get nvim window (configurable)
    local nvim_window=${NVIM_JUMP_WINDOW:-nvim}
    
    # Switch to nvim window
    if ! tmux select-window -t "$nvim_window" 2>/dev/null; then
        echo "Neovim window '$nvim_window' not found"
        echo "Set NVIM_JUMP_WINDOW environment variable if your nvim window has a different name"
        return 1
    fi
    
    # Send command to nvim
    local nvim_cmd
    if [[ "$col" != "1" && -n "$col" ]]; then
        nvim_cmd=":edit +${line} ${file} | normal! ${col}|"
    else
        nvim_cmd=":edit +${line} ${file}"
    fi
    
    # Get first pane of nvim window
    local nvim_pane=$(tmux list-panes -t "$nvim_window" -F '#{pane_id}' | head -n1)
    
    # Send to nvim
    tmux send-keys -t "$nvim_pane" C-c  # Cancel any current operation
    sleep 0.1
    tmux send-keys -t "$nvim_pane" "$nvim_cmd" Enter
    
    echo "Opened ${file}:${line}:${col} in Neovim"
}
