# zsh stuff
export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="$HOME/.config"
export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# PATH
export PATH="$HOME/.rd/bin:$PATH" # Rancher Desktop
export PATH="/opt/homebrew/bin:$PATH" # Homebrew M chip install
eval "$(/opt/homebrew/bin/brew shellenv)" # Homebrew env vars
export PATH="$PATH:$HOME/.local/bin" # My custom bin scrips - `bin/.local/bin/`

# Rust setup
. "$HOME/.cargo/env"

# Load env
source "$HOME/.config/zsh/env.local" 2>/dev/null || true

# Lazy load slow functions, faster shell startup
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

source $ZSH/oh-my-zsh.sh
