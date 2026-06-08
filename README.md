# dotfiles management

This repo is to manage dotfiles and installing them using stow.
It accomodates:
- personal and work configurations for gitconfig and zsh.
- packages installation by host

## Layout

- `install` — single entrypoint: runs `setup/bootstrap` → `packages/install` → `setup/sync-stow`, in that order.
- `setup/` — one-time provisioning machinery:
  - `bootstrap` — OS-agnostic setup (shell, zsh plugins, TPM, submodules); dispatches to `os/<os>`.
  - `os/<os>` — OS-specific prerequisites. `os/macos` does Xcode, Homebrew, and Finder/Dock defaults. Add `os/linux` to extend.
  - `lib.sh` — shared helpers (`dotfiles_host`, `dotfiles_os`) sourced by the scripts so host/OS detection has one definition.
  - `sync-stow` — stows the config packages into `$HOME`.
- `packages/` — package lists per host under `group/<host>/` (a shared `base` symlinked in, plus a `host` file), installed by `packages/install`.

# Provision a machine

One command does bootstrap, packages, and stow:

```sh
./install
```

The steps are also runnable on their own:

```sh
./setup/bootstrap    # prerequisites: Xcode/Homebrew, zsh plugins, TPM, submodules
./packages/install   # CLI tools (incl. stow) for this host
./setup/sync-stow    # symlink configs into $HOME
```

> macOS GUI defaults (Finder/Dock) are applied once and then skipped on re-runs.
> Force a re-apply with `DOTFILES_MACOS_DEFAULTS=force ./setup/os/macos`.

If there are ad hoc installed packages on the host that are not synced to a file, run:

```sh
./packages/analyze
```

# After I change something — what to run

`./install` is the *provision-a-machine* tool, not the *I-tweaked-a-dotfile* tool. Configs are
stowed as **symlinks**, so editing an already-stowed file is live the moment you save — no command
needed. Running `./install` is always safe (every step is idempotent), but usually a targeted
script is faster and clearer.

| What you changed | What to run |
|---|---|
| Edited an **already-stowed** config (`zsh/…`, `git/…`, `starship/…`) | **Nothing** — it's a symlink, already live. New shell or `szsh` to reload. |
| Added a **new package dir** or a file outside an existing stowed tree | `./setup/sync-stow` (creates the new symlink) |
| Added a tool to a `packages/group/<host>` file | `./packages/install` |
| Changed a `defaults write` in `setup/os/macos` | `DOTFILES_MACOS_DEFAULTS=force ./setup/os/macos` — plain `./install` **skips** it (marker) |
| Fresh machine / "just make everything right" | `./install` |

> [!note] Host commands on mac os
> ```sh
> scutil --get ComputerName
> scutil --get LocalHostName
> scutil --get HostName
> sudo scutil --set HostName axiom.local
> ```

# ZSH and env vars
Set all needed env vars in the [env.local](zsh/.config/zsh/env.local) file:

```sh
export WORK_ENV=true
export MY_KEY=sk-123
```

# Git
- Check the [gitconfig](./git/.config/git/config-work-template) file for an example of a work configuration. Make a copy and make necessary changes:

```sh
cp ./git/.config/git/config-work-template ./git/.config/git/config-work
```

- This configuration assumes that the work repos will be in `~/Documents/repos_work/` and the personal ones in `~/code/`. This will then play nicely with the `zsh` functions to find work and personal repos defined in the [functions](./zsh/.config/zsh/functions.zsh) file.

# Neovim

Included as a submodule from [kickstart.nvim fork](https://github.com/tcpessoa/kickstart.nvim). After cloning:

```sh
git submodule update --init --recursive
```
