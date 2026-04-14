---
name: suggest-permissions
description: Analyze Claude session logs to suggest additions to settings.json's permissions.allow list. Use when tools keep triggering manual approval prompts, when you want to review which commands could be auto-approved, when setting up a new machine, or when you notice repeated permission friction in recent sessions. Covers Bash commands and MCP tools. Flags dangerous patterns separately before proposing any changes.
allowed-tools:
  - Bash(find *)
  - Bash(xargs *)
  - Bash(ls *)
  - Bash(jq *)
  - Bash(sort *)
  - Bash(uniq *)
  - Bash(wc *)
  - Bash(grep *)
  - Bash(sed *)
  - Bash(awk *)
  - Bash(head *)
  - Bash(tail *)
  - Bash(stat *)
  - Bash(echo *)
  - Bash(printf *)
  - Bash(ln *)
  - Read:*
  - Edit:*
  - Write:*
  - Skill:*
---

# Update Permissions from Session Logs

Scans `~/.claude/projects/` session logs to find tools and commands you've approved manually that aren't yet auto-approved in `settings.json`, then proposes additions.

## Phase 1: Scope and Settings

Determine scope (ask the user if not clear from context):
- **User-level** (default): `~/.claude/settings.json` — applies to all projects
- **Project-level**: `<project>/.claude/settings.json` — applies only to one project
- **Time range**: default last 30 days; accept "all time" or "last N days"

Read the current allow list:
```bash
jq -r '.permissions.allow[]? // empty' ~/.claude/settings.json
```

Store the patterns in memory — you'll need them to check coverage in Phase 3.

## Phase 2: Extract Tool Uses from Logs

Find JSONL files for the chosen time range:
```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -30 -print0 2>/dev/null \
  | xargs -0 stat -f "%m %N" 2>/dev/null \
  | sort -rn | awk '{print $2}'
```

Extract Bash first-line commands across all files at once:
```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -30 2>/dev/null \
  | xargs -P4 -I{} jq -r '
      select(.type == "assistant")
      | .message.content[]?
      | select(.type == "tool_use")
      | select(.name == "Bash")
      | (.input.command // "") | split("\n")[0] | ltrimstr(" ")
    ' {} 2>/dev/null \
  | grep -E "^[a-zA-Z][a-zA-Z0-9_-]" \
  | awk '{print $1}' \
  | grep -E "^[a-zA-Z][a-zA-Z0-9_-]+$" \
  | grep -v "/" \
  | sort | uniq -c | sort -rn
```

For CLIs with subcommands (`git`, `gh`, `docker`, `kubectl`, `aws`, `gcloud`), also extract first two words to find partially-uncovered subcommands:
```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -30 2>/dev/null \
  | xargs -P4 -I{} jq -r '
      select(.type == "assistant")
      | .message.content[]?
      | select(.type == "tool_use")
      | select(.name == "Bash")
      | (.input.command // "") | split("\n")[0] | ltrimstr(" ")
    ' {} 2>/dev/null \
  | grep -E "^(git|gh|docker|kubectl|aws|gcloud) " \
  | awk '{print $1, $2}' \
  | sort | uniq -c | sort -rn
```

Extract MCP tool usages:
```bash
find ~/.claude/projects -name "*.jsonl" -not -path "*/subagents/*" -mtime -30 2>/dev/null \
  | xargs -P4 -I{} jq -r '
      select(.type == "assistant")
      | .message.content[]?
      | select(.type == "tool_use")
      | select(.name | startswith("mcp__"))
      | .name
    ' {} 2>/dev/null \
  | sort | uniq -c | sort -rn
```

Key extraction rules:
- **Bash commands**: take only the **first line** of `input.command` (multi-line commands contain heredocs, commit messages, etc. that should be ignored)
- **MCP tools**: use the full `name` field as-is
- Skip built-in tools (Read, Write, Edit, Glob, Grep) — they're almost always covered by wildcard patterns already

## Phase 3: Check Coverage Against Allow List

### For Bash commands

Extract the "base pattern" from each command using this logic:
1. Strip leading comment lines (`# ...`) and blank lines
2. For pipelines/chains (`|`, `&&`, `;`): split into stages and check each stage separately
3. Strip leading env var assignments (e.g., `FOO=bar cmd ...` → `cmd ...`)
4. Extract the first meaningful word as the binary name
5. If the binary contains a `/` (absolute/relative path): **skip** — handled by `pipe-stage-permissions.sh` locally
6. For well-known CLIs with subcommands (`git`, `gh`, `docker`, `kubectl`, `aws`, `gcloud`): use first two words as prefix (e.g., `git push`, `docker run`)
7. Otherwise: use first word only (e.g., `npm`, `python3`, `make`)

