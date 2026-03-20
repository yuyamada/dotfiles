# Design: `/retrospect` Skill for Continuous Claude Config Improvement

Date: 2026-03-20
Status: Approved

## Overview

A manually-triggered Claude Code skill (`/retrospect`) that reads recent conversation transcripts, identifies friction patterns, proposes targeted improvements to rules/skills/settings, and applies approved changes.

## Problem

`rules/workflow.md` describes a "Self-improvement Loop" as a principle, but there is no actual mechanism to execute it. Improvements to Claude's configuration currently happen on an ad-hoc basis when the user notices a problem.

## Goals

- Analyze recent JSONL transcripts to surface actionable improvement candidates
- Present proposals with clear justification (target file, change, reason)
- Apply user-approved changes and commit them to the dotfiles repo
- Keep the loop lightweight enough to run regularly (manually, post-session)

## Non-Goals

- Automatic/scheduled execution (can be added later)
- Analysis of `tool-access.log` (out of scope for v1)
- Fully autonomous changes without user approval

## Definitions

- **Session**: one JSONL file under `~/.claude/projects/<project-dir>/`. Each file corresponds to one Claude Code session (one conversation).
- **Project**: one subdirectory under `~/.claude/projects/`, corresponding to one working directory.

## Architecture

### File Location

```
config/claude/skills/retrospect/
└── SKILL.md
```

Symlinked to `~/.claude/skills/retrospect` via `install.sh`.

### Context Window Budget

Reading all transcripts is not feasible. The skill limits scope as follows:

- Collect JSONL files modified in the last **7 days** across all project directories
- Sort by modification time (most recent first), take at most **10 files**
- If a single file exceeds **200 KB**, read only the last 200 KB (tail) to capture recent turns
- Exclude any JSONL files under `*/subagents/*` paths (these are subagent sessions, not main sessions)
- Report the actual count of files analyzed in the output header

### Skill Flow

```
/retrospect invoked
    ↓
Find JSONL files: ~/.claude/projects/**/*.jsonl, mtime < 7d, max 10, sorted by recency
    ↓
Claude reads transcripts and classifies signals into two categories:
  [RULE]       → addition/edit to rules/*.md
  [SKILL]      → new skill or improvement to existing skill
(see Signal Detection below)
    ↓
Present numbered proposal list: target file, change, reason
    ↓
Multi-turn: user replies with numbers to apply ("1 3", "all", "none")
    ↓
Apply approved changes via Edit/Write tools
Commit with message: "chore(claude): apply retrospect improvements"
```

### Interaction Model

The skill is implemented as a **multi-turn conversation**:

1. Skill reads transcripts and presents proposals — waits for user reply
2. User replies with which proposals to apply (e.g. `"1 3"`, `"all"`, `"none"`)
3. Skill applies the selected changes and confirms

No mid-turn interactive input is needed; the wait happens between conversation turns naturally.

### JSONL Schema Reference

Transcript files use newline-delimited JSON. Relevant entry types:

```jsonc
// User message
{"type": "user", "message": {"role": "user", "content": [{"type": "text", "text": "..."}]}}

// Assistant message
{"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": "..."}]}}

// Tool use result (within assistant content)
{"type": "tool_use", "name": "Edit", "input": {...}}

// Tool result (within user content)
{"type": "tool_result", "content": [...]}
```

To extract user and assistant text: read `.message.content[].text` where `.message.role` is `"user"` or `"assistant"`.

### Signal Detection Logic

**User correction signals** — indicate a rule or workflow gap:
- User messages containing correction language ("no", "違う", "やり直し", "そうじゃなくて", "that's wrong", "ちがう") followed by Claude re-attempting the same task
- A user correction message immediately following a tool use sequence (Edit/Write calls)

**Repetition signals** — indicate a missing skill:
- Same type of user instruction appearing across 3+ sessions (e.g. "summarize today's work", "commit this", "create a PR")
- Same explanation or error appearing more than twice across sessions

**Note:** Permission prompt detection is not included in v1. The JSONL format does not contain reliable markers for approval prompts. This can be added in v2 using `tool-access.log`.

### Output Format

```
Retrospective — 2026-03-20 (N sessions analyzed, last 7 days)

[1] RULE: Add to rules/tools.md
    Change: "Prefer git status before diffing to understand working tree state"
    Reason: User corrected git workflow approach in 2 sessions

[2] SKILL: Create /standup skill
    Reason: User performed "summarize today's work" manually in 4 sessions this week

Apply which? Reply with numbers (e.g. "1 2"), "all", or "none":
```

### Commit Workflow

After applying approved changes:

- The skill commits directly to `main` (no branch required for config-only changes to dotfiles)
- Commit message: `chore(claude): apply retrospect improvements`
- The skill uses `git add` + `git commit` directly (not the `commit` skill, to avoid branching assumptions)
- The commit is made in the dotfiles repo (`/Users/yuyamada/workspace/dotfiles`)

### Allowed Tools

```yaml
allowed-tools:
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(jq:*)
  - Bash(git log:*)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(wc:*)
  - Bash(tail:*)
  - Read:*
  - Edit:*
  - Write:*
```

## Implementation Plan

1. Create `config/claude/skills/retrospect/SKILL.md`
2. Add symlink in `install.sh` (same pattern as other skills)
3. Update `settings.json` `permissions.allow` with:
   - `Read(~/.claude/skills/retrospect/*)`
   - `Read(~/.claude/projects/**)`
4. Run `/reload-plugins` after creation

## Success Criteria

- Running `/retrospect` with at least 3 recent sessions produces at least one proposal with a specific file + change
- A transcript containing the user message "違う、やり直して" immediately after an Edit tool call results in a `[RULE]` proposal in the output
- Applying proposal [1] successfully writes to the target file and the change is visible in `git diff`
- The commit appears in `git log` with the expected message format
