# Roadmap: Claude Code 自律開発設定

## Overview

Three phases to eliminate every human approval prompt from the task-to-PR cycle. Phase 1 fixes the permission baseline (the hard dependency everything else needs). Phase 2 removes confirmation gates from the commit and pr skills. Phase 3 adds the agent selection guide so the existing 22-agent suite gets used correctly. All v1 requirements are covered; the result is a Claude Code environment where "implement X, create PR" runs to completion without a single approval click.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Permissions Baseline** - Expand allowedTools for git/gh/npm, fix deprecated syntax, extend sandbox write paths
- [ ] **Phase 2: Skill Auto Flags** - Add `--auto` flag to commit and pr skills to remove confirmation gates
- [ ] **Phase 3: Discoverability** - Write agent selection guide in rules/agents.md and wire it into CLAUDE.md

## Phase Details

### Phase 1: Permissions Baseline
**Goal**: Claude can execute git, gh, and npm commands without any human approval prompt
**Depends on**: Nothing (first phase)
**Requirements**: PERM-01, PERM-02, PERM-03, PERM-04, PERM-05, PERM-06
**Success Criteria** (what must be TRUE):
  1. Running `git commit`, `git push`, `git worktree`, `gh pr create`, `npm test` in a GSD workflow produces zero approval prompts
  2. `git push --force`, `rm -rf`, and `sudo` are explicitly listed in the deny block; `curl|bash` remains approval-prompted (not denied) per Phase 1 locked decision
  3. All 22 deprecated `:*` entries in settings.json have been replaced with space-separated syntax
  4. Subagents writing to `.planning/**` succeed without sandbox permission errors
**Plans:** 2 plans

Plans:
- [ ] 01-01-PLAN.md — Migrate all 22 deprecated `:*` syntax entries to space-separated form
- [ ] 01-02-PLAN.md — Add git/gh/npm allow entries, create deny block, extend sandbox allowWrite

### Phase 2: Skill Auto Flags
**Goal**: `commit` and `pr` skills execute end-to-end without stopping for confirmation when `--auto` is passed
**Depends on**: Phase 1
**Requirements**: SKIL-01, SKIL-02
**Success Criteria** (what must be TRUE):
  1. `commit --auto` stages specified files, generates a commit message, commits, and pushes without any interactive confirmation step
  2. `pr --auto` pushes the branch and creates a draft PR with an auto-generated title and body without any confirmation step
  3. When `--auto` is NOT passed, existing interactive behavior is unchanged
**Plans**: TBD

Plans:
- [ ] 02-01: Add `--auto` flag to commit skill — skip branch/message/push confirmation gates, keep explicit file staging
- [ ] 02-02: Add `--auto` flag to pr skill — skip push confirmation and content review gate, auto-generate title/body

### Phase 3: Discoverability
**Goal**: Users know which agent to reach for and when, making the 22-agent suite actively useful rather than invisible
**Depends on**: Phase 2
**Requirements**: DISC-01, DISC-02
**Success Criteria** (what must be TRUE):
  1. `rules/agents.md` exists and lists each agent with a one-line description of its role and at least one example scenario for when to invoke it
  2. `CLAUDE.md` imports `@rules/agents.md` so the guide is loaded into every Claude session automatically
  3. A user asking "which agent should I use to verify my implementation?" can find the answer by reading rules/agents.md without consulting any other file
**Plans**: TBD

Plans:
- [ ] 03-01: Write `rules/agents.md` — scenario-based agent selection guide covering all 22 agents
- [ ] 03-02: Add `@rules/agents.md` import to `CLAUDE.md`

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Permissions Baseline | 0/2 | Not started | - |
| 2. Skill Auto Flags | 0/2 | Not started | - |
| 3. Discoverability | 0/2 | Not started | - |
