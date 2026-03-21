# Phase 1: Permissions Baseline - Research

**Researched:** 2026-03-21
**Domain:** Claude Code settings.json — permissions, deny block, deprecated syntax migration, sandbox filesystem
**Confidence:** HIGH (all key claims verified against official Claude Code docs)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Scope**
- All changes go to the **project-level** `config/claude/settings.json` only — NOT `~/.claude/settings.json`
- Blast radius limited to this dotfiles repo

**allowedTools — git commands**
Allow (no approval prompt):
- `git add`, `git commit`, `git push`, `git checkout`, `git worktree` (PERM-01)
- `git status`, `git diff`, `git fetch` (read-only, low risk, needed in every workflow)

Do NOT add:
- `git merge`, `git rebase`, `git stash` — not needed; worktrees eliminate stash; merges go via PR

**allowedTools — gh commands**
Allow (no approval prompt):
- `gh pr create`, `gh pr edit`, `gh run watch`, `gh run view` (PERM-02)
- Existing read-only gh commands remain (after deprecated syntax migration)

Do NOT add:
- `gh pr merge` — out of scope for Phase 1; add in v2 if needed

**allowedTools — npm/node ecosystem**
Allow all subcommands for: `npm`, `npx`, `node`, `yarn`, `pnpm`, `bun` (PERM-03)
Pattern: `Bash(npm *)`, `Bash(npx *)`, `Bash(node *)`, `Bash(yarn *)`, `Bash(pnpm *)`, `Bash(bun *)`

**Deny block**
Add a `deny` array to `permissions` with:
- `Bash(git push --force *)` — deny unconditionally
- `Bash(git push -f *)` — deny unconditionally
- `git push --force-with-lease` — do NOT deny (safe variant; checks remote state first)
- `Bash(rm -rf /*)` and `Bash(rm -rf ~*)` — dangerous paths only; `rm -rf ./dist` etc. remain approval-prompted
- `Bash(sudo *)` — privilege escalation risk
- `curl|bash` — NOT denied; leave as approval-prompted (legitimate installer use cases exist)

**Deprecated syntax migration**
- All `Bash(command:*)` entries must be migrated to `Bash(command *)` (space-separated)
- Actual count in settings.json: 22 entries (requirements doc says 11 — that count is stale; migrate all 22)
- Migration must happen **before** expanding any new permissions (RCE risk from stale syntax)
- `List:*`, `Read:*`, `Search:*` use a different format — do not touch these

**Sandbox allowWrite**
- Add `.planning/**` to `sandbox.filesystem.allowWrite` (PERM-06)

### Claude's Discretion

- Exact deny pattern syntax for `rm -rf` (e.g., one entry with glob vs. multiple specific paths)
- Whether `.claude/projects/**` sandbox path needs adding alongside `.planning/**`
- Order of entries in the allow array (keep existing read-only block, append new write commands after)

### Deferred Ideas (OUT OF SCOPE)

- `gh pr merge` — needed for v2 auto-merge workflow; add when RESI-02 is implemented
- `curl|bash` deny — revisited if a security incident occurs; currently left at approval-prompt level
- Additional sandbox paths beyond `.planning/**` — deferred to planner assessment
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PERM-01 | `git add`, `git commit`, `git push`, `git checkout`, `git worktree` が承認なしで実行できる | Bash wildcard patterns `Bash(git add *)` etc. confirmed in official docs |
| PERM-02 | `gh pr create`, `gh pr edit`, `gh run watch`, `gh run view` が承認なしで実行できる | Same wildcard pattern support; confirmed current gh run view syntax |
| PERM-03 | `npm`, `npx`, `node`, `yarn`, `pnpm`, `bun` が承認なしで実行できる | `Bash(npm *)` pattern confirmed; covers all subcommands |
| PERM-04 | `deny` ブロックに `git push --force`, `rm -rf`, `sudo`, `curl\|bash` が明示登録されている | `deny` array syntax confirmed; critical bug caveat documented below |
| PERM-05 | 既存の11個の `:*` 非推奨構文が `space *` 形式に移行されている | Actual count is 22 entries (not 11); legacy `:*` suffix confirmed deprecated |
| PERM-06 | `.planning/**` がサブエージェントからも書き込み可能 (sandbox allowWrite 拡張) | `sandbox.filesystem.allowWrite` path format confirmed; `./` prefix for project-relative |
</phase_requirements>

---

## Summary

