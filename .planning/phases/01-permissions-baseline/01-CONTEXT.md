# Phase 1: Permissions Baseline - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Expand `allowedTools` for git/gh/npm write commands, add an explicit deny block for dangerous patterns, migrate all deprecated `:*` syntax entries to space-separated form, and extend sandbox `allowWrite` to include `.planning/**`. Result: Claude can run the full git/gh/npm workflow without approval prompts.

</domain>

<decisions>
## Implementation Decisions

### Scope
- All changes go to the **project-level** `config/claude/settings.json` only — NOT `~/.claude/settings.json`
- Blast radius limited to this dotfiles repo

### allowedTools — git commands
Allow (no approval prompt):
- `git add`, `git commit`, `git push`, `git checkout`, `git worktree` (PERM-01)
- `git status`, `git diff`, `git fetch` (read-only, low risk, needed in every workflow)

Do NOT add:
- `git merge`, `git rebase`, `git stash` — not needed; worktrees eliminate stash; merges go via PR

### allowedTools — gh commands
Allow (no approval prompt):
- `gh pr create`, `gh pr edit`, `gh run watch`, `gh run view` (PERM-02)
- Existing read-only gh commands remain (after deprecated syntax migration)

Do NOT add:
- `gh pr merge` — out of scope for Phase 1; add in v2 if needed

### allowedTools — npm/node ecosystem
Allow all subcommands for: `npm`, `npx`, `node`, `yarn`, `pnpm`, `bun` (PERM-03)
Pattern: `Bash(npm *)`, `Bash(npx *)`, `Bash(node *)`, `Bash(yarn *)`, `Bash(pnpm *)`, `Bash(bun *)`

### Deny block
Add a `deny` array to `permissions` with:
- `Bash(git push --force *)` — deny unconditionally
- `Bash(git push -f *)` — deny unconditionally
- `git push --force-with-lease` — **do NOT deny** (safe variant; checks remote state first)
- `Bash(rm -rf /*)` and `Bash(rm -rf ~*)` — dangerous paths only; `rm -rf ./dist` etc. remain approval-prompted
- `Bash(sudo *)` — privilege escalation risk
- `curl|bash` — NOT denied; leave as approval-prompted (legitimate installer use cases exist)

### Deprecated syntax migration
- **All** `Bash(command:*)` entries must be migrated to `Bash(command *)` (space-separated)
- Actual count in settings.json: 22 entries (requirements doc says 11 — that count is stale; migrate all 22)
- Migration must happen **before** expanding any new permissions (RCE risk from stale syntax)
- `List:*`, `Read:*`, `Search:*` use a different format — do not touch these

### Sandbox allowWrite
- Add `.planning/**` to `sandbox.filesystem.allowWrite` (PERM-06)
- Claude's Discretion: whether `.claude/projects/**` also needs extension (planner to assess based on GSD agent write patterns)

### Claude's Discretion
- Exact deny pattern syntax for `rm -rf` (e.g., one entry with glob vs. multiple specific paths)
- Whether `.claude/projects/**` sandbox path needs adding alongside `.planning/**`
- Order of entries in the allow array (keep existing read-only block, append new write commands after)

</decisions>

<specifics>
## Specific Ideas

- `git push --force-with-lease` must remain executable — it is the safe alternative to force-push and is used in rebase-then-push workflows
- `curl|bash` should stay at approval-prompt level (not denied) because Homebrew/asdf/etc. use this pattern legitimately

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current settings structure
- `config/claude/settings.json` — The file being modified. Read it before planning any edits to understand current entry count, structure, and existing patterns.

### Requirements
- `.planning/REQUIREMENTS.md` — PERM-01 through PERM-06 definitions. Planner must verify every requirement ID is addressed by at least one task.

### Project state
- `.planning/STATE.md` — Contains two pre-existing decisions: project-scope-only and migrate-before-expand order.

</canonical_refs>

<code_context>
## Existing Code Insights

### Current allowedTools structure
- Read-only git: `git log:*`, `git branch:*` (deprecated syntax — will be migrated)
- Read-only gh: `gh pr view:*`, `gh pr diff:*`, `gh pr list:*`, `gh issue view:*`, `gh issue list:*`, `gh repo view:*`, `gh release view:*`, `gh run view:*`, `gh workflow view:*`, `gh project view:*`, `gh project list:*`, `gh pr checks:*`, `gh search *` (deprecated)
- Shell utils: `grep:*`, `ls:*`, `diff:*`, `find:*`, `sed:*`, `jq:*`, `wc:*`, `tail:*` (deprecated)
- Already space-separated: `gh search *`, `~/.claude/skills/my-tasks/scripts/*`

### No deny block exists
- `permissions` object has only `allow` array — `deny` array must be created from scratch

### Sandbox allowWrite paths
- Current: `.git/config`, `.git/**`, `~/.claude/skills/**`, `~/workspace/dotfiles/.git/config`, `~/workspace/dotfiles/.git/**`
- Missing: `.planning/**` (subagent write target)

</code_context>

<deferred>
## Deferred Ideas

- `gh pr merge` — needed for v2 auto-merge workflow; add when RESI-02 is implemented
- `curl|bash` deny — revisited if a security incident occurs; currently left at approval-prompt level
- Additional sandbox paths beyond `.planning/**` — deferred to planner assessment

</deferred>

---

*Phase: 01-permissions-baseline*
*Context gathered: 2026-03-21*
