---
phase: 01-permissions-baseline
verified: 2026-03-21T03:00:00Z
status: passed
score: 7/7 must-haves verified
re_verification: false
---

# Phase 1: Permissions Baseline Verification Report

**Phase Goal:** Establish a safe, complete permissions baseline in settings.json — migrating deprecated syntax and adding git/gh/npm write commands with a deny block for dangerous patterns.
**Verified:** 2026-03-21T03:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | `git commit`, `git push`, `git worktree`, `gh pr create`, `npm test` produce zero approval prompts | ✓ VERIFIED | All entries present in `permissions.allow`: `Bash(git commit *)`, `Bash(git push *)`, `Bash(git worktree *)`, `Bash(gh pr create *)`, `Bash(npm *)` |
| 2   | `git push --force`, `rm -rf`, and `sudo` are in deny block; `curl\|bash` remains approval-prompted | ✓ VERIFIED | `permissions.deny` has 5 entries: `Bash(git push --force *)`, `Bash(git push -f *)`, `Bash(rm -rf /*)`, `Bash(rm -rf ~*)`, `Bash(sudo *)`; `curl` count in deny = 0 |
| 3   | All 22 deprecated `:*` entries replaced with space-separated syntax | ✓ VERIFIED | `grep -c 'Bash([^)]*:\*)' config/claude/settings.json` returns 0; all 22 entries confirmed present in `Bash(command *)` form |
| 4   | Subagents writing to `.planning/**` succeed without sandbox errors | ✓ VERIFIED | `.planning/**` present in `sandbox.filesystem.allowWrite` (6-entry array, index 5) |

**Score:** 4/4 success criteria verified

### Additional Must-Have Truths (from PLAN frontmatter)

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 5   | `List:*`, `Read:*`, `Search:*` entries unchanged | ✓ VERIFIED | Each has exactly 1 match in allow array; no colon migration touched them |
| 6   | No functional regression — all previously allowed commands remain allowed | ✓ VERIFIED | All 22 migrated entries confirmed present in space form; allow array grew from ~47 to 64 entries (17 net-new added as planned) |
| 7   | `git push --force-with-lease` NOT in deny block | ✓ VERIFIED | `jq '.permissions.deny | map(select(test("force-with-lease"))) | length'` returns 0 |

**Overall Score:** 7/7 must-haves verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `config/claude/settings.json` | Complete permissions baseline with allow, deny, and sandbox sections | ✓ VERIFIED | File exists, valid JSON, contains all required allow entries (64 total), deny block (5 entries), sandbox allowWrite (6 entries) |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `permissions.allow` with `Bash(git commit *)` | Claude Code permission engine | allow array entries auto-approve matching commands | ✓ WIRED | Pattern `Bash(git commit *)` present at line 45 of settings.json |
| `permissions.deny` with `Bash(git push --force *)` | Claude Code permission engine | deny array entries block matching commands | ✓ WIRED | Pattern present at line 8 of settings.json; backup enforcement via `gsd-prompt-guard.js` PreToolUse hook |
| `sandbox.filesystem.allowWrite` with `.planning/**` | OS-level sandbox enforcement | allowWrite paths permit subprocess file writes | ✓ WIRED | `.planning/**` present at line 184 of settings.json |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| PERM-01 | 01-02-PLAN.md | `git add`, `git commit`, `git push`, `git checkout`, `git worktree` run without approval | ✓ SATISFIED | 5 git write entries present; `jq` query returns 5 |
| PERM-02 | 01-02-PLAN.md | `gh pr create`, `gh pr edit`, `gh run watch` run without approval | ✓ SATISFIED | 3 gh write entries present; query returns 3 |
| PERM-03 | 01-02-PLAN.md | `npm`, `npx`, `node`, `yarn`, `pnpm`, `bun` run without approval | ✓ SATISFIED | 6 npm ecosystem entries present; query returns 6 |
| PERM-04 | 01-02-PLAN.md | `deny` block contains `git push --force`, `rm -rf`, `sudo`; `curl\|bash` not denied | ✓ SATISFIED | Deny block has exactly 5 entries; curl count = 0; force-with-lease count = 0 |
| PERM-05 | 01-01-PLAN.md | All 22 deprecated `:*` entries migrated to space-separated syntax | ✓ SATISFIED | `grep -c 'Bash([^)]*:\*)'` returns 0; all 22 space-form entries confirmed |
| PERM-06 | 01-02-PLAN.md | `.planning/**` in `sandbox.filesystem.allowWrite` | ✓ SATISFIED | Present at index 5 of allowWrite array; total length = 6 |

