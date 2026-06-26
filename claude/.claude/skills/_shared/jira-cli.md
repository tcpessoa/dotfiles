# Jira CLI — quirks, queries, and apply order

This is a **Jira-specific reference**. The generic `/next` and `/reconcile` commands only consult this file when the workspace `CONTEXT.md` declares `Tracker: Jira`. If your workspace uses `gh` or no tracker, ignore this file — the generic commands handle those cases inline.

Captures everything about the `jira` CLI (https://github.com/ankitpokhrel/jira-cli) that's non-obvious. Username and config-file path are workspace-specific; see your `CONTEXT.md` § Identity / Issue tracker. Default location for the CLI's own config is `~/.config/.jira/.config.yml`.

## ⚠️ Four quirks that will silently break queries

1. **Default project scope.** The CLI's config file (typically `~/.config/.jira/.config.yml`) usually sets a default `project:`. Every query is silently scoped to that project unless you include `project IS NOT EMPTY` in the JQL. **Always include it** when you want a cross-project view.

2. **No `ORDER BY` inside `-q`.** The CLI appends its own ordering clause and will 400 with `Expecting ',' but got 'ORDER'`. Use the `--order-by <field>` flag (single field only) plus `--reverse` for DESC. Do NOT put `ORDER BY` in the JQL string.

3. **Empty result = exit code 1** with stderr `✗ No result found for given query in project "<default-project>"`. The "in project X" text is misleading — `project IS NOT EMPTY` IS honored; the message just always echoes the default project. **Treat `No result found` as a valid empty result, not an error. Do not retry the query.**

4. **Status names are workflow-specific.** Specific status names (e.g., `Backlog, Todo, Start, In Progress, Done, Resolved, Closed`) and their semantics depend on the project's workflow — `CONTEXT.md` should call out anything non-obvious for the workspace you're in. General rules that hold across most Jira workflows:
   - **A "queued / next up" status (often called `Start`, `Selected for Development`, or similar)** ≠ in-progress. The ticket has been accepted/assigned but no work has begun. Don't bucket these as WIP.
   - **`In Progress`** is the real WIP status.
   - The `statusCategory = "In Progress"` Jira filter only catches the literal `In Progress` status — that's the correct behavior for finding real WIP.
   - Even within `In Progress`, sanity-check there's evidence of recent work (a comment, commit, or update in the last week) before calling it "in flight" — status alone can lie.

## Reusable JQL slices

Always include `project IS NOT EMPTY` and use `--order-by` (never `ORDER BY` inside `-q`).

| Slice | JQL | Sort |
|---|---|---|
| All my open work, all projects | `assignee = currentUser() AND statusCategory != Done AND project IS NOT EMPTY` | `--order-by priority --reverse` |
| Active sprint, all projects | `sprint in openSprints() AND assignee = currentUser() AND project IS NOT EMPTY` | `--order-by priority --reverse` |
| High/Highest, not done | `assignee = currentUser() AND priority in (Highest, High) AND statusCategory != Done AND project IS NOT EMPTY` | `--order-by priority --reverse` |
| Real WIP (no `Start`) | `assignee = currentUser() AND status in ("In Progress", "Work in progress", "In Dev", "In Review") AND project IS NOT EMPTY` | `--order-by updated --reverse` |
| Reporter ≠ assignee (waiting on others) | `reporter = currentUser() AND assignee != currentUser() AND statusCategory != Done AND project IS NOT EMPTY` | `--order-by priority --reverse` |
| Closed in last 7 days | `assignee = currentUser() AND statusCategory = Done AND resolved >= -7d AND project IS NOT EMPTY` | `--order-by resolved --reverse` |
| Stale open (≥14d no update) | `assignee = currentUser() AND statusCategory != Done AND updated <= -14d AND project IS NOT EMPTY` | `--order-by updated` |
| Open tickets for matching commits | `(assignee = currentUser() OR reporter = currentUser()) AND statusCategory != Done AND project IS NOT EMPTY` | (no sort needed) |

Standard columns for digest output: `--plain --columns key,type,status,priority,summary --no-truncate`.

## Comment voice (PM-facing)

Jira comments posted by `/reconcile` are **read by PMs and non-engineers**, not just the user. Write accordingly:

- **Prefix every progress comment with `Update:`** — never a label that leaks the internal command or mode name. Those labels are for the slash command's own bookkeeping, not for stakeholders reading the ticket.
- **No commit SHAs, no branch names, no merge/squash mechanics in the body.** Lines like "merged to main via 0d7f579", "squashed commits abc1234, def5678", "branch X rebased onto Y" do not belong in a progress update. They're implementation plumbing.
- **Lead with the business outcome**: what is now true that wasn't true before? what's the next user-visible step? what's blocking?
- Keep it short. One short paragraph. If you find yourself writing a second paragraph, you're probably leaking implementation detail.

**The exception — back-fill comments for ticket↔code traceability.** When work is fully merged and you're back-filling a link from a Jira ticket to the MR/branch/SHA (if `CONTEXT.md` § Conventions sets that expectation), that's a *separate*, explicitly internal comment — fine to include repo, branch, MR URL, merge SHA there. Don't blend it into a progress update.

**Good vs bad examples:**

Good:
> Update: backend work is merged to main. The new entity-relation model is in place, and the rename + migration script is idempotent (safe to re-run). Only step left is running the migration in production, tracked separately under <KEY>.

Bad (leaks plumbing):
> Update: feature branch `<KEY>-entity-relation-rename` merged to `main` via `0d7f579`. Squashed: `fac3aa6` (model-def), `f9e3528` (rename script), `22fca13` (lint).

## Writing — commands and apply order

When the user says "go" / "apply" / "yes", run actions in this order:

1. **Comments first** (low blast radius, idempotent if you've done the hash check):
   ```bash
   jira issue comment add <KEY> "<body>"
   ```
2. **New tickets next** (creates state, captures new key from output):
   ```bash
   jira issue create -p<PROJECT> -t<TYPE> -s"<summary>" -b"<description>"
   ```
   `jira issue create` may prompt for required fields it can't infer. If the project has no extra required fields, pass `--no-input`. Otherwise let the prompt happen and tell the user "this one needs a few extra fields, answer them".
3. **Daily-note AI block last** (per `daily-notes.md`) — only after Jira ops succeeded, so the block accurately reflects what was actually applied.

Print confirmations after each: `✅ Commented on <KEY>` / `✅ Created <KEY>: <summary>`.

If a step fails, **stop**, report the error, and don't proceed with the rest. The user can re-issue `go` for the remainder after fixing.

## Reading comments (for idempotency)

Before proposing a comment, you need to know what's already on the ticket. See `issue-match.md` for the timestamp-based idempotency protocol (comment bodies don't carry SHAs, so idempotency is "is my last comment newer than the latest matched commit?"). The CLI invocation is:

```bash
jira issue view <KEY> --plain --comments 20
```

(`--comments N` includes the last N comments inline. 20 is enough — older comments are unlikely to mention today's commits.)
