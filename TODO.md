# TODO

## packages: backend seam for non-brew OSes

`packages/install`, `packages/analyze`, and `packages/health` are currently 100% Homebrew-coupled
(`is_cask`, `brew install`, `brew leaves`, `brew list --cask`, `scutil`). To support a Linux host,
extract the install/query primitives behind a backend selected by `dotfiles_os`:

- `packages/backend/brew.sh` — `pkg_is_installed`, `pkg_install`, `pkg_list_installed` (current logic).
- `packages/backend/apt.sh` (or pacman) — same interface for Linux.
- `packages/install` sources `backend/$(dotfiles_os).sh` and stops calling brew directly.

Keep the list-file format unchanged: shared `group/base` + per-host `group/<host>/host`. Only a few
package *names* differ across OSes (e.g. `fd` vs `fd-find`); handle those with either a per-OS overlay
file (`group/<host>/linux`) or a name-map inside the backend — not a full host×OS matrix.

Deferred: only worth doing when actually provisioning a Linux box.

## provisioning: improvements queue (2026-08-31 review)

Ranked by payoff; each stands alone.

### 1. Migrate package lists to `brew bundle` (Brewfiles)
One `Brewfile` per group (`packages/group/<host>/Brewfile` + a shared base) using
`tap` / `brew` / `cask` / `mas` entries. Makes whole bug classes structurally
impossible: cask-vs-formula registries (the postman bug), tap-qualified name
matching, the keg-only special case (`brew "libpq", link: true`). Replaces
`packages/analyze` outright (`brew bundle dump` / `cleanup` / `check`).
`packages/install` shrinks to `brew bundle --file` per group plus the non-brew
section (rust/nvm/npm); most of `health` becomes `brew bundle check` + nvm/npm
probes. Migration is mechanical: `brew bundle dump` per host, diff against
current lists, gut the script.
Note: partially supersedes the backend-seam TODO above — on Linux, `brew bundle`
still works under linuxbrew, or the seam applies to the much smaller residue.

### 2. `./update` entrypoint for steady state
Fresh boot has one command; maintenance still has a README table. All steps are
idempotent already, so: `git pull --rebase` → submodule update → packages →
sync-stow → health. Thin wrapper in `bin/` (`dotfiles-update`) so it runs from
anywhere. The README "when to run what" table collapses to one line.

### 3. CI smoke test
GitHub Action: `/bin/bash -n` + shellcheck over install/setup/packages scripts,
then the stub-brew dry run (DOTFILES_YES=1, fake `brew`/`npm` on PATH, fake HOME
for sync-stow — same harness as the 2026-08-31 review). Optional macOS runner
job running the real flow end-to-end (runners ship with brew). Guards the
bare-machine path, which is exercised least and breaks most.

### 4. Secrets out of plaintext env.local
`pass` + `pinentry-mac` are already installed; or macOS keychain
(`security find-generic-password -w -s <NAME>`). Lazy-load in init.zsh (fetch on
first use, not per shell) to keep startup fast. env.local keeps only WORK_ENV
and non-secret toggles.

### 5. Smaller
- `health`'s tool list is hand-maintained and drifts from `base` (adding a
  formula there doesn't add a check) — mostly moot after item 1.
- `mise` could replace nvm + the ensure_node deferral machinery with one brew
  formula. Toolchain change, not a cleanup — only if nvm chafes.
