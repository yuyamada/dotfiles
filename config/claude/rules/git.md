# Git Operations

## Branch Management
- Use `git worktree` for branch operations instead of `git checkout -b`
- This keeps the main working directory clean and enables parallel work

## Commit Messages
- Follow Conventional Commits: `<type>(<scope>): <description>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`
- Description is lowercase, no period at end, under 72 chars

## Pull Requests
- PR titles follow Conventional Commits format, under 72 chars
- Always create as draft first
