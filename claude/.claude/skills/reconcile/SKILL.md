---
name: reconcile
description: Write-back loop — reflect commits to the tracker, update THREADS, draft tomorrow's bridge, refresh the AI block, commit the vault. Two modes: mid-day (light) and eod (full); auto-catches-up across a skipped span.
---

You are running the user's **write-back** loop (`/reconcile`): update the system's record of reality — tracker, THREADS, daily note, vault history — to match what actually happened, and close the gaps that today's work resolved. This is the reconcile half of the control loop; `/next` is the read half.

## Mode — read this first

`/reconcile` runs in one of two modes. The difference is only *how much it writes*:

| | **mid-day** | **eod** |
|---|---|---|
| Tracker comments on existing tickets | yes | yes |
| New tickets for untracked work | **no** (list as deferred) | yes |
| THREADS edits | **deletions only** (done threads) | full (add / delete / demote / promote) |
| Hemingway bridge draft | **no** | yes |
| Vault commit | optional | yes |

**Picking the mode:** if the user passed an explicit arg (`mid-day` / `eod`), use it. Otherwise infer from local time — before ~17:00 → mid-day, later → eod — and **state which mode you chose** in the output so the user can override ("actually do eod"). When in doubt, default to mid-day (it makes fewer irreversible writes).

In mid-day mode, follow the **mid-day** rows of the "Which command does what" tables in `_shared/threads.md`; in eod mode, the **eod** rows. The steps below are written for eod (the superset) and annotated **[eod only]** where mid-day skips them.

### Catch-up — backfill a skipped span (auto, on top of eod)

The loop must be **level-triggered**, not edge-triggered on "today" (adr/0003): if you skipped one or more days, a plain today-only scan loses that work — it never reaches the tracker, THREADS, or the commit-to-track balance, and they silently drift from reality.

So `/reconcile` reconciles **the gap since the last full reconcile**, not just today:

