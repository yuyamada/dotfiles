---
name: pr
description: >
  Create a draft pull request from the current branch. Use when the user says
  "PR作って", "プルリク", "PR出したい", "open a PR", "submit a pull request",
  "pull request作って", or finishes work and wants to open a PR.
  Will push any unpushed commits before creating the PR.
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git push:*), Bash(git branch:*), Bash(cat:*), Bash(gh pr create:*), Bash(gh pr list:*), Bash(gh pr view:*)
---

## Current state

- Branch: !`git branch --show-current`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || echo "none"`
- PR template: !`cat .github/pull_request_template.md 2>/dev/null || echo "none"`

## Overview

Create a draft PR that matches this repo's style. The key things: find the right
format, generate good content, and confirm with the user before creating.

## Auto mode

If `--auto` was passed, skip all confirmation gates and proceed autonomously:

- **Push**: If there are unpushed commits, push immediately with `git push -u origin <branch>`. Do not ask.
- **PR format**: Find the template or check recent PRs exactly as in interactive mode (no gate to skip here).
- **Title and body**: Generate a Conventional Commits title (`<type>(<scope>): <description>`, lowercase, no period, under 72 chars) and body from the commit history and diff. Create the draft PR immediately without showing for review.
- **Browser**: Do not ask about opening in browser. Just display the PR URL.

When `--auto` is NOT passed, follow the interactive steps below unchanged.

## Steps

### Step 1: Check for unpushed commits

> **Auto mode**: If there are unpushed commits, push immediately with `git push -u origin <branch>`. Skip to Step 2.

If there are unpushed commits (see above), show them to the user and ask whether
to push first:
```bash
git push -u origin <branch>
```

If the branch doesn't exist on remote yet, push it. If the user says no, stop here.

### Step 2: Find the PR format

If a PR template was found above, use it as the structure for the body.

If no template, check recent PRs to understand the expected style:
```bash
gh pr list --limit 3 --state all
gh pr view <number> --json title,body
```

### Step 3: Generate and confirm

> **Auto mode**: Generate the title and body, then skip directly to Step 4 (do not show for review).

Draft a PR title and body based on:

The title must follow Conventional Commits format: `<type>(<scope>): <description>`
Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`
Scope is optional. Description is lowercase, no period at end. Keep it under 72 chars.
```bash
git log @{u}..HEAD --oneline
git diff @{u}..HEAD
```

If a template exists, fill in each section using the commit history and diff — don't
leave sections empty. If no template, match the style of recent PRs.

Show the full content to the user and wait for confirmation before proceeding.
Let the user edit if needed.

### Step 4: Create

```bash
gh pr create --draft --title "<title>" --body "<body>"
```

### Step 5: Show the link

> **Auto mode**: Display the PR URL. Do not ask about opening in browser. Done.

Display the PR URL clearly. Ask if the user wants to open it in the browser:
```bash
open <url>  # only if the user says yes
```