Phase 1 modifies a single file — `config/claude/settings.json` — to eliminate approval prompts for the core git/gh/npm development workflow. The work divides into four distinct edits: (1) migrate 22 deprecated `:*` entries to space-separated syntax, (2) add write-capable git and gh commands plus npm ecosystem commands to the `allow` array, (3) add a `deny` array with force-push and privilege-escalation patterns, and (4) extend `sandbox.filesystem.allowWrite` with `.planning/**`.

All syntax has been verified against official Claude Code documentation (code.claude.com/docs). The permission system uses the format `Bash(command *)` where `*` is a glob wildcard; the space before `*` enforces a word boundary so `Bash(npm *)` matches `npm install` but not `npmls`. The legacy `:*` suffix is deprecated and semantically equivalent but must be replaced before adding new entries to avoid ambiguity.

One significant risk has been identified: the `deny` block has known enforcement bugs (GitHub issues #27040, #8961, #6699 — open as of 2026-03-21). The `deny` array entries are part of the formal spec and should be added as documented, but the planner must note that deny rules alone do not provide reliable enforcement. The existing PreToolUse hook (`gsd-prompt-guard.js`) in settings.json is the more reliable enforcement layer for blocking dangerous commands.

**Primary recommendation:** Execute tasks in order — migrate first, then expand allow, then add deny, then fix sandbox — to eliminate RCE risk from stale colon syntax before any capability is granted.

---

## Standard Stack

### Core

| Component | Version/Format | Purpose | Notes |
|-----------|---------------|---------|-------|
| `config/claude/settings.json` | JSON (schemastore) | Project-level Claude Code settings | Only file being modified |
| `permissions.allow` | string array | Commands auto-approved without prompt | Space-wildcard format: `Bash(cmd *)` |
| `permissions.deny` | string array | Commands unconditionally blocked | Must create from scratch — does not yet exist |
| `sandbox.filesystem.allowWrite` | string array | OS-level subprocess write paths | Merged across settings scopes |

### Syntax Reference

**Current deprecated (must migrate):**
```json
"Bash(grep:*)"
"Bash(gh pr view:*)"
"Bash(git log:*)"
```

**Correct current syntax:**
```json
"Bash(grep *)"
"Bash(gh pr view *)"
"Bash(git log *)"
```

**Word boundary behavior (confirmed in official docs):**
- `Bash(npm *)` matches `npm install` — YES
- `Bash(npm *)` matches `npmls` — NO (space enforces word boundary)
- `Bash(npm*)` matches `npmls` — YES (no space, no boundary)

---

## Architecture Patterns

### Recommended settings.json Structure (post-migration)

```json
{
  "permissions": {
    "allow": [
      "List:*",
      "Read:*",
      "Search:*",
      "Bash(grep *)",
      "Bash(ls *)",
      "Bash(diff *)",
      "Bash(find *)",
      "Bash(sed *)",
      "Bash(jq *)",
      "Bash(wc *)",
      "Bash(tail *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git fetch *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(git checkout *)",
      "Bash(git worktree *)",
      "Bash(gh pr view *)",
      "Bash(gh pr diff *)",
      "Bash(gh pr list *)",
      "Bash(gh pr checks *)",
      "Bash(gh pr create *)",
      "Bash(gh pr edit *)",
      "Bash(gh issue view *)",
      "Bash(gh issue list *)",
      "Bash(gh repo view *)",
      "Bash(gh release view *)",
      "Bash(gh run view *)",
      "Bash(gh run watch *)",
      "Bash(gh workflow view *)",
      "Bash(gh project view *)",
      "Bash(gh project list *)",
      "Bash(gh search *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(yarn *)",
      "Bash(pnpm *)",
      "Bash(bun *)"
    ],
    "deny": [
      "Bash(git push --force *)",
      "Bash(git push -f *)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~*)",
      "Bash(sudo *)"
    ]
  }
}
```

### Sandbox allowWrite Extension

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": [
        ".git/config",
        ".git/**",
        "~/.claude/skills/**",
        "~/workspace/dotfiles/.git/config",
        "~/workspace/dotfiles/.git/**",
        ".planning/**"
      ]
    }
  }
}
```

**Path resolution for sandbox allowWrite (confirmed in official docs):**

| Prefix | Resolves to | Example |
|--------|-------------|---------|
| `/` | Absolute path | `/tmp/build` stays `/tmp/build` |
| `~/` | Home directory | `~/.kube` becomes `$HOME/.kube` |
| `./` or no prefix | Project root (for project settings) | `./output` → `<project-root>/output` |

Since `config/claude/settings.json` is the **project settings file**, `.planning/**` (no prefix) resolves relative to the project root — which is correct for this use case.

### Rule Evaluation Order

From official docs: **deny → ask → allow**. First matching rule wins. Deny rules always take precedence regardless of settings scope level.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Blocking force push | Custom shell guard script | `deny` array entry `Bash(git push --force *)` | Native permission system; hooks as backup |
| Blocking sudo | Environment restrictions | `deny` array entry `Bash(sudo *)` | Same layer as other permissions |
| Per-command approval | Manual yolo mode toggling | `allow` array with specific patterns | Persistent, version-controlled, zero friction |
| Subprocess write access | Workaround with excluded commands | `sandbox.filesystem.allowWrite` | OS-level enforcement; merged across scopes |

---

## Common Pitfalls

### Pitfall 1: Deny Block Enforcement Bug
**What goes wrong:** `deny` array entries in project-level `settings.json` are ignored at runtime. Claude executes denied commands without prompting or error.
**Why it happens:** Known open bug in Claude Code (GitHub #27040, #8961, #6699, open as of 2026-03-21). Reported across multiple settings scopes and tool types.
**How to avoid:** Add deny entries as documented (they represent intent and may work when bugs are fixed). For actual enforcement, rely on the existing PreToolUse hook (`gsd-prompt-guard.js`) already wired in settings.json. Adding deny entries is still correct — defense in depth.
**Warning signs:** A denied command (`git push --force`) executes without any prompt or block message.

### Pitfall 2: Word Boundary Confusion with `*`
**What goes wrong:** `Bash(npm*)` without a space matches `npmls` and other commands starting with `npm`. `Bash(npm *)` with a space correctly requires `npm ` as a prefix.
**Why it happens:** The space enforces a word boundary in the glob matcher.
**How to avoid:** Always include a space before `*` when the intent is "any subcommand of X".
**Warning signs:** Unrelated commands like `npmls` become auto-approved.

### Pitfall 3: Migrating `List:*` / `Read:*` / `Search:*`
**What goes wrong:** These three entries use a different format than `Bash(...)` entries and should NOT be migrated to space-separated form. They are tool-level wildcards, not Bash command patterns.
**Why it happens:** The CONTEXT.md explicitly calls this out, but automated migration could touch them if using a naive `:*` → ` *` substitution.
**How to avoid:** Scope the migration regex to only `Bash(...)` entries. The three `List:*`, `Read:*`, `Search:*` entries stay exactly as they are.
**Warning signs:** `Read *` or `List *` appear in settings — these are incorrect.

### Pitfall 4: Ordering — Expand Before Migrate
**What goes wrong:** Adding new `allow` entries in `:*` deprecated form before migrating existing entries creates mixed syntax and potential RCE ambiguity.
**Why it happens:** `:*` suffix and space `*` have slightly different matching semantics in edge cases.
**How to avoid:** Locked decision: migrate all 22 deprecated entries FIRST in a separate commit, then add new entries in a second commit.
**Warning signs:** New entries like `Bash(git push:*)` appear instead of `Bash(git push *)`.

### Pitfall 5: `.planning/**` Path Already Writeable in Some Contexts
**What goes wrong:** Subagents writing to `.planning/**` may fail with sandbox write denied errors even though the parent directory is under the project root.
**Why it happens:** The sandbox default `allowWrite` only covers the current working directory at Bash launch time, not all subdirectories. The project-settings file adds explicit paths; without `.planning/**`, subagent Bash writes (e.g., `cat > file`) are blocked.
**How to avoid:** Add `.planning/**` (no prefix — resolves to project root) to `sandbox.filesystem.allowWrite`.
**Warning signs:** `gsd-tools.cjs commit` or Write tool calls to `.planning/` fail with "Operation not permitted".

### Pitfall 6: `gh run view` Already in Allow List (Deprecated Syntax)
**What goes wrong:** `gh run view:*` is already present in the allow list. Adding `gh run view *` (space form) creates a duplicate after migration.
**Why it happens:** PERM-02 adds `gh run view` but it already exists in the pre-migration list.
**How to avoid:** During migration of the 22 entries, the `gh run view:*` → `gh run view *` conversion covers PERM-02 partially. Only `gh run watch *` and `gh pr create *` and `gh pr edit *` are net-new additions.
**Warning signs:** Duplicate `gh run view *` entries in the allow array.

---

## Code Examples

### Pattern 1: Correct Bash Wildcard (from official docs)
```json
// Source: https://code.claude.com/docs/en/permissions
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "Bash(git * main)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

### Pattern 2: Sandbox allowWrite with path prefixes (from official docs)
```json
// Source: https://code.claude.com/docs/en/sandboxing
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "allowWrite": ["~/.kube", "/tmp/build"]
    }
  }
}
```

### Pattern 3: PreToolUse hook as reliable deny enforcement (community workaround)
```json
// Source: GitHub issue #27040 workaround — for context only;
// gsd-prompt-guard.js already exists in this project's settings.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node \"/Users/yuyamada/.claude/hooks/gsd-prompt-guard.js\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

---

## Current State Inventory

This is a configuration-edit phase (not a rename/refactor), but the current file state is critical.

### Deprecated Entries to Migrate (all 22)

```
Line 11: "Bash(grep:*)"           → "Bash(grep *)"
Line 12: "Bash(ls:*)"             → "Bash(ls *)"
Line 13: "Bash(diff:*)"           → "Bash(diff *)"
Line 14: "Bash(find:*)"           → "Bash(find *)"
Line 15: "Bash(gh pr view:*)"     → "Bash(gh pr view *)"
Line 16: "Bash(gh pr diff:*)"     → "Bash(gh pr diff *)"
Line 17: "Bash(gh pr list:*)"     → "Bash(gh pr list *)"
Line 18: "Bash(gh issue view:*)"  → "Bash(gh issue view *)"
Line 19: "Bash(gh issue list:*)"  → "Bash(gh issue list *)"
Line 20: "Bash(gh repo view:*)"   → "Bash(gh repo view *)"
Line 21: "Bash(gh release view:*)"→ "Bash(gh release view *)"
Line 22: "Bash(gh run view:*)"    → "Bash(gh run view *)"
Line 23: "Bash(gh workflow view:*)"→ "Bash(gh workflow view *)"
Line 24: "Bash(gh project view:*)"→ "Bash(gh project view *)"
Line 25: "Bash(gh project list:*)"→ "Bash(gh project list *)"
Line 26: "Bash(gh pr checks:*)"   → "Bash(gh pr checks *)"
Line 28: "Bash(sed:*)"            → "Bash(sed *)"
Line 29: "Bash(git log:*)"        → "Bash(git log *)"
Line 30: "Bash(git branch:*)"     → "Bash(git branch *)"
Line 31: "Bash(jq:*)"             → "Bash(jq *)"
Line 32: "Bash(wc:*)"             → "Bash(wc *)"
Line 33: "Bash(tail:*)"           → "Bash(tail *)"
```

**Do NOT touch (different format, not deprecated):**
- `"List:*"` (line 8)
- `"Read:*"` (line 9)
- `"Search:*"` (line 10)

### Net-New Allow Entries Required

After migration, add these (none currently exist):

**git write commands (PERM-01):**
- `Bash(git add *)`
- `Bash(git commit *)`
- `Bash(git push *)`
- `Bash(git checkout *)`
- `Bash(git worktree *)`
- `Bash(git status *)` (read-only but needed)
- `Bash(git diff *)` (read-only but needed)
- `Bash(git fetch *)` (read-only but needed)

**gh write commands (PERM-02):**
- `Bash(gh pr create *)`
- `Bash(gh pr edit *)`
- `Bash(gh run watch *)`
- (Note: `gh run view *` is already present after migration)

**npm ecosystem (PERM-03):**
- `Bash(npm *)`
- `Bash(npx *)`
- `Bash(node *)`
- `Bash(yarn *)`
- `Bash(pnpm *)`
- `Bash(bun *)`

### Deny Array (must be created, PERM-04)

```json
"deny": [
  "Bash(git push --force *)",
  "Bash(git push -f *)",
  "Bash(rm -rf /*)",
  "Bash(rm -rf ~*)",
  "Bash(sudo *)"
]
```

**Notes on discretion areas:**
- `rm -rf` deny: Two entries cover the dangerous path prefixes (`/*` = absolute root, `~*` = home dir variants). Local relative paths like `rm -rf ./dist` remain approval-prompted. This is correct per locked decision.
- `curl|bash`: NOT added to deny per locked decision.
- `git push --force-with-lease`: NOT denied (safe force variant).

### Sandbox allowWrite Addition (PERM-06)

Add `.planning/**` to the existing `allowWrite` array. The `.` prefix resolves to project root in project-level settings.

**Claude's discretion — `.claude/projects/**`:**
GSD agents write memory files to `~/.claude/projects/`. The Write tool (not Bash) is used for most file writes, so sandbox `allowWrite` only affects Bash subprocess writes. If GSD agents use `cat >` or other Bash writes to `.claude/projects/`, that path also needs adding. Recommendation: add it preemptively since it's already in the `permissions.allow` Read list (`"Read(~/.claude/projects/**)"`).

---

## Validation Architecture

`nyquist_validation` is enabled in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test framework exists for JSON config changes) |
| Config file | n/a |
| Quick run command | `jq '.permissions.allow | length' config/claude/settings.json` |
| Full suite command | See Phase Requirements test map below |

### Phase Requirements Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PERM-01 | git write commands in allow array | smoke | `jq '.permissions.allow | map(select(startswith("Bash(git "))) | length' config/claude/settings.json` | ✅ |
| PERM-02 | gh write commands in allow array | smoke | `jq '.permissions.allow | map(select(test("gh pr create|gh pr edit|gh run watch"))) | length' config/claude/settings.json` | ✅ |
| PERM-03 | npm ecosystem in allow array | smoke | `jq '.permissions.allow | map(select(test("Bash\\\\(npm |Bash\\\\(npx |Bash\\\\(node |Bash\\\\(yarn |Bash\\\\(pnpm |Bash\\\\(bun "))) | length' config/claude/settings.json` | ✅ |
| PERM-04 | deny block exists with required entries | smoke | `jq '.permissions.deny | length' config/claude/settings.json` | ✅ |
| PERM-05 | No deprecated `:*` in Bash entries | smoke | `grep -c 'Bash([^)]*:\*)' config/claude/settings.json && echo "FAIL: deprecated syntax found" \|\| echo "OK: no deprecated syntax"` | ✅ |
| PERM-06 | .planning/** in sandbox allowWrite | smoke | `jq '.sandbox.filesystem.allowWrite | map(select(contains(".planning"))) | length' config/claude/settings.json` | ✅ |

### Sampling Rate
- **Per task commit:** Run the smoke command for the requirement just addressed
- **Per wave merge:** Run all 6 smoke commands
- **Phase gate:** All 6 green + manual spot-check that `git commit` runs without approval prompt

### Wave 0 Gaps
None — all tests above are simple `jq` and `grep` commands against the existing file; no test framework install required.

---

## Open Questions

1. **`.claude/projects/**` sandbox path**
   - What we know: GSD agents write to `~/.claude/projects/` for memory/context. `Read(~/.claude/projects/**)` is already in allow list.
   - What's unclear: Whether agents use Bash writes (affected by sandbox) vs. Write tool (not affected). The `gsd-context-monitor.js` hook fires on Write tool use, suggesting the Write tool is the primary path.
   - Recommendation: Add `~/.claude/projects/**` to `sandbox.filesystem.allowWrite` preemptively (low risk, prevents future surprises).

2. **Deny block enforcement reliability**
   - What we know: GitHub issues #27040, #6699, #8961 report deny rules being completely ignored (open as of 2026-03-21).
   - What's unclear: Whether project-level deny rules work while local/user-level don't, or if it's pervasive.
   - Recommendation: Add deny entries as documented. The existing `gsd-prompt-guard.js` PreToolUse hook provides actual enforcement. Document in PLAN.md that deny entries are best-effort, hooks are the real safety net.

---

## Sources

### Primary (HIGH confidence)
- [code.claude.com/docs/en/permissions](https://code.claude.com/docs/en/permissions) — Verified: permission rule syntax, wildcard behavior, deny array format, deprecated `:*` documentation
- [code.claude.com/docs/en/sandboxing](https://code.claude.com/docs/en/sandboxing) — Verified: `sandbox.filesystem.allowWrite` format, path prefix semantics, merge behavior across scopes

### Secondary (MEDIUM confidence)
- [GitHub issue #27040](https://github.com/anthropics/claude-code/issues/27040) — deny block enforcement bug, open as of 2026-03-21; multiple related issues confirm systemic problem

### Tertiary (LOW confidence)
- WebSearch results — corroborated by official doc inspection; no unique LOW-confidence claims made

---

## Metadata

**Confidence breakdown:**
- Permission syntax (`allow`/`deny` array format): HIGH — official docs, specific examples
- Wildcard word-boundary behavior: HIGH — explicitly documented with examples
- Deprecated `:*` migration: HIGH — official docs confirm equivalence and deprecation
- Sandbox `allowWrite` path format: HIGH — official docs with path prefix table
- Deny block enforcement reliability: MEDIUM — known bug, open GitHub issues, workaround confirmed
- Net-new entry count (22 deprecated, not 11): HIGH — direct grep of settings.json

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (settings.json format is stable; deny bug status may change sooner)
