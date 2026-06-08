# Completion and interactivity enhancements
# Cache shell init scripts for faster startup (regenerate with: rm ~/.cache/zsh/*.zsh)
_zsh_cache_dir="$XDG_CACHE_HOME/zsh"
[[ -d "$_zsh_cache_dir" ]] || mkdir -p "$_zsh_cache_dir"

## fzf - the sed part enables history pretty date on CTRL-R
## see this [github issue](https://github.com/junegunn/fzf/issues/1049#issuecomment-2168007994)
if [[ ! -f "$_zsh_cache_dir/fzf.zsh" ]]; then
  fzf --zsh | sed -e '/zmodload/s/perl/perl_off/' -e '/selected/s/fc -rl/fc -rlt \"%Y-%m-%d %H:%M\"/' > "$_zsh_cache_dir/fzf.zsh"
fi
zsrc "$_zsh_cache_dir/fzf.zsh"

## starship prompt
if [[ ! -f "$_zsh_cache_dir/starship.zsh" ]]; then
  starship init zsh > "$_zsh_cache_dir/starship.zsh"
fi
zsrc "$_zsh_cache_dir/starship.zsh"

# CLI completions, generated once and cached (regenerate: rm ~/.cache/zsh/comp-*.zsh*)
# Generating these spawns the tool (slow); sourcing the cached file is cheap.
for _tool in kubectl docker; do
  _cf="$_zsh_cache_dir/comp-${_tool}.zsh"
  if [[ ! -s "$_cf" ]] && command -v "$_tool" >/dev/null 2>&1; then
    "$_tool" completion zsh >| "$_cf" 2>/dev/null
  fi
  zsrc "$_cf"
done
unset _tool _cf

unset _zsh_cache_dir

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

## -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}


# Preview file content using bat
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# CTRL-R history: syntax-highlight the *selected* command in a small preview.
# Cost is one bat call per focused line (not the whole list), so the list stays instant.
# Row layout is "INDEX DATE TIME cmd…", so {4..} is just the command.
export FZF_CTRL_R_OPTS="
  --preview 'echo {4..} | bat --color=always -pl zsh --style plain'
  --preview-window 'down:3:wrap'
  --preview-label ' C-o expand '
  --bind 'ctrl-o:change-preview-window(down:75%:wrap|down:3:wrap)'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

