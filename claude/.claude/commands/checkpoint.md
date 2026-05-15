---
description: Mid-day checkpoint — what shipped since last run, what's next, idempotent tracker comments. Safe to run multiple times a day.
---

You are running the user's mid-day checkpoint. Goal: post tracker progress for commits since the last comment, refresh the daily-note AI block, and suggest what to do next. This is `/end-of-day` without the new-ticket proposals or the Hemingway bridge draft — those are end-of-day-only.

## Step 0 — Load workspace context

Read `CONTEXT.md` (cwd, then `~/.claude/CONTEXT.md`). It tells you who the user is, where their daily notes / THREADS / repos live, and which tracker (`jira` / `gh` / `none`) they use. If neither file exists, stop and ask the user to set one up — see `~/.claude/CONTEXT.md.example`.

## Helpers (read these next)

- `~/.claude/commands/_issue-match.md` — commit→ticket matching protocol + **timestamp-based idempotency check**.
- `~/.claude/commands/_daily-notes.md` — context loading + AI block write.
- `~/.claude/commands/_threads.md` — THREADS.md format and update protocol.
- `~/.claude/commands/_propose-apply.md` — propose-first rule; apply only on `go`.
- **If `CONTEXT.md` says `Tracker: Jira`**: also read `~/.claude/commands/_jira-cli.md` — CLI quirks + apply order. Skip otherwise.

If `Tracker: none`, this command degrades to: scan commits, update threads/AI block. No tracker queries, no comments. Useful for "where am I" mid-day resets on personal projects.

## Step 1 — Load context

In parallel:
- Re-read `CONTEXT.md` if needed (routing / glossary section).
- Read `THREADS.md` (path from `CONTEXT.md`; skip if none).
- Read the **last 7 daily entries before today** per `_daily-notes.md` (full files, AI blocks included).
- Read **today's daily file** if it exists — especially the existing AI block. If `/morning` or a prior `/checkpoint` ran today, you'll find their breadcrumbs there.

The today's AI block tells you what's already been recorded, so you don't repeat it.

## Step 2 — Scan today's commits

Run `review-changes` (no args = today, walks all repos under the code root declared in `CONTEXT.md`). Record `(repo, hash, subject)`. Skip merge commits.

For active repos only:
- `git -C <repo-path> branch --show-current` — branch name often has the ticket key.
- `git -C <repo-path> show -s --format=%B <hash>` only if the subject is ambiguous.

If no commits today: say "No commits since midnight. Nothing to comment on the tracker." Then offer to refresh the AI block anyway with current state (in flight, what's next) — useful if the user just wants a mid-day "where am I" reset.

## Step 3 — Pull open tickets/issues for matching

Skip this step if `Tracker: none`.

### If `Tracker: Jira`

```bash
jira issue list -q'(assignee = currentUser() OR reporter = currentUser()) AND statusCategory != Done AND project IS NOT EMPTY' --plain --columns key,status,priority,summary --no-truncate
```

### If `Tracker: gh`

```bash
gh search issues --assignee=@me --state=open --json repository,number,title,labels,updatedAt
# plus, if relevant: --author=@me to catch issues you opened
```

## Step 4 — Match commits and run idempotency check

Follow `_issue-match.md`:

1. Match each commit (branch key → explicit key → topic similarity).
2. **For every matched ticket, fetch its recent comments** and run the **timestamp-based idempotency check** (see `_issue-match.md` § Idempotency): if the user's most recent comment on the ticket is newer than the latest matched commit, skip; otherwise propose a new `Update:` comment summarizing the progress topically. **No commit SHAs in the body** — see `_jira-cli.md` § Comment voice (the rule applies to gh comments too: PM-readable, no plumbing).
3. Group remaining commits by ticket.

Fetching comments:
- Jira: `jira issue view <KEY> --plain --comments 20`
- gh: `gh issue view <N> -R <repo> --comments`

**`/checkpoint` does NOT propose new tickets.** Untracked commits get listed under "Untracked (deferred to end-of-day)" but produce no action. End-of-day catches them.

If after filtering there's nothing left to post, say so plainly. Still offer to refresh the AI block.

## Step 4.5 — Match commits/comments against open threads

Per `_threads.md`: for each 🔥 Open thread in THREADS.md, check whether today's commits or the tracker comments you're about to post topically resolve it. If yes, propose **deleting** the entry (done = deleted). Also: if the user marked any 🔥 entry inline with `✅ this is done` (or similar), propose deletion of that entry too.

**`/checkpoint` does NOT propose new threads, demotions, or promotions** — defer to `/end-of-day`, mirroring how it defers new tickets.

If nothing to delete, skip this section in the output.

## Step 5 — Decide "what's next"

Lightweight, NOT a full sprint/issues re-scan. Look at:
- The picked ticket from this morning's AI block (if `/morning` ran).
- In-flight branches from `git branch --show-current` across active repos.
- The just-shipped commits — what's the obvious next subtask?

Surface 1–3 candidates max, with one-line "why." Continuation > novelty. Don't pull all backlog tickets.

If the user has clearly switched contexts (e.g., the just-shipped commits are on a different ticket than morning's pick), flag it: "you started on <KEY-A> this morning but today's commits are all on <KEY-B> — update the plan?"

## Step 6 — Present the plan

```
## ⏱️ Checkpoint — <date> <HH:MM>

Scanned <N> repos, found <M> commits since midnight. After idempotency filter: <K> new to post.

### ✅ Comments to add (idempotent)         (skip if Tracker: none)

**<KEY>** — <ticket summary>
Repo: <repo-path> (shown to you, not in the comment body)
Internal context (NOT in comment): commits since your last comment include `<hash>` (<topic>), `<hash>` (<topic>).
Proposed comment (PM-facing, `Update:` prefix, no SHAs/branches/squash mechanics):
> Update: <one short paragraph in business-outcome voice — what's now true, what's next, what's blocking>.

---

### 🔁 Already covered (skipped)            (skip if Tracker: none)

- <KEY> → your last comment (<HH:MM>) is newer than the latest matched commit; nothing new to say, skipped.

### 📦 Untracked (deferred to end-of-day)    (skip if Tracker: none)

- <hash> [<repo>] <subject> — no match, will be picked up by /end-of-day.

### 🧶 Thread updates (THREADS.md)
**Delete (done):**
- <theme> — matched by commit `<hash>` / new comment on <KEY>.

### 🎯 What's next

1. **<KEY-or-branch>** (continuation) — <one-line>
2. **<KEY-or-branch>** (next-highest open) — <one-line>

### 🤖 AI block update (today's daily note)

Refreshed sections: Shipped today, Tracker activity, In flight, What's next.

### To apply

Reply `go` to apply everything above. Or selectively: `apply 1`, `skip ai`, `change 1 to <KEY>`.
```

## Step 7 — Apply on confirmation

Per `_propose-apply.md`:
1. For each existing-ticket comment:
   - Jira: `jira issue comment add <KEY> "<body>"`
   - gh: `gh issue comment <N> -R <repo> -b "<body>"`
2. Apply approved THREADS.md deletions (per `_threads.md`). Recompute the section count headers.
3. Update today's AI block per `_daily-notes.md`.
4. Print confirmations.

## Tone

- Dense, scannable. No preamble.
- If matching is uncertain, route to "Need your decision" — `/checkpoint` is conservative; defer ambiguity to the user or to end-of-day.
- Never invent a ticket key.
