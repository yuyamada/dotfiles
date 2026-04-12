#!/usr/bin/env python3
import json, re, sys, subprocess, os

data = json.load(sys.stdin)

RESET = "\033[0m"
GRAY  = "\033[2m"


_parts      = data.get("model", {}).get("display_name", "").split()
model       = next((p for p in _parts if p not in ("Claude",) and not p[0].isdigit()), _parts[0] if _parts else "")
current_dir = data.get("workspace", {}).get("current_dir", "")

def short_path(path):
    if not path:
        return ""
    short = path.replace(os.path.expanduser("~"), "~", 1)
    head, tail = os.path.split(short)
    abbr = re.sub(r"/([^/])[^/]*", r"/\1", head)
    return f"{abbr}/{tail}"

dir_name = short_path(current_dir)
ccvm     = os.environ.get("CCVM", "")

try:
    branch = subprocess.check_output(
        ["git", "-C", current_dir, "branch", "--show-current"],
        stderr=subprocess.DEVNULL,
    ).decode().strip() if current_dir else ""
except Exception:
    branch = ""

# Line 1: [vm] directory | branch
line1 = f"{GRAY}"
if ccvm:
    line1 += "[vm] "
line1 += dir_name
if branch:
    line1 += f" | {branch}"
line1 += RESET

# Line 2: model | context% | in | out | cached
cw       = data.get("context_window", {})
pct      = int(cw.get("used_percentage", 0))
cost_usd = data.get("cost", {}).get("total_cost_usd", 0)
cost_str = f"${cost_usd:.1f}"

line2 = f"{GRAY}{model} | {pct}% | {cost_str}{RESET}"

print(f"{line1} {GRAY}|{RESET} {line2}")