Generate the candidate `Bash(prefix *)` pattern from the prefix.

Check coverage: a command is **already covered** if any existing allow pattern is a prefix of it. For example:
- Command `git log --oneline -5` is covered by `Bash(git log *)` or `Bash(git *)`
- Command `docker ps -a` is NOT covered by `Bash(git *)` but IS covered by `Bash(docker *)`

### For MCP tools

A tool like `mcp__plugin_playwright_playwright__browser_navigate` is covered only if the **exact name** appears in the allow list.

## Phase 4: Rank and Present Suggestions

Group uncovered patterns by the suggested allow-list entry, count occurrences across all sessions.

**Classify each entry on two axes: side-effects × risk level.**

### Side-effects axis

Mark each suggested pattern as one of:
- **Read-only** — never modifies files, processes, or external state. Safe to auto-approve freely.
  - Examples: `cat`, `echo`, `head`, `printf`, `wc`, `which`, `sleep`, `diff`, read-only git (`git log`, `git diff`, `git status`, `git fetch`), read-only gh (`gh pr view`, `gh issue list`), MCP tools with "search", "fetch", "read", "list" in the name
- **Side-effects** — creates/modifies/deletes files, spawns processes, sends data externally, or changes system state. Needs explicit review even if low-risk.
  - Examples: `mkdir`, `ln`, `cp`, `touch`, `mv`, `curl`, `wget`, `gcloud`, `kubectl`, `aws`, `docker`, `git push`, `gh pr create`, `python3`, `node`, write-type MCP tools (update-page, create-pages, send-message)

### Risk axis

🔴 **High risk — never suggest auto-approving:**
- `rm` with `-r`, `-f`, or `--force` flags
- `git push --force` / `git push -f`
- `sudo`
- `git reset --hard`
- `dd`, `mkfs`
- Anything already in `permissions.deny`

⚠️ **Side-effects + elevated risk — present separately for explicit review:**
- `curl`, `wget` — network calls to arbitrary URLs
- `python3`, `node`, `ruby` — arbitrary code execution
- `docker`, `kubectl`, `gcloud`, `aws` — infrastructure with broad reach
- `git push` — remote write
- `gh pr create`, `gh pr merge`, `gh pr edit` — GitHub write operations
- `rm` (without force flags), `chmod`, `chown`

📝 **Side-effects + low risk — suggest but note they modify state:**
- `mkdir`, `ln`, `cp`, `touch`, `mv` — local filesystem writes
- `make`, `cargo build`, `go build` — build artifacts
- MCP write tools (notion-update, slack-send, etc.) — external service writes

✅ **Read-only — safe to suggest:**
- `cat`, `echo`, `head`, `printf`, `wc`, `which`, `sleep`, `diff`
- Read-only git and gh subcommands
- MCP tools with read/search/fetch/list semantics

Present results in three sections:

### ✅ Read-only — Safe to Add
| # | Pattern | Count | Example |
|---|---------|-------|---------|
| 1 | `Bash(cat *)` | 114 | `cat file.txt` |

### 📝 Side-effects — Review Recommended
| # | Pattern | Count | Side-effects | Example |
|---|---------|-------|--------------|---------|
| 1 | `Bash(mkdir *)` | 34 | creates dirs | `mkdir -p dist/` |
| 2 | `mcp__plugin_Notion_notion__notion-update-page` | 67 | modifies Notion | — |

### ⚠️ Side-effects + Elevated Risk — Explicit Confirmation Required
| # | Pattern | Count | Risk | Example |
|---|---------|-------|------|---------|
| 1 | `Bash(gcloud *)` | 168 | infra write | `gcloud run deploy` |
| 2 | `Bash(python3 *)` | 33 | code exec | `python3 analyze.py` |

**Do NOT present 🔴 high-risk patterns as candidates for addition.** Mention them in a closing note: "N commands (e.g. `rm -rf`, `sudo`) were excluded — they were used in sessions but are intentionally not suggested."

## Phase 5: Apply Changes

After the user confirms which patterns to add, use the `update-config` skill to apply them to `settings.json`.

If the user selects patterns from the ⚠️ flagged section, acknowledge the risk briefly and confirm before proceeding.

## Tips

- If the same command appears in many projects, that's a stronger signal it belongs in user-level settings
- MCP tool names are verbose but exact — add them as-is; there's no wildcard for MCP tools
- After applying, remind the user to reload if Claude Code is currently running
