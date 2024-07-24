#!/usr/local/bin/zsh

# Function to check if a tool is installed, with a special case for ripgrep
check_tool() {
    local tool=$1
    local command=$2
    echo -n "Checking for $tool..."
    if [[ $tool == "ripgrep" ]]; then
        # Special case for ripgrep using `command -v`
        if command -v rg > /dev/null; then
            local version=$(rg --version | head -1)
            echo " FOUND: $version"
        else
            echo " NOT FOUND"
            missing_tools+=($tool)
        fi
    elif (( $+commands[$tool] )); then
        # General case for other tools
        local version=$(eval $command)
        echo " FOUND: $version"
    else
        echo " NOT FOUND"
        missing_tools+=($tool)
    fi
}

typeset -A tools
tools=(
    fzf "fzf --version"
    jq "jq --version"
    ripgrep "rg --version"
    fd "fd --version"
    bat "bat --version"
    kubectl "kubectl version --client"
    docker "docker --version"
    delta "delta --version" # brew install git-delta
    eza "eza --version"
    node "node --version"
    npm "npm --version"
    bun "bun --version"
    starship "starship --version"
    pyenv "pyenv --version"
    tms "tms --version" # cargo install tmux-sessionizer
)
# CHECK kubectx manually, includes kubens

# Check for nvm
echo -n "Checking for nvm..."
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    source "$HOME/.nvm/nvm.sh"
    nvm --version && echo " FOUND: $(nvm --version)" || echo " NOT FOUND"
else
    echo " NOT FOUND"
    missing_tools+=("nvm")
fi

# Loop through tools and check each one
missing_tools=()
for tool command in ${(kv)tools}; do
    check_tool $tool $command
done

echo "\n---> Check for [kubectx, grc] manually, it doesn't have a version command"
# Final status
if (( ${#missing_tools} )); then
    echo "The following tools are missing: $missing_tools"
    echo "Please install them to ensure proper functionality."
else
    echo "All tools are installed and ready."
fi
