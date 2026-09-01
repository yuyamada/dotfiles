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
- If the work is naturally a chain of dependent branches (a stack), don't
  create one worktree per branch — create a single worktree for the whole
  stack and manage the branches inside it with `gh stack`; see "Stacked /
  Dependent Pull Requests" below

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
- Always create as draft first, and assign yourself as assignee:
  `gh pr create --draft --assignee @me --title "<title>" --body "<body>"`
- After creating, show the PR URL and ask if the user wants to open it in
  the browser

## Stacked / Dependent Pull Requests
- Use the `gh stack` extension (`github/gh-stack`) for a change that's
  naturally split into sequential, dependent pieces (依存のある PR), instead
  of hand-rolling `gh pr create --base <parent-branch>` per branch
- Work inside a single worktree for the whole stack. `gh stack`'s own
  navigation (`checkout`, `up`, `down`, `top`, `bottom`, `switch`) moves
  between the stack's branches by checking out in place, so giving each
  branch its own worktree defeats it
- The same `gh`/`gh-write` split from `references/gh.md` applies to `gh
  stack` subcommands — pick the wrapper by whether the subcommand writes to
  GitHub, not by habit:
  - `gh stack ...` (readonly): `init`, `add`, `checkout`, `view`, `rebase`,
    and the navigation commands (`up`/`down`/`top`/`bottom`/`switch`/`trunk`)
    — these only touch the local repo (`rebase` fetches but never pushes)
  - `gh-write stack ...` (write): `submit`, `sync`, `merge`, `push`, `link`,
    `unstack` — these push branches, create/update PRs, or touch the
    remote stack object
- Set up: `gh stack init <base-branch>` in that worktree, then `gh stack add
  <branch> -Am "<message>"` per layer — each new branch is based on the
  previous one automatically
- Publish or update the whole stack's PRs in one step with `gh-write stack
  submit` (interactive editor for title/body/draft state per PR unless
  `--auto` is passed) — this replaces creating/updating each PR by hand.
  Confirm with the user before running it, same as any other push
- Keep the stack current with `gh-write stack sync` (fetch, cascade-rebase
  each branch onto its parent, force-push with `--force-with-lease
  --atomic`, then sync PR state) — confirm with the user first since it
  force-pushes every branch in the stack. If it hits a rebase conflict, it
  rolls back automatically and reports that `gh stack rebase` is needed to
  resolve interactively
- Merge with `gh-write stack merge`, which atomically merges the stack up
  to a chosen PR (or all of it) using GitHub's native stack merge — confirm
  with the user first, including which merge method (`--squash`/`--merge`/
  `--rebase`) to use
- `gh stack view` shows the current stack's state; check it before deciding
  what to sync, submit, or merge
