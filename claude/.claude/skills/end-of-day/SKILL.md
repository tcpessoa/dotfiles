---
name: end-of-day
description: (deprecated alias) Old name for /reconcile in eod mode — full write-back. Scheduled for removal ~2026-06-29.
---

`/end-of-day` is now **`/reconcile` in eod mode** (see vault `adr/0004`).

Invoke the `reconcile` skill (Skill tool, `skill: "reconcile"`) and run it in **eod** mode: tracker comments + new tickets for untracked work + all THREADS edits (add/delete/demote/promote) + tomorrow's Hemingway bridge + the vault commit. This alias exists only for muscle memory and will be removed around 2026-06-29.
