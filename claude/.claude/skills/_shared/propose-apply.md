# Propose-first, apply-on-go

Universal rule for `/morning`, `/checkpoint`, `/end-of-day`. Do not skip this gate even if the user usually trusts you. Do not apply on first invocation.

## The contract

1. **First invocation** — present the plan in chat. Wait. **Apply nothing.**
2. **User confirmation** — phrases like `go`, `apply`, `yes`, `do it`, `lgtm` → apply everything proposed in the prior turn, in order.
3. **Selective confirmation** — `apply 1,3`, `skip 2`, `change 2 to <KEY>` → adjust and apply the chosen subset.
4. **No confirmation, follow-up question** — answer the question, refine the plan, re-present, wait again.

## Plan presentation — required footer

Every plan ends with:

```
### To apply

Reply `go` to apply everything above. Or selectively: `apply 1,3` (using the order shown), or `skip 2`, or `change 2 to <KEY>`.
```

If there's nothing to apply (e.g., morning with no Jira writes proposed and you're only asking to write the AI block), say so plainly and ask for `go` to write just the AI block.

## Apply order on "go"

Tracker-specific details live in the helper for the tracker you're using (e.g., `jira-cli.md` § "Writing — commands and apply order"). Generic order:

1. Comments on existing tickets/issues.
2. New ticket/issue creations.
3. Daily-note AI block update (per `daily-notes.md`).
4. THREADS.md edits (if the workspace keeps one).
5. CONTEXT.md edits (if any were approved).
6. Print confirmations after each step:
   - `✅ Commented on <KEY>`
   - `✅ Created <KEY>: <summary>`
   - `✅ Updated <daily-notes-dir>/<YYYY-MM-DD>.md AI block`

## Failure handling

If a step fails: **stop immediately.** Report which step failed and the error. Do not proceed with subsequent steps (don't write the daily-note block if a Jira comment failed — the block would lie).

The user can fix the issue and re-issue `go` for the remainder.

## Idempotency

Re-running the same command later in the day must be safe:
- Comments: timestamp-based idempotency per `issue-match.md` — skip commits already covered by a newer user comment.
- Daily-note AI block: replaced wholesale per `daily-notes.md` — no append duplication.

If everything that would be proposed is already covered, say so plainly ("Nothing new since last run — no tracker writes needed. Refresh the AI block anyway?") rather than presenting an empty plan.

## Never

- Never invent a ticket/issue key. Untracked is fine; fabricated is not.
- Never edit an existing tracker comment in place. New comment each time.
- Never auto-apply on the first turn, even for "obviously safe" things.
- Never propose deleting or editing the user's hand-written daily-note sections (brain dump, Hemingway bridge). Touch only the bounded AI block.
