---
name: retrospect
description: Analyze recent Claude conversation transcripts to identify friction patterns and propose improvements to Claude config (rules, skills, settings.json). Run after sessions where Claude made mistakes or you found yourself repeating instructions.
allowed-tools:
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(wc:*)
  - Bash(tail:*)
  - Bash(jq:*)
  - Bash(git log:*)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Read:*
  - Edit:*
  - Write:*
---

# Retrospect: Claude Config Improvement

Analyze recent conversation transcripts and propose targeted improvements to Claude's config.

## Phase 1: Collect Transcripts

Find JSONL transcript files from the last 7 days, excluding subagent sessions, most recent first, max 10 files:

```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -7 -print0 2>/dev/null \
  | xargs -0 stat -f "%m %N" 2>/dev/null \
  | sort -rn | head -10 | awk '{print $2}'
```

If this returns no files, report "No sessions found in the last 7 days" and stop.

For each file: check its size first:
```bash
wc -c <file>
```

If it exceeds 200000 bytes, read only the last 200000 bytes:
```bash
tail -c 200000 <file>
```
(The first line of a `tail`-truncated file may be incomplete — discard it and start reading from the second line.)

Otherwise read the full file with the Read tool.

Record the count of files read (N).

## Phase 2: Analyze for Signals

Read each transcript and look for these signals:

**[RULE] signals — indicate a workflow or tooling rule is missing:**
- User messages containing correction language: "no", "違う", "やり直", "そうじゃなくて", "ちがう", "that's wrong", "don't do that", "やめて" — especially when followed by Claude re-attempting the same task
- A user correction message that immediately follows a sequence of Edit or Write tool calls in the same conversation

**[SKILL] signals — indicate a missing skill:**
- The same type of user request (by intent, not exact wording) appears 3 or more times across 3 or more distinct JSONL files (one file = one session) — for example "今日やったことまとめて", "コミットして", "PR作って" — but only if no existing skill in `~/.claude/skills/` already handles it

If no signals are found, or if all detected signals are filtered out (e.g. all [SKILL] candidates are already covered by existing skills), report "No improvement opportunities detected in the last N sessions" and stop.

## Phase 3: Present Proposals

Output exactly this format:

Use today's date for YYYY-MM-DD in the header.

```
Retrospective — YYYY-MM-DD (N sessions analyzed, last 7 days)

[1] RULE: <target file, e.g. rules/workflow.md>
    Change: "<one sentence description of the rule to add>"
    Reason: <what transcript evidence triggered this>

[2] SKILL: Create /<skill-name> skill
    Reason: <what request pattern was repeated and how many times>

Apply which? Reply with numbers (e.g. "1 2"), "all", or "none":
```

Wait for the user's reply before continuing.

## Phase 4: Apply Approved Changes

Parse the user's reply:
- "none" → confirm "No changes applied." and stop
- Numbers or "all" → apply each selected proposal
- If the reply contains a number that is out of range (higher than the total number of proposals), ask the user to re-enter a valid selection before proceeding.

**For [RULE] proposals:** Use the Edit tool to append the new rule to the target file under `~/workspace/dotfiles/config/claude/` (assumes dotfiles repo is at `~/workspace/dotfiles`). Follow the existing formatting style of that file (look at surrounding content before editing).

**For [SKILL] proposals:** Inform the user: "To create the /<name> skill, use the skill-creator skill: `/skill-creator`". Do not create the skill directly.

After applying all file changes, commit from the dotfiles repo:

```bash
cd ~/workspace/dotfiles && git add config/claude/ && git diff --cached --quiet || git commit -m "chore(claude): apply retrospect improvements"
```

Confirm: "Applied [N] change(s) and committed."
