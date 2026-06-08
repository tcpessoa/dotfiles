# Commit → ticket/issue matching protocol

This helper is referenced by `/checkpoint` and `/end-of-day`. Given a list of commits and a candidate pool of open tickets/issues, produce a match decision per commit with explicit confidence.

The protocol below is tracker-agnostic. Tracker-specific CLI invocations (Jira, gh) appear inline as branches — pick the one your workspace `CONTEXT.md` says you use.

## Inputs you need before matching

For each commit:
- `repo`, `hash`, `subject`, optionally `body` (fetch lazily if subject is ambiguous: `git -C <repo-path> show -s --format=%B <hash>`).
- `branch` for the repo: `git -C <repo-path> branch --show-current`. Branch names often contain a ticket key — gold for matching.

Skip merge commits in matching. They're plumbing, not work.

The candidate pool: open tickets you can match against. Pull once:

- **Jira**:
  ```bash
  jira issue list -q'(assignee = currentUser() OR reporter = currentUser()) AND statusCategory != Done AND project IS NOT EMPTY' --plain --columns key,status,priority,summary --no-truncate
  ```
- **gh**:
  ```bash
  gh search issues --assignee=@me --state=open --json repository,number,title,labels,updatedAt
  # plus, if relevant, issues you opened that others own:
  gh search issues --author=@me --state=open --json repository,number,title,assignees
  ```

(Sprint / milestone membership doesn't matter for matching — a commit might relate to any open ticket of yours.)

## Match algorithm (per commit)

In order:

1. **Explicit key in branch name, commit subject, or body** — for Jira, regex `[A-Z]{2,}-\d+`. For gh, look for `#\d+` (same-repo) or `<owner>/<repo>#\d+` (cross-repo). If found and the key exists in the open pool (or just looks valid), use it. **High confidence.**

2. **Topic similarity vs open ticket summaries** — semantic match, not string match. Use repo context: a commit in repo X is far more likely to relate to a ticket already tagged to repo X. Read `CONTEXT.md` § Project routing if you haven't. Pick the best candidate. If confidence is low, mark it `unsure` and surface it in the "Need your decision" section rather than silently committing to it.

3. **No match** — the commit goes into the **untracked work** bucket for new-ticket proposal (end-of-day only — `/checkpoint` defers untracked work to end-of-day).

## Bias rules

- `feat:` / `fix:` commits usually map to a single ticket.
- Multiple commits with similar topics in the same repo → one comment under one ticket, not several. Group before proposing.
- Merge commits: omit from the report entirely.
- Never invent a ticket key. If you can't find one, the commit is untracked.

## Idempotency — timestamp-based

Comment bodies don't include SHAs (see `jira-cli.md` § Comment voice — the rule applies to any tracker: PM-readable, no plumbing). So idempotency is by timestamp, not by hash:

1. Fetch the ticket's recent comments:
   - Jira: `jira issue view <KEY> --plain --comments 20`
   - gh: `gh issue view <N> -R <repo> --comments`
2. Find the **timestamp of the most recent comment authored by the current user** on this ticket.
3. Find the **timestamp of the latest commit** in the candidate group matched to this ticket: `git -C <repo-path> show -s --format=%ci <hash>`.
4. **If the latest commit is older than (or equal to) the user's latest comment on the ticket → skip the proposal** — the comment already covers everything up to that point. If newer → propose a new `Update:` comment summarizing the progress topically (no SHAs in the body).

If no prior comment from the user exists on the ticket → always propose (first comment).

This is what makes `/checkpoint` safe to run multiple times a day: a second run within the same hour with no new commits will find the user's earlier comment is newer than every matched commit and skip.

## Clustering untracked work into new-ticket proposals (end-of-day only)

For commits with no matched ticket, group them by `(repo, topic)`. Each group becomes ONE proposed new ticket. Don't propose one ticket per commit — that's noise.

For each proposed new ticket, draft:
- **Where it lands**:
  - Jira: infer the project from the repo via `CONTEXT.md` § Project routing. If ambiguous, say `Project: ??? (need user input)`.
  - gh: the repo itself is where the issue lives. `CONTEXT.md` may declare a default repo for cross-cutting work.
- **Type / labels**: `Task` by default (Jira) or no special label (gh); `Bug` (Jira) / `bug` label (gh) if commits look like fixes (subject starts with `fix:` or contains "fix", "bug", "revert").
- **Summary**: short one-line title derived from the commit subjects.
- **Description**: PM-facing — what the work accomplished and why, in business terms. **No commit SHAs or branch names in the description body** (per `jira-cli.md` § Comment voice). After the ticket is created, you can back-fill a separate internal comment with repo/branch/SHA/MR for ticket↔code traceability (per `CONTEXT.md` § Conventions, if the user has set that convention).

## What to surface to the user

Group your output into three buckets:

1. **Comments to add to existing tickets** — confident matches, idempotency-filtered.
2. **New tickets to create** — untracked work clusters (end-of-day only).
3. **Need your decision** — low-confidence matches with 2–3 options each (e.g., "comment on X / create new / skip").
