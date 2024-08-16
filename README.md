# dotfiles management

This repo is to manage dotfiles and installing them using stow.
It accomodates personal and work configurations for gitconfig and zsh.

# MAC OS

Install homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Show all hidden files in Finder:
```sh
defaults write com.apple.Finder AppleShowAllFiles true;
killall Finder
```

Check the rest of the [macos setup](./install_macos.sh) script for installation of other packages.


# Alacritty
- Ensure some Nerd Font is installed:
```sh
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font
```
- `brew install alacritty`
- `mkdir -p ~/.config/alacritty`
- `git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes`
- `stow alacritty -t ~`

# ZSH
If it is the work station, then the [zshenv](./zsh/.zshenv) file should handle the `WORK_ENV` var:

- Refer to [macos setup](./install_macos.sh) for installation of `oh-my-zsh` and `zsh-syntax-highlighting`.
- Refer to [health.zsh](./zsh/.config/zsh/health.zsh) for health check and needed packages. You may need to adjust the _shebang_ to the correct path of the `zsh` executable:

```sh
#!/usr/local/bin/zsh
(...)
```

```sh
#!/opt/homebrew/bin/zsh
(...) M chip macos
```

# Git
- Check the [gitconfig](./git/.gitconfig-work-example) file for an example of a work configuration. This file should be copied to `~/.gitconfig-work`:
```sh
cp git/.gitconfig-work-example ~/.gitconfig-work
```
- This configuration assumes that the work repos will be in `~/Documents/work/` and the personal ones in `~/code/`. This will then play nicely with the `zsh` functions to find work and personal repos defined in the [functions](./zsh/.config/zsh/functions.zsh) file.

# Stow

In order to create the symlinks run:
```sh
stow zsh -t ~
```
Using `-t ~` is explicitly defining that the target for the symlinks is the home directory, which is usually what you want when managing dotfiles. 
If you do not specify `-t`, `stow` assumes the parent directory of where it is run as the target directory.

# Scripts
```sh
stow scripts -t ~
```

Then from the home directory, run:
```sh
chmod +x dotfiles/scripts/bin/*
```

# Starship

Currently using the pure preset, need to run:
```sh
starship preset pure-preset -o ~/.config/starship.toml
```

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
