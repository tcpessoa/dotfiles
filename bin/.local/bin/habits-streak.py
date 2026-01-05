#!/usr/bin/env python3
"""
Habit Tracker v2 - Behavioral Science Edition

CHANGES FROM V1 (with research citations):

1. REMOVED: MOMENTUM section
   Why: Sparklines are "dashboard porn" - aesthetically pleasing but behaviorally inert.
   Knowing you're "declining" doesn't change behavior. (No actionable signal)

2. REMOVED: WEEKLY GOALS section
   Why: Redundant with TODAY panel. Same information, different visualization.

3. DEMOTED: HISTORY table
   Why: Reference info, not motivational. Moved to bottom, shows only last 4 weeks.

4. DEMOTED: STREAKS section
   Why: Overlaps with CONSISTENCY. Now inline with consistency display.

5. ADDED: Implementation intentions (Gollwitzer)
   Research: Meta-analysis of 94 studies shows d=0.65 effect size for "when X, I will Y" planning.
   Implementation: Track habit completion times, surface patterns as prompts.

6. ADDED: Identity framing (Clear, Atomic Habits + Bem's self-perception theory)
   Research: "I'm a runner" > "I'm trying to run". Identity-based motivation is durable.
   Implementation: Map consistency % to identity labels.

7. ADDED: Fresh start effect (Dai, Milkman, Riis 2014)
   Research: Goal pursuit increases after temporal landmarks (new week/month/year).
   Implementation: Detect first run of new period, show forward-looking frame.

8. ADDED: Recovery mode (Neff, Breines & Chen - self-compassion research)
   Research: Self-criticism after failure REDUCES goal pursuit; self-compassion INCREASES it.
   Implementation: After 2+ missed weeks, suppress normal display, show compassionate re-entry.

9. CHANGED: "behind" → "restart tomorrow?"
   Why: SDT (Deci & Ryan) - autonomy matters. External judgment undermines intrinsic motivation.

10. CHANGED: Consistency now primary metric with inline best-streak
    Why: Polivy & Herman's "what-the-hell effect" - percentages are recoverable, streaks are not.
"""

import sys
import re
import os
import json
from datetime import datetime
from pathlib import Path


# ═══════════════════════════════════════════════════════════════════════════
# DATA PARSING
# ═══════════════════════════════════════════════════════════════════════════


def parse_habits(filepath):
    """Parse habit file into structured weekly data."""
    with open(filepath) as f:
        content = f.read()

    weeks = []
    current_week = None

    for line in content.split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        if re.match(r"^\d{8}-\d{8}$", line):
            if current_week:
                weeks.append(current_week)
            current_week = {"range": line, "habits": {}}
        elif ":" in line and current_week:
            name, value = line.split(":", 1)
            name = name.strip()
            value = value.strip()

            days = []
            total = 0
            if value != "0":
                for part in value.split(","):
                    part = part.strip()
                    match = re.match(r"(\w+)\s+(\d+)", part)
                    if match:
                        days.append(match.group(1))
                        total += int(match.group(2))
                if not days and value.isdigit() and int(value) > 0:
                    total = int(value)
                    days = ["?"]

            current_week["habits"][name] = {"days": days, "total": total}

    if current_week:
        weeks.append(current_week)

    return weeks


# ═══════════════════════════════════════════════════════════════════════════
# LEARNING: Track patterns for implementation intentions
# ═══════════════════════════════════════════════════════════════════════════


def get_patterns_file():
    """Get path to patterns file (stored alongside habit file)."""
    return Path.home() / ".habit_patterns.json"


def load_patterns():
    """Load learned patterns (which days user typically does each habit)."""
    path = get_patterns_file()
    if path.exists():
        try:
            return json.loads(path.read_text())
        except:
            pass
    return {}


def save_patterns(patterns):
    """Save learned patterns."""
    path = get_patterns_file()
    path.write_text(json.dumps(patterns, indent=2))


def learn_patterns(weeks):
    """
    Learn which days user typically completes each habit.
    Returns: {habit: {day_name: count, ...}, ...}

    This enables implementation intentions - "when X, I will Y"
    """
    patterns = {}
    day_map = {
        "Mon": 0,
        "Tue": 1,
        "Wed": 2,
        "Thu": 3,
        "Fri": 4,
        "Sat": 5,
        "Sun": 6,
        "M": 0,
        "T": 1,
        "W": 2,
        "Th": 3,
        "F": 4,
        "Sa": 5,
        "Su": 6,
    }

    for w in weeks:
        for habit, data in w["habits"].items():
            if habit not in patterns:
                patterns[habit] = {
                    d: 0 for d in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                }
            for day in data["days"]:
                # Normalize day name
                for key, idx in day_map.items():
                    if day.lower().startswith(key.lower()):
                        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        patterns[habit][day_names[idx]] += 1
                        break

    save_patterns(patterns)
    return patterns


