# Feature Landscape: Autonomous Development Workflow

**Domain:** Claude Code dotfiles / autonomous agent configuration
**Researched:** 2026-03-21
**Overall confidence:** HIGH (official docs verified + existing codebase inspected)

---

## Existing Skill Coverage Map

Before defining what to build, this is what already exists and where gaps are.

| Workflow Step | Existing Asset | Coverage | Gap |
|---|---|---|---|
| Task intake | manual prompt | none — human types task | no automation |
| Branch creation | `commit` skill (asks first) | partial — proposes name, waits for confirmation | confirmation gate breaks autonomy |
| Worktree isolation | nothing | MISSING | full gap |
| Code implementation | `feature-dev` plugin (7-phase) | partial — Phase 5 "waits for explicit approval" | approval gate |
| Test execution | nothing in `permissions.allow` | MISSING | npm/test runners blocked by permissions |
| Commit | `commit` skill | partial — confirms at step 3 before committing | confirmation gate |
| Code review | `parallel-review` skill | covered — launches 3 sub-agents concurrently | good |
| PR creation | `pr` skill | partial — confirms before `gh pr create` | confirmation gate |
| CI status polling | `gh run view` in permissions | partial — can read CI status | no retry/wait loop |
| PR merge | nothing | MISSING | full gap |
| Context handoff | `ralph-loop` skill | partial — iterates same session | no state file for cross-session |
| Error recovery | `gsd-executor` deviation rules | covered — auto-fix bugs/blocking issues | only in GSD plans |

**Summary:** Every existing skill that touches git or GitHub has at least one human confirmation step. The skills were designed for interactive use. The permissions list omits write-side commands (git add, git commit, git push, gh pr create, npm test).

---

## Table Stakes

Features that must work for zero-intervention autonomy to be possible at all. Without these, the workflow halts and waits for a human.

| Feature | Why Required | Complexity | Current State |
|---|---|---|---|
| Permitted write-side git commands | `git add`, `git commit`, `git push` are absent from `permissions.allow` — every commit triggers approval prompt | Low | MISSING from settings.json |
| Permitted test runner commands | `npm test`, `npx vitest`, `go test`, `pytest` etc. absent from `permissions.allow` | Low | MISSING from settings.json |
| Permitted `gh pr create` | PR creation currently triggers approval prompt | Low | MISSING from settings.json |
| Autonomous `commit` skill variant | Current `commit` skill asks user at step 1 (branch name), step 3 (message confirm), step 4 (push confirm) | Medium | Needs autonomous variant |
| Autonomous `pr` skill variant | Current `pr` skill asks user at step 1 (push confirm), step 3 (content confirm) | Medium | Needs autonomous variant |
| Worktree isolation | Without worktrees, autonomous work on main branch risks dirty state; parallel tasks collide | Medium | MISSING — no worktree management |
| State persistence file | When a long autonomous run hits context limit or crashes, it needs a file on disk to resume from — not just git history | Medium | MISSING |

### Permission gaps in detail

Current `permissions.allow` covers read-only operations well. The blocked commands for autonomous development:

```
# Currently MISSING from permissions.allow:
Bash(git add:*)
Bash(git commit:*)
Bash(git push:*)
Bash(git worktree:*)
Bash(npm test:*)
Bash(npm run:*)
Bash(npx:*)
Bash(gh pr create:*)
Bash(gh pr merge:*)
Bash(gh run watch:*)
```

**Recommended approach:** Add project-scoped permissions in `.claude/settings.json` (not global `~/.claude/settings.json`) to limit blast radius. Global settings expand permissions for every project; project-scoped settings only apply in context.

---

## Differentiators

Features that make the autonomous workflow robust rather than fragile. Not strictly required for a single successful run, but required for consistent reliability.

