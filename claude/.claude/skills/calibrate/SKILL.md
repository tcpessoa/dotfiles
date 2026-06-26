---
name: calibrate
description: Setpoint loop — re-weight PRIORITIES tracks against sustained commit balance, resolve stale TBDs, bulk-prune the thread backlog, and stamp Last reviewed. The slow outer loop; propose-only. Run monthly or on a real decision.
---

You are running the user's **setpoint loop** (`/calibrate`) — the slow, outer tier of the cascade. Where `/next` orients per-session and `/reconcile` records per-day, `/calibrate` runs **monthly (or on a real decision)** and adjusts the *desired-state itself*: the PRIORITIES track weights and the thread backlog. It compares **sustained** actual activity against what the user *said* should get their hours, surfaces the drift, and proposes a re-weighting.

This is the one loop allowed to **write PRIORITIES** — and even here it is **propose-only** (`_shared/priorities.md`): the human ratifies every weight change. `/next` and `/reconcile` only ever read PRIORITIES.

**Watermark.** On apply, `/calibrate` stamps `Last reviewed:` in PRIORITIES. `/next`'s control-plane health check reads that stamp and stops flagging calibration as overdue (see vault `adr/0006`). That's how the loop closes — no separate state.

**Cadence.** `Revisit cadence` in PRIORITIES (default monthly), **or** on a real decision — a job change, a track winning, a bandwidth shift. The "on a decision" trigger is manual; `/next` only auto-surfaces the time-based half.

## Step 0 — Load workspace context

Read `CONTEXT.md` (cwd, then `~/.claude/CONTEXT.md`). It gives the daily-notes dir, THREADS/PRIORITIES paths, code root, and the repo→track map. If there's **no PRIORITIES.md**, stop — `/calibrate` has nothing to calibrate; tell the user this loop only applies to workspaces with a declared track budget.

## Helpers (read these next)

