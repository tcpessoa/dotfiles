# Environment setup
export ZSH="$HOME/.oh-my-zsh"
export BAT_THEME="TwoDark"
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
# For my custom scripts
export PATH="$HOME/bin:$PATH"
# Rust setup
. "$HOME/.cargo/env"

# Lazy load NVM function
lazy_load_nvm() {
  unset -f npm node nvm
  export NVM_DIR=~/.nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}

npm() { lazy_load_nvm; npm $@; }
node() { lazy_load_nvm; node $@; }
nvm() { lazy_load_nvm; nvm $@; }

# Plugin setup
plugins=(git docker docker-compose kubectl nvm)
plugins+=(zsh-autosuggestions zsh-syntax-highlighting)

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

export PATH="/opt/homebrew/bin:$PATH"
