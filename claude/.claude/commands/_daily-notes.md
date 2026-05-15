# Daily notes — read context, write AI block

This helper is referenced by `/morning`, `/checkpoint`, and `/end-of-day`. Daily notes live in the directory declared in the workspace `CONTEXT.md` under § Paths → "Daily notes." Read `CONTEXT.md` first if you don't have that path in mind.

Files are named `YYYY-MM-DD.md`. Each file has user-written sections (typically `## 🗒️ Brain dump`, `## 🔖 Hemingway bridge`) and may include Obsidian dataview blocks at the bottom. The AI-generated block lives between them. If the workspace uses different section names, `CONTEXT.md` should call that out — adapt the headings accordingly.

## Reading the last 7 entries (context for any command)

Take the 7 most recent daily files **before today** (exclude today's file):

```bash
ls "<daily-notes-dir>" \
  | grep -v "$(date +%Y-%m-%d).md" \
  | sort -r \
  | head -7
```

Substitute `<daily-notes-dir>` with the path from `CONTEXT.md`.

Read each file in full — frontmatter, brain dump, Hemingway bridge, **and AI block**. The AI block from past days is the whole point: it's compressed continuity written by past you (via prior commands), and it's exactly what current-you needs to reload state. Do NOT strip it.

If you find fewer than 7 entries (e.g., long gap), use what you have.

## Reading today's daily note

Read today's file at `<daily-notes-dir>/$(date +%Y-%m-%d).md` separately. If it doesn't exist yet, that's fine — create it on the write step. Specifically check:

- `## 🗒️ Brain dump` — user's free-form notes from today.
- `## 🔖 Hemingway bridge` — user's forward-looking note from end of YESTERDAY (if previous EOD ran). This is the continuity anchor for `/morning`.
- Existing AI block (between `<!-- AI:START -->` and `<!-- AI:END -->`) — if a prior command ran today, its output is here. Read it so you don't repeat / contradict.

For `/morning`: the Hemingway bridge you care about is in **yesterday's file** (or the most recent prior weekday). Today's file's bridge is what `/end-of-day` will write later, for tomorrow's `/morning` to read. Direction: EOD writes today's bridge → next morning reads it.

## AI block format

Bounded by HTML comments. Always replaced wholesale, never appended. Placement: **directly after `## 🔖 Hemingway bridge`** and before the next top-level heading (e.g., an Obsidian dataview block).

```markdown
<!-- AI:START -->
## 🤖 AI Generated
*Last updated: YYYY-MM-DD HH:MM by /checkpoint*

### Shipped today
- <KEY>: <topic> (<hash>, <hash>)

### Tracker activity
- Commented on <KEY> at HH:MM

### In flight
- <KEY> — branch `<branch>`

### What's next
- Continue <KEY> (<topic>) or pick up <KEY> (<topic>)

### Suggested Hemingway bridge for today (paste into the section above)
> <first-person, terse, concrete forward-looking note>

### Carryover for tomorrow
- (only /end-of-day writes this)
<!-- AI:END -->
```

### Which command writes which sections

| Section | morning | checkpoint | end-of-day |
|---|---|---|---|
| Header `*Last updated: ... by /X*` | yes | yes | yes |
| **Today's plan** (replaces "Shipped/In flight/What's next") | yes | — | — |
| **Shipped today** | — | yes | yes |
| **Tracker activity** | — | yes (skip if Tracker: none) | yes (skip if Tracker: none) |
| **In flight** | yes (carried from yesterday) | yes | yes |
| **What's next** | yes | yes | — |
| **Suggested Hemingway bridge for today** | — | — | **yes** |
| **Carryover for tomorrow** | — | — | yes |

`/morning` uses a slightly different shape since there are no commits yet:

```markdown
<!-- AI:START -->
## 🤖 AI Generated
*Last updated: YYYY-MM-DD HH:MM by /morning*

### Today's plan
- Pick: <KEY> — first action: `cd <repo> && git checkout <branch>`
- Also consider: <KEY> (<topic>), <KEY> (<topic>)

### Yesterday's bridge (continuity anchor)
> [quoted from yesterday's `## 🔖 Hemingway bridge` if non-empty]

### In flight
- <KEY> — <repo>, <branch>, <where you left off>
<!-- AI:END -->
```

## Writing the AI block

1. Read today's file. If absent, create it with frontmatter + headings (mirror the structure of the most recent existing file).
2. Find the `## 🔖 Hemingway bridge` heading.
3. Locate `<!-- AI:START -->` and `<!-- AI:END -->`:
   - If both present: replace everything between them (inclusive of the markers' content, keep the markers).
   - If absent: insert the entire `<!-- AI:START -->` ... `<!-- AI:END -->` block immediately after the Hemingway bridge section's content (i.e., before the next `## ` or `# ` heading).
4. Use the Edit tool with exact strings. Don't risk regex shenanigans.

Timestamp the header line: `*Last updated: $(date +"%Y-%m-%d %H:%M") by /<command>*`.

## Mini idempotency note

If you ran twice in a session (e.g., user said `go`, then ran `/checkpoint` again ten minutes later), re-reading the AI block tells you what's already recorded. Don't duplicate `Tracker activity` entries — only add new ones since the last block update.
