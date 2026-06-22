---
name: checkpoint
description: (deprecated alias) Old name for /reconcile in mid-day mode — light write-back. Scheduled for removal ~2026-06-29.
---

`/checkpoint` is now **`/reconcile` in mid-day mode** (see vault `adr/0004`).

Invoke the `reconcile` skill (Skill tool, `skill: "reconcile"`) and run it in **mid-day** mode: tracker comments on existing tickets + THREADS deletions + AI-block refresh — **no** new tickets, **no** Hemingway bridge. This alias exists only for muscle memory and will be removed around 2026-06-29.
