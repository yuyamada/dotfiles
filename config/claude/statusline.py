#!/usr/bin/env python3
import json, sys, subprocess, os

data = json.load(sys.stdin)

RESET  = "\033[0m"
DIM    = "\033[2m"

model       = data.get("model", {}).get("display_name", "")
current_dir = data.get("workspace", {}).get("current_dir", "")
dir_name    = os.path.basename(current_dir) if current_dir else ""

try:
    branch = subprocess.check_output(
        ["git", "-C", current_dir, "branch", "--show-current"],
        stderr=subprocess.DEVNULL,
    ).decode().strip()
except Exception:
    branch = ""

# Line 1: [model] directory | branch
line1 = f"{DIM}[{model}] {dir_name}"
if branch:
    line1 += f" | {branch}"
line1 += RESET

# Line 2: progress bar n% | cost | time
pct    = int(data.get("context_window", {}).get("used_percentage", 0))
filled = round(pct * 5 / 100)
empty  = 5 - filled
bar = f"{DIM}{'━' * filled}{'╌' * empty}{RESET}"

cost_usd = data.get("cost", {}).get("total_cost_usd", 0)
cost_str = f"${cost_usd:.3f}"

ms       = int(data.get("cost", {}).get("total_duration_ms", 0))
mins     = ms // 60000
secs     = (ms % 60000) // 1000
time_str = f"{mins}m {secs:02d}s"

line2 = f"{bar} {DIM}{pct}% | {cost_str} | {time_str}{RESET}"

print(line1)
print(line2)
