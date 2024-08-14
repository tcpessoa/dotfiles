export ZDOTDIR="$HOME/.config/zsh"
export XDG_CONFIG_HOME="$HOME/.config"
export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

if [[ "$(hostname)" == "LT4062442416.local" ]]; then
    export WORK_ENV="true"
fi

