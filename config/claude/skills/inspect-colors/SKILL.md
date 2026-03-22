---
name: inspect-colors
description: >
  Analyze ANSI/256-color/24-bit color escape codes used in the current tmux
  pane. Use when the user wants to identify what color a terminal UI element
  is using, inspect escape codes in terminal output, or asks things like
  "この●は何色？", "このテキストの色コードは？", "what color is this element",
  "inspect terminal colors", "escape codes を見たい", or wants to reverse-engineer
  a terminal app's color scheme. Captures the current tmux pane and decodes
  all color codes found, converting 256-color indices to hex.
allowed-tools: Bash(tmux:*), Bash(grep:*), Bash(printf:*)
---

## Context

- Current pane content: !`tmux capture-pane -p -e 2>/dev/null | cat -v | tail -50`

## Overview

Help the user identify what color a specific terminal UI element is using,
by capturing the current tmux pane and decoding its escape codes.

The key insight: **always display with 256-color codes (`38;5;N`) rather than
converting to 24-bit RGB** — they render differently in the terminal and only
the original code will match what the user actually sees.

## Workflow

### If the user wants to identify a specific element's color

Ask them to trigger the element first (e.g., run a failing command to see
the error indicator), then run this analysis. The capture happens after they
respond, so the element will be visible in the pane.

### Step 1: Extract all color codes

```bash
tmux capture-pane -p -e | cat -v | grep -oE '\^\[\[[0-9;]+m' | sort | uniq -c | sort -rn
```

Parse the codes found:
- `^[[38;5;Nm` — 256-color foreground, color N
- `^[[48;5;Nm` — 256-color background, color N
- `^[[38;2;R;G;Bm` — 24-bit foreground
- `^[[48;2;R;G;Bm` — 24-bit background
- `^[[32m`, `^[[91m` etc. — 16-color ANSI (color depends on terminal theme)

### Step 2: Show colors with context

For each unique color code, show what text it's applied to and display
a colored swatch using the **original 256-color code**:

```bash
# Example: show color 153
printf '\e[38;5;153m● 38;5;153  <context text here>\e[0m\n'
```

### Step 3: Convert 256-color to hex (for reference)

For colors 16–231 (the 6×6×6 color cube):
```
i = N - 16
r = i / 36;  rv = (r == 0) ? 0 : 55 + r * 40
g = (i % 36) / 6;  gv = (g == 0) ? 0 : 55 + g * 40
b = i % 6;  bv = (b == 0) ? 0 : 55 + b * 40
hex = #RRGGBB
```

For colors 232–255 (grayscale):
```
v = 8 + (N - 232) * 10
hex = #vvvvvv
```

For colors 0–15: these depend on the terminal theme (e.g., Iceberg Dark),
so report the ANSI name (`red`, `greenBright`, etc.) rather than a fixed hex.

### Step 4: Present results

Show a table of colors found, with:
- The 256-color swatch (rendered with `printf`)
- The color code
- Approximate hex (note: actual rendering may differ by terminal theme)
- What text/element uses it

**Note:** For 16-color ANSI codes, mention that the actual color depends on
the terminal's theme palette (e.g., `\e[91m` renders as Iceberg's redBright
= `#ef9898` in Ghostty with Iceberg Dark).
