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

## --- k8s fzf tools
## [k]ubectl [logs]
klogs() {
    if ! kubectl version --request-timeout='3s' &>/dev/null; then
        echo "Failed to connect to the Kubernetes cluster."
        return
    fi

    local namespace=$(kubectl get namespaces --no-headers | fzf --height 40% --reverse --prompt 'Select a namespace: ' | awk '{print $1}')

    local pod=$(kubectl get pods -n $namespace --no-headers | fzf --height 40% --reverse --prompt 'Select a pod: ' | awk '{print $1}')

    if [[ -n $pod ]]; then
        kubectl logs -f -n $namespace $pod
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
## [d]ocker [logs]
dlogs() {
    if ! docker version &>/dev/null; then
        echo "Failed to connect to the Docker daemon."
        return
    fi
    local container=$(docker ps --format "table {{.ID}}\t{{.Names}}" | fzf --height 40% --reverse --prompt 'Select a container: ' | awk '{print $1}')

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
    # Check Docker daemon connection
    if ! docker version &>/dev/null; then
        echo "Failed to connect to the Docker daemon."
        return
    fi

    # Select a container using fzf
    local container=$(docker ps --format "table {{.ID}}\t{{.Names}}" | fzf --height 40% --reverse --prompt 'Select a container: ' | awk '{print $1}')

    # Execute command or shell in the selected container
    if [[ -n $container ]]; then
        if [[ -n $1 ]]; then
            # If a command argument is provided, execute it
            docker exec -it $container $1
        else
            # Default to opening an interactive shell
            docker exec -it $container /bin/sh
        fi
    else
        echo "No container selected."
    fi
}

## [d]ocker [stop]
## Stop a running container
dstop() {
    if ! docker version &>/dev/null; then
        echo "Failed to connect to the Docker daemon."
        return
    fi
    local container=$(docker ps --format "table {{.ID}}\t{{.Names}}" | fzf --height 40% --reverse --prompt 'Select a container: ' | awk '{print $1}')

    if [[ -n $container ]]; then
        docker stop $container
    else
        echo "No container selected."
    fi
}

