# dotfiles management

This repo is to manage dotfiles and installing them using stow

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

Check the rest of the `install_macos.sh` script for installation of other packages.

# ZSH
- Ensure that the file `~/.zshenv` exists and is:
```sh
export ZDOTDIR=$HOME/.config/zsh
```

If it is the work station, then the `~/.zshenv` file should be:
```sh
export ZDOTDIR=$HOME/.config/zsh
export WORK_ENV="true"
```

- Refer to `install_macos.sh` for installation of `oh-my-zsh` and `zsh-syntax-highlighting`.
- Refer to `zsh/health.zsh` for health check and needed packages.

# Neovim

Managed in other [repo](https://github.com/tcpessoa/kickstart.nvim)