- **Floor = last full reconcile.** The newest daily note *before today* whose AI block is stamped `by /reconcile (eod)` marks when you last reconciled. The daily-note stamp *is* the watermark — no separate state file. Step 2 computes this and scans from there.
- **Auto-widen.** If the floor is >1 day before today, you're in **catch-up**: announce it (`Catching up: N days since last reconcile (<floor> → today)`) and widen the scan automatically. A 0–1 day gap is a normal eod. This is the whole point — you don't have to *remember* to backfill.
- **Override.** `catch-up` / `backfill` forces it; `catch-up=YYYY-MM-DD` pins an explicit floor. Mid-day mode never catches up (it's the light, frequent loop — keep it today-only).
- **Catch-up only changes the *window*, not the writes.** Everything downstream (tracker, THREADS, bridge, vault commit) runs exactly as eod. Tracker idempotency (Step 3.3) makes the wider scan safe by construction — it cannot double-post. The daily-note rule below keeps it honest.
- **No retro-writing.** Do **not** rewrite past days' AI blocks — a skipped day's note stays as the true record (often empty; you weren't there). The whole span is summarized once, in **today's** block, clearly labeled (`Shipped (catch-up <floor>→<today>)`). Backfill repairs the *shared* record (tracker + THREADS), not the diary.

Goals, in order (eod; mid-day runs the subset per the table above):

1. Make sure the window's commits (today, or the whole catch-up span) are reflected in the issue tracker (comments on existing, **[eod only]** new tickets for untracked).
2. **[eod only]** Help the user write today's `## 🔖 Hemingway bridge` — the forward-looking note tomorrow's `/next` will read.
3. Refresh today's daily-note AI block with full-day summary + carryover.
4. **[eod only]** Commit the vault's day with clean, track-scoped conventional commits — so the vault's own git history becomes a usable **observe source** (note work shows up in the commit-to-track balance, not just code).

## Step 0 — Load workspace context

Read `CONTEXT.md` (cwd, then `~/.claude/CONTEXT.md`). It tells you who the user is, where their daily notes / THREADS / repos live, and which tracker (`jira` / `gh` / `none`) they use. If neither file exists, stop and ask the user to set one up — see `~/.claude/CONTEXT.md.example`.

If `Tracker: none`, this command degrades to: commit summary, threads update, Hemingway bridge draft, AI block refresh, **vault commit**. No tracker comments, no new tickets. The bridge + carryover loop and a clean vault history are still the point.

## Helpers (read these next)

- `~/.claude/skills/_shared/issue-match.md` — matching protocol + **timestamp idempotency** (important — if an earlier mid-day run already commented, don't re-post).
- `~/.claude/skills/_shared/daily-notes.md` — context loading + AI block write.
- `~/.claude/skills/_shared/threads.md` — THREADS.md format and update protocol.
- `~/.claude/skills/_shared/priorities.md` — PRIORITIES.md protocol: track weighting; tag new threads with a track. Skip if the workspace has no PRIORITIES.md.
- `~/.claude/skills/_shared/propose-apply.md` — propose-first rule.
- `~/.claude/skills/commit/SKILL.md` — the user's commit house style (conventional, concise, body sparingly, no co-author trailer, multiple small commits preferred). Used in the final step to commit the vault.
- **If `Tracker: Jira`**: also read `~/.claude/skills/_shared/jira-cli.md` — CLI quirks + apply order + Comment voice.

## Step 1 — Load context

In parallel:
- Re-read `CONTEXT.md` if needed (routing / glossary section).
- Read `THREADS.md` (path from `CONTEXT.md`; skip if none).
- Read `PRIORITIES.md` (path from `CONTEXT.md`; skip if none) per `priorities.md` — tracks & weights (to tag new threads and to keep the bridge pointed at the right track).
- Read the **last 7 daily entries before today** per `daily-notes.md`.
- Read **today's daily file** — especially:
  - The existing AI block (if `/next` or an earlier `/reconcile` ran today). It records what's already been done.
  - Today's `## 🗒️ Brain dump` — if the user wrote thoughts there, they're context for what really happened today.

## Step 2 — Scan the reconcile window

First compute the **floor** — the last full reconcile (see "Catch-up" above). Find the newest daily note before today whose AI block was written by a full reconcile:

```bash
# newest daily file (excluding today) stamped by a full reconcile → its date is the floor
ls "<daily-dir>"/*.md \
  | grep -v "$(date +%Y-%m-%d).md" \
  | sort -r \
  | while read f; do grep -lq 'by /reconcile (eod)' "$f" && { basename "$f" .md; break; }; done
```

- **mid-day mode:** ignore the floor — always scan today only (`review-changes`, no args).
- **eod mode:** floor → today.
  - Floor is today or yesterday (gap ≤1 day) → normal eod: `review-changes` (no args, today only).
  - Floor is >1 day ago → **catch-up**: `review-changes --since <floor>` (inclusive of the floor day is fine — idempotency filters the overlap). Announce the span. The `catch-up=YYYY-MM-DD` arg overrides the detected floor; bare `catch-up` with no detectable floor falls back to a 7-day window (`--since "$(date -v-7d +%Y-%m-%d)"`) — say so.

Skip merge commits. For each active repo, fetch branch via `git branch --show-current`. Fetch commit body lazily only when subject is ambiguous. **In catch-up, group commits by day** so the recap shows the span honestly (`06-22: …`, `06-23: …`), not collapsed into today.

If nothing in the window: skip ahead to Step 5 (Hemingway bridge reflection) — even a no-commits span deserves a closing note.

## Step 3 — Match, idempotency-filter, and cluster

Skip this step entirely if `Tracker: none` — go to Step 3.5.

Per `issue-match.md`:

1. Pull open tickets/issues:
   - Jira: `jira issue list -q'(assignee = currentUser() OR reporter = currentUser()) AND statusCategory != Done AND project IS NOT EMPTY' --plain --columns key,status,priority,summary --no-truncate`
   - gh: `gh search issues --assignee=@me --state=open --json repository,number,title,labels`
2. Match each commit (branch key → explicit key → topic).
3. **Run timestamp idempotency check** per matched ticket — drop commits already covered by a newer comment from the user.
4. **[eod only]** Cluster untracked commits by `(repo, topic)` into new-ticket proposals. In mid-day mode, list them under "Untracked (deferred to eod)" and propose nothing.

## Step 3.5 — Update THREADS.md

Skip if the user doesn't keep a THREADS.md.

Per `threads.md`. **Mode gate:** in **mid-day** mode propose **deletions only** (bucket 1) — defer add/demote/promote to eod, mirroring how mid-day defers new tickets. In **eod** mode propose all four. Only show non-empty buckets in the output:

1. **Delete (done)** — for each 🔥 Open thread, check whether today's commits, new tracker comments, or new tickets you're about to create topically resolve it. If yes → delete. Also: any 🔥 entry marked inline with `✅ this is done` (or similar) → delete.
2. **Add (new from today)** — scan today's `## 🗒️ Brain dump` permissively for any intent / idea / observation not already in THREADS.md → propose adding as 🔥. Include ambiguous fragments; user triages on `go`. **If a PRIORITIES.md exists, tag each new thread with a `**Track:**` field** (per `threads.md` / `priorities.md`) — pick the best-fit track, or `— (life/self-knowledge)` if it isn't track work.
3. **Demote (>30d)** — 🔥 entries with last-seen >30 days ago and no mention today → demote to 💤.
4. **Promote (mentioned again)** — 💤 entries mentioned in today's brain dump → promote to 🔥; refresh Span and Recent quote.

## Step 4 — Draft tomorrow's Hemingway bridge — [eod only]

_Mid-day runs skip this step entirely (no bridge mid-day)._


This is the eod loop's signature move. You're drafting the user's forward-looking note in their voice — but YOU never write it into the `## 🔖 Hemingway bridge` section directly. That section is the user's prose. Your draft goes into the AI block under "Suggested Hemingway bridge for today (paste up if you like)" — and is also shown prominently in chat so the user can copy it.

Source material for the draft:
- Today's commits (what actually shipped) — concrete progress.
- Today's brain dump (what was on the user's mind) — direction.
- Yesterday's bridge (what was promised) — did it land? what got dropped?
- In-flight branches with uncommitted work — that's tomorrow's pickup.

Tone: first-person, terse, the user's voice. Concrete. **What you were in the middle of, what to do first tomorrow.** Not a status report — a note to future-you.

Examples of good bridges:
- *"Rename script works on dev sample. Next: validate against full dataset, then wire global filter UI in the FE (start at Filters/X.tsx stub)."*
- *"Stuck on null windows in the HISTORY query — asked <person>. Don't keep coding until you hear back."*
- *"Light day. Spent it reviewing PRs. Tomorrow: actually start <KEY>."*

Bad bridges (don't do these):
- *"Made progress on <KEY>."* — too vague.
- *"Today I worked on..."* — past-facing, not forward-facing.

## Step 5 — Reflect on yesterday's bridge

Briefly compare yesterday's `## 🔖 Hemingway bridge` (read from the most recent prior daily) against what actually shipped today. Surface:
- ✅ Landed.
- 🔀 Pivoted to something else (and what).
- ❌ Dropped / didn't happen.

This is a one-paragraph reflection, not a full retro. The point is to acknowledge drift honestly so the new bridge isn't aspirational fiction.

## Step 5.5 — Plan the vault commit — [eod only, optional mid-day]

Goal: leave the **vault repo** with a clean, descriptive git history so its commits are a usable observe source (today they're noisy `sync` auto-commits — see prerequisite below). This commits the vault's own working tree, NOT the code repos (the user commits those during work themselves).

The vault working tree at this point includes: notes the user wrote today (daily brain dump, project-folder notes, inbox captures) **plus the edits this skill is about to apply** (AI block, THREADS updates). So this step is *planned* now but *executed last*, after those writes land (Step 7), so the commit captures them.

Plan the commits per `commit/SKILL.md` (the user's house style — conventional, concise, body sparingly, **no co-author trailer**, multiple small commits preferred):

1. Run `git -C <vault-root> status --short` to see what changed today. The vault root is the repo containing the daily-notes dir from `CONTEXT.md` (e.g. `~/code/my-vault`).
2. **Group by concern, and prefer track-scoped commits** using the PRIORITIES repo→track map and folder layout — the commit *scope* should reflect the track/area touched. Examples:
   - `docs(offplan): …` for `01-Projects/offplan-evaluator/` or `02-Areas/...` notes mapping to Track A
   - `docs(visibility): …` for `02-Areas/writing/` drafts
   - `chore(threads): update open threads` for THREADS.md
   - `chore(daily): <date> notes + AI block` for the daily file
   - `chore(inbox): capture <topic>` for new `0-Inbox/` items
3. Mechanical/self-evident changes get no body. Don't invent prose for the notes — the commit *message* describes the change; it never rewrites the note content (vault AGENTS.md rule).

**Prerequisite (flag once if you see `sync` commits in `git log`):** Obsidian's git plugin is likely auto-committing on a timer. For these clean commits to stick, the user should disable Obsidian **auto-commit** (keep auto-sync/pull). Surface this as a one-line note the first time, not every run.

## Step 6 — Present the plan

```
## 📅 Reconcile (eod) — <date>            (catch-up: "## 📅 Reconcile (catch-up) — <floor> → <date>")

Scanned <N> repos, found <M> commits <today | across <floor>→<date>>. After idempotency filter: <K> new for the tracker.
<catch-up only: "⏪ Catching up — N days since last reconcile (<floor>). Past days' notes left as-is; the span is summarized in today's block.">

<catch-up only — per-day recap so the span is honest:>
Shipped by day:
- <floor>: <repo> <n> commits — <topic>
- …: …

### 🔁 Reflection on yesterday's bridge
Yesterday you wrote:
> <quote>

Today: <2-3 line honest reflection — landed/pivoted/dropped>

### ✅ Comments to add to existing tickets        (skip if Tracker: none)

**<KEY>** — <ticket summary>
Repo: <repo-path> (shown to you, not in the comment body)
Internal context (NOT in comment): commits since your last comment include `<hash>` (<topic>), `<hash>` (<topic>).
Proposed comment (PM-facing, `Update:` prefix, no SHAs/branches/squash mechanics):
> Update: <one short paragraph in business-outcome voice>.

---

### 🆕 New tickets to create (untracked work)     (skip if Tracker: none)

**[draft] <PROJECT-or-repo> — <Type> — "<summary>"**
Repo: <repo> (branch: <branch>)
Commits:
- <hash> <subject>
Why: <one-line — why this deserves its own ticket>

---

### ❓ Need your decision                         (skip if Tracker: none)

- `<hash> [<repo>] <subject>` — possible match: <KEY> (<ticket summary>)? confidence low. Pick: (a) comment on <KEY>, (b) create new ticket, (c) skip.

### 🧶 Thread updates (THREADS.md)
**Delete (done):**
- <theme> — matched by commit `<hash>` / new ticket <KEY> / user-marked.

**Add (new from today):**
- <theme title> — proposed from brain-dump line "<quote>".

**Demote (>30d):**
- <theme> — last seen YYYY-MM-DD, no mention since.

**Promote (mentioned again):**
- <theme> — re-surfaced in today's brain dump ("<quote>").

### 🔖 Tomorrow's Hemingway bridge (draft — paste into today's bridge section if you like)

> <first-person, terse, concrete forward-looking note>

### 🤖 AI block update

Refreshed sections: Shipped today, Tracker activity, In flight, Suggested Hemingway bridge, Carryover for tomorrow. In catch-up, "Shipped today" → "Shipped (catch-up <floor>→<today>)" with the per-day breakdown; **only today's block is written — past days' notes are left untouched.**

### 📝 Proposed updates to CONTEXT.md
(only if you spotted anything worth saving)

### 📓 Vault commit (runs last, after the writes above land)
Proposed commits for the vault repo (per your commit house style):
- `<type(scope): subject>` — <files>
- `<type(scope): subject>` — <files>
<first-run only: "⚠️ `git log` shows `sync` auto-commits — disable Obsidian auto-commit (keep auto-sync) so these stick.">

### To apply

Reply `go` to apply everything: tracker comments, new tickets, AI block, (optionally) CONTEXT.md edits, then the vault commit. Or selectively: `apply 1,3`, `skip 2`, `skip commit`, `change 2 to <KEY>`. The Hemingway bridge draft is yours to paste manually into the `## 🔖 Hemingway bridge` section.
```

## Step 7 — Apply on confirmation

Per `propose-apply.md`:
1. For each existing-ticket comment:
   - Jira: `jira issue comment add <KEY> "<body>"`
   - gh: `gh issue comment <N> -R <repo> -b "<body>"`
2. For each new ticket:
   - Jira: `jira issue create -p<PROJECT> -t<TYPE> -s"<summary>" -b"<description>"` — if the project has extra required fields, let `jira issue create` prompt; tell the user "this one needs a few extra fields, answer them."
   - gh: `gh issue create -R <repo> -t "<summary>" -b "<description>" [-l <labels>] [-a @me]`
3. Apply approved THREADS.md edits per `threads.md` (deletions, additions, demotions, promotions). Recompute section count headers.
4. Update **today's** AI block per `daily-notes.md` (with the "Suggested Hemingway bridge for today" subsection populated and "Carryover for tomorrow" filled). In catch-up, label the shipped section with the span and do **not** edit any prior day's file.
5. Apply CONTEXT.md edits if approved.
6. **Vault commit — LAST, after steps 1–5 have written to disk** (unless the user said `skip commit`). Per `commit/SKILL.md`: stage per group and make one focused, track-scoped conventional commit per concern (`git -C <vault-root> add <paths>` then `git -C <vault-root> commit -m "…"`). No co-author trailer. Do NOT push — committing only; let Obsidian sync handle the remote. Print each `✅ <type(scope): subject>`.
7. Print confirmations.

If a step fails: stop, report, don't proceed. User can re-issue `go` after fixing. The vault commit running last means a failure earlier never produces a commit that lies about what landed.

## Tone

- Dense and scannable. No greetings.
- The bridge draft is the one place to be more conversational and first-person — it's a note to future-self, not a tracker comment.
- Never invent a ticket key. Never write into the user's `## 🔖 Hemingway bridge` section — propose the text, let them paste it.
