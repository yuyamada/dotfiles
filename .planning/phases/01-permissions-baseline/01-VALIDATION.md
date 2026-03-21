---
phase: 1
slug: permissions-baseline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (`jq` + `grep` against JSON config) |
| **Config file** | `config/claude/settings.json` |
| **Quick run command** | `jq '.permissions.allow | length' config/claude/settings.json` |
| **Full suite command** | Run all 6 smoke commands in Per-Task Verification Map |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smoke command for the requirement just addressed
- **After every plan wave:** Run all 6 smoke commands
- **Before `/gsd:verify-work`:** Full suite must be green + manual spot-check that `git commit` runs without approval prompt
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01-01 | 1 | PERM-05 | smoke | `grep -c 'Bash([^)]*:\*)' config/claude/settings.json && echo "FAIL: deprecated syntax found" \|\| echo "OK: no deprecated syntax"` | ✅ | ⬜ pending |
| 1-02-01 | 01-02 | 2 | PERM-01 | smoke | `jq '.permissions.allow \| map(select(startswith("Bash(git "))) \| length' config/claude/settings.json` | ✅ | ⬜ pending |
| 1-02-02 | 01-02 | 2 | PERM-02 | smoke | `jq '.permissions.allow \| map(select(test("gh pr create\|gh pr edit\|gh run watch"))) \| length' config/claude/settings.json` | ✅ | ⬜ pending |
| 1-02-03 | 01-02 | 2 | PERM-03 | smoke | `jq '.permissions.allow \| map(select(test("Bash\\(npm \|Bash\\(npx \|Bash\\(node \|Bash\\(yarn \|Bash\\(pnpm \|Bash\\(bun "))) \| length' config/claude/settings.json` | ✅ | ⬜ pending |
| 1-03-01 | 01-03 | 2 | PERM-04 | smoke | `jq '.permissions.deny \| length' config/claude/settings.json` | ✅ | ⬜ pending |
| 1-04-01 | 01-04 | 2 | PERM-06 | smoke | `jq '.sandbox.filesystem.allowWrite \| map(select(contains(".planning"))) \| length' config/claude/settings.json` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no test framework install needed. All verification is via `jq` and `grep` against the existing `config/claude/settings.json` file.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `git commit` runs without approval prompt | PERM-01 | Requires live Claude Code session to observe prompt behavior | Run a GSD workflow step; confirm no approval dialog appears for `git commit` |
| `deny` block actually blocks `git push --force` | PERM-04 | Deny block has known enforcement bugs (GitHub #27040, #8961, #6699); automated check only confirms entry exists | Attempt `git push --force` in Claude Code; confirm it is blocked or triggers the PreToolUse hook |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
