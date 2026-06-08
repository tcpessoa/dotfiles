# XDG config
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Helper: source a file via a compiled .zwc bytecode copy (recompiled only when newer).
zsrc() {
  local f="$1"
  [[ -r "$f" ]] || return 0
  if [[ ! -s "${f}.zwc" || "$f" -nt "${f}.zwc" ]]; then
    zcompile -R -- "${f}.zwc" "$f" 2>/dev/null
  fi
  source "$f"
}

# zsh stuff
export ZSH_PLUGIN_DIR="$XDG_DATA_HOME/zsh/plugins" # standalone plugins (no framework)
export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# apps
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export PYTHONHISTFILE="$XDG_STATE_HOME/python/history"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export GOPATH="$XDG_DATA_HOME/go"

# PATH — OS-specific bits (homebrew, rancher, …) live in os/<os>.zsh
case "$OSTYPE" in
  darwin*) source "$ZDOTDIR/os/darwin.zsh" ;;
  linux*)  [[ -r "$ZDOTDIR/os/linux.zsh" ]] && source "$ZDOTDIR/os/linux.zsh" ;;
esac
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

bindkey -v # Use vi keybindings in ZSH (starship draws the ❯/❮ mode indicator)
export KEYTIMEOUT=1 # Reduce key timeout, vi mode

# --- Completion system (replaces oh-my-zsh's compinit) ---
autoload -Uz compinit
_zcompdump="$ZDOTDIR/.zcompdump"
# Full, fpath-scanning compinit only if the dump is missing or >20h old; else trust it (-C, fast).
if [[ -z "$_zcompdump"(#qNmh-20) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
# Compile the dump to bytecode for faster reloads
if [[ -s "$_zcompdump" && ( ! -s "${_zcompdump}.zwc" || "$_zcompdump" -nt "${_zcompdump}.zwc" ) ]]; then
  zcompile -R -- "${_zcompdump}.zwc" "$_zcompdump" 2>/dev/null
fi
unset _zcompdump
autoload -Uz bashcompinit && bashcompinit # for bash-style completion scripts

# --- Completion styling (parity with oh-my-zsh defaults) ---
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*' # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# --- Sensible shell options (parity with oh-my-zsh defaults) ---
setopt auto_cd interactive_comments prompt_subst long_list_jobs multios
setopt complete_in_word always_to_end
setopt extended_history hist_ignore_dups hist_ignore_space hist_expire_dups_first \
       hist_verify hist_find_no_dups hist_reduce_blanks share_history
