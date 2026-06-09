---
name: morning
description: Morning standup — pull yesterday's bridge, recent commits, tracker state, and suggest what to start on. Writes today's AI block on confirmation.
---

You are starting the user's workday. Be concise — this is a quick orientation, not an essay.

This skill runs an **OODA loop** over the workspace files (see the target `CONTEXT.md` → "How my system thinks"). Steps are annotated with their role: **Observe** (commits) → **Orient** (CONTEXT + PRIORITIES + THREADS + recent daily) → **Decide** (the pick). Re-reading THREADS/daily *is* part of Orient, not a separate step.

## Step 0 — Load workspace context

**First**, read `CONTEXT.md` to learn who the user is, where their daily notes and repos live, what issue tracker (if any) they use, and any local conventions. Resolution order:

1. `./CONTEXT.md` in cwd.
2. `~/.claude/CONTEXT.md`.

If neither exists, stop and tell the user: "I need a `CONTEXT.md` to know about this workspace — see `~/.claude/CONTEXT.md.example` for the template."

Everything downstream depends on this file: daily-notes directory, THREADS.md location, code root, tracker choice (`jira` / `gh` / `none`). When this file says "read your daily notes" or "query your tracker," it means using the paths and tools declared in `CONTEXT.md`.

## Helpers (read these next)

- `~/.claude/skills/_shared/daily-notes.md` — how to read the last 7 daily entries and write today's AI block.
- `~/.claude/skills/_shared/threads.md` — THREADS.md format and read protocol.
- `~/.claude/skills/_shared/priorities.md` — PRIORITIES.md protocol: track weighting, commit-to-track balance, how it weights the pick. Skip if the workspace has no PRIORITIES.md.
- `~/.claude/skills/_shared/propose-apply.md` — propose-first rule; apply only on `go`.
- **If `CONTEXT.md` says `Tracker: Jira`**: also read `~/.claude/skills/_shared/jira-cli.md` — CLI quirks (4 gotchas) + reusable JQL. Skip if your tracker is `gh` or `none`.

## Step 1 — Load context (Orient)

