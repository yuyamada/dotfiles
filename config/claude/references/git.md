# Git Operations

## Branch Management
- Use `git worktree` for branch operations instead of `git checkout -b`
- This keeps the main working directory clean and enables parallel work
- Create worktrees under `.worktrees/` within the repo; this path is ignored
  via the global ignore file (worktree management is unaffected by ignore —
  metadata lives in `.git/worktrees/`, separate from the working tree)
- Never run aggressive cleanup (`git clean -ffdx`) in a repo that has live
  worktrees nested inside it
- Before creating a new branch or worktree, always `git fetch` and confirm
  the base branch is up to date with its remote-tracking branch
- If it's behind, update it (e.g. `git pull`) before branching off it
- If you're about to commit and find yourself sitting on the default branch
  with uncommitted changes for a distinct piece of work, don't silently
  `checkout -b` in place — stop and ask the user whether to set up a worktree
  for it or commit directly to the default branch (small config-only repos
  sometimes commit directly by convention; check recent history for the norm)

## Committing
- Run `git diff` (or `git status --short`) first to see what actually changed
- Stage only files clearly related to the current task; avoid `git add -A`/
  `git add .` unless every change belongs to the same piece of work
- If unrelated changes are mixed in, ask whether to split into separate
  commits rather than bundling them
- Write the message to explain *why* the change was made, not just what
  changed — the diff already shows the what
- After committing, ask whether to push — don't push automatically. If the
  branch doesn't exist on the remote yet, push with `git push -u origin <branch>`

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
- If there are unpushed commits, ask before pushing them (`git push -u origin
  <branch>`) — a PR can't be created from commits the remote doesn't have
- Find the repo's PR format before drafting content:
  - Look for a single template: `.github/pull_request_template.md`,
    `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`, or
    `pull_request_template.md`
  - If `.github/PULL_REQUEST_TEMPLATE/` holds multiple templates, pick the
    best match, or ask the user if more than one plausibly fits
  - If no template exists, check recent PRs for the expected style
    (`gh pr list --limit 3 --state all`, `gh pr view <number> --json title,body`)
- PR titles follow Conventional Commits format, under 72 chars
- If a template exists, fill in every section using the commit history and
  diff (`git log '@{u}..HEAD' --oneline`, `git diff '@{u}..HEAD'`) — don't
  leave sections empty. Without a template, match the style of recent PRs
- Show the full drafted title and body to the user and wait for confirmation
  before creating — let them edit if needed
- Always create as draft first: `gh pr create --draft --title "<title>" --body "<body>"`
- After creating, show the PR URL and ask if the user wants to open it in
  the browser
