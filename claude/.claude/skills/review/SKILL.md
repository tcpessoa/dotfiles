---
name: review
description: Weekly inward loop — reflect on the week and keep the active set honest. Three-way fidelity reconciliation (THREADS ↔ 01-Projects ↔ commits), a next-action audit, and the slot-survival check (is the protected Track A slot surviving). Lighter than /calibrate, heavier than /reconcile. Propose-only. Run weekly.
---

You are running the user's **weekly review** loop (`/review`) — the *reflect-inward* half of the weekly tier. It sits between per-day `/reconcile` (record what happened) and monthly `/calibrate` (re-weight the setpoint). Its job: **keep the active set honest.** A stale "active" project generates false guilt and noise — worse than a missing archive — so the value here is **fidelity, not archival.** (Rationale: vault `adr/0007`.)

This loop does **not** re-weight PRIORITIES (that's `/calibrate`'s authority) and does **not** comment on the tracker (that's `/reconcile`). It writes only THREADS edits and its own watermark — propose-only.

## Step 0 — Load workspace context

Read `CONTEXT.md` (cwd, then `~/.claude/CONTEXT.md`) — daily-notes dir, THREADS/PRIORITIES paths, code root, repo→track map, and the PARA project root (`01-Projects/`). If there's no THREADS.md, this loop has little to reconcile — tell the user it's built around an active-thread index.

## Helpers (read these next)

- `~/.claude/skills/_shared/threads.md` — THREADS format, the next-action field, the `Last weekly review:` watermark.
- `~/.claude/skills/_shared/priorities.md` — tracks & weights, the **protected Track A slot**, and the balance scan (incl. the posting-grep so Visibility reads true).
- `~/.claude/skills/_shared/daily-notes.md` — read the last 7 entries.
- `~/.claude/skills/_shared/propose-apply.md` — propose-first; apply only on `go`.

**Vault prose rule:** propose *structural* edits (add/demote a thread, fill or flag a Next action, mark a project stale). Where a Next action is genuinely undecided, surface it as a question for the user to answer in their words — don't invent the action for them.

## Step 1 — Load the active set (three sources)

In parallel, load the three things the fidelity check reconciles:
- **Attention** — `THREADS.md` in full (🔥 Open + 💤 Dormant).
- **Knowledge containers** — list `01-Projects/` (folders and top-level notes). These are the project *homes*.
- **Reality** — handled in Step 2 (commits). Also read the **last 7 daily entries** for narrative signal (a project quietly abandoned, a new direction).
- `PRIORITIES.md` — tracks, weights, and the line you'll test in Step 3.3: *"is the protected Track A slot surviving, or is OI's grind eating it?"*

## Step 2 — Observe: the week's reality

Run the 7-day balance scan per `priorities.md`:

```bash
review-changes --since "$(date -v-7d +%Y-%m-%d)"
```

Attribute commits to tracks. **Fold in the posting-grep** (per `priorities.md`): scan the in-window brain dumps for completed-posting signals (`posted` / `published` / `tweeted` / `shipped a thread`) and count them toward Visibility — otherwise the leverage track reads dark even on weeks the user posted.

## Step 3 — Diff: the three fidelity checks

### 3.1 Three-way reconciliation (THREADS ↔ 01-Projects ↔ commits)

Flag anything live in one source but dead in the others:
- **Project with no pulse** — a `01-Projects/` folder with no 🔥 thread *and* no commits in the window → propose: confirm it's done (→ archive) or dormant, or resurface a thread. Don't auto-archive; ask.
- **Orphan thread** — a 🔥 thread doing real work with no project home in `01-Projects/` → propose: file a project note (or confirm it belongs elsewhere in PARA).
- **Unsurfaced work** — commits to a repo this week with no matching 🔥 thread → propose: add a thread (work happening off the books).

### 3.2 Next-action audit

For every 🔥 Open thread: does it have a **live** Next action, or a placeholder (`*(fill when ready)*`, empty)? List the placeholders — a thread without a next action is the #1 thing that silently rots (GTD's core invariant). Surface each as a question; don't write the action for the user.

### 3.3 Slot-survival check (the one metric)

From the balance scan: did **Track A (the protected discretionary slot)** get its hours this week, or did the day job eat it? Report it as a plain verdict — `surviving` / `starved` — with the number. This is the user's own stated metric to watch; the system asks it on schedule so the user doesn't have to notice. **Never moralize** — state the data, let the user decide whether to renegotiate hours.

## Step 4 — Present the plan (propose-only)

```
## 🪞 Weekly review — <date>
Last reviewed <date> (<N> days ago). Window: last 7d.

### 🎯 Slot-survival (the one metric)
Track A this week: <N commits / signals> — **<surviving | starved>**. <one line, no lecture>

### 🧭 Fidelity (THREADS ↔ 01-Projects ↔ commits)
**Stale project (no pulse):**
- <project> — no thread, no commits in 7d → done? dormant? (your call)
**Orphan thread (no home):**
- <thread> — real work, no `01-Projects/` note → file one?
**Unsurfaced work:**
- <repo> — <N> commits, no thread → add a thread?

### 📌 Next-action audit (placeholders to fill)
- <thread> — Next action is a placeholder. What's the next concrete step? (you word it)

### 🗓️ Stamp
- `Last weekly review:` <old> → <today> in THREADS.

### To apply
Reply `go` to apply the structural edits + stamp, or selectively (`apply 1,3`, `skip stamp`). The Next actions I leave for you to word; the thread adds/marks I apply.
```

## Step 5 — Apply on confirmation

Per `propose-apply.md`, on `go`:
1. Apply approved THREADS edits (adds, marks, demotions) per `threads.md`; recompute the `## 🔥 Open (N)` / `## 💤 Dormant (N)` headers.
2. For Next actions the user worded, write them into the thread's `Next action:` field. Leave un-worded ones flagged.
3. **Stamp** `**Last weekly review:** <today>` in THREADS.md's header (add the line if absent) — the watermark `/next` reads.
4. Print confirmations.

If a step fails: stop, report, don't proceed. The stamp lands only if the review actually applied, or `/next` will think the loop ran.

## Tone

- Dense, propose-first, no greetings.
- This is a reflection, not a status report — but a terse one. The slot-survival line is the headline; everything else is hygiene.
- Never re-weight tracks (that's `/calibrate`) and never moralize about the balance — surface, propose, move on.