- `~/.claude/skills/_shared/priorities.md` — PRIORITIES protocol: what the tracks mean, the repo→track map, the commit-to-track balance, and the long (~4-week) window this loop uses.
- `~/.claude/skills/_shared/threads.md` — THREADS format + promotion/demotion/deletion rules (this loop does the periodic bulk pass, heavier than `/reconcile`'s daily touch).
- `~/.claude/skills/_shared/propose-apply.md` — propose-first; apply only on `go`.
- `~/.claude/skills/commit/SKILL.md` — house commit style, for the vault commit at the end.

**Vault prose rule (important):** PRIORITIES is the user's *normative, human-facing* file. Propose **structural** edits — weight cells, target hours, track status, a settled `TBD`, the `Last reviewed:` date, thread deletions. Do **not** invent narrative prose (the *why* paragraphs, the phase description). Where a decision is genuinely open, surface it as a question for the user to answer in their own words — don't write the rationale for them.

## Step 1 — Load context (the whole picture)

In parallel:
- Read **`PRIORITIES.md` in full** — current weights/target hours, the repo→track map, `Last reviewed:`, `Revisit cadence`, and any unresolved debris (`TBD`, "think about this", "(fill)", phase notes a later decision may have settled).
- Read **`THREADS.md` in full** — both 🔥 Open and 💤 Dormant. This loop GCs the whole backlog, not just today's deltas.
- Read the **daily notes since `Last reviewed:`** (or the last ~30 if that's unclear) per `daily-notes.md` — the episodic record of what actually happened and any brain-dump signals of a priority shift or a real decision.

## Step 2 — Observe: the sustained balance

Per `priorities.md`, run the **long-window** balance scan (not `/next`'s 7-day snapshot):

```bash
review-changes --since "<Last reviewed date, or $(date -v-4w +%Y-%m-%d)>"
```

Attribute each commit's repo to a track via the repo→track map; tally per-track counts over the window. Repos not in the map → "untracked." Keep it counts-only. **Also fold in note-work**: the vault's own track-scoped commits (`docs(<track>): …`) count toward a track's activity — visibility/writing work shows up as commits too, not just code.

## Step 3 — Diff: actual vs declared (the gaps to close)

1. **Weight drift** — per track, declared weight / target-hours vs actual share over the window:
   - A **Primary** track chronically at ~0 → either it's not really primary, or something is eating its slot. Name the suspect (often the day job or a capped track).
   - A **capped/gym** track running over its cap or displacing a Primary slot → flag the inversion.
   - A **Dormant** track with sustained activity → the phase may be shifting; propose promoting it.
2. **Stale setpoints** — `TBD` / "think about this" / "(fill)" / phase notes that a real decision since `Last reviewed:` has settled. (E.g., a job change resolves "is Track B the day job?" and "job hunt weighting.")
3. **Thread backlog hygiene** — the periodic GC `/reconcile`'s daily pass keeps deferring: 🔥 Open threads long past the dormancy threshold; 💤 Dormant threads that are never coming back (propose delete, not just demote); whole tracks gone silent.
4. **Cadence** — how overdue the review itself is (`Last reviewed:` vs `Revisit cadence`).

## Step 4 — Present the plan (propose-only)

Dense and scannable. Only show non-empty buckets.

```
## 🎛️ Calibrate — <date>
Last reviewed <date> (<N> days / <overdue|on-cadence>). Window: <start> → today (~<W> weeks).

### ⚖️ Balance vs declared
<one compact line per track: declared weight/target → actual commits in window → verdict>
> e.g. A (primary, ~4–5h/wk): 1 commit/4wk → starved. B (day job): 60 → as expected. Visibility (leverage): 0 → dark.

### 🔧 Re-weight (PRIORITIES edits)
- **<Track>**: <current weight/hours> → <proposed>. Why: <balance evidence, one line>.

### ❓ Decisions to settle (I won't word these for you)
- <stale TBD / phase note> — the decision looks settled by <event>; how do you want to phrase it? (or: still open?)

### 🧶 Thread GC (THREADS.md)
**Delete (dead):**
- <theme> — dormant since <date>, <N> mentions, no path back.
**Demote (>cadence):**
- <theme> — 🔥 but last seen <date>.
**Promote (phase shift):**
- <theme> — sustained activity; track is heating up.

### 🗓️ Stamp
- `Last reviewed:` <old> → <today>. Cadence: <keep monthly | propose change>.

### 📓 Vault commit (runs last, after the writes land)
- `chore(priorities): recalibrate track weights <month>`
- `chore(threads): periodic GC — N deleted, M demoted`

### To apply
Reply `go` to apply everything, or selectively (`apply 1,3`, `skip threads`, `skip commit`). Weight cells and thread edits I apply directly; the "Decisions to settle" I leave for you to word.
```

## Step 5 — Apply on confirmation

Per `propose-apply.md`:
1. Edit **PRIORITIES.md** — weight/target cells, track statuses, any `TBD` the user settled (in *their* words, not invented), then update `Last reviewed:` to today.
2. Apply **THREADS.md** edits (deletes / demotes / promotes) per `threads.md`; recompute the `## 🔥 Open (N)` / `## 💤 Dormant (N)` count headers.
3. **Vault commit — LAST**, after 1–2 land, per `commit/SKILL.md`: track-scoped, conventional, concise, no co-author trailer, multiple small commits. Do not push. Print each `✅ <type(scope): subject>`.

If a step fails: stop, report, don't proceed. The `Last reviewed:` stamp must only land if the calibration actually applied — otherwise `/next` would wrongly think the loop ran.

## Tone

- Dense, propose-first, no greetings.
- **Never moralize** about the imbalance (per `priorities.md`) — surface the data, propose the rebalance, let the user decide.
- This loop changes *intentions*, so bias toward asking over asserting on anything narrative. Weights are yours to propose; the *why* is the user's to write.
