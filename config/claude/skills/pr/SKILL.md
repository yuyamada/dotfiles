---
name: pr
description: >
  Create a draft pull request from the current branch. Use when the user says
  "PR作って", "プルリク", "PR出したい", or finishes work and wants to open a PR.
  Assumes the branch is already pushed — use the commit skill first if not.
---

## What you're doing

Create a draft PR that matches this repo's style. The key things: find the right
format, generate good content, and confirm with the user before creating.

## Step 1: Find the PR format

Check for a template:
```bash
cat .github/pull_request_template.md 2>/dev/null
```

If no template, check recent PRs to understand the expected style:
```bash
gh pr list --limit 3 --state all
gh pr view <number> --json title,body
```

## Step 2: Generate and confirm

Draft a PR title and body based on `git log origin/HEAD..HEAD --oneline` and the
diff. Follow the template structure if one exists, otherwise match recent PR style.

Show the full content to the user and wait for confirmation before proceeding.
Let the user edit if needed.

## Step 3: Create

```bash
gh pr create --draft --title "<title>" --body "<body>"
```

## Step 4: Show the link

Display the PR URL clearly. Ask if the user wants to open it in the browser:
```bash
open <url>  # only if the user says yes
```
