# Git Operations

## Branch Management
- Use `git worktree` for branch operations instead of `git checkout -b`
- This keeps the main working directory clean and enables parallel work
- Create worktrees under `.worktrees/` within the repo; this path is ignored
  via the global ignore file (worktree management is unaffected by ignore —
  metadata lives in `.git/worktrees/`, separate from the working tree)
- Never run aggressive cleanup (`git clean -ffdx`) in a repo that has live
  worktrees nested inside it

## Ignore Strategy
Choose the ignore layer by who should see the rule, not by convenience:
- **Shared with the team** → repo `.gitignore` (committed). For rules everyone
  must follow (build artifacts, generated files)
- **This repo, just me** → `.git/info/exclude` (repo-local, never committed).
  For project-specific personal scratch files
- **Across all repos** → global ignore (`~/.config/git/ignore`). For
  machine-wide conventions
- Throwaway temp files go in a `tmp/` directory at any depth; `tmp/` is
  registered in the global ignore, so no per-file ignore upkeep is needed
- Never list personal scratch files in the shared `.gitignore`

## Commit Messages
- Follow Conventional Commits: `<type>(<scope>): <description>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`
- Description is lowercase, no period at end, under 72 chars

## Pull Requests
- PR titles follow Conventional Commits format, under 72 chars
- Always create as draft first
