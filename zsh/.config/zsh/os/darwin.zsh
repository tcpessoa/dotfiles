# macOS-specific shell setup (PATH, env). Sourced from init.zsh when $OSTYPE is darwin*.
# Keep OS-conditional logic here so init.zsh stays platform-neutral; add os/linux.zsh similarly.

export PATH="$HOME/.rd/bin:$PATH" # Rancher Desktop

if [[ -d /opt/homebrew/bin ]]; then
  export PATH="/opt/homebrew/bin:$PATH" # Homebrew (Apple silicon)
  # Cache `brew shellenv` output — spawning brew costs ~20-35ms/startup; the output is static.
  # (regenerate after a brew prefix change: rm ~/.cache/zsh/brew-shellenv.zsh)
  _brewenv="$XDG_CACHE_HOME/zsh/brew-shellenv.zsh"
  if [[ ! -s "$_brewenv" ]]; then
    mkdir -p "${_brewenv:h}" && /opt/homebrew/bin/brew shellenv >| "$_brewenv"
  fi
  zsrc "$_brewenv"
  unset _brewenv
fi
