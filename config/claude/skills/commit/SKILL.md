---
name: commit
description: >
  Stage relevant files, create a well-crafted commit, and optionally push.
  Use when the user says "コミットして", "commit", "変更を保存", "save my changes",
  finishes a task, or asks to record their work. Does NOT create a PR — use the
  pr skill for that.
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git checkout:*), Bash(git push:*), Bash(git log:*), Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git symbolic-ref:*)
---

## Current state

- Branch: !`git branch --show-current`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'`
- Changes: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Overview

Make sure the user is on the right branch, stage the relevant files, create a
well-crafted commit, and ask whether to push.

## Steps

### Step 1: Check the branch

If on the default branch:
- Look at the current state above to understand the work
- Propose a branch name that reflects it (e.g. `feat/add-statusline`, `fix/install-symlink`)
- Confirm with the user before creating: `git checkout -b <branch>`

If already on a feature branch, proceed directly.

### Step 2: Stage relevant files

Run `git diff` to see what changed. Stage files clearly related to the current
task with `git add <specific files>`. If unrelated changes are mixed in, ask the
user whether to commit them together or separately. Avoid `git add .` unless
everything belongs to the same change.

### Step 3: Commit

Check recent commits to see if the repo uses a convention (e.g. `feat:`, `fix:`).
Generate a commit message that explains *why* the change was made. Show it to the
user and confirm before committing.

```bash
git commit -m "<message>"
```

### Step 4: Ask about push

Ask the user if they want to push:

- If yes: `git push -u origin <branch>`
- If no: stop here.
- If yes and the user wants to open a PR next, let them know they can run `/pr` to continue.
