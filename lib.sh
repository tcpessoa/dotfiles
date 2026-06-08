# Shared helpers for the dotfiles provisioning scripts (install, bootstrap, packages/*).
# Source this; don't execute it. Keep ONE definition of host/OS detection so the
# scripts never disagree about which packages/group/<host> dir to use.

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
