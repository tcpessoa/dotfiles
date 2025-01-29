# dotfiles management

This repo is to manage dotfiles and installing them using stow.
It accomodates personal and work configurations for gitconfig and zsh.

# MAC OS base installation

Run this for base installation (oh my zsh, homebrew, finder, etc):

```sh
./base_macos.sh
```

# CLI and GUI tools

# ZSH
If it is the work station, then the [zshenv](./zsh/.zshenv) file should handle the `WORK_ENV` var:


# Git
- Check the [gitconfig](./git/.gitconfig-work-example) file for an example of a work configuration. This file should be copied to `~/.gitconfig-work`:
```sh
cp git/.gitconfig-work-example ~/.gitconfig-work
```
- This configuration assumes that the work repos will be in `~/Documents/work/` and the personal ones in `~/code/`. This will then play nicely with the `zsh` functions to find work and personal repos defined in the [functions](./zsh/.config/zsh/functions.zsh) file.

# Stow

In order to create the symlinks run:
```sh
./sync-stow
```

# Starship

At work I add for kubernetes:

```toml
format = """
(...)
$kubernetes\
(...)
"""
(...)
[kubernetes]
format = '[$symbol\[[$context](bold fg:purple) $namespace\]](fg:bright-blue) '
disabled = false
```

# Neovim

Managed in other [repo](https://github.com/tcpessoa/kickstart.nvim)
