# Workflow Design

## 1. Plan Mode as Default
- Start with Plan mode for tasks with 3+ steps or architectural decisions
- Stop and replan immediately when things go wrong
- Use Plan mode for verification steps, not just building
- Document detailed specs before implementing

## 2. Sub-agent Strategy
- Use proactively to keep context window clean
- Delegate research, investigation, and parallel analysis to sub-agents
- Invest more compute on complex problems
- Assign one task per sub-agent

## 3. Self-improvement Loop
- After user corrections, record lessons in a project-local file
- Create rules to avoid repeating the same mistakes
- Continuously improve until error rate decreases
- Review relevant lessons at session start

## 4. Always Verify Before Completion
- Don't mark as complete until functionality is proven
- Check diff against main branch
- Ask "would a staff engineer approve this?"
- Show correctness through tests and log verification

## 5. Pursue Elegance (with balance)
- Before significant changes, consider "is there a better way?"
- When a fix feels hacky, implement an elegant solution instead
- Avoid over-engineering for simple fixes
- Review your own work before presenting

## 6. Autonomous Bug Fixing
- Fix bugs thoroughly when reported
- Resolve from logs, errors, and failing tests independently
- Minimize user context switching
- Fix CI failures without being asked

## 7. Core Principles
- **Simplicity first**: Minimize changes, minimize impacted code
- **No shortcuts**: Find root causes, avoid temporary fixes
- **Minimize impact**: Change only what's needed, avoid new bugs
