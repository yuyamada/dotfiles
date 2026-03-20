# Retrospect Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `/retrospect` Claude Code skill that reads recent JSONL transcripts, proposes config improvements, and applies approved changes.

**Architecture:** A single SKILL.md file in `config/claude/skills/retrospect/` that is auto-symlinked by `install.sh`. Two entries are added to `settings.json`: sandbox `allowWrite` is expanded to permit git commits, and two `permissions.allow` entries document the skill's access (note: `Read:*` already exists globally, so these entries are documentation-only and harmless).

**Tech Stack:** Claude Code skills (markdown), bash (find/tail/jq), settings.json permissions

**Spec:** `docs/superpowers/specs/2026-03-20-retrospect-skill-design.md`

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `config/claude/skills/retrospect/SKILL.md` | Skill instructions for Claude |
| Modify | `config/claude/settings.json` | Expand sandbox allowWrite + add permission entries |
| Create (runtime) | `~/.claude/skills/retrospect` → above dir | Symlink (manual for this session) |

Note: `install.sh` already loops over `config/claude/skills/*/` and symlinks each directory automatically on fresh installs.

---

## Task 1: Create the Skill Directory and SKILL.md

**Files:**
- Create: `config/claude/skills/retrospect/SKILL.md`

- [ ] **Step 1.1: Create the skill directory**

```bash
mkdir -p /Users/yuyamada/workspace/dotfiles/config/claude/skills/retrospect
```

- [ ] **Step 1.2: Write SKILL.md**

Create `config/claude/skills/retrospect/SKILL.md` with this exact content:

