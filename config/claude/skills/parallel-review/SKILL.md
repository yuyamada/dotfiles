---
name: parallel-review
description: Orchestrate parallel sub-agent review of current git changes. Launches
  specialist agents concurrently and aggregates results. Currently runs security-reviewer.
  Add more agents to config/claude/agents/ to extend coverage.
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

2. Launch sub-agents in parallel using the Agent tool. Pass the full diff as context
   to each agent with a clear instruction.

   Current agents to launch:
   - **security-reviewer** — detect security vulnerabilities in the diff

   To add more agents: create `config/claude/agents/<name>.md` and add them to this list.

3. Collect all agent reports and present a unified summary:

```
PARALLEL REVIEW RESULTS
=======================
Branch: [current branch]
Diff:   [X files changed, Y insertions, Z deletions]

--- SECURITY ---
[security-reviewer output]

--- VERDICT ---
[PASS if all agents pass, FAIL if any agent fails, NEEDS_REVIEW if uncertain]
```

## Notes

- Agents run with their own context windows — they only see what you pass them
- Always pass the full diff text in the agent prompt, not just a file list
- If an agent fails to start, report the error and continue with remaining agents
