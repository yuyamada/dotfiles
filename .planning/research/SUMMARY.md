# Project Research Summary

**Project:** Claude Code 自律開発設定
**Domain:** Developer tooling / Claude Code dotfiles configuration
**Researched:** 2026-03-21
**Confidence:** HIGH

## Executive Summary

This project upgrades a Claude Code dotfiles configuration so agents can execute the full "task → code → test → PR" cycle without any human approval prompts. The setup is unusual in that the "stack" is entirely configuration files (JSON, Markdown) — no new runtime or framework is required. The recommended approach is to work in three ordered layers: first eliminate permission friction (settings.json), then wire up autonomous skill variants that remove confirmation gates, and finally document the agent system so the 22 existing agents are discoverable and used correctly.

The largest barrier to autonomy is not missing agents — a sophisticated 22-agent suite already exists — but missing permission entries. Write-side git commands (`git add`, `git commit`, `git push`), npm/test runners, and `gh pr create` are absent from `permissions.allow`, causing approval prompts on every meaningful action. Fixing this is low-complexity, high-impact, and must come first because every other capability depends on it. Permissions should be scoped at the project level (not globally in `~/.claude/settings.json`) to limit blast radius.

The key risk is expanding permissions carelessly. The `sed :*` deprecated syntax is flagged as an RCE vector, the sandbox network allowlist must stay intact to prevent prompt-injection exfiltration, and `git add .` in autonomous mode must never be used — only explicit file staging. Security boundaries are non-negotiable even in full YOLO mode: `git push --force`, `rm -rf`, `sudo`, and `curl | bash` must remain in the deny list permanently.

## Key Findings

### Recommended Stack

