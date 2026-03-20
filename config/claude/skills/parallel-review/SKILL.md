---
name: parallel-review
description: Orchestrate parallel sub-agent review of current git changes. Launches
  specialist agents concurrently and aggregates results. Runs security-reviewer,
  performance-reviewer, and test-coverage agents in parallel.
allowed-tools:
- Bash
- Agent
---

# Parallel Review

Orchestrate specialist agents to review current changes in parallel.

## Steps

1. Get the diff to review:
```bash
git diff HEAD 2>/dev/null || git diff 2>/dev/null
```
If the diff is empty, try:
```bash
git diff origin/$(git branch --show-current)..HEAD 2>/dev/null
```
If still empty, tell the user: "No changes detected. Make some commits or stage changes first."

2. Launch all three sub-agents **in parallel** using the Agent tool. Pass the full diff
   as context to each agent with a clear instruction.

   Agents to launch simultaneously:
   - **security-reviewer** — detect security vulnerabilities in the diff
   - **performance-reviewer** — detect performance issues and regressions in the diff
   - **test-coverage** — identify test coverage gaps and missing edge cases in the diff

   To add more agents: create `config/claude/agents/<name>.md` and add them to this list.

3. Collect all agent reports and present a unified summary:

```
PARALLEL REVIEW RESULTS
=======================
Branch: [current branch]
Diff:   [X files changed, Y insertions, Z deletions]

--- SECURITY ---
[security-reviewer output]

--- PERFORMANCE ---
[performance-reviewer output]

--- TEST COVERAGE ---
[test-coverage output]

--- VERDICT ---
[PASS if all agents pass, FAIL if any agent fails, NEEDS_REVIEW if uncertain]
Overall: [1-2 sentence summary of the most important findings]
```

## Notes

- Agents run with their own context windows — they only see what you pass them
- Always pass the full diff text in the agent prompt, not just a file list
- If an agent fails to start, report the error and continue with remaining agents
