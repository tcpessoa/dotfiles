# zmodload zsh/zprof
source $HOME/.config/zsh/init.zsh

source $HOME/.config/zsh/settings.zsh
source $HOME/.config/zsh/aliases.zsh
source $HOME/.config/zsh/functions.zsh
source $HOME/.config/zsh/completions.zsh


if [[ "$WORK_ENV" == "true" ]]; then
    source $HOME/.config/zsh/.zshrc_work
    source $HOME/.config/zsh/env_work.zsh
fi
# zprof
