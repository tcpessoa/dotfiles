# dotfiles management

This repo is to manage dotfiles and installing them using stow.
It accomodates:
- personal and work configurations for gitconfig and zsh.
- packages installation by host

# MAC OS base installation

Run this for base installation (oh my zsh, homebrew, finder, etc):

```sh
./base_macos
```

# Install packages

```sh
./packages/install
```

If there are ad hoc installed packages in the host that are not synced to a file, run:

```sh
./packages/analyze
```

> [!note] Host commands on mac os
> ```sh
> scutil --get ComputerName
> scutil --get LocalHostName
> scutil --get HostName
> sudo scutil --set HostName axiom.local
> ```

# Stow all home configs

In order to create the symlinks run:
```sh
./sync-stow
```

# ZSH and env vars
Set all needed env vars in the [env.local](zsh/.config/zsh/env.local) file:

```sh
export WORK_ENV=true
export MY_KEY=sk-123
```

# Git
- Check the [gitconfig](./git/.gitconfig-work-example) file for an example of a work configuration. This file should be copied to `~/.gitconfig-work`:

```sh
cp git/.gitconfig-work-example ~/.gitconfig-work
```

- This configuration assumes that the work repos will be in `~/Documents/work/` and the personal ones in `~/code/`. This will then play nicely with the `zsh` functions to find work and personal repos defined in the [functions](./zsh/.config/zsh/functions.zsh) file.

# Useful LLM context

`{ tree -a -I '.git|tmux' && echo && tree -d -L 2 .; } | pbcopy`

# Neovim

Managed in other [repo](https://github.com/tcpessoa/kickstart.nvim)
