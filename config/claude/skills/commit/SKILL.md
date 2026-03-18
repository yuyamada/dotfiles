---
name: commit
description: >
  Stage, commit, and optionally push changes. Use when the user says "コミットして",
  "commit", "変更を保存", "push して", or finishes a task and needs to record the work.
  Does NOT create a PR — use the pr skill for that.
---

## What you're doing

Make sure the user is on the right branch, stage the relevant files, create a
well-crafted commit, and ask whether to push.

## Step 1: Check the branch

Run `git branch --show-current` and find the default branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'
```

If on the default branch:
- Look at `git log --oneline -5` and `git diff` to understand the work
- Propose a branch name that reflects it (e.g. `feat/add-statusline`, `fix/install-symlink`)
- Confirm with the user before creating: `git checkout -b <branch>`

If already on a feature branch, proceed directly.

## Step 2: Stage relevant files

Run `git status` and `git diff` to see what changed. Stage files clearly related
to the current task with `git add <specific files>`. If unrelated changes are mixed
in, ask the user whether to commit them together or separately. Avoid `git add .`
unless everything belongs to the same change.

## Step 3: Commit

Check `git log --oneline -5` to see if the repo uses a convention (e.g. `feat:`,
`fix:`). Generate a commit message that explains *why* the change was made. Show
it to the user and confirm before committing.

```bash
git commit -m "<message>"
```

## Step 4: Ask about push

Ask the user if they want to push:

- If yes: `git push -u origin <branch>`
- If no: stop here. Remind them they can run `/pr` after pushing.
