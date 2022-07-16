zmodload zsh/zprof
# Still need to figure out why I had this before
# export PATH=$HOME/bin:/usr/local/bin:$PATH 
export PATH=/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"

export NVM_LAZY=1 # this is to lazy load nvm for faster startup
ZSH_THEME=robbyrussell
plugins=(git docker docker-compose kubectl nvm)
plugins+=(zsh-autosuggestions zsh-syntax-highlighting)

# Load plugins
source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='nvim'
 fi

## Function to measure startup time of shell
timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# ALIASES
## HOMEBREW
alias brewup="brew update; brew upgrade; brew cleanup; brew doctor"

### USEFUL TERMINAL
alias lt="du -sh * | sort -h"  #sort by size
# alias left='ls -t -1' # to check last modified files
alias ls="ls -aG"
alias gh="history|grep"
alias vim="nvim"

### COMMNON DIRECTORIES
alias proj="cd ~/Documents/repos_work"
alias pproj="cd ~/Documents/repos_pers"
alias notes="cd ~/Documents/my_notes"

### PYTHON venvs 
alias ve='python3 -m venv ./venv'
alias va='source ./venv/bin/activate'

### DOCKER utils
alias dockersh="docker run -it --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh"

# Uncomment if using java
# export PATH="/usr/local/opt/openjdk@8/bin:$PATH"
