---
phase: 02-skill-auto-flags
plan: "02"
subsystem: skills
tags: [claude-skills, pr, auto-mode, gh-cli]

# Dependency graph
requires:
  - phase: 02-skill-auto-flags
    provides: phase context and locked decisions for --auto flag implementation
provides:
  - "--auto flag support in pr skill: push without confirmation, skip content review, skip browser prompt"
affects: [gsd-orchestrators, subagents creating PRs non-interactively]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Blockquote auto-mode annotations at start of each step with confirmation gates"
    - "Additive prose-based flag detection: If --auto was passed... / When --auto is NOT passed..."

key-files:
  created: []
  modified:
    - config/claude/skills/pr/SKILL.md

key-decisions:
  - "Auto mode section placed after Overview, before Steps, to give callers a single reference point for auto behavior"
  - "Blockquotes used additively (not replacing) so interactive and auto paths coexist in same steps"
  - "PR always created as --draft in auto mode, consistent with interactive mode"

patterns-established:
  - "Auto-mode skill pattern: Auto mode section + per-step blockquotes for each skipped gate"

requirements-completed: [SKIL-02]

# Metrics
duration: 4min
completed: 2026-03-21
---

# Phase 02 Plan 02: pr --auto Flag Summary

**pr skill extended with --auto flag that pushes immediately, skips title/body review, and skips browser prompt — enabling GSD orchestrators to create draft PRs end-to-end without human interaction**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-21T03:02:31Z
- **Completed:** 2026-03-21T03:06:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `## Auto mode` section to pr SKILL.md documenting all 3 skipped gates with exact behavior
- Added blockquote auto-mode annotations to Steps 1, 3, and 5 (the 3 gates)
- Steps 2 and 4 left unchanged (no confirmation gates to skip)
- All existing interactive confirmation prose preserved verbatim

## Task Commits

Each task was committed atomically:

1. **Task 1: Add --auto flag documentation and conditional behavior to pr skill** - `1d0ab07` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `config/claude/skills/pr/SKILL.md` - Added Auto mode section and step-level blockquote annotations for gates in Steps 1, 3, 5

## Decisions Made

- Auto mode section placed after Overview (before Steps) so callers can read the full auto behavior in one place without scanning individual steps
- Blockquotes used as additive annotations rather than replacing existing prose — both interactive and auto paths documented clearly
- PR created as `--draft` in auto mode (same as interactive `gh pr create --draft`)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both `commit` and `pr` skills now have `--auto` flag support (commit was handled in plan 02-01)
- GSD orchestrators can now call `/pr --auto` to create PRs non-interactively
- Phase 02 complete: skill-auto-flags objective achieved

---
*Phase: 02-skill-auto-flags*
*Completed: 2026-03-21*
