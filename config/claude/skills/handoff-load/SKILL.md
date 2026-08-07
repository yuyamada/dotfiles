---
name: handoff-load
description: >
  Load the most recent handoff document from tmp/ to resume work from a
  previous session. Use when the user says "引き継ぎを読み込んで",
  "続きから始めたい", "handoff読み込んで", "load handoff", "/handoff-load", or
  starts a new session referencing earlier work that was saved with
  handoff-save.
allowed-tools: Bash(ls:*), Read
---

## Overview

Restore context from a handoff document written by the `handoff-save` skill,
then confirm the plan before continuing.

## Steps

### Step 1: Find the handoff document

```bash
ls -t tmp/handoff-*.md 2>/dev/null | head -1
```

If no matching file exists, tell the user no handoff document was found in
`tmp/` and stop. If the user passed an explicit path as an argument, use that
path instead of searching.

### Step 2: Read it

Read the file with the Read tool.

### Step 3: Confirm and continue

Summarize back to the user in 2-3 sentences: the goal, what's already done,
and the first item under "Next steps". Ask if they want to proceed with that
next step, or if anything has changed since the handoff was written.

Do not start acting on "Next steps" until the user confirms.
