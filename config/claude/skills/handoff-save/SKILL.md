---
name: handoff-save
description: >
  Summarize the current session's work into a handoff document saved under
  tmp/, so a new session can pick up where this one left off. Use when the
  user says "引き継ぎドキュメント作って", "セッションをクリアする前にまとめて",
  "作業内容をまとめて", "handoff作って", "save handoff", "/handoff-save", or
  wants to clear/end the current session without losing context.
allowed-tools: Bash(mkdir:*), Bash(date:*), Write
---

## Overview

Write a concise handoff document that lets a fresh session continue this work
with minimal re-reading. Summarize from the conversation itself — do not
re-read transcript files.

## Steps

### Step 1: Prepare the destination

```bash
mkdir -p tmp
date +%Y%m%d-%H%M%S
```

Use the timestamp for the filename: `tmp/handoff-<timestamp>.md`.

### Step 2: Compose the summary

Fill in this exact structure, based on the current conversation:

```markdown
# Handoff — <YYYY-MM-DD HH:MM>

## Goal
<what the user is trying to accomplish, in 1-3 sentences>

## Done
- <completed step>
- <completed step>

## Key decisions
- <decision> — <why, especially anything non-obvious or that the user chose over an alternative>

## Files touched
- <path> — <what changed and why>

## Next steps
- [ ] <concrete next action>
- [ ] <concrete next action>

## Open questions / blockers
- <anything unresolved, or "none">
```

Guidelines:
- Be concrete and specific — write for someone with zero memory of this conversation, not a vague recap.
- "Key decisions" should capture *why*, not just *what* — that's the part a fresh session can't infer from a diff.
- "Next steps" must be actionable, not restatements of the goal.
- Keep it tight. This is a working document, not a report — omit sections with nothing to say rather than padding them.

### Step 3: Write and confirm

Write the file with the Write tool. Then tell the user the file path and that
they can start a new session and run `/handoff-load` to resume.
