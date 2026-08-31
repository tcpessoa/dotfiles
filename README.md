# dotfiles management

This repo is to manage dotfiles and installing them using stow.
It accomodates:
- personal and work configurations for gitconfig and zsh.
- packages installation by host

## Layout

- `setup/init` — **pre-clone** bootstrap, the one thing you run on a bare machine. Installs Xcode CLT + Homebrew, clones this repo, then hands over to `./install`. Self-contained (it runs before the repo exists) and bash 3.2 clean (that is what stock macOS ships).
- `install` — single entrypoint once the repo exists: `setup/bootstrap` → `packages/install` → `setup/sync-stow` → `setup/postinstall`, in that order.
- `setup/` — one-time provisioning machinery:
  - `bootstrap` — OS-agnostic setup (host identity, `env.local`, shell, zsh plugins, TPM, submodules); dispatches to `os/<os>`.
  - `os/<os>` — OS-specific prerequisites. `os/macos` does Xcode, Homebrew, and Finder/Dock defaults. Add `os/linux` to extend.
  - `lib.sh` — shared helpers (`dotfiles_host`, `dotfiles_os`, `dotfiles_root`, prompts) sourced by the scripts so host/OS detection has one definition.
  - `sync-stow` — stows the config packages into `$HOME`.
  - `postinstall` — needs both tools and configs in place: `gh auth login`, the optional HTTPS→SSH remote upgrade, tmux plugins, Neovim plugin sync.
- `packages/` — package lists per host under `group/<host>/` (a shared `base` symlinked in, a `host` file, and an optional opt-in `gui` file), installed by `packages/install`.

# Provision a machine

## From scratch (nothing installed — no git, no brew, no SSH key)

One command in a stock Terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/tcpessoa/dotfiles/main/setup/init | bash
```

It installs the Xcode Command Line Tools and Homebrew, clones this repo over
**HTTPS** (public, so no credentials needed), and runs `./install`.

You get asked three things — hostname, work-or-personal, GUI apps — each pre-filled
with the right default, plus a browser tab for `gh auth login` and an editor for
API keys. Everything else is inferred.

> [!note] No SSH key is needed to provision
> The clone and the nvim submodule both use HTTPS. `setup/postinstall` offers to
> generate a key, register it with `gh ssh-key add`, and flip `origin` to SSH at
> the very end — decline it and nothing breaks.

## If the repo is already cloned

```sh
./install
```

The steps are also runnable on their own, and each is idempotent:

```sh
./setup/bootstrap    # prerequisites: Xcode/Homebrew, hostname, env.local, zsh plugins, TPM, submodules
./packages/install   # CLI tools (incl. stow) for this host
./setup/sync-stow    # symlink configs into $HOME
./setup/postinstall  # gh auth, SSH upgrade, tmux + nvim plugins
```

> `DOTFILES_YES=1` takes the default for every prompt — useful for a dry run or CI.
> The repo works from any path; nothing is hardcoded to `~/dotfiles`.

> macOS GUI defaults (Finder/Dock) are applied once and then skipped on re-runs.
> Force a re-apply with `DOTFILES_MACOS_DEFAULTS=force ./setup/os/macos`.

## Hosts and package groups

`packages/install` resolves `packages/group/$(scutil --get LocalHostName)`. If that
group does not exist it now **fails loudly** instead of installing nothing and
exiting 0. `./setup/bootstrap` asks for the hostname (pre-filled with the current
one) and offers to create the group, seeded from an existing host or from `base`
alone.

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
| Added a tool to a `packages/group/<host>` file (incl. `gui`) | `./packages/install` |
| Changed a `defaults write` in `setup/os/macos` | `DOTFILES_MACOS_DEFAULTS=force ./setup/os/macos` — plain `./install` **skips** it (marker) |
| Fresh machine / "just make everything right" | `./install` |
| Bare machine, nothing installed at all | `curl … setup/init \| bash` (see above) |

> [!note] Host commands on mac os
> ```sh
> scutil --get ComputerName
> scutil --get LocalHostName
> scutil --get HostName
> sudo scutil --set HostName axiom.local
> ```

# ZSH and env vars

`env.local` is gitignored, so it never exists on a fresh clone. `setup/bootstrap`
creates it from [env.local.example](zsh/.config/zsh/env.local.example) and offers to
open it. Set all needed env vars there:

```sh
export WORK_ENV=true
export MY_KEY=sk-123
```

`WORK_ENV` drives the work-only shell config and the work gitconfig, which is why
bootstrap asks for it up front rather than leaving it to you.

> [!note] Login-shell config lives in `$ZDOTDIR`
> `~/.zshenv` sets `ZDOTDIR`, so zsh reads `~/.config/zsh/.zprofile` — a file at
> `~/.zprofile` is never sourced. There is no `.zprofile` in this repo today;
> if you ever need login-shell setup, that is where it goes.

# Git
- On a work machine, `setup/bootstrap` copies the work config from the template for you
and opens it. To do it by hand, see the [template](./git/.config/git/config-work-template):

```sh
cp ./git/.config/git/config-work-template ./git/.config/git/config-work
```

- This configuration assumes that the work repos will be in `~/Documents/repos_work/` and the personal ones in `~/code/`. This will then play nicely with the `zsh` functions to find work and personal repos defined in the [functions](./zsh/.config/zsh/functions.zsh) file.

# Neovim

Included as a submodule from [kickstart.nvim fork](https://github.com/tcpessoa/kickstart.nvim),
over HTTPS so it clones without an SSH key. `setup/bootstrap` handles it; by hand:

```sh
git submodule sync --recursive && git submodule update --init --recursive
```

Plugins are synced headlessly by `setup/postinstall`, so the first launch isn't a progress bar.