def get_best_days(patterns, habit, top_n=3):
    """Get the days user most often does this habit."""
    if habit not in patterns:
        return []
    sorted_days = sorted(patterns[habit].items(), key=lambda x: -x[1])
    return [d for d, count in sorted_days[:top_n] if count > 0]


# ═══════════════════════════════════════════════════════════════════════════
# METRICS
# ═══════════════════════════════════════════════════════════════════════════


def get_streak(weeks, habit):
    """Current consecutive weeks with activity."""
    streak = 0
    for w in reversed(weeks):
        if habit in w["habits"] and len(w["habits"][habit]["days"]) > 0:
            streak += 1
        else:
            break
    return streak


def get_best_streak(weeks, habit):
    """Best consecutive weeks ever."""
    best = current = 0
    for w in weeks:
        if habit in w["habits"] and len(w["habits"][habit]["days"]) > 0:
            current += 1
            best = max(best, current)
        else:
            current = 0
    return best


def get_consistency(weeks, habit, window=8):
    """Percentage of weeks with activity in window."""
    recent = weeks[-window:] if len(weeks) >= window else weeks
    active = sum(
        1
        for w in recent
        if habit in w["habits"] and len(w["habits"][habit]["days"]) > 0
    )
    return active, len(recent)


def is_recovery_mode(weeks, habit, threshold=2):
    """
    True if user missed last `threshold` consecutive weeks.
    Triggers compassionate recovery UI instead of failure dashboard.
    """
    if len(weeks) < threshold:
        return False
    recent = weeks[-threshold:]
    return all(
        habit not in w["habits"] or len(w["habits"][habit]["days"]) == 0 for w in recent
    )


# ═══════════════════════════════════════════════════════════════════════════
# IDENTITY MAPPING (Clear's Atomic Habits + self-perception theory)
# ═══════════════════════════════════════════════════════════════════════════

# Map habits to identity nouns - customize for your habits
IDENTITY_MAP = {
    "saas": ("builder", "building", "exploring building"),
    "study": ("learner", "learning", "exploring"),
    "tweets": ("writer", "writing", "finding your voice"),
}


def get_identity_label(habit, consistency_pct):
    """
    Map consistency percentage to identity statement.
    Higher consistency = stronger identity claim.
    Never negative framing - even low consistency is "exploring"
    """
    nouns = IDENTITY_MAP.get(habit, ("practitioner", "practicing", "exploring"))

    if consistency_pct >= 85:
        return f"a consistent {nouns[0]}"
    elif consistency_pct >= 70:
        return f"a regular {nouns[0]}"
    elif consistency_pct >= 50:
        return f"building the {nouns[1]} habit"
    else:
        return nouns[2]


# ═══════════════════════════════════════════════════════════════════════════
# FRESH START DETECTION (Dai, Milkman, Riis 2014)
# ═══════════════════════════════════════════════════════════════════════════


def get_fresh_start_type(today=None):
    """
    Detect if today is a fresh start opportunity.
    Returns: None, 'week', 'month', or 'year'
    """
    if today is None:
        today = datetime.now()

    if today.month == 1 and today.day <= 7:
        return "year"
    elif today.day <= 7:
        return "month"
    elif today.weekday() == 0:  # Monday
        return "week"
    return None


# ═══════════════════════════════════════════════════════════════════════════
# DISPLAY HELPERS
# ═══════════════════════════════════════════════════════════════════════════


def format_range(r):
    """Format date range for display."""
    months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
    ]
    start, end = r[:8], r[9:]
    m1, d1 = int(start[4:6]), int(start[6:8])
    m2, d2 = int(end[4:6]), int(end[6:8])
    if m1 == m2:
        return f"{months[m1 - 1]} {d1:2}-{d2}"
    return f"{months[m1 - 1]} {d1}-{months[m2 - 1]} {d2}"


def progress_bar(filled, total, width=12):
    """Simple progress bar."""
    if total == 0:
        return "░" * width
    pct = min(1.0, filled / total)
    full = int(pct * width)
    return "█" * full + "░" * (width - full)


