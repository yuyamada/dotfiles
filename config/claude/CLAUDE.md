# References

Detailed, topic-scoped guidance lives under `references/*.md` and is **not**
auto-loaded. Skim the one-liners below; when a task matches one, read that file
with the Read tool before acting — don't rely on memory of past sessions or on
having seen it in an earlier turn of this one.

- `references/permissions.md` — permission-fix workflow (use the `update-config`
  skill), always confirm before posting GitHub PR/issue comments. Read before:
  editing settings.json permissions, or posting any GitHub comment.
- `references/workflow.md` — planning/sub-agent/verification discipline (Plan
  mode for 3+ step tasks, delegate research to sub-agents, verify before
  claiming done). Read before: starting a non-trivial multi-step task.
- `references/writing.md` — Japanese text spacing around embedded English
  words/symbols. Read before: writing Japanese prose that mixes in English
  terms.
- `references/skills.md` — skill authoring conventions (English only, symlink
  placement under `config/claude/skills/<name>/`, company-specific skills stay
  out of public dotfiles). Read before: creating or editing a skill.
- `references/git.md` — git workflow conventions (worktrees over
  `checkout -b`, ignore-file layering, Conventional Commits, draft-first PRs).
  Read before: any git branch/commit/PR operation.
- `references/technical-answers.md` — cite official docs or source code before
  answering technical questions (API behavior, CLI flags, config, version
  differences). Read before: answering any technical claim.
- `references/gh.md` — `gh` (readonly) vs `gh-write` (write) command split via
  ghtkn. Read before: running any `gh` command.
- `references/tools.md` — shell-only tooling (no python), settings.json
  permission awareness, `gh api --method GET`, no newlines in Bash commands.
  Read before: choosing which tool or command to run.
