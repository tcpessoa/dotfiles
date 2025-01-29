# ALIASES
## HOMEBREW
alias brewup="brew update; brew upgrade; brew cleanup; brew doctor"

## ZSH
# reloads the .zshrc file
alias szsh="source ~/.config/zsh/.zshrc"

## NVIM
alias v='nvim'

### USEFUL TERMINAL
# [l]ist all files with git status, directories first (dot files and directories first), alpabetically
alias l='# List all files with git status, directories first (dot files and directories first)
eza --color=always --long --git --icons=always --no-user --no-permissions --group-directories-first --all --sort=name --time-style=long-iso'
# ls [s]ize - Show files sorted by size (largest first), directories last
alias lss='# Show files sorted by size (largest first), directories last
eza --color=always --long --icons=always --no-user --no-permissions --sort size -r -a --time-style=long-iso --group-directories-last'
# ls [s]ize [t]otal - calculates size of directories, can be slow
alias lsst='# Show files and directories sorted by size with directory size calculation (can be slow)
eza --color=always --long --icons=always --no-user --no-permissions --sort size -r -a --total-size --time-style=long-iso'
# ls [m]odified
alias lsm='# Show files sorted by modified date (newest first)
eza --color=always --long --icons=always --no-user --no-permissions --sort modified -r -a --time-style=long-iso'

# [h]istory [t]ime
alias ht="fc -rlt '%Y-%m-%d %H:%M:%S' 1"

### COMMNON DIRECTORIES
alias proj="cd ~/Documents/repos_work"
alias pproj="cd ~/code"

### PYTHON venvs 
alias ve='python3 -m venv ./.venv'
alias va='source ./.venv/bin/activate'

### DOCKER utils
alias dockersh="docker run -it --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh"
alias dcpsp="docker compose ps --format=json | jq -r '. | [.Name, \"\(.State) \(.Health | if . == \"healthy\" then \"(healthy)\" else \"\" end)\"] | @tsv' | (echo -e \"Name\tStatus\"; cat) | column -t"

### KUBE
alias kx="kubectx"
alias kns="kubens"

### TMUX
alias tl='tmuxp_file=$(fd -t f -e yaml . ~/.config/tmuxp | \
  fzf --reverse \
      --height 40% \
      --min-height 10 \
      --layout reverse \
      --border \
      --preview "bat --style=numbers --color=always {}" \
      --preview-window right:50%); \
  if [ -n "$tmuxp_file" ]; then \
    (cd ~ && tmuxp load -y "$tmuxp_file"); \
  fi'
alias ta='tmux a'
alias tls='tmux ls'

### LAZYGIT
alias lg='lazygit'

### TASKWARRIOR
alias tt='taskwarrior-tui'