In parallel:
- Re-read `CONTEXT.md` if you haven't kept its contents in mind — you'll need the routing/glossary section to map tickets to repos.
- Read `THREADS.md` (path from `CONTEXT.md`; skip if the user doesn't keep one).
- Read `PRIORITIES.md` (path from `CONTEXT.md`; skip if none) per `priorities.md` — load the **tracks & weights**, the **repo→track map** (for Step 2's balance), and the **Protected/fixed** blocks (constraints, never commit-counted).
- Read the **last 7 daily entries before today** per `daily-notes.md` (full files, AI blocks included). These are your cross-day memory.
- Read today's daily file (if it exists) — note any existing AI block from a prior run today.
- Count files in `0-Inbox/` under the vault (observe-only — do **not** process them here; that's `/process-inbox`). You'll surface the count in the digest.

The single most important thing you're looking for: **yesterday's `## 🔖 Hemingway bridge`** (or the most recent prior weekday's, if yesterday was a weekend). That's the user's own forward-looking note about where they left off. It's your continuity anchor — quote it back to them.

## Step 2 — Pull commits (Observe)

Run `review-changes -y` (script lives in the user's `PATH` — typically `~/dotfiles/bin/.local/bin/review-changes`). If today is Monday, use `review-changes --since "$(date -v-3d +%Y-%m-%d)"` to cover Friday — assume weekday work unless `CONTEXT.md` says otherwise. This is the **continuity** scan (what happened yesterday).

`review-changes` walks every repo under the code root (from `CONTEXT.md`) using each repo's local git identity, so author filtering is implicit. If `CONTEXT.md` doesn't declare a code root, ask the user where their repos live before scanning.

**If the workspace has a PRIORITIES.md**, also run the **7-day balance scan** per `priorities.md`: `review-changes --since "$(date -v-7d +%Y-%m-%d)"`, attribute each repo to a track via the repo→track map, and tally per-track commit counts. This feeds the ⚖️ Track balance line and the priority-weighted pick in Step 4. Keep it cheap — counts only, no per-commit detail.

## Step 3 — Pull current tracker state

Branch on `CONTEXT.md` § Issue tracker:

### If `Tracker: Jira`

Run these 4 queries in parallel (per `jira-cli.md` — always include `project IS NOT EMPTY`, never put `ORDER BY` inside `-q`):

```bash
# (a) Active sprint — assignee me, all projects, all statuses
jira issue list -q'sprint in openSprints() AND assignee = currentUser() AND project IS NOT EMPTY' --order-by priority --reverse --plain --columns key,type,status,priority,summary

# (b) High/Highest backlog, not done, assignee me
jira issue list -q'assignee = currentUser() AND priority in (Highest, High) AND statusCategory != Done AND project IS NOT EMPTY' --order-by priority --reverse --plain --columns key,type,status,priority,summary

# (c) Real WIP — In Progress / In Review / In Dev / Work in progress (NOT Start — Start is queued)
jira issue list -q'assignee = currentUser() AND status in ("In Progress", "Work in progress", "In Dev", "In Review") AND project IS NOT EMPTY' --order-by updated --reverse --plain --columns key,type,status,priority,updated,summary

# (d) Reporter ≠ assignee — work others owe me
jira issue list -q'reporter = currentUser() AND assignee != currentUser() AND statusCategory != Done AND project IS NOT EMPTY' --order-by priority --reverse --plain --columns key,type,status,priority,assignee,summary
```

If any query exits with `✗ No result found`, that's empty — treat as zero rows, do not retry.

### If `Tracker: gh`

Use the GitHub CLI. Repos in scope are listed in `CONTEXT.md`. Run in parallel (one set per repo, or use `--search` across the user's issues):

```bash
# (a) All open issues assigned to me, across the user's tracked repos
gh search issues --assignee=@me --state=open --json repository,number,title,labels,updatedAt

# (b) High-priority open issues (assumes you label with priority — adapt to your labels)
gh search issues --assignee=@me --state=open --label="priority: high,priority: urgent" --json repository,number,title,labels

# (c) WIP — issues with an "in progress" label or assigned-and-recent activity
gh search issues --assignee=@me --state=open --label="in progress" --json repository,number,title,updatedAt --sort updated

# (d) Issues you opened that someone else owns (work others owe you)
gh search issues --author=@me --state=open --json repository,number,title,assignees,updatedAt
```

Adapt the label names to what the user's repos actually use — `CONTEXT.md` may declare them; otherwise infer from a quick `gh label list -R <repo>`.

### If `Tracker: none`

Skip Step 3 entirely. The "Active sprint" / "High priority" / "In Progress" sections drop out of the digest. You still have commits, daily notes, threads, and the Hemingway bridge — that's enough for a useful morning.

### Common to all trackers

Deduplicate across (a)–(c) when presenting. (d) is its own section.

For 2–3 tickets/issues you're about to recommend, fetch detail lazily:
- Jira: `jira issue view <KEY> --plain`
- gh: `gh issue view <N> -R <repo>`

## Step 4 — Present the digest (Decide)

Skip empty sections. Use ticket/issue keys as the user's tracker formats them (`<PROJECT>-NNN` for Jira, `owner/repo#N` or `#N` for gh).

```
## 🔖 Yesterday's bridge
> [verbatim quote from yesterday's `## 🔖 Hemingway bridge` — if empty/missing, say so plainly]

## 🕐 Yesterday recap
- <repo>: <N> commits on `<branch>` — <topic>
- <repo>: <N> commits on `<branch>` — <topic>

## ⚖️ Track balance (last 7d)                (skip if no PRIORITIES.md)
<one line: per-track commit counts vs declared weight, flagging any starved Primary/leverage track — see priorities.md>

## 📥 Inbox                                  (skip if 0 or no 0-Inbox/)
<N> unprocessed in `0-Inbox/` → run `/process-inbox` (not handled here)

## 🏃 Active sprint / Open assigned       (skip section if Tracker: none)
- <KEY> (priority, status) — <summary> → <repo>
- <KEY> (priority, status) — <summary> → <repo>

## 🔥 High priority (not in active sprint)  (skip if Tracker: none)
- <KEY> (priority, status) — <summary> → <repo>

## 🚧 In progress — finish these            (skip if Tracker: none)
- <KEY> (priority) — <summary> → <repo>

## ⏳ Waiting on others (you're the reporter)  (skip if Tracker: none)
- <KEY> assignee=<name> — <summary>

## 🧶 Open threads (opportunistic)
_From THREADS.md — half-finished ideas / intents not (yet) ticketed. Surface if you have time._
- <theme> — <one-line summary> (last seen YYYY-MM-DD)

## 🎯 Today's pick
**<KEY-or-thread>** — <one-line why (lean on yesterday's bridge if it points somewhere)>
Repo: `<absolute path to the repo>`
Next step: <concrete first action — a command, a file to open, a question to answer>

Also consider:
- <KEY> — <one-liner>
- <KEY> — <one-liner>

## 🗣️ Standup snippet
**Yesterday:** <1–2 bullets summarizing yesterday's commits, mapped to ticket keys>
**Today:** <what you're picking up, with the ticket key>
**Blockers:** <anything from "Waiting on others", or "none">
```

If `Tracker: none`, drop the "Standup snippet" section (no audience for it) unless `CONTEXT.md` says otherwise.

Rules for picking the top pick:

1. **Bridge wins**: if yesterday's Hemingway bridge points somewhere concrete and maps to an open ticket (or to a repo with active work), that's the default pick.
2. Else, **continuity wins**: yesterday's commits → matching open ticket / branch in progress.
3. Else, **priority-weighting** (per `priorities.md`): if the ⚖️ balance shows a **Primary or leverage track starved** (~0 activity over 7d), bias the pick toward it — surface that track's top `THREADS` next-action as the pick or the first "Also consider." Continuity (1–2) still outranks this; it only breaks the tie when nothing's in flight.
4. Else, in-progress sprint/labeled tickets (continuation > new start).
5. Else, highest priority in active sprint / "high priority" label set.
6. Else, highest priority anywhere.
7. Tie-break with most-recently-updated.
8. If no obvious repo from `CONTEXT.md`, say so and guess from ticket text + an `ls` of the code root.

**Threads in "Also consider":** when the top pick is blocked (awaiting review, dependency, external answer), include 1–2 🔥 Open threads in the "Also consider" list as opportunistic options — phrased as "if you have time, also work on X." Threads are never the top pick (they don't have a ticket); they only appear as fallback options.

For the **Standup snippet**: copy-pasteable, use ticket keys not free-form repo names. If yesterday's commits have no matching ticket, say "untracked work in `<repo>` — should I `/end-of-day` to file tickets?"

## Step 5 — Propose today's AI block

Per `daily-notes.md`, propose the AI block to write into today's daily note. Shape (morning variant):

```markdown
<!-- AI:START -->
## 🤖 AI Generated
*Last updated: YYYY-MM-DD HH:MM by /morning*

### Today's plan
- Pick: <KEY> — first action: <one-line>
- Also consider: <KEY>, <KEY>

### Yesterday's bridge (continuity anchor)
> <verbatim quote, or "(empty)">

### In flight
- <KEY> — <repo, branch, where you left off>
<!-- AI:END -->
```

Show it in chat, then add the standard "Reply `go` to write this to today's daily note" footer per `propose-apply.md`.

## Step 6 — Propose CONTEXT.md updates

While reading tickets, watch for:
- New acronyms / systems / domain terms not in the glossary or routing section.
- Repo mappings that turn out to be wrong or missing.
- New tracker projects / repos appearing that aren't yet listed.

If anything, append a short "📝 Proposed updates to CONTEXT.md" section. Don't apply — let the user say yes.

## Step 7 — Apply on confirmation

When user says `go`: write today's AI block per `daily-notes.md`. Then apply any `CONTEXT.md` edits if those were also approved. Print confirmations.

## Tone

- No greetings, no preamble. Jump straight into "## 🔖 Yesterday's bridge".
- Bullets beat paragraphs.
- If the user asks "tell me more about X" or "let's start on Y", drop into the relevant repo and read code.
