# Loop contract — the portable layer

Workspace-agnostic protocol for every routine loop (`/next`, `/reconcile`, `/review`, `/express`, `/calibrate`, `/process-inbox` — and future repo-scoped loops per the vault's `adr/0004`). This file plus the state-format helpers (`threads.md`, `daily-notes.md`, `priorities.md`, `propose-apply.md`) are the **durable interface**: they carry between workspaces (vault ↔ code repo). Per-skill step-by-step process is scaffolding — an agent may adapt it; it may never trade away anything in this file.

## Contract shape (how a loop skill is written)

A contract-format SKILL.md has four blocks, in order:

1. **Job** — one paragraph: what the loop is for, what it optimizes, what it deliberately does not do.
2. **Invariants** — the never-list. Hard constraints. An agent may never trade these away, however smart the trade looks.
3. **Output contract** — what the user must be able to *do* after reading the output. Capabilities, not a template: rendering may evolve; the capabilities may not regress.
4. **Hints** (optional appendix) — default heuristics, query recipes, worked shapes. An agent may deviate **when evidence warrants, and must label the deviation and show the evidence** in the output.

Universal invariants (all loops, all workspaces — skills reference these instead of repeating them):

- **Never write prose on the user's behalf.** Move, restructure, propose; drafting goes in a bounded AI block or a clearly-labeled draft, never into the user's own sections.
- **Detect and route, never run.** A loop may surface that another loop is due; it never executes it.
- **Never fabricate a ticket/issue key.** Untracked is fine; invented is not.
- **Writes obey the autonomy tier of their action class** (below). Tier ≥1 follows `propose-apply.md`.
- **Watermarks are the only cross-loop state.** A loop's "last ran" lives in the shared files it already writes — no side-channel state files.

## Autonomy tiers (earned per action class, not per loop)

Uniform propose-first makes the human's `go` the bottleneck for everything from a trivial block refresh to a priorities re-weight. Instead, every **action class** (a kind of write, e.g. "daily AI block", "THREADS edit") has a tier, declared in the workspace `CONTEXT.md` § Autonomy. Undeclared classes default to **Tier 1**.

| Tier | Meaning | Qualifies when |
|---|---|---|
| **0** | Auto-apply. No approval slot; print `✅` + how to undo. | Bounded (fenced / wholesale-replace), idempotent, reversible from git. |
| **1** | Propose-first per `propose-apply.md`. | Default for anything else. |
| **2** | Always ask, never draft the content — surface the decision, the user words it. | Normative files (priorities/weights), deletions of user-authored content, anything resembling the user's prose or voice. |

**Tier 0 and apply order:** Tier 0 removes the *approval*, not the *sequencing*. A Tier 0 write that summarizes Tier 1 writes (e.g. an AI block recording tracker comments) still runs after them in the apply order; it just never appears as a numbered item awaiting `go`. When a loop proposes nothing at Tier ≥1, its Tier 0 writes apply immediately.

**The ratchet (how tiers change):**

- **Promotion** (1→0, 2→1) is proposed only by the setpoint loop (`/calibrate`), against evidence since the last calibration: the class was applied repeatedly (≥ ~8 times) with **zero** rejections, user modifications, or subsequent reverts (check the workspace git history for reverts/corrections of loop-written changes; ask the user to confirm no silent annoyances). The human ratifies — a tier change is itself a Tier 2 write.
- **Demotion** is immediate and needs no ratification: one bad write (user complaint, observed revert) drops the class a tier on the spot; note it in `CONTEXT.md` § Autonomy with the date and reason.

## Pick-follow (the audit that decides whether the control plane is real)

The orient loop picks; nothing else checks whether picks get followed. Without this metric, the pick rules are the past self's frozen theory. Protocol: **stamp at write-back, aggregate at setpoint.**

**Stamp** — the write-back loop (`/reconcile` eod), which already holds both halves (today's pick from the AI block, today's activity from its scan), classifies the day and writes one line into the block it's already writing:

```
Pick: <key-or-thread> [src: <source>] → followed
Pick: <key-or-thread> [src: <source>] → diverted (→ <where the hours actually went>)
Pick: <key-or-thread> [src: <source>] → dropped
Pick: (none — orient loop not run)
```

Classify by judgment, not string-matching: commit-invisible follow-through (the brain dump shows the day went to reading/design/outreach *on the pick*) counts as `followed`. Evidence of activity is workspace-dependent — vault: code + vault commits + brain dump; code repo: commits, PR/merge activity, issue/review comments.

**`src` — which rule produced the pick**, recorded by the orient loop in the same block, copied verbatim by the write-back loop: `bridge` / `continuity` / `starved-track` / `thread` / `tracker` / `guard-override`. This field is the audit's vocabulary: without it a learned rule can only name specific tracks (a hypothesis pinned to entities), with it a rule can quantify over a *class* of picks. Missing/unknown → `src: ?`; never guess.

**Aggregate** — the setpoint loop (`/calibrate`) tallies stamps over its window (classifying any unstamped pick-days itself from the raw notes it already loaded) and reports:

1. **Follow rate** — `followed / picks issued`, overall **and broken out by `src`**. The by-source split is the one that yields a generalizable rule; the overall number is just a health signal.
2. **Diversion matrix** — where the hours went on non-followed days. Read the pattern, they mean different things: always diverting to the same track → continuity gravity beats the pick rules (rules problem); diverting away from one specific track's picks → avoidance (not a rules problem — say so plainly, don't moralize); high `dropped` → picks aren't actionable enough (next-step too big).
3. **At most one proposed rule change** to the orient loop's pick heuristics, selected per § Rule selection below.
4. **At most one proposed retirement** from the same heuristics, per § Rule selection.

