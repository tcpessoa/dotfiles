# zmodload zsh/zprof
source $HOME/.config/zsh/init.zsh
if [[ "$WORK_ENV" == "true" ]]; then
    source $HOME/.config/zsh/.zshrc_work
fi

source $HOME/.config/zsh/settings.zsh
source $HOME/.config/zsh/aliases.zsh
source $HOME/.config/zsh/functions.zsh
source $HOME/.config/zsh/completions.zsh
source $HOME/.config/zsh/kubectl-aliases.zsh # kgp/k/kl/... (from old OMZ kubectl plugin)
source $HOME/.config/zsh/docker-aliases.zsh  # dcup/dclf/dcupd/... (from old OMZ docker plugins)

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# Interactive plugins — sourced LAST (zsh-syntax-highlighting must come after every
# other ZLE widget/keybinding; zsh-autosuggestions just before it). zsrc compiles each.
zsrc "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
zsrc "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# zprof
