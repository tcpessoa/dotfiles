# Priorities — PRIORITIES.md protocol (the Orient layer)

Referenced by `/morning`, `/checkpoint`, `/end-of-day`. Defines how the routine skills use `PRIORITIES.md` to **orient** — to weight what they surface against the tracks the user has consciously chosen.

**File location:** declared in the workspace `CONTEXT.md` under § Paths → "PRIORITIES.md". If the workspace has no PRIORITIES.md, skip everything here — the skills still run fine on commits + threads + daily notes.

## What PRIORITIES.md is

The deliberate, top-down time budget: the tracks the user chose, their relative weight, and the repo→track map. It answers *"what should get my hours, in what proportion."* It is the **Orient** input in the skills' OODA loop:

> **Observe** (commits + today's notes) → **Orient** (CONTEXT + PRIORITIES + THREADS/recent daily) → **Decide** (the pick) → **Act** (the work).

The skills **READ** it. They never re-weight it — re-weighting is a deliberate human act. At most, surface drift and ask.

## What the skills read from it

1. **Tracks & weights** — the "## Tracks & weighting" table. Note which tracks are **Primary**, which are **capped/gym**, which are **Dormant**.
2. **Repo → track map** — the "## Repo → track map" list. Maps each repo to a track so commits can be attributed. Repos not in the map → "untracked (not a priority this phase)".
3. **Protected / fixed** — non-negotiable blocks (family, health, sleep). These are **NOT tracks**: never weighted, never commit-counted, never flagged as "neglected." Ignore them in the balance math; respect them as constraints.

## Commit-to-track balance (the data-driven nudge)

This is what makes the skills *steer* rather than merely *record*.

1. **Compute per-track commit counts** over a window:
   - `/morning`: last 7 days — run `review-changes --since "$(date -v-7d +%Y-%m-%d)"` (in addition to the yesterday scan it already does).
   - `/checkpoint`, `/end-of-day`: today's scan is enough; a weekly window is optional.
2. **Attribute** each commit's repo to a track via the repo→track map.
3. **Compare actual activity to declared weight:**
   - A **Primary** track with ~0 activity in the window → **flag it.** This is the signal.
   - A **capped/gym** track (e.g. LC) running over its cap or eating a Primary slot → flag the inversion.
   - A **Dormant** track with activity → just note it (maybe the phase is shifting).
4. **Output one compact line** — not a lecture. Example:
   > ⚖️ Last 7d: B 9 · A 0 · Visibility 0 · LC 2 — **Track A (primary) and Visibility (leverage) are at zero.**

## How it weights the pick

Insert priority-weighting into the pick logic, *below* continuity:

- **Bridge / continuity still win** — never abandon genuine in-flight work to chase a starved track.
- **When nothing in-flight forces the choice**, bias the pick toward the **highest-weight track that's starved** in the balance check. Surface that track's top `THREADS` next-action as the pick, or as the first "Also consider."
- In `/checkpoint` and `/end-of-day`, apply the same rule with a lighter touch: when "what's next" / the bridge is otherwise neutral, prefer the starved high-weight track.

## Tone

One line for the balance, one nudge in the pick. **Never moralize** about the imbalance — surface the data, suggest the rebalance, move on. The user decides.
