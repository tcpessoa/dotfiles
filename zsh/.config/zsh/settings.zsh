# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export BAT_THEME="TwoDark"
export TASKRC=$HOME/.config/taskwarrior/taskrc
