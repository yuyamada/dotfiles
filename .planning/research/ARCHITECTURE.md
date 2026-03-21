# Architecture Research: Claude Code Multi-Agent Orchestration

**Analysis Date:** 2026-03-21
**Confidence:** HIGH (direct source analysis)

## Agent Inventory & Classification

The 22 agents in `config/claude/agents/` fall into 4 roles:

### Planning Specialists (8 agents)
| Agent | Role |
|-------|------|
| gsd-planner | Creates phase plans (PLAN.md) |
| gsd-roadmapper | Builds project roadmap from requirements |
| gsd-phase-researcher | Pre-planning domain research |
| gsd-project-researcher | New project domain research |
| gsd-advisor-researcher | Single decision research |
| gsd-research-synthesizer | Combines parallel research outputs |
| gsd-ui-researcher | UI design contract (UI-SPEC.md) |
| gsd-codebase-mapper | Analyzes codebase structure |

### Execution Specialists (2 agents)
| Agent | Role |
|-------|------|
| gsd-executor | Executes plans with atomic commits |
| gsd-debugger | Scientific debugging with session state |

### Verification & Review Specialists (6 agents)
| Agent | Role |
|-------|------|
| gsd-verifier | Phase goal verification (VERIFICATION.md) |
| gsd-plan-checker | Pre-execution plan quality check |
| gsd-nyquist-auditor | Test coverage gap filling |
| gsd-integration-checker | Cross-phase integration validation |
| performance-reviewer | Performance issue detection |
| security-reviewer | Security vulnerability detection |
| test-coverage | Test coverage analysis |

### UI Specialists (3 agents)
| Agent | Role |
|-------|------|
| gsd-ui-auditor | Retroactive UI quality audit |
| gsd-ui-checker | UI spec validation |
| gsd-user-profiler | Developer behavioral profiling |

**Key insight:** There are NO orchestrator agents. Orchestration is done by workflow `.md` skill files that spawn agents via `Task()`. Agents are pure specialists.

## Orchestration Patterns

### Pattern 1: Wave-Based Parallel Execution
Plans in the same dependency wave run simultaneously via parallel `Task()` calls. Later waves wait for earlier ones to complete. Used by `gsd:execute-phase`.

```
Wave 1: [executor-A, executor-B, executor-C] (parallel)
   ↓ all complete
Wave 2: [executor-D, executor-E] (parallel)
```

### Pattern 2: File-Based Context Passing
Every agent uses a `<files_to_read>` intake protocol. Agents pull their own context from disk rather than receiving it in the prompt. Results are written to disk (SUMMARY.md, VERIFICATION.md, PLAN.md) rather than returned inline.

```
Orchestrator → writes task description → spawns agent
Agent → reads PROJECT.md, REQUIREMENTS.md, etc.
Agent → writes output to .planning/[result-file].md
Orchestrator → reads result file → continues
```

### Pattern 3: Permission Inheritance
Agent `tools:` frontmatter narrows the global `settings.json` allowedTools. Reviewer agents specify minimal tools (Read, Grep, Glob). Executor agents specify broader tools (Read, Write, Edit, Bash).

```yaml
# Reviewer agent — read-only
tools: Read, Bash, Grep, Glob

# Executor agent — full access
tools: Read, Write, Edit, Bash, Grep, Glob
```

## Gap Analysis

### Gap 1: No "task → PR" Pipeline Skill
The existing `feature-dev` skill exists but is incomplete. There's no single entry point that takes a task description and autonomously executes: research → plan → code → test → commit → PR.

**Impact:** User must manually chain multiple skills.

### Gap 2: No Agent Selection Guide
22 agents exist with no "when to use which" documentation. Users don't know whether to reach for `gsd-executor`, `gsd-debugger`, or a custom agent for a given task.

**Impact:** Agents are underutilized; user falls back to direct prompting.

### Gap 3: No Context Handoff Pattern
When context window fills during a long autonomous task, there's no standardized way to checkpoint state and resume in a fresh session.

**Impact:** Long autonomous tasks fail mid-stream with no recovery path.

### Gap 4: allowedTools Gaps
The current `settings.json` doesn't cover all commands autonomous execution needs (npm, yarn, test runners, build tools). Agents hit permission prompts even when the overall task is approved.

## Ideal Architecture for Autonomous Dev

```
User: "implement feature X"
         ↓
[Orchestrator Skill]
  → spawns gsd-phase-researcher (domain research)
  → spawns gsd-planner (creates PLAN.md)
  → spawns gsd-plan-checker (validates plan)
  ↓ plan approved (auto in YOLO mode)
  → spawns gsd-executor (implements per PLAN.md)
  → spawns test-runner (inline bash)
  → spawns gsd-verifier (checks goal achievement)
  ↓ verified
  → runs commit skill
  → runs pr skill
Done: PR created, no human approval needed
```

## Recommendations

1. **Phase 1 priority:** permissions audit + allowedTools expansion (zero new code, highest impact)
2. **Phase 2:** agent selection guide in CLAUDE.md rules (zero new code, improves discoverability)
3. **Phase 3:** complete `feature-dev` skill or create new `autonomous-dev` skill
4. **Phase 4:** context handoff/resume strategy documentation

The existing agent suite is architecturally sound. Gaps are in tooling (permissions) and discoverability (documentation), not agent design.

---
*Architecture research: 2026-03-21*
