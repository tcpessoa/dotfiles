# TMUX
remove dependency on tms, rollout own tmux sessionizer, something like:

```tmux
# tmux sessionizer
bind C-k display-popup -E "tmux list-windows -a -F '#{session_name}:#{window_index} - #{window_name}' | grep -v \"^$(tmux display-message -p '#S')\$\" | fzf --reverse | sed -E 's/\s-.*$//' | xargs -r tmux switch-client -t"

bind C-l display-popup -E "\
  tmuxp_file=\$(fd -t f -e yaml . ~/.config/tmuxp | \
    fzf --reverse \
        --preview 'bat --style=numbers --color=always {}' \
        --preview-window right:50%); \
  if [ -n \"\$tmuxp_file\" ]; then \
    (cd ~ && tmuxp load -y \"\$tmuxp_file\";) \
  fi"
```

# ZSH
improve startup time, research on zsh plugins there are faster ways to load - check zinit

# NVIM
add neovim as submodule to this repo
