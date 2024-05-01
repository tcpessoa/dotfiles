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
