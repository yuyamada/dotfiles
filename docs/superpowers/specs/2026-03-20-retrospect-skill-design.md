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
- Analysis of `tool-access.log` (out of scope for v1; transcripts are the primary source)
- Fully autonomous changes without user approval

## Architecture

### File Location

```
config/claude/skills/retrospect/
└── SKILL.md
```

Symlinked to `~/.claude/skills/retrospect` via `install.sh`.

### Skill Flow

```
/retrospect invoked
    ↓
Collect recent JSONL transcripts
  - Source: ~/.claude/projects/ (all subdirectories)
  - Scope: sessions from the last 7 days (by file mtime)
    ↓
Claude reads transcripts and classifies signals into three categories:
  [RULE]       → addition/edit to rules/*.md
  [SKILL]      → new skill or improvement to existing skill
  [PERMISSION] → addition to settings.json allow list
    ↓
Present numbered proposal list with: target file, change, reason
    ↓
User selects which proposals to apply (by number or "all"/"none")
    ↓
Apply approved changes via Edit/Write tools
Invoke commit skill to record changes
```

### Signal Detection Logic

The following signals indicate configuration improvement opportunities:

**User correction signals**
- User messages containing correction language ("no", "違う", "やり直し", "そうじゃなくて", "that's wrong") followed by Claude re-attempting the same task
- Multiple Edit/Write calls to the same file within a single turn (indicates first attempt was rejected)

**Permission prompt signals**
- Bash tool calls that triggered approval prompts (identifiable from transcript context)
- Same command pattern appearing across multiple sessions without being in the `allow` list

**Repetition signals**
- Same type of user instruction appearing across multiple sessions ("summarize today's work", "commit this")
- Same error pattern or explanation appearing more than twice

### Output Format

```
Retrospective — 2026-03-20 (5 sessions analyzed)

[1] PERMISSION: Add "Bash(git status:*)" to settings.json allow list
    Reason: Triggered approval prompts in 3 separate sessions

[2] RULE: Add to rules/tools.md — prefer git status over manual file diffing
    Reason: Pattern of requesting git status followed by corrections about approach

[3] SKILL: Create /standup skill
    Reason: User performed "summarize today's work" manually in 4 sessions this week

Apply which? (e.g. "1 3", "all", "none"):
```

### Allowed Tools

The skill declares these tools to avoid approval prompts during execution:

```yaml
allowed-tools:
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(jq:*)
  - Bash(git log:*)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Read:*
  - Edit:*
  - Write:*
  - Skill(commit)
```

## Implementation Plan

1. Create `config/claude/skills/retrospect/SKILL.md`
2. Add symlink in `install.sh` (same pattern as other skills)
3. Update `settings.json` `permissions.allow` with `Read(~/.claude/skills/retrospect/*)`
4. Test with a real session transcript

## Success Criteria

- Running `/retrospect` surfaces at least one actionable proposal per 5 sessions
- Proposals include specific file + change, not vague suggestions
- Approved changes are applied cleanly and committed without manual intervention
