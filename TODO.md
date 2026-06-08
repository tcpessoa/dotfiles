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
