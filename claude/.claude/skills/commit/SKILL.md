---
name: commit
description: Create git commits the way the user likes them — conventional commits, concise, body used sparingly, no co-author trailer, multiple small commits preferred over one big one.
---

You are creating one or more git commits. Follow the user's house style below — these are firm preferences, not suggestions.

## Rules

1. **Conventional Commits.** Every subject line is `type(scope): summary`. Scope is optional; use it when it adds clarity. Common types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `build`, `ci`.

2. **Concise.** The subject line is usually the whole commit. Keep it short, imperative, lowercase after the colon, no trailing period. Aim for ≤ 50 chars; hard-stop at 72.

3. **Body used sparingly.** Only add a body when the *why* isn't obvious from the subject and the diff — a non-obvious tradeoff, a workaround, a breaking change, context a future reader would otherwise have to reconstruct. Mechanical or self-evident changes get no body. When in doubt, leave it out.

4. **Multiple commits are fine — preferred, even.** Don't cram unrelated changes into one commit to "keep it tidy." If the working tree spans several logical changes, split them: stage selectively (`git add -p` or per-path) and make one focused commit per concern. Each commit should stand on its own.

5. **No co-author trailer.** Never append `Co-Authored-By: Claude ...` or any "Generated with Claude Code" line. The user's commits are the user's.

## Flow

1. Run `git status` and `git diff` (and `git diff --staged`) to see what's there.
2. Decide whether this is one logical change or several. If several, group the changes and plan one commit per group.
3. For each commit: stage just that group's files/hunks, then commit. Prefer `git commit -m "..."` for subject-only; use a second `-m` for a body only when rule 3 calls for it.
4. Match the repo's existing style — skim recent `git log --oneline -20` for the scopes and types this project actually uses, and mirror them.

## Examples

Good (subject-only, the common case):
```
feat(auth): add refresh-token rotation
fix: handle empty config file
refactor(claude): commands to skills
docs: document install entrypoint
```

Good (body earns its place — explains a non-obvious why):
```
fix(parser): fall back to UTC when tz is missing

The vendor feed intermittently drops the tz field; defaulting to
UTC matches their documented behavior and avoids a hard crash.
```

Avoid:
- `update stuff`, `fixes`, `wip` — not conventional, not descriptive.
- One commit mixing a feature, a refactor, and a docs tweak — split it.
- A body that just restates the subject in a full sentence.
- Any `Co-Authored-By` / "Generated with" trailer.