def visible_len(s):
    """Calculate visible length of string (excluding ANSI codes)."""
    import re

    return len(re.sub(r"\033\[[0-9;]*m", "", s))


def pad_line(content, width):
    """Pad content to width, accounting for ANSI codes."""
    vlen = visible_len(content)
    return content + " " * (width - vlen)


# ═══════════════════════════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════════════════════════


class C:
    """ANSI color codes."""

    reset = "\033[0m"
    bold = "\033[1m"
    dim = "\033[90m"
    green = "\033[92m"
    red = "\033[91m"
    yellow = "\033[93m"

    # Habit colors - customize as needed
    habits = {
        "saas": "\033[38;5;208m",  # orange
        "study": "\033[92m",  # green
        "tweets": "\033[94m",  # blue
    }

    @classmethod
    def h(cls, habit):
        return cls.habits.get(habit, "\033[96m")


# ═══════════════════════════════════════════════════════════════════════════
# MAIN DISPLAY
# ═══════════════════════════════════════════════════════════════════════════


def display_recovery_mode(habit, weeks_away, best_days):
    """
    Compassionate UI for returning after absence.
    Research: Self-compassion increases re-engagement; self-criticism reduces it.
    """
    hc = C.h(habit)
    print(f"  {hc}{habit}{C.reset}: {weeks_away} weeks away")
    if best_days:
        print(f"       You usually do this on {', '.join(best_days[:2])}")
    print(f"       {C.dim}One day puts you back in motion{C.reset}")
    print()


