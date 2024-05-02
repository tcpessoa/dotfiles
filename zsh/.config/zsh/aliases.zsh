# ALIASES
## HOMEBREW
alias brewup="brew update; brew upgrade; brew cleanup; brew doctor"

## ZSH
# reloads the .zshrc file
alias szsh="source ~/.config/zsh/.zshrc"

## NVIM
alias nv='nvim'

### USEFUL TERMINAL
alias l="/bin/ls -lah"
alias ls="eza --color=always --long --git --icons=always --no-user --no-permissions --group-directories-first --sort modified"
# ls [s]ize
alias lss="eza --color=always --long --icons=always --no-user --no-permissions --sort size -r -a"
# ls [s]ize [t]otal (calculates size of directories, can be slow)
alias lsst="eza --color=always --long --icons=always --no-user --no-permissions --sort size -r -a --total-size"
# ls [m]odified
alias lsm="eza --color=always --long --icons=always --no-user --no-permissions --sort modified -r -a"

### COMMNON DIRECTORIES
alias proj="cd ~/Documents/repos_work"
alias pproj="cd ~/Documents/repos_pers"

### PYTHON venvs 
alias ve='python3 -m venv ./.venv'
alias va='source ./.venv/bin/activate'

### DOCKER utils
alias dockersh="docker run -it --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh"
alias dcpsp="docker compose ps --format=json | jq -r '. | [.Name, \"\(.State) \(.Health | if . == \"healthy\" then \"(healthy)\" else \"\" end)\"] | @tsv' | (echo -e \"Name\tStatus\"; cat) | column -t"

### KUBE
alias kctx="kubectx"
alias kns="kubens"

### OBSIDIAN
alias obssync="git add . && git commit -m \"sync\" && git push origin main"

