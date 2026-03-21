# Stack Research: Claude Code Permissions Architecture

**Analysis Date:** 2026-03-21
**Confidence:** HIGH (direct source analysis + official docs)

## Current State Audit

### Deprecated Patterns (11 found)
The current `settings.json` uses the old `:*` suffix syntax which should be migrated to the modern space-separated syntax:

```json
// Deprecated (old)
"Bash(git log:*)"

// Modern (correct)
"Bash(git log *)"
```

### Missing Command Categories (5 major gaps)

| Category | Commands Needed | Current Status |
|----------|----------------|----------------|
| Git write ops | `git add`, `git commit`, `git push`, `git checkout`, `git merge`, `git rebase` | ✗ Missing |
| GitHub CLI write | `gh pr create`, `gh pr edit`, `gh issue create`, `gh pr merge` | ✗ Missing |
| Node/npm ecosystem | `npm`, `npx`, `yarn`, `pnpm`, `bun`, `node` | ✗ Missing |
| Test runners | `jest`, `vitest`, `mocha`, `pytest`, `go test`, `cargo test` | ✗ Missing |
| Linters/formatters | `eslint`, `prettier`, `ruff`, `gofmt`, `rustfmt` | ✗ Missing |

## Correct Permissions Architecture

### Two-Layer Model

```
Layer 1: sandbox.filesystem / sandbox.network  (OS-level, hard limits)
Layer 2: permissions.allow / permissions.deny   (Claude decision layer)
```

These serve different purposes — both should be used together:
- **Sandbox** = hard limits (cannot be overridden by prompt injection)
- **Permissions** = Claude's decision scope (what it autonomously chooses to do)

### Recommended allowedTools Pattern

Use **category-level wildcards + explicit deny rules** rather than enumerating every subcommand:

```json
"permissions": {
  "allow": [
    "Bash(git *)",
    "Bash(gh *)",
    "Bash(npm *)",
    "Bash(npx *)",
    "Bash(node *)",
    "Bash(yarn *)",
    "Bash(pnpm *)",
    "Bash(bun *)",
    "Bash(cat *)",
    "Bash(head *)",
    "Bash(tail *)",
    "Bash(echo *)",
    "Bash(which *)",
    "Bash(mkdir *)",
    "Bash(touch *)",
    "Bash(cp *)",
    "Bash(mv *)",
    "Bash(ls *)",
    "Bash(find *)",
    "Bash(jq *)",
    "Bash(sed *)",
    "Bash(awk *)",
    "Bash(diff *)",
    "Bash(wc *)",
    "Bash(sort *)",
    "Bash(uniq *)",
    "Bash(grep *)",
    "Bash(rg *)"
  ],
  "deny": [
    "Bash(git push --force*)",
    "Bash(git push -f *)",
    "Bash(git reset --hard *)",
    "Bash(git clean -f*)",
    "Bash(rm -rf *)",
    "Bash(sudo *)",
    "Bash(chmod 777 *)",
    "Bash(curl * | bash)",
    "Bash(wget * | bash)"
  ]
}
```

### Settings Layering

```
~/.claude/settings.json         ← global defaults (universal dev commands)
<project>/.claude/settings.json ← per-repo overrides (project-specific tools)
<project>/.claude/settings.local.json ← machine-specific (never commit)
```

**Global settings.json** is the right place for the universal dev command list above.
**Project settings** should add project-specific test commands (e.g., `Bash(make *)`).

### Sandbox Fixes Needed

The current sandbox `filesystem.write.allowOnly` is missing the project working directory:

```json
// Current — writing to project files may be blocked
"allowOnly": ["/tmp/claude", ".", "/Users/yuyamada/.claude/skills", ...]

// The "." entry should cover the cwd, but .planning/ subdirectories
// may not be accessible to subagents running in different cwd contexts
// Fix: explicitly add the planning paths in project-level config
```

## Security Boundaries (Non-Negotiable)

Even in YOLO mode, these should always require a prompt or be denied:

- `rm -rf` with absolute paths outside project
- `git push --force` to main/master
- `sudo` commands
- Piping remote content to shell (`curl | bash`)
- Writing to `~/.ssh/`, `~/.aws/`, `~/.config/` outside project scope
- Modifying `settings.json` or `settings.local.json` (credentials risk)

## Skill-Level Permissions

Each skill's `allowed-tools` frontmatter should also be updated from deprecated syntax:

```markdown
---
# SKILL.md — deprecated
allowed-tools: Bash(git log:*), Bash(git status:*)

# SKILL.md — modern
allowed-tools: Bash(git log *), Bash(git status *)
---
```

## Open Questions for Requirements

1. Should `Bash(rm *)` be allowed (with `-rf` specifically denied), or require prompts entirely?
2. Should `Bash(docker *)` be included? (Not in current repo but common in dev workflows)
3. Is `.planning/**` intentionally excluded from sandbox allowWrite, or should it be added?

---
*Stack analysis: 2026-03-21*