| Feature | Value Proposition | Complexity | Notes |
|---|---|---|---|
| Worktree-per-task isolation | Each autonomous task gets its own branch + working directory via `claude --worktree <name>`; no dirty-state contamination between tasks | Medium | Claude Code supports `--worktree` flag natively; also `isolation: worktree` in agent frontmatter |
| Autonomous `feature-dev` orchestration skill | Single-entry skill: takes task description, creates worktree, implements, tests, reviews, commits, opens PR — no checkpoints | High | `feature-dev` plugin Phase 5 currently requires approval; need a new skill or wrapper that skips confirmation gates |
| Context handoff protocol | Structured state file (`.claude/task-state.json` or similar) written at each checkpoint so a resumed session or fresh agent picks up exactly where it left off | Medium | `ralph-loop` solves single-session iteration but not cross-context handoff; GSD has STATE.md precedent |
| Test-gate before commit | Run tests after implementation; only commit if tests pass; on failure, apply auto-fix loop (max 3 attempts per `gsd-executor` pattern) then report blocked | Medium | Pattern exists in `gsd-executor` TDD flow; needs extraction into standalone skill |
| CI polling loop | After PR creation, poll `gh run view` until CI passes or fails; surface result back to operator | Medium | `gh run view` already permitted; need a polling wrapper with timeout |
| Review-gate before PR | Run `parallel-review` before creating PR; block PR creation if critical issues found; auto-fix moderate issues | Medium | `parallel-review` skill exists but is not wired into the PR creation flow |
| Deviation classification | When the autonomous flow encounters something unexpected (new file type, ambiguous requirement, auth gate), classify it: auto-fix vs escalate to operator | Medium | `gsd-executor` deviation rules (Rules 1-4) are the right model; needs porting into standalone skill |
| Agent usage guide for users | Document in `rules/` or `CLAUDE.md`: which agent does what, when to invoke it, how to chain them | Low | PROJECT.md notes this as a gap: "エージェント認識不足" |

### Worktree isolation detail

Claude Code's `--worktree` flag (confirmed in official docs, HIGH confidence) creates a dedicated working directory at `<repo>/.claude/worktrees/<name>` with branch `worktree-<name>`. For autonomous sub-agents, adding `isolation: worktree` to agent frontmatter gives each sub-agent its own worktree automatically.

For a dotfiles project this matters less (single-developer, single repo), but for any target project where the autonomous skill operates, worktree isolation prevents:
- Uncommitted changes from one task bleeding into another
- Race conditions when two autonomous sessions run in parallel
- Needing to stash/unstash before switching context

### Context handoff design

The `ralph-loop` skill handles same-session iteration well. Cross-session handoff requires a state file. The GSD system uses `.planning/STATE.md` as its model. For a lightweight autonomous skill, a simpler structure suffices:

```json
{
  "task": "add OAuth login",
  "worktree": "feature-oauth-login",
  "branch": "worktree-feature-oauth-login",
  "phase": "testing",
  "completed": ["explore", "design", "implement"],
  "last_commit": "abc1234",
  "blocker": null
}
```

When context is exhausted mid-task, `claude --continue` + the state file allows recovery without starting over.

---

## Anti-Features

Things that would break autonomy or introduce unacceptable risk.

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| Global `permissions.allow` for write commands | Adds `git commit`, `git push`, `gh pr create` globally — affects every project including ones where autonomous commits are dangerous | Use project-scoped `.claude/settings.json` per-project, or use the `--allowedTools` CLI flag at invocation time |
| `--dangerously-skip-permissions` as default | Bypasses ALL sandboxing including filesystem and network restrictions; appropriate for CI but not local interactive use | Enumerate specific tools in `permissions.allow`; reserve YOLO mode for disposable CI containers |
| Auto-merge to main without CI gate | Merging before CI passes creates broken main branches | Always poll CI to green before merge; never merge draft PRs |
| Uncapped auto-fix loop | Looping on test failures indefinitely consumes tokens and can introduce regressions | Cap at 3 attempts per `gsd-executor` pattern; on cap-exceeded, write blocker to state file and stop |
| Silencing human escalation entirely | Some failures (auth gates, architectural decisions, ambiguous requirements) genuinely require human judgment | Preserve "escalate to operator" path for Rule 4-class situations; write structured blocker to a file the user can read |
| Committing generated/temp files | Autonomous agents run tools that produce output files (coverage reports, build artifacts); committing these pollutes history | After every Bash execution, check `git status | grep '^??'`; add to `.gitignore` or explicitly exclude from staging |
| Broad `git add .` in autonomous commits | Stages unrelated changes, secrets, large binaries accidentally | Always stage specific files by name; never `git add .` or `git add -A` in autonomous mode |
| Removing worktree on changes without prompt | If autonomous run produced commits, silent worktree removal destroys that work | Follow Claude Code's default: auto-remove only if no changes; write state if commits exist |

