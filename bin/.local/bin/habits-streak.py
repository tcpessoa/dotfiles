#!/usr/bin/env python3
"""
Habit Tracker - Behavioral Science

Immediate TODOs:
- Improvement 1: Variable micro-reward (rare, post-action)
- Improvement 2: Event-based habit stacking (one-time input, Contextual cues > temporal cues (Wood & Neal))
- Improvement 3: Goal conflict acknowledgment (protects motivation)
- Identity elasticity under failure

CHANGELOG
---

CHANGES FROM V2:

1. MOVED: Identity to pre-action micro-prime (single line, top)
   Research: Oyserman (2007, 2015) - identity primes must be brief and pre-decisional.
   Pre-action primes affect behavior through non-conscious activation.
   Post-action labels trigger explicit self-evaluation (pressure).

2. ADDED: Sunday obstacle prompt (WOOP completion)
   Research: Oettingen & Gollwitzer (2010) - implementation intentions double in
   effectiveness when paired with obstacle identification. MCII/WOOP protocol.

3. REPLACED: Suggested-days (yellow ◦) with streak-to-beat counter
   Research: Kivetz, Urminsky & Zheng (2006) - goal gradient effect.
   Garcia & Tor (2009) - self-competition framing avoids social comparison downsides.
   "1 more = new best" creates endowed progress and clear approaching target.

4. CHANGED: Sort Today panel - struggling habits first
   Research: Attention primacy, anti-licensing. Completed habits at bottom
   reduce moral licensing ("I did X so I can skip Y").

5. CHANGED: "✓ done" → "✓ this week"
   Research: Semantic framing. "Done" sounds like permission to disengage.
   "This week" is factual without finality.

6. ADDED: First-run "STARTING" state for new users
   Research: Fogg's Tiny Habits - lower the bar. "First one counts" emphasizes
   any action creates data.

7. ADDED: Milestone markers at 8/12 weeks for perfect users
   Research: Lally et al. - 66 days average for automaticity.
   Fresh start effect works in reverse - people disengage after completing
   temporal milestones unless given new frame.

8. REMOVED: Dedicated "YOU ARE" section (redundant with inline consistency)

9. CHANGED: Fresh start banner moved to subtle position (end, not top)
   Research: Only relevant ~14 days/year. Training eye to skip top is bad.

PRESERVED FROM V2:
- Implementation intentions (Gollwitzer)
- Recovery mode with self-compassion (Neff)
- Consistency over streaks (Polivy & Herman)
- Autonomy-preserving language (Deci & Ryan)

---
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
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

# Combined habit configuration - customize as needed
# identity: (noun, verb_phrase) for micro-prime
# goal: {"goal": int, "type": "days" or "count"}
# color: ANSI color code
HABIT_CONFIG = {
    "saas": {
        "identity": ("builders", "build"),
        "goal": {"goal": 4, "type": "days"},
        "color": "\033[38;5;208m",  # orange
    },
    "study": {
        "identity": ("learners", "learn"),
        "goal": {"goal": 5, "type": "days"},
        "color": "\033[92m",  # green
    },
    "tweets": {
        "identity": ("writers", "write"),
        "goal": {"goal": 10, "type": "count"},
        "color": "\033[94m",  # blue
    },
}

# Milestone weeks for special recognition
MILESTONE_WEEKS = [8, 12]
MILESTONE_MESSAGES = {8: "8 weeks solid", 12: "quarterly habit"}

# Recovery mode threshold: weeks missed to trigger recovery
RECOVERY_THRESHOLD = 2

# Consistency window: weeks to calculate consistency percentage
CONSISTENCY_WINDOW = 8


# ═══════════════════════════════════════════════════════════════════════════════════════════
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


def is_recovery_mode(weeks, habit, threshold=RECOVERY_THRESHOLD):
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


def get_identity_micro_prime(habits):
    """
    Generate single-line identity micro-prime.
    Research: Oyserman - brief, action-oriented, pre-decisional.
    """
    primes = []
    for h in habits:
        if h in HABIT_CONFIG and "identity" in HABIT_CONFIG[h]:
            noun, verb = HABIT_CONFIG[h]["identity"]
            primes.append(f"{noun} {verb}")
        else:
            # Generic fallback
            primes.append(f"{h}ers {h}")
    return " · ".join(primes)


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
    cyan = "\033[96m"

    # Habit colors
    habits = {h: config["color"] for h, config in HABIT_CONFIG.items()}

    @classmethod
    def h(cls, habit):
        return cls.habits.get(habit, "\033[96m")


# ═══════════════════════════════════════════════════════════════════════════
# SORTING: Struggling habits first (anti-licensing)
# ═══════════════════════════════════════════════════════════════════════════


def sort_habits_by_need(habits, current_week, goals, weekday):
    """
    Sort habits: struggling first, completed last.
    Research: Attention primacy + anti-licensing.
    """

    def priority(h):
        goal_info = goals.get(h, {"goal": 4, "type": "days"})
        goal = goal_info["goal"]
        type_ = goal_info["type"]
        if current_week and h in current_week["habits"]:
            if type_ == "count":
                done = current_week["habits"][h]["total"]
            else:
                done = len(current_week["habits"][h]["days"])
        else:
            done = 0

        if done >= goal:
            return 2  # Completed - show last
        elif done == 0:
            return 0  # Not started - show first
        else:
            # Partial - sort by how far behind
            remaining = goal - done
            days_left = 6 - weekday
            if remaining > days_left:
                return 0  # Behind schedule - show first
            return 1  # On track - middle

    return sorted(habits, key=priority)


# ═══════════════════════════════════════════════════════════════════════════
# MAIN DISPLAY
# ═══════════════════════════════════════════════════════════════════════════


def main():
    # Parse args
    show_full_history = "--history" in sys.argv

    # Date override for testing: --date=YYYY-MM-DD
    date_override = None
    for arg in sys.argv[1:]:
        if arg.startswith("--date="):
            date_str = arg.split("=")[1]
            date_override = datetime.strptime(date_str, "%Y-%m-%d")

    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    filepath = args[0] if args else "habits.txt"

    if not os.path.exists(filepath):
        print(f"  No habit file found at: {filepath}")
        print(f"  Create one with format:")  # noqa: F541
        print(f"    20250101-20250107")  # noqa: F541
        print(f"    habit_name: Mon 1, Wed 1, Fri 1")  # noqa: F541
        return

    weeks = parse_habits(filepath)

    # Collect all habits
    all_habits = []
    for w in weeks:
        for h in w["habits"]:
            if h not in all_habits:
                all_habits.append(h)

    # Goals (days per week)
    goals = {h: config["goal"] for h, config in HABIT_CONFIG.items()}

    # Learn patterns for implementation intentions
    patterns = learn_patterns(weeks) if weeks else {}

    today = date_override if date_override else datetime.now()
    weekday = today.weekday()
    is_sunday = weekday == 6

    current = weeks[-1] if weeks else None

    # Check for habits in recovery mode
    recovery_habits = [h for h in all_habits if is_recovery_mode(weeks, h)]
    active_habits = [h for h in all_habits if h not in recovery_habits]

    # Sort active habits: struggling first (anti-licensing)
    active_habits = sort_habits_by_need(active_habits, current, goals, weekday)

    print()

    # ═══════════════════════════════════════════════════════════════════
    # FIRST-RUN STATE: No history yet
    # Research: Fogg's Tiny Habits - lower the bar
    # ═══════════════════════════════════════════════════════════════════
    if not weeks or not all_habits:
        W = 50
        print(f"  ┌{'─' * W}┐")
        header = f"  {C.bold}STARTING{C.reset}"
        print(f"  │{pad_line(header, W)}│")
        print(f"  │{' ' * W}│")

        # Show placeholder habits from goals
        for h in goals.keys():
            hc = C.h(h)
            dots = f"{C.dim}· · · · · · ·{C.reset}"
            line = f"  {hc}{h:<8}{C.reset} {dots}  first one counts"
            print(f"  │{pad_line(line, W)}│")

        print(f"  │{' ' * W}│")
        footer = f"  {C.dim}No history yet. That's fine. Start anywhere.{C.reset}"
        print(f"  │{pad_line(footer, W)}│")
        print(f"  └{'─' * W}┘")
        print()
        return

    # ═══════════════════════════════════════════════════════════════════
    # IDENTITY MICRO-PRIME (pre-action, single line)
    # Research: Oyserman (2007) - brief, pre-decisional primes
    # ═══════════════════════════════════════════════════════════════════
    micro_prime = get_identity_micro_prime(all_habits)
    print(f"  {C.dim}{micro_prime}{C.reset}")
    print()

    # ═══════════════════════════════════════════════════════════════════
    # RECOVERY MODE (if any habits need it)
    # Research: Self-compassion > self-criticism after failure
    # ═══════════════════════════════════════════════════════════════════
    if recovery_habits:
        W = 50
        print(f"  ┌{'─' * W}┐")

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
    # Research: Immediacy drives action (Fogg)
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
        goal_info = goals.get(h, {"goal": 4, "type": "days"})
        goal = goal_info["goal"]
        type_ = goal_info["type"]
        hc = C.h(h)

        if current and h in current["habits"]:
            days_done = len(current["habits"][h]["days"])
            total = current["habits"][h]["total"]
        else:
            days_done = 0
            total = 0

        # Get streak info for "streak-to-beat" feature
        current_streak = get_streak(weeks, h)
        best_streak = get_best_streak(weeks, h)

        # Build dot display: ● done, ○ missed, · future
        # REMOVED: yellow suggested days (felt prescriptive)
        dots = ""
        for i in range(7):
            if i < days_done:
                dots += f"{hc}●{C.reset} "
            elif i <= weekday:
                dots += f"{C.dim}○{C.reset} "
            else:
                dots += f"{C.dim}·{C.reset} "

        # Status logic with streak-to-beat
        # Research: Kivetz (goal gradient), Garcia & Tor (self-competition)
        if type_ == "count":
            if total >= goal:
                status = f"{C.green}✓ this week{C.reset}"
            else:
                remaining = goal - total
                status = f"{remaining} to go"
        else:
            remaining = max(0, goal - days_done)
            days_left = 6 - weekday

            if days_done >= goal:
                status = f"{C.green}✓ this week{C.reset}"
            elif remaining <= days_left:
                # Check if completing this week would beat best streak
                # (current_streak is weeks completed, so if we complete this week it becomes current_streak + 1)
                if best_streak > 0 and current_streak + 1 > best_streak:
                    status = f"{C.yellow}{remaining} more = new best{C.reset}"
                elif best_streak > 0 and current_streak + 1 == best_streak:
                    status = f"{remaining} to go · ties best"
                else:
                    status = f"{remaining} to go"
            else:
                # Changed from "behind" - autonomy-preserving language
                status = "restart?"

        # Add milestone recognition if completed this week
        if (type_ == "count" and total >= goal) or (
            type_ == "days" and days_done >= goal
        ):
            if current_streak in MILESTONE_MESSAGES:
                status += f" · {MILESTONE_MESSAGES[current_streak]}"
            elif current_streak > 12 and current_streak % 4 == 0:
                status += f" · {current_streak}w"

        content = f"  {hc}{h:<8}{C.reset} {dots} {status}"
        print(f"  │{pad_line(content, W)}│")

    # ═══════════════════════════════════════════════════════════════════
    # SUNDAY OBSTACLE PROMPT (WOOP completion)
    # Research: Oettingen & Gollwitzer (2010) - obstacle identification
    # doubles implementation intention effectiveness
    # ═══════════════════════════════════════════════════════════════════
    if is_sunday:
        print(f"  │{' ' * W}│")
        print(f"  │{pad_line('  ' + '─' * 46, W)}│")
        print(f"  │{pad_line(f'  {C.bold}NEXT WEEK{C.reset}', W)}│")
        prompt = f"  {C.dim}What might get in the way?{C.reset}"
        print(f"  │{pad_line(prompt, W)}│")
        examples = f"  {C.dim}(travel, deadline, energy){C.reset}"
        print(f"  │{pad_line(examples, W)}│")

    print(f"  └{'─' * W}┘")
    print()

    # ═══════════════════════════════════════════════════════════════════
    # CONSISTENCY (inline, compact)
    # Shows 8-week consistency with best-streak note when relevant
    # ═══════════════════════════════════════════════════════════════════
    print(f"  {C.dim}CONSISTENCY ({CONSISTENCY_WINDOW} weeks){C.reset}")
    print()

    for h in all_habits:
        hc = C.h(h)
        active, total = get_consistency(weeks, h, CONSISTENCY_WINDOW)
        pct = (active / total * 100) if total > 0 else 0

        bar = progress_bar(active, total, 8)

        current_streak = get_streak(weeks, h)
        best = get_best_streak(weeks, h)

        streak_note = ""
        if current_streak > 0 and current_streak == best and best >= 3:
            streak_note = f" {C.yellow}★{C.reset}"
        elif best > current_streak and best >= 4:
            streak_note = f" {C.dim}(best: {best}w){C.reset}"

        print(f"  {hc}▸{C.reset} {h:<10} {bar} {pct:.0f}%{streak_note}")

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
                type_ = goals.get(h, {"type": "days"})["type"]
                if type_ == "count":
                    display = str(w["habits"][h]["total"])
                else:
                    display = f"{len(w['habits'][h]['days'])}d"
                print(f" {hc}{display:>6}{C.reset}", end="")
            else:
                print(f" {C.dim}{'·':>6}{C.reset}", end="")
        print()

    print()

    # ═══════════════════════════════════════════════════════════════════
    # FRESH START BANNER (moved to end, subtle)
    # Research: Only relevant ~14 days/year
    # ═══════════════════════════════════════════════════════════════════
    fresh_start = get_fresh_start_type(today)
    if fresh_start == "year":
        print(f"  {C.dim}🌱 New year. Fresh start.{C.reset}")
        print()
    elif fresh_start == "month":
        print(f"  {C.dim}🌱 {today.strftime('%B')} begins.{C.reset}")
        print()


if __name__ == "__main__":
    main()
