# Still need to figure out why I had this before
# export PATH=$HOME/bin:/usr/local/bin:$PATH 
export PATH=/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"

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


# NVM config
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use # This loads nvm in lazy mode (--no-use)
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# For pyenv to take over the shell

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
