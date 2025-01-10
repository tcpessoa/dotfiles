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

# Configuration
DEFAULT_IMAGE="alpine"
DEFAULT_CPU_LIMIT="0.5"
DEFAULT_MEM_LIMIT="512Mi"
DEFAULT_CPU_REQUEST="0.25"
DEFAULT_MEM_REQUEST="256Mi"

typeset -A DEBUG_IMAGES
DEBUG_IMAGES=(
  ubuntu "ubuntu:22.04"
  alpine "alpine" # alpine:3.20.3
  netshoot "nicolaka/netshoot"
  troubleshoot "debian:bullseye-slim"
)

usage() {
    echo "Usage: kdebug [OPTIONS]"
    echo "Create a debug pod in Kubernetes"
    echo
    echo "Options:"
    echo "  -n, --name NAME       Pod name (default: debug-pod-<random>)"
    echo "  -i, --image IMAGE     Container image to use"
    echo "                        Available: ${(k)DEBUG_IMAGES}"
    echo "  -c, --cpu CPU        CPU limit (default: ${DEFAULT_CPU_LIMIT})"
    echo "  -m, --memory MEM     Memory limit (default: ${DEFAULT_MEM_LIMIT})"
    echo "  -h, --help           Show this help message"
}

create_debug_pod() {
    local name=$1
    local image=$2
    local cpu_limit=$3
    local mem_limit=$4
    local cpu_request=$5
    local mem_request=$6

    local command='["/bin/bash"]'
    if [[ "$image" == "alpine:3.19" ]]; then
        command='["/bin/sh", "-c", "apk add --no-cache vim curl wget bash && /bin/bash"]'
    fi

    # Generate manifest
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${name}
  labels:
    app: debug-pod
spec:
  containers:
  - name: debug
    image: ${image}
    command: ["/bin/bash"]
    stdin: true
    tty: true
    resources:
      limits:
        cpu: "${cpu_limit}"
        memory: "${mem_limit}"
      requests:
        cpu: "${cpu_request}"
        memory: "${mem_request}"
  restartPolicy: Never
EOF

    echo "Waiting for pod to be ready..."
    kubectl wait --for=condition=Ready pod/${name} --timeout=60s
    echo "Pod ${name} is ready. Connecting..."
    kubectl exec -it ${name} -- /bin/bash
}

# Main script
# [k]ubectl [debug]
kdebug() {
    local name="debug-pod-$(head -c 6 /dev/urandom | xxd -p)"
    local image="${DEFAULT_IMAGE}"
    local cpu_limit="${DEFAULT_CPU_LIMIT}"
    local mem_limit="${DEFAULT_MEM_LIMIT}"
    local cpu_request="${DEFAULT_CPU_REQUEST}"
    local mem_request="${DEFAULT_MEM_REQUEST}"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                name="$2"
                shift 2
                ;;
            -i|--image)
                if (( ${+DEBUG_IMAGES[$2]} )); then
                    image="${DEBUG_IMAGES[$2]}"
                else
                    image="$2"
                fi
                shift 2
                ;;
            -c|--cpu)
                cpu_limit="$2"
                cpu_request=$(awk "BEGIN {print $2/2}")
                shift 2
                ;;
            -m|--memory)
                mem_limit="$2"
                mem_request=$(echo "$2" | sed 's/Gi//'| awk '{print $1/2}')Gi
                shift 2
                ;;
            -h|--help)
                usage
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                return 1
                ;;
        esac
    done

    create_debug_pod "$name" "$image" "$cpu_limit" "$mem_limit" "$cpu_request" "$mem_request"
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

## [f]ile [log]
## Logs to console and to files
# 1. As a function: log_output "output.log" "error.log" "your_command"
# 2. With a pipe: echo "Hello, World!" | log_output "output.log" "error.log"
flog() {
    local stdout_log="${1:-out.log}"
    local stderr_log="${2:-err.log}"

    # Check if we're receiving input from a pipe
    if [ -p /dev/stdin ]; then
        # Handle piped input
        { tee "$stdout_log"; } 2> >(tee "$stderr_log" >&2)
    else
        # Handle direct command execution
        shift 2
        local cmd=("$@")
        if [ ${#cmd[@]} -eq 0 ]; then
            echo "Error: No command provided and no piped input detected." >&2
            return 1
        fi

        { "${cmd[@]}"; } > >(tee "$stdout_log") 2> >(tee "$stderr_log" >&2)
    fi
}
