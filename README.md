# dotfiles

Dotfiles managed with stow, per-host package lists, and a personal/work split
for git and zsh.

## Layout

- `setup/init` — pre-clone bootstrap for a bare machine: Xcode CLT, Homebrew, clone, then `./install`.
- `install` — single entrypoint once the repo exists: bootstrap → packages → stow → postinstall.
- `setup/bootstrap` — host identity, `env.local`, shell, zsh plugins, TPM, submodules; dispatches to `setup/os/<os>`.
- `setup/sync-stow` — symlinks the config packages into `$HOME`.
- `setup/postinstall` — `gh auth login`, optional HTTPS→SSH remote upgrade, tmux + nvim plugins.
- `packages/group/<host>/` — package lists: shared `base` (symlinked in), a `host` file, an optional `gui` file (casks, opt-in).

Each script has a header comment with the details.

# Provision a machine

## From scratch (no git, no brew, no SSH key)

```sh
curl -fsSL https://raw.githubusercontent.com/tcpessoa/dotfiles/main/setup/init | bash
```

You get asked three things — hostname, work-or-personal, GUI apps — each
pre-filled with a sane default, plus a browser tab for `gh auth login` and an
editor for API keys.

> [!note] No SSH key is needed
> The clone and the nvim submodule use HTTPS. `setup/postinstall` offers to
> generate a key, add it to GitHub, and flip `origin` to SSH at the end —
> decline it and nothing breaks.

## If the repo is already cloned

```sh
./install
```

The steps also run on their own, each idempotent:

```sh
./setup/bootstrap    # Xcode/Homebrew, hostname, env.local, zsh plugins, TPM, submodules
./packages/install   # CLI tools (incl. stow) for this host
./setup/sync-stow    # symlink configs into $HOME
./setup/postinstall  # gh auth, SSH upgrade, tmux + nvim plugins
```

> `DOTFILES_YES=1` takes the default for every prompt (dry run / CI).
> The repo works from any path; nothing is hardcoded to `~/dotfiles`.

> macOS GUI defaults (Finder/Dock) apply once, then are skipped on re-runs.
> Re-apply with `DOTFILES_MACOS_DEFAULTS=force ./setup/os/macos`.

## Hosts and package groups

`packages/install` uses `packages/group/$(scutil --get LocalHostName)`; a
missing group is a hard error. `setup/bootstrap` asks for the hostname and
creates the group, seeded from an existing host or just `base`.

To find packages installed on the host but missing from the lists:

```sh
./packages/analyze
```

# After I change something — what to run

Configs are stowed as symlinks, so editing an already-stowed file is live on
save. `./install` is always safe (idempotent), but a targeted script is faster:

| What you changed | What to run |
|---|---|
| An **already-stowed** config (`zsh/…`, `git/…`) | **Nothing** — new shell or `szsh` to reload |
| A **new package dir** or a file outside a stowed tree | `./setup/sync-stow` |
| A `packages/group/<host>` file (incl. `gui`) | `./packages/install` |
| A `defaults write` in `setup/os/macos` | `DOTFILES_MACOS_DEFAULTS=force ./setup/os/macos` |
| Fresh machine / "make everything right" | `./install` |
| Bare machine | `curl … setup/init \| bash` (above) |

# ZSH and env vars

`env.local` is gitignored; `setup/bootstrap` creates it from
[env.local.example](zsh/.config/zsh/env.local.example). All machine-local env
vars go there:

```sh
export WORK_ENV=true
export MY_KEY=sk-123
```

`WORK_ENV` drives the work-only shell config and the work gitconfig.

> [!note] Login-shell config lives in `$ZDOTDIR`
> `~/.zshenv` sets `ZDOTDIR`, so zsh reads `~/.config/zsh/.zprofile` — a file at
> `~/.zprofile` is never sourced. If you need login-shell setup, that is where
> it goes.

# Git

On a work machine, `setup/bootstrap` creates `config-work` from the
[template](./git/.config/git/config-work-template). Work repos live in
`~/work/`, personal ones in `~/code/` — the git config and the zsh repo
functions in [functions.zsh](./zsh/.config/zsh/functions.zsh) assume this.

# Neovim

A submodule of my [kickstart.nvim fork](https://github.com/tcpessoa/kickstart.nvim),
cloned over HTTPS. `setup/bootstrap` updates it; `setup/postinstall` syncs
plugins headlessly so the first launch isn't a progress bar.
