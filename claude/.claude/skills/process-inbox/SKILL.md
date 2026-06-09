---
name: process-inbox
description: Clear the 0-Inbox capture buffer — route each item to its cognitive home (PARA knowledge, THREADS, PRIORITIES, daily, or trash). Propose-first; moves files on go, never rewrites their prose.
---

You are clearing the user's **intake buffer** (`0-Inbox/`). This is **categorization mode**, not steering mode: the one job is to empty the buffer by moving each item to the file/folder that matches its cognitive function. You do **not** re-weight priorities, prune threads, or check commit balance — that's a separate weekly review. Run this whenever the buffer fills (buffer-triggered, not calendar-triggered).

The guiding model (see the target `CONTEXT.md` → "How my system thinks"): every captured item belongs to exactly one function — **Knowledge** (PARA), **Attention** (THREADS), **Intention** (PRIORITIES), **Episodic** (daily), or it's **trash**. Most land in Knowledge/PARA.

## Step 0 — Load workspace context

Read `CONTEXT.md` (cwd, then `~/.claude/CONTEXT.md`) for the vault root, the PARA layout, and the paths to THREADS.md / PRIORITIES.md / daily. If neither exists, stop and ask the user to set one up.

## Helpers (read these next)

- `~/.claude/skills/_shared/threads.md` — THREADS.md format (for items that are in-flight intents).
- `~/.claude/skills/_shared/priorities.md` — track map (helps route an item to the right project/area, and tag any new thread).
- `~/.claude/skills/_shared/propose-apply.md` — propose-first rule; apply only on `go`.

## The vault prose rule (non-negotiable)

The vault's `AGENTS.md` says: **don't write prose on the user's behalf — move / restructure / suggest.** So this skill **moves and files** (that's restructuring, allowed) but never rewrites an item's content into new prose. If an item genuinely needs synthesis/merging, *propose* it and let the user do the writing, or wrap a suggestion in an AI block. Renaming a file for clarity is fine; rewriting its body is not.

## Step 1 — List the buffer

List every file in `0-Inbox/`. Read each one (they're short). For each, determine its dominant cognitive function.

## Step 2 — Classify and route

For each item, propose ONE destination:

| If the item is… | Function | Route to | Action |
|---|---|---|---|
| Durable reference / knowledge (links, notes, how-tos, book lists, ideas to keep) | Knowledge | matching `03-Resources/<topic>/`, or an existing `02-Areas/<area>/` note | **move** (or merge-suggest if a target note already covers it) |
| A scoped piece of an active project | Knowledge | the project folder under `01-Projects/<proj>/` | **move** |
| An in-flight intent / next action / idea to act on | Attention | add a `🔥` thread to `THREADS.md` (tag its `**Track:**`), and/or move the source note to its project | **add thread** (+ move) |
| A decision about what should get time | Intention | `PRIORITIES.md` | **flag for the user** (never auto-edit PRIORITIES) |
| A record of something that happened | Episodic | the relevant `daily/` note | **move/merge-suggest** |
| Stale / done / no longer relevant | — | delete | **delete** (always confirm) |

Routing guidance:
- Prefer an **existing** target folder/note over creating new ones. Match against the actual `03-Resources/` and `02-Areas/` subfolders you see.
- If an item maps to a PRIORITIES track (via the track map), prefer that track's project/area as the home.
- When unsure between two homes, present both and let the user pick — don't guess silently.
- Group obvious like-items (e.g. several "cool repos" notes → one `03-Resources/programming-general/` home).

## Step 3 — Present the routing plan

```
## 📥 Process inbox — <N> items

### → Knowledge (PARA)
- `0-Inbox/<file>` → `03-Resources/<topic>/<file>`  (move)
- `0-Inbox/<file>` → merge into `02-Areas/<area>/<note>`  (suggest — needs your prose)

### → Attention (THREADS)
- `0-Inbox/<file>` → new 🔥 thread "<title>" (Track: <X>); move source to `01-Projects/<proj>/`

### → Intention (PRIORITIES) — your call
- `0-Inbox/<file>` — looks like a priority decision; review and fold into PRIORITIES yourself.

### → Episodic (daily)
- `0-Inbox/<file>` → append to `daily/<date>.md`  (suggest)

### 🗑️ Delete (confirm)
- `0-Inbox/<file>` — <why it's stale/done>

### ❓ Need your decision
- `0-Inbox/<file>` — home unclear: (a) `03-Resources/X`, (b) `02-Areas/Y`, (c) keep in inbox.

### To apply
Reply `go` to apply moves + thread additions + confirmed deletes. Or selectively: `apply 1,3`, `skip deletes`, `change 2 to <path>`.
```

## Step 4 — Apply on confirmation

Per `propose-apply.md`, only on `go`:
1. **Moves** — `git mv` / move the file to its destination (preserves history where the vault is a repo). Create the destination folder only if the user approved a new one.
2. **THREADS additions** — add the `🔥` entry per `threads.md` (with `**Track:**`), recompute the `## 🔥 Open (N)` count. Move the source note too if proposed.
3. **Deletes** — remove confirmed files.
4. **PRIORITIES / merge-suggest items** — do NOT auto-write. Leave them in the inbox and restate them as "still needs your hand" so they're not lost.
5. Print confirmations (`✅ Moved <file> → <dest>`, `✅ Added thread "<title>"`, `🗑️ Deleted <file>`).

Items you couldn't confidently route stay in the inbox — that's fine. An inbox that's 90% cleared is a success; don't force-file ambiguous things.

## Tone

- Dense, scannable. No preamble.
- Default to moving, not rewriting. When in doubt, ask — the inbox tolerates leftovers.