The configuration is pure JSON and Markdown — no new dependencies needed. The existing `settings.json` uses the deprecated `:*` suffix syntax (e.g., `Bash(git log:*)`) instead of the modern space-separated syntax (`Bash(git log *)`). Eleven deprecated entries need migration. The permissions model is a two-layer system: the OS-level sandbox (hard limits, prompt-injection-resistant) and the `permissions.allow/deny` list (Claude's autonomous decision scope). Both layers must be used together.

**Core technologies:**
- `settings.json` (global): universal dev command allowlist — category-level wildcards with explicit deny rules
- `settings.json` (project-scoped): project-specific additions (test runners, build tools) — limits blast radius vs global
- Agent frontmatter `tools:`: narrows allowedTools per agent — reviewer agents get read-only, executor agents get full access
- Skill `allowed-tools`: per-skill permission scope — prevents individual skills from over-reaching

### Expected Features

**Must have (table stakes):**
- Write-side git commands in `permissions.allow` — `git add`, `git commit`, `git push`, `git worktree` currently missing; every commit halts for human approval
- Test runner commands in `permissions.allow` — `npm test`, `npx`, `jest`, `vitest`, `pytest` etc. absent; tests cannot run autonomously
- `gh pr create` / `gh run watch` in `permissions.allow` — PR creation currently triggers approval prompt
- Autonomous `commit` skill variant — current `commit` skill gates at branch name, message confirm, and push confirm
- Autonomous `pr` skill variant — current `pr` skill gates at push confirm and content confirm
- Deprecated `:*` syntax migration — 11 entries need migration to modern space-separated syntax

**Should have (competitive):**
- Worktree isolation — each autonomous task gets its own branch/directory; prevents dirty-state contamination and enables parallel tasks; Claude Code supports `--worktree` flag and `isolation: worktree` in agent frontmatter natively
- Test-gate before commit — run tests, require green before staging; cap auto-fix retries at 3 (per gsd-executor pattern)
- Review-gate before PR — wire `parallel-review` as pre-PR gate; `parallel-review` skill already exists but is not wired into PR flow
- Context handoff state file — structured JSON checkpoint so a fresh session or resumed `claude --continue` picks up exactly where context was exhausted
- Agent selection guide in rules/ — 22 agents exist but users don't know which to reach for; underutilization is the documented impact
- CI polling loop — poll `gh run view` after PR creation; `gh run view` is already permitted, needs a wrapper with timeout

**Defer (v2+):**
- Auto-merge to main — risky without battle-tested CI; add after review-gate and CI polling are validated
- Cross-session state file — implement when the first autonomous run hits context limits in practice, not speculatively
- Agent usage guide in rules/ — write after the autonomous skills exist so the guide reflects reality, not plans

### Architecture Approach

The existing architecture is sound: 22 agents organized into 4 specialist tiers (planning, execution, verification, UI), orchestrated by workflow Markdown skill files that spawn agents via `Task()`. There are no orchestrator agents — orchestration lives in skills. All inter-agent context passes through files on disk (`<files_to_read>` protocol), not inline in prompts. Gaps are in tooling and discoverability, not agent design.

**Major components:**
1. `settings.json` permissions layer — global allowedTools baseline; project-scoped overrides for per-repo needs
2. Autonomous skill files — `autonomous-commit`, `autonomous-pr`, and ultimately `feature-dev-auto`; wrappers around existing skills with confirmation gates removed
3. GSD agent suite — 8 planning, 2 execution, 6 verification, 3 UI specialists; unchanged but needs discoverability documentation

**Ideal orchestration flow (target state):**
```
User: "implement feature X"
  -> gsd-phase-researcher (domain research)
  -> gsd-planner (PLAN.md)
  -> gsd-plan-checker (validates plan)
  -> gsd-executor (implements per PLAN.md)
  -> test-gate (run tests, verify pass)
  -> gsd-verifier (goal achievement check)
  -> autonomous-commit (stage, commit, push)
  -> autonomous-pr (gh pr create --draft)
  -> CI polling loop (wait for green)
Done: PR created, zero human approval steps
```

### Critical Pitfalls

1. **`Bash(sed:*)` RCE vector (CVE-2025-66032)** — `sed -e` executes shell commands; migrate deprecated syntax before expanding any other permissions; this fix must come first
2. **`git add .` in autonomous mode** — stages secrets, large binaries, generated files accidentally; always stage explicit files by name in autonomous skills; never use `git add -A` or `git add .`
3. **Global `permissions.allow` for write commands** — adding `git commit`, `git push`, `gh pr create` globally affects every project including ones where autonomous commits are dangerous; use project-scoped `.claude/settings.json` or `--allowedTools` at invocation time
4. **Sandbox network allowlist disabled** — MCP tools (Slack/Notion) are prompt-injection entry points; disabling the network allowlist enables exfiltration to attacker servers; keep allowlist always
5. **Uncapped auto-fix loop** — looping on test failures indefinitely consumes tokens and introduces regressions; cap at 3 attempts per gsd-executor pattern; write structured blocker to state file on cap-exceeded

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Permissions Baseline
**Rationale:** Zero new code, highest impact. Every subsequent capability is blocked until write-side commands are permitted. The deprecated syntax bug (RCE vector) must also be fixed here before expanding anything else.
**Delivers:** Autonomous git/gh/npm execution without approval prompts; security regression fixed
**Addresses:** All table-stakes permission gaps from FEATURES.md; deprecated syntax migration from STACK.md
**Avoids:** RCE vector (sed), global permission blast radius (use project-scoped settings)

### Phase 2: Autonomous Skill Wrappers
**Rationale:** Permission fixes unblock the commands; now the skills must remove confirmation gates. `autonomous-commit` and `autonomous-pr` are thin wrappers around existing skills — medium complexity, high payoff.
**Delivers:** `autonomous-commit` skill (no confirmation gates, explicit file staging, test-gate integrated); `autonomous-pr` skill (auto-generated title/body, review-gate integrated, creates draft PR)
**Implements:** Confirmation-gate removal pattern; test-gate (cap at 3 retries); review-gate (wire parallel-review)
**Avoids:** `git add .` (always stage explicit files); uncapped auto-fix loop (cap at 3)

### Phase 3: Full Orchestration Skill
**Rationale:** With permissions and atomic skills in place, the orchestration layer can be assembled. `feature-dev-auto` is the single-entry autonomous workflow skill.
**Delivers:** `feature-dev-auto` skill — takes task description, creates worktree, implements, tests, reviews, commits, opens PR, polls CI; one command, zero confirmations
**Implements:** Worktree isolation (per-task branch + directory); CI polling loop (gh run view with timeout)
**Avoids:** Dirty-state contamination (worktree isolation); auto-merge before CI green

### Phase 4: Discoverability and Resilience
**Rationale:** The system works but users don't know how to use the 22 agents. Context handoff makes long runs recoverable. Both are documentation/lightweight additions.
**Delivers:** Agent selection guide in rules/ (when to use which agent); context handoff state file pattern (JSON checkpoint for `claude --continue` recovery)
**Addresses:** "Agent recognition gap" noted in PROJECT.md Context section
**Avoids:** Under-utilization of existing agent suite; failed autonomous runs with no recovery path

### Phase Ordering Rationale

- Phase 1 before everything else because permissions are a hard dependency — skills that can't run the commands they need are non-functional regardless of how well they're written
- Phase 2 before Phase 3 because the orchestration skill needs working atomic pieces; building the orchestrator on confirmation-gated sub-skills defeats the purpose
- Phase 4 last because the agent guide and state file should reflect what actually exists after Phases 1-3, not what was planned; writing documentation for features before they ship produces stale docs
- Worktree isolation lands in Phase 3 rather than Phase 2 because it adds complexity (new branch management) but isn't strictly required for the first autonomous end-to-end run

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Worktree lifecycle management (creation, cleanup, orphan handling) has known edge cases when autonomous commits exist; and CI polling timeout/retry semantics need validated thresholds — run `/gsd:research-phase` before planning Phase 3
- **Phase 4:** Context handoff state file schema depends on how Phase 3 is actually implemented; defer schema design research until Phase 3 is complete

Phases with standard patterns (skip research-phase):
- **Phase 1:** Permissions syntax and scoping are fully documented in official Claude Code docs; direct implementation appropriate
- **Phase 2:** Confirmation-gate removal is straightforward refactoring of existing skills; pattern is documented in gsd-executor deviation rules

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Direct source analysis of settings.json + official Claude Code permissions docs |
| Features | HIGH | Official docs verified for --worktree, isolation: worktree, --allowedTools, --continue; existing skill source code inspected directly |
| Architecture | HIGH | All 22 agents inspected directly; orchestration patterns confirmed from gsd-executor, gsd-planner, gsd-verifier source |
| Pitfalls | HIGH | CVE reference confirmed; security patterns from official docs; existing codebase confirms all gaps |

**Overall confidence:** HIGH

### Gaps to Address

- **`rm` command scope**: STACK.md flags an open question — should `Bash(rm *)` be allowed (with `-rf` explicitly denied) or require prompts entirely? Resolve in Phase 1 requirements before implementing permissions changes.
- **`.planning/` sandbox write access**: STACK.md notes `.planning/**` may not be writable to subagents running in different cwd contexts. Verify during Phase 1 implementation; add explicit path to project-level sandbox config if agents cannot write research/planning files.
- **Docker**: STACK.md flags whether `Bash(docker *)` belongs in the global allowlist. Out of scope for this project but worth deciding before Phase 1 lands to avoid a follow-up PR immediately after.

## Sources

### Primary (HIGH confidence)
- Official Claude Code docs — permissions syntax, project vs global scoping, --worktree flag, isolation: worktree frontmatter, --allowedTools, --continue behavior
- `/Users/yuyamada/workspace/dotfiles/config/claude/settings.json` — direct inspection; confirmed missing write-side commands and deprecated syntax
- `/Users/yuyamada/workspace/dotfiles/config/claude/agents/` (all 22 agents) — direct source read; agent classification and gap analysis
- `/Users/yuyamada/workspace/dotfiles/config/claude/skills/` (commit, pr, parallel-review, ralph-loop, feature-dev) — direct source read; confirmation gate locations confirmed
- `PROJECT.md` — requirements, constraints, existing context, key decisions

### Secondary (MEDIUM confidence)
- CVE-2025-66032 (sed RCE via `-e` flag) — referenced in PITFALLS.md; treat as credible given the concrete CVE number but verify patch status before citing externally

---
*Research completed: 2026-03-21*
*Ready for roadmap: yes*
