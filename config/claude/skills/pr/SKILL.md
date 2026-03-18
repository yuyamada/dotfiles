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
- Unpushed commits: !`git log origin/$(git branch --show-current)..HEAD --oneline 2>/dev/null || echo "none"`
- PR template: !`cat .github/pull_request_template.md 2>/dev/null || echo "none"`

## Overview

Create a draft PR that matches this repo's style. The key things: find the right
format, generate good content, and confirm with the user before creating.

## Steps

### Step 1: Check for unpushed commits

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

Draft a PR title and body based on:
```bash
git log origin/$(git branch --show-current)..HEAD --oneline
git diff origin/$(git branch --show-current)..HEAD
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

Display the PR URL clearly. Ask if the user wants to open it in the browser:
```bash
open <url>  # only if the user says yes
```