````markdown
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
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -7 -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -10
```

If this returns no files, report "No sessions found in the last 7 days" and stop.

For each file: check its size first:
```bash
wc -c <file>
```

If it exceeds 200000 bytes, read only the last 200 KB:
```bash
tail -c 200000 <file>
```
Otherwise read the full file with the Read tool.

Record the count of files read (N).

## Phase 2: Analyze for Signals

Read each transcript and look for these signals:

**[RULE] signals — indicate a workflow or tooling rule is missing:**
- User messages containing correction language: "no", "違う", "やり直", "そうじゃなくて", "ちがう", "that's wrong", "don't do that", "やめて" — especially when followed by Claude re-attempting the same task
- A user correction message that immediately follows a sequence of Edit or Write tool calls in the same conversation

**[SKILL] signals — indicate a missing skill:**
- The same type of user request (by intent, not exact wording) appears 3 or more times across different sessions — for example "今日やったことまとめて", "コミットして", "PR作って" — but only if no existing skill in `~/.claude/skills/` already handles it

If no signals are found, report "No improvement opportunities detected in the last N sessions" and stop.

## Phase 3: Present Proposals

Output exactly this format:

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

**For [RULE] proposals:** Use the Edit tool to append the new rule to the target file under `~/workspace/dotfiles/config/claude/`. Follow the existing formatting style of that file (look at surrounding content before editing).

**For [SKILL] proposals:** Inform the user: "To create the /<name> skill, use the skill-creator skill: `/skill-creator`". Do not create the skill directly.

After applying all file changes, commit from the dotfiles repo:

```bash
cd ~/workspace/dotfiles && git add config/claude/ && git commit -m "chore(claude): apply retrospect improvements"
```

Confirm: "Applied [N] change(s) and committed."
````

- [ ] **Step 1.3: Verify the file was created**

```bash
head -5 /Users/yuyamada/workspace/dotfiles/config/claude/skills/retrospect/SKILL.md
```

Expected: YAML frontmatter starting with `---` and `name: retrospect`.

- [ ] **Step 1.4: Commit**

```bash
cd /Users/yuyamada/workspace/dotfiles
git add config/claude/skills/retrospect/SKILL.md
git commit -m "feat(claude): add retrospect skill for continuous config improvement"
```

---

## Task 2: Update settings.json

**Files:**
- Modify: `config/claude/settings.json`

Two changes are needed:
1. Expand `sandbox.filesystem.allowWrite` to include `.git/**` so the skill's git commit is not blocked
2. Add two `permissions.allow` entries for documentation (note: `Read:*` already exists globally, these entries are redundant but harmless and explicit)

- [ ] **Step 2.1: Read the current settings.json**

Read `config/claude/settings.json` to confirm the current structure before editing.

- [ ] **Step 2.2: Add sandbox allowWrite entry for .git/**

Locate the `sandbox.filesystem.allowWrite` array. It currently contains `[".git/config"]`. Change it to:

```json
"allowWrite": [".git/config", ".git/**"]
```

- [ ] **Step 2.3: Add permission entries**

In `permissions.allow`, add these two entries after the last existing entry (`"mcp__google-developer-knowledge__batch_get_documents"`):

```json
      "Read(~/.claude/skills/retrospect/*)",
      "Read(~/.claude/projects/**)"
```

The end of the array should become:

```json
      "mcp__google-developer-knowledge__batch_get_documents",
      "Read(~/.claude/skills/retrospect/*)",
      "Read(~/.claude/projects/**)"
    ]
```

- [ ] **Step 2.4: Validate JSON syntax**

```bash
jq . /Users/yuyamada/workspace/dotfiles/config/claude/settings.json > /dev/null && echo "JSON valid"
```

Expected: `JSON valid`

- [ ] **Step 2.5: Commit**

```bash
cd /Users/yuyamada/workspace/dotfiles
git add config/claude/settings.json
git commit -m "chore(claude): expand sandbox allowWrite and add retrospect permissions"
```

---

## Task 3: Create Symlink and Reload

- [ ] **Step 3.1: Create the symlink**

```bash
cd /Users/yuyamada/workspace/dotfiles
ln -sf "$(pwd)/config/claude/skills/retrospect" ~/.claude/skills/retrospect
```

- [ ] **Step 3.2: Verify symlink is correct**

```bash
ls -la ~/.claude/skills/retrospect
ls ~/.claude/skills/retrospect/
```

Expected: symlink pointing to the dotfiles directory, with `SKILL.md` visible inside.

- [ ] **Step 3.3: Reload plugins (manual)**

In Claude Code terminal, run:
```
/reload-plugins
```

Verify `retrospect` appears in the available skills list.

---

## Task 4: End-to-End Verification

- [ ] **Step 4.1: Verify transcripts are findable**

```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -7 -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -10
```

Expected: 1-10 JSONL paths. If none, there are no sessions in the last 7 days — check with `-mtime -30` to confirm files exist.

- [ ] **Step 4.2: Verify a transcript contains correction language**

To test the correction-signal detection, check if any recent transcript contains a known correction word:

```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -7 -print0 2>/dev/null \
  | xargs -0 grep -l "違う\|やり直\|そうじゃ\|ちがう" 2>/dev/null | head -3
```

If matches are found, note the file paths — these sessions should produce [RULE] proposals when the skill runs.

If no matches, the skill will likely report "No improvement opportunities detected" which is still a valid (correct) outcome.

- [ ] **Step 4.3: Invoke the skill**

Run `/retrospect` in Claude Code. Confirm:
- Output header shows `(N sessions analyzed, last 7 days)` with N > 0
- If step 4.2 found correction language: at least one `[RULE]` proposal appears
- If step 4.2 found no correction language: "No improvement opportunities detected" is reported

Both outcomes confirm the skill is working correctly.

- [ ] **Step 4.4: Test rejection path**

If proposals appeared in 4.3, reply `none`. Confirm "No changes applied." is shown and `git status` shows no uncommitted changes.

- [ ] **Step 4.5: Verify sandbox does not block git commit (if a proposal was applied)**

If you applied at least one proposal, verify the commit succeeded:

```bash
git -C ~/workspace/dotfiles log --oneline -1
```

Expected: the commit message `chore(claude): apply retrospect improvements` appears.
