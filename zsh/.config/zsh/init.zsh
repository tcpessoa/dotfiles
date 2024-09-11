# Environment setup
export ZSH="$HOME/.oh-my-zsh"
export BAT_THEME="TwoDark"
export PATH="$HOME/.rd/bin:$PATH" ### Rancher Desktop
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
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

bindkey -v # Use vi keybindings in ZSH
export KEYTIMEOUT=1 # Reduce key timeout, vi mode

npm() { lazy_load_nvm; npm $@; }
node() { lazy_load_nvm; node $@; }
nvm() { lazy_load_nvm; nvm $@; }

# Plugin setup
plugins=(git docker docker-compose kubectl nvm vi-mode)
plugins+=(zsh-autosuggestions zsh-syntax-highlighting)

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh
