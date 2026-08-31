# Shared helpers for the dotfiles provisioning scripts (install, bootstrap, packages/*).
# Source this; don't execute it. Keep ONE definition of host/OS detection so the
# scripts never disagree about which packages/group/<host> dir to use.

# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

# Canonical short host name.
# macOS: LocalHostName (this is what the packages/group/<host> dirs are named after);
# everything else falls back to `hostname -s`.
dotfiles_host() {
  scutil --get LocalHostName 2>/dev/null || hostname -s
}

# Normalized OS id used to pick os/<id> and (later) the package backend.
dotfiles_os() {
  case "$OSTYPE" in
    darwin*) echo macos ;;
    linux*)  echo linux ;;
    *)       echo unknown ;;
  esac
}

# Repo root, derived from this library's own location — nothing is tied to ~/dotfiles.
dotfiles_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# Set every macOS host name field at once. Needs sudo.
dotfiles_set_host() {
  local new="$1"
  sudo scutil --set ComputerName "$new"
  sudo scutil --set LocalHostName "$new"
  sudo scutil --set HostName "$new.local"
}

# Load the machine-local env (WORK_ENV, API keys) so any entrypoint sees the same
# values. env.local is gitignored, so this is a no-op on a fresh clone.
dotfiles_load_env() {
  local f
  f="$(dotfiles_root)/zsh/.config/zsh/env.local"
  # shellcheck disable=SC1090
  [[ -r "$f" ]] && source "$f"
  return 0
}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
# Everything goes to stderr so `ask` can return its answer on stdout.

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m ! \033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m x \033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
# Prompts read from /dev/tty, never stdin: the `curl … | bash` entrypoint has the
# script itself on stdin. With DOTFILES_YES=1, or with no tty at all, every prompt
# silently takes its default — which is what makes the scripts CI/dry-run safe.

dotfiles_interactive() {
  [[ "${DOTFILES_YES:-}" == "1" ]] && return 1
  [[ -r /dev/tty && -w /dev/tty ]]
}

# ask <prompt> [default] -> answer on stdout
ask() {
  local prompt="$1" default="${2:-}" reply
  if ! dotfiles_interactive; then
    echo "$default"
    return 0
  fi
  printf '\033[1;36m ? \033[0m %s [\033[1m%s\033[0m]: ' "$prompt" "$default" >/dev/tty
  IFS= read -r reply </dev/tty || reply=""
  echo "${reply:-$default}"
}

# ask_yn <prompt> [y|n] -> exit status 0 for yes
ask_yn() {
  local prompt="$1" default="${2:-y}" reply
  if ! dotfiles_interactive; then
    [[ "$default" == "y" ]]
    return
  fi
  while true; do
    if [[ "$default" == "y" ]]; then
      printf '\033[1;36m ? \033[0m %s [\033[1mY\033[0m/n]: ' "$prompt" >/dev/tty
    else
      printf '\033[1;36m ? \033[0m %s [y/\033[1mN\033[0m]: ' "$prompt" >/dev/tty
    fi
    IFS= read -r reply </dev/tty || reply=""
    reply="${reply:-$default}"
    case "$reply" in
      y|Y|yes|YES|Yes) return 0 ;;
      n|N|no|NO|No)    return 1 ;;
      *)               warn "Answer y or n." ;;
    esac
  done
}

# Keep sudo warm so password prompts happen once, up front, instead of
# interrupting a long unattended run.
dotfiles_sudo_keepalive() {
  dotfiles_interactive || return 0
  sudo -v </dev/tty || die "sudo is required to provision this machine."
  # `|| true`: the subshell inherits errexit, so a single transient sudo failure
  # would otherwise kill the keepalive for the rest of the run and the next step
  # would prompt for a password again.
  ( while true; do sudo -n true || true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

# Put Homebrew on PATH for the *current* process. The Homebrew installer only
# prints this line; it does not run it. Without this, every step after the brew
# install in a single `./install` run has no `brew` on PATH.
dotfiles_brew_shellenv() {
  command -v brew >/dev/null 2>&1 && return 0
  local prefix
  for prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x "$prefix/bin/brew" ]]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done
  return 1
}