---

## Feature Dependencies

```
permissions.allow (write commands)
  -> autonomous-commit skill
  -> autonomous-pr skill

worktree isolation
  -> parallel autonomous tasks (optional, but enables it)

autonomous-commit skill
  -> test-gate (run tests, verify pass before commit)
  -> autonomous-pr skill

test-gate
  -> permissions.allow (test runner commands)

autonomous-pr skill
  -> review-gate (run parallel-review before PR)
  -> CI polling loop (after PR, wait for green)

CI polling loop
  -> (optional) auto-merge

context handoff state file
  -> recovery after context limit
  -> multi-session autonomous runs
```

---

## MVP Recommendation

The minimum viable autonomous workflow for this dotfiles project:

**Priority 1 — Unblock the basics (permissions + skill wrappers)**

1. Add write-side git/gh commands to a project-scoped `permissions.allow` template (or document the `--allowedTools` invocation pattern for autonomous sessions)
2. Create `autonomous-commit` skill: same as `commit` skill but removes all confirmation gates; stages named files, commits with auto-generated message, pushes
3. Create `autonomous-pr` skill: same as `pr` skill but removes all confirmation gates; auto-generates title/body, runs `gh pr create --draft`

**Priority 2 — Add robustness (test gate + review gate)**

4. Add test execution to the autonomous commit flow: run tests, require green before staging/committing
5. Wire `parallel-review` as a pre-PR gate in `autonomous-pr`

**Priority 3 — Full orchestration skill**

6. `feature-dev-auto` skill: takes task description, creates worktree, runs implementation, runs test gate, runs review gate, creates PR, polls CI, reports result to operator — one command, zero confirmations

**Defer:**

- Auto-merge: risky without battle-tested CI; add after Priority 2 is validated
- Cross-session state file: implement when the first autonomous run hits context limits in practice
- Agent usage guide in `rules/`: write after the skills exist, so the guide reflects reality

---

## Quality Gate Checklist

- [x] Existing skills mapped to autonomous workflow steps (every skill has a gap analysis above)
- [x] Failure modes identified (permissions gap, confirmation gates, context exhaustion, untracked files, unbounded retry loops)
- [x] Feature checklist proposed for robust autonomous execution
- [x] Differentiators separated from table stakes
- [x] Anti-features documented with mitigations

---

## Sources

- [Claude Code: Common Workflows](https://code.claude.com/docs/en/common-workflows) — HIGH confidence, official docs (confirmed --worktree flag, isolation: worktree frontmatter)
- [Claude Code: Run Claude Code programmatically](https://code.claude.com/docs/en/headless) — HIGH confidence, official docs (confirmed -p mode, --allowedTools syntax, --continue behavior)
- [Claude Code: Configure permissions](https://code.claude.com/docs/en/permissions) — HIGH confidence, official docs (confirmed permissions.allow syntax, project vs global scoping)
- Existing codebase inspection: commit/SKILL.md, pr/SKILL.md, parallel-review/SKILL.md, ralph-loop/SKILL.md — HIGH confidence, direct source read
- gsd-executor.md agent — HIGH confidence, direct source read (deviation rules, TDD flow, commit protocol)
- PROJECT.md — HIGH confidence, direct source read (requirements, constraints, existing context)
- ~/.claude/settings.json permissions inspection — HIGH confidence, direct read (confirmed missing write-side commands)
- feature-dev plugin README (da61886c07a4) — HIGH confidence, direct read (confirmed Phase 5 approval gate)
