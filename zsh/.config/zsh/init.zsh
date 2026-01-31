# XDG config
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# zsh stuff
export ZSH="$HOME/.oh-my-zsh"
export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# apps
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export PYTHONHISTFILE="$XDG_STATE_HOME/python/history"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export GOPATH="$XDG_DATA_HOME/go"

# PATH
export PATH="$HOME/.rd/bin:$PATH" # Rancher Desktop
export PATH="/opt/homebrew/bin:$PATH" # Homebrew M chip install
eval "$(/opt/homebrew/bin/brew shellenv)" # Homebrew env vars
export PATH="$PATH:$HOME/.local/bin" # My custom bin scrips - `bin/.local/bin/`

# Rust setup
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Load env
source "$HOME/.config/zsh/env.local" 2>/dev/null || true

# Pre-populate PATH with the latest installed Node version (for nvim and bg processes)
if [[ -d "$XDG_DATA_HOME/nvm/versions/node" ]]; then
  # Get the latest version (highest version number)
  LATEST_NODE=$(ls "$XDG_DATA_HOME/nvm/versions/node" | sort -V | tail -n1)
  NODE_BIN_DIR="$XDG_DATA_HOME/nvm/versions/node/$LATEST_NODE/bin"
  [[ -d "$NODE_BIN_DIR" ]] && export PATH="$NODE_BIN_DIR:$PATH"
fi

# Lazy load slow functions, faster shell startup
lazy_load_nvm() {
  unset -f nvm node npm npx 2>/dev/null
  export NVM_DIR="$XDG_DATA_HOME/nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

# lazy-loading wrappers for all Node tools
for cmd in nvm node npm npx; do
  eval "${cmd}() { lazy_load_nvm; ${cmd} \$@; }"
done

bindkey -v # Use vi keybindings in ZSH
export KEYTIMEOUT=1 # Reduce key timeout, vi mode

# Plugin setup
plugins=(git docker docker-compose kubectl nvm vi-mode)
plugins+=(zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
