# Threads — vault/THREADS.md protocol

This helper is referenced by `/morning`, `/checkpoint`, and `/end-of-day`. It defines the THREADS.md system: format, statuses, update rules, and apply order.

**File location:** declared in the workspace `CONTEXT.md` under § Paths → "THREADS.md". If the user doesn't keep a THREADS.md, the commands that reference this helper should skip the thread-update sections entirely.

THREADS.md is the living index of half-finished ideas, intents, and observations captured from past daily-note brain dumps. The point: brain-dump items don't die when the daily file scrolls past the 7-day window. They live here until done.

## File shape

```
# Open Threads
<header explaining the system>

## 🔥 Open (N)
### <theme title>
- **Span:** YYYY-MM-DD → YYYY-MM-DD (N mentions)
- **Summary:** <one line>
- **Recent quote:** `YYYY-MM-DD` — "<short>"
- **Ticket:** <key or *(none)*>
- **Next action:** <text or *(fill when ready)*>

## 💤 Dormant (N)
### <theme title>
- **Last seen:** YYYY-MM-DD · **Mentions:** N
- <summary>
- _"<quote>"_ (`YYYY-MM-DD`)
```

Section count headers (`## 🔥 Open (N)`, `## 💤 Dormant (N)`) must be kept accurate on every write.

## Status semantics

- 🔥 **Open** — active in the last ~30 days OR mentioned multiple times. Surfaced in `/morning`.
- 💤 **Dormant** — last touched >30 days ago. Not surfaced by default in `/morning`; available as fallback context.
- **Done = deleted**, not archived. There is no archive section. When a thread is done, its entry is removed on confirmation. (User signaled this explicitly during cleanup on 2026-05-14.)

## Promotion / demotion / deletion rules

Compute on each `/checkpoint` or `/end-of-day` run. Always **propose** — never auto-apply.

| Trigger | Action |
|---|---|
| User wrote `✅ this is done` (or similar) inline on a 🔥 entry | Propose: delete the entry |
| Today's commits or Jira comments topically match a 🔥 thread | Propose: delete the entry (it's done) |
| 🔥 entry with last-seen >30 days, no new mention today | Propose: demote to 💤 |
| 💤 entry mentioned again in today's brain dump | Propose: promote to 🔥; refresh Span + Recent quote |
| New theme in today's brain dump not yet in THREADS.md | Propose: add new 🔥 entry |

**Permissive capture.** When extracting new threads from brain dumps, err strongly on inclusion. Include ambiguous fragments, casual observations, questions — anything that could be a future-work hook. User triages on `go`. Don't pre-filter for "actionability."

## Which command does what

| Command | Reads | Proposes |
|---|---|---|
| `/morning` | yes (read-only) | nothing — surfaces 🔥 Open in the digest |
| `/checkpoint` | yes | **deletions only** (done threads). No new-thread or demotion proposals — defer to /end-of-day, mirroring how /checkpoint defers new tickets. |
| `/end-of-day` | yes | additions (from today's brain dump), deletions (done), demotions (>30d), promotions (re-mentioned) |

## Apply order

Thread edits piggyback on each command's existing propose-first cycle (see `_propose-apply.md`).

- `/checkpoint` apply order: Jira comments → **THREADS.md deletions** → AI block.
- `/end-of-day` apply order: Jira comments → new Jira tickets → **THREADS.md edits** → AI block.

After every set of changes, recompute and update the section count headers.

## Editing the file

- Use the Edit tool. Match the entire entry block (heading + bullets) for deletions — including the trailing blank line.
- For additions: insert before the next `## ` heading, with one blank line above and below.
- For promotions/demotions: delete from old section, add to new — don't try to move entries with regex.
- Read the file once at the start of the run and operate on that snapshot — user may have edited between runs.

## Output sections in the digest

In `/morning`: a section titled `## 🧶 Open threads (opportunistic)`. List 🔥 entries as one-liners. If the top Jira pick is blocked, include 1–2 of these in "Also consider" as "if you have time" options.

In `/checkpoint` and `/end-of-day`: a section titled `### 🧶 Thread updates (THREADS.md)` with sub-bullets: **Delete (done)**, **Add (new from today)**, **Demote (>30d)**, **Promote (mentioned again)**. Only show non-empty sub-bullets.

## Related

- `_daily-notes.md` — how AI blocks summarize thread activity ("Threads changed: X added, Y deleted").
- `_propose-apply.md` — the propose-first contract this layers onto.