This audit outranks the orient loop's default heuristics: once pick-follow data exists, the agent may cite it to deviate from the default pick ordering (labeled, with the evidence).

## Rule selection (how a learned lesson is worded)

A heuristics store that only ever *adds* rules gets monotonically more specific — each new rule removes picks the loop would otherwise permit, so it fits last month's diversions tighter and next month's situations worse. Learning has to be able to widen, not just narrow. Three constraints, in order:

1. **Validity first — check against the days that went right.** A candidate rule must still produce the observed choice on the window's `followed` days. Rules derived only from diversions are fitted to failure; the `followed` stamps are the constraint that kills the overfitted ones. State explicitly which followed days a candidate would have overturned — if it's more than one or two, it isn't a rule, it's a preference.
2. **Then weakest wins.** Among candidates that survive (1), propose the **least specific** one — the rule that permits the most picks while still explaining the pattern. Prefer a rule quantified over a class (`src`, first-action size, track *status* like starved/capped) over one naming a specific track, thread, repo, key, or weekday. Specific bindings are allowed only where the evidence genuinely depends on them. Note this is *not* "shortest" — a longer rule that quantifies over a class is weaker, and therefore better, than a terse one that names an entity.
3. **Prefer a gate to an ordering link.** The orient loop's Invariants are gates (they remove candidates and permit the rest); its pick ordering designates exactly one pick per situation and is the strongest form a rule can take. Land the lesson as a widened or narrowed gate where it fits; append to the ordering chain only when nothing else expresses it, and say so.

**Retirement** (the widening half, ≤1 per audit): drop a heuristic whose permitted-pick set is subsumed by another's, or that no pick in the window cites as its deciding factor. Prune by redundant *reach*, never by length — brevity is not the objective and compressing the rules is not the same as generalizing them.

Both halves are proposals like any other Tier ≥1 write. One add and one retire per audit, maximum — rule churn is its own failure mode.

## Off-script slot

Any loop's output may include **one** `📡 Off-script` observation: something true and load-bearing that the output contract didn't ask for ("this thread has been the pick 3× and never started — the next action is probably wrong"). Hard bounds: max one, must cite its evidence, never a task or a pick, never moralizing. If there's nothing worth saying, the slot doesn't render. This is the sanctioned channel for the agent's own noticing — use it for signal, not commentary.

## Headless runs

A loop run non-interactively (scheduled/cron) applies **Tier 0 writes only**. Everything Tier ≥1 is written into a `### ⏸️ Pending (headless <loop>, <timestamp>)` subsection of today's AI block — the proposal text, ready to review. No tracker writes, no commits, no pushes. The orient loop surfaces any ⏸️ pending section as a one-line route ("reconcile draft awaiting review — open today's note or re-run `/reconcile`"). A fresh interactive run of the same loop supersedes and removes its pending section.