def main():
    # Parse args
    show_full_history = "--history" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    filepath = args[0] if args else "habits.txt"

    if not os.path.exists(filepath):
        print(f"  No habit file found at: {filepath}")
        print(f"  Create one with format:")  # noqa: F541
        print(f"    20250101-20250107")  # noqa: F541
        print(f"    habit_name: Mon 1, Wed 1, Fri 1")  # noqa: F541
        return

    weeks = parse_habits(filepath)
    if not weeks:
        print("  No data found")
        return

    # Collect all habits
    all_habits = []
    for w in weeks:
        for h in w["habits"]:
            if h not in all_habits:
                all_habits.append(h)

    # Goals (days per week) - customize
    goals = {"saas": 4, "study": 5, "tweets": 10}

    # Learn patterns for implementation intentions
    patterns = learn_patterns(weeks)

    today = datetime.now()
    weekday = today.weekday()
    day_names_full = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    current = weeks[-1] if weeks else None

    # Check for habits in recovery mode
    recovery_habits = [h for h in all_habits if is_recovery_mode(weeks, h)]
    active_habits = [h for h in all_habits if h not in recovery_habits]

    print()

    # ═══════════════════════════════════════════════════════════════════
    # FRESH START BANNER (when applicable)
    # Research: Dai, Milkman, Riis - temporal landmarks increase goal pursuit
    # ═══════════════════════════════════════════════════════════════════
    fresh_start = get_fresh_start_type(today)
    if fresh_start == "year":
        print(f"  {C.bold}🌱 NEW YEAR{C.reset}")
        print(f"  {C.dim}Fresh start. What matters is what you do now.{C.reset}")
        print()
    elif fresh_start == "month":
        print(f"  {C.bold}🌱 NEW MONTH{C.reset}")
        print(f"  {C.dim}{today.strftime('%B')} starts fresh.{C.reset}")
        print()

    # ═══════════════════════════════════════════════════════════════════
    # RECOVERY MODE (if any habits need it)
    # Research: Self-compassion > self-criticism after failure
    # ═══════════════════════════════════════════════════════════════════
    if recovery_habits:
        W = 50
        print(f"  ┌{'─' * W}┐")

        # Header
        header = f"  {C.bold}WELCOME BACK{C.reset}"
        print(f"  │{pad_line(header, W)}│")
        print(f"  │{' ' * W}│")

        for h in recovery_habits:
            best = get_best_days(patterns, h, 2)
            best_str = f"  (try {', '.join(best)})" if best else ""
            hc = C.h(h)

            line = f"  {hc}○ {h}{best_str}{C.reset}"
            print(f"  │{pad_line(line, W)}│")

        print(f"  │{' ' * W}│")
        footer = f"  {C.dim}One day this week puts you back in motion.{C.reset}"
        print(f"  │{pad_line(footer, W)}│")
        print(f"  └{'─' * W}┘")
        print()

    # ═══════════════════════════════════════════════════════════════════
    # TODAY PANEL - Primary action driver
    # Research: Immediacy drives action (Fogg); implementation intentions
    # ═══════════════════════════════════════════════════════════════════
    W = 50
    print(f"  ┌{'─' * W}┐")

    # Header with day name emphasized
    day_str = today.strftime("%A")
    date_str = today.strftime("%b %d")
    header = f"  {C.bold}TODAY{C.reset}  {day_str}, {date_str}"
    print(f"  │{pad_line(header, W)}│")
    print(f"  │{' ' * W}│")

    for h in active_habits:
        goal = goals.get(h, 4)
        hc = C.h(h)
        best_days = get_best_days(patterns, h, 3)
        is_best_day = day_names_full[weekday] in best_days

        if current and h in current["habits"]:
            days_done = len(current["habits"][h]["days"])
            total = current["habits"][h]["total"]
        else:
            days_done = 0
            total = 0

        # Build dot display: ● done, ○ missed, · future
        # Yellow highlights future "best days" (learned from patterns)
        dots = ""
        for i in range(7):
            if i < days_done:
                dots += f"{hc}●{C.reset} "
            elif i <= weekday:
                dots += f"{C.dim}○{C.reset} "
            else:
                # Highlight best days in future (implementation intention cue)
                if day_names_full[i] in best_days:
                    dots += f"{C.yellow}◦{C.reset} "  # distinct marker
                else:
                    dots += f"{C.dim}·{C.reset} "

        # Status with implementation intention prompt
        if h == "tweets":
            if total >= goal:
                status = f"{C.green}✓ done{C.reset}"
            else:
                remaining = goal - total
                status = f"{remaining} to go"
        else:
            remaining = max(0, goal - days_done)
            days_left = 6 - weekday

            if days_done >= goal:
                status = f"{C.green}✓ done{C.reset}"
            elif remaining <= days_left:
                # Forward-looking, not judgmental
                if is_best_day and days_done < goal:
                    status = f"{C.yellow}today?{C.reset}"
                else:
                    status = f"{remaining} to go"
            else:
                # Changed from "behind" - autonomy-preserving language
                status = "restart?"

        # Format: "  habit     ● ● ○ · · · ·  status"
        content = f"  {hc}{h:<8}{C.reset} {dots} {status}"
        print(f"  │{pad_line(content, W)}│")

    print(f"  └{'─' * W}┘")
    print()

    # ═══════════════════════════════════════════════════════════════════
    # IDENTITY PANEL
    # Research: Clear's identity-based habits; Bem's self-perception theory
    # "I am X" is more durable than "I do X"
    # ═══════════════════════════════════════════════════════════════════
    print(f"  {C.bold}YOU ARE{C.reset}")
    print()

    for h in all_habits:
        hc = C.h(h)
        active, total = get_consistency(weeks, h, 8)
        pct = (active / total * 100) if total > 0 else 0
        identity = get_identity_label(h, pct)

        # Show consistency inline
        bar = progress_bar(active, total, 8)

        # Best streak shown only if notable and not current
        current_streak = get_streak(weeks, h)
        best = get_best_streak(weeks, h)

        streak_note = ""
        if current_streak > 0 and current_streak == best and best >= 3:
            streak_note = f" {C.yellow}★{C.reset}"
        elif best > current_streak and best >= 4:
            streak_note = f" {C.dim}(best: {best}w){C.reset}"

        print(f"  {hc}▸{C.reset} {identity:<28} {bar} {pct:.0f}%{streak_note}")

    print()

    # ═══════════════════════════════════════════════════════════════════
    # HISTORY (demoted - reference only)
    # Default: last 4 weeks. Use --history for full view.
    # ═══════════════════════════════════════════════════════════════════
    if show_full_history:
        print(f"  {C.dim}HISTORY{C.reset}")
        recent_weeks = weeks
    else:
        print(f"  {C.dim}RECENT{C.reset}")
        recent_weeks = weeks[-4:] if len(weeks) >= 4 else weeks

    for w in recent_weeks:
        label = format_range(w["range"])
        print(f"  {C.dim}{label:<12}{C.reset}", end="")
        for h in all_habits:
            hc = C.h(h)
            if h in w["habits"] and len(w["habits"][h]["days"]) > 0:
                if h == "tweets":
                    display = str(w["habits"][h]["total"])
                else:
                    display = f"{len(w['habits'][h]['days'])}d"
                print(f" {hc}{display:>6}{C.reset}", end="")
            else:
                print(f" {C.dim}{'·':>6}{C.reset}", end="")
        print()

    print()


if __name__ == "__main__":
    main()