All 6 phase requirements satisfied. No orphaned requirements detected — REQUIREMENTS.md Traceability table maps PERM-01 through PERM-06 to Phase 1, all covered by plans 01-01 and 01-02.

### Anti-Patterns Found

No anti-patterns detected. `config/claude/settings.json` is a pure data file (JSON configuration) with no placeholder values, TODO comments, or stub patterns. All entries are concrete, non-empty permission strings.

### Human Verification Required

#### 1. Approval-prompt behavior at runtime

**Test:** In a fresh Claude Code session, run `git status`, `git add .`, `git commit -m "test"`, `git push`, `gh pr create --draft --title "test" --body "test"`, `npm test` in sequence.
**Expected:** Zero approval prompt dialogs appear for any of these commands.
**Why human:** Permission enforcement is runtime behavior — grep can verify the entries exist in settings.json but cannot verify Claude Code's permission engine reads and applies them correctly.

#### 2. Deny block enforcement

**Test:** Attempt to run `git push --force origin main` and `sudo ls` in a Claude Code session.
**Expected:** Commands are blocked unconditionally (no approval prompt offered — hard deny).
**Why human:** The SUMMARY notes a known Claude Code bug (GitHub #27040) affecting deny enforcement. Cannot verify runtime denial behavior from file inspection alone.

#### 3. Sandbox write enforcement

**Test:** In a subagent (Task tool), attempt to write a file to `.planning/test-write.txt`.
**Expected:** Write succeeds without a sandbox permission error.
**Why human:** Sandbox enforcement is OS-level at runtime; file inspection confirms the path is listed but cannot verify the sandbox actually allows the write.

### Gaps Summary

No gaps. All 6 requirements verified against the actual codebase. Phase goal achieved.

---

## Verification Evidence (Raw)

```
grep -c 'Bash([^)]*:\*)' config/claude/settings.json   → 0   (PERM-05: no deprecated syntax)
jq '.permissions.allow | map(select(test("Bash\\(git (add|commit|push|checkout|worktree) "))) | length'  → 5   (PERM-01)
jq '.permissions.allow | map(select(test("Bash\\(git (status|diff|fetch) "))) | length'                  → 3   (PERM-01 read helpers)
jq '.permissions.allow | map(select(test("gh pr create|gh pr edit|gh run watch"))) | length'              → 3   (PERM-02)
jq '.permissions.allow | map(select(test("Bash\\(npm |npx |node |yarn |pnpm |bun "))) | length'           → 6   (PERM-03)
jq '.permissions.deny | length'                                                                            → 5   (PERM-04)
jq '.permissions.deny | map(select(test("curl"))) | length'                                                → 0   (PERM-04: curl not denied)
jq '.permissions.deny | map(select(test("force-with-lease"))) | length'                                   → 0   (PERM-04: safe variant not denied)
jq '.sandbox.filesystem.allowWrite | map(select(contains(".planning"))) | length'                         → 1   (PERM-06)
jq '.sandbox.filesystem.allowWrite | length'                                                               → 6   (PERM-06)
grep -c 'List:\*'   → 1   (PERM-05: preserved)
grep -c 'Read:\*'   → 1   (PERM-05: preserved)
grep -c 'Search:\*' → 1   (PERM-05: preserved)
jq . config/claude/settings.json → exit 0 (valid JSON)
```

**Commits verified:**
- `2bd0f41` — feat(01-01): migrate 22 deprecated Bash(command:*) to Bash(command *) syntax
- `3e96086` — feat(01-02): add git/gh/npm write commands to permissions.allow
- `08b274f` — feat(01-02): add deny block and extend sandbox allowWrite

---

_Verified: 2026-03-21T03:00:00Z_
_Verifier: Claude (gsd-verifier)_
