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

# GIT
## gitconfig
- In order for the conditional include to work, the `~/Documents/repos_work/` directory must exist and be a git repository.
- It should include a `.gitignore` file with the following content:
```
*
!.gitignore
```
- Another `.ignore` file should be created in the same directory with the following content:
```
!*
```

This is to ensure that the `~/Documents/repos_work/` directory is a git repository, but only the `.gitignore` file is tracked.
The `.ignore` file is to ensure that `ripgrep` and `fd` work properly in the directory.
# Neovim

Managed in other [repo](https://github.com/tcpessoa/kickstart.nvim)

# Stow

In order to create the symlinks run:
```sh
stow zsh -t ~
```
Using `-t ~` is explicitly defining that the target for the symlinks is the home directory, which is usually what you want when managing dotfiles. 
If you do not specify `-t`, `stow` assumes the parent directory of where it is run as the target directory.
