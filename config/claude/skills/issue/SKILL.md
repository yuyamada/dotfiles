---
name: issue
description: >
  Create a well-structured GitHub issue from a vague or rough idea.
  Use when the user wants to file a GitHub issue, capture a bug or feature
  request, or says things like "issue 作って", "issue 起票して", "create an
  issue", "file a bug", "これ issue にしたい", "I have an idea for...", or
  describes a problem they want to formalize. Also triggers when the user
  has a fuzzy problem statement and wants help shaping it into an actionable
  GitHub issue. Accepts an optional --repo owner/repo argument to target a
  specific repository; otherwise auto-detects from the current directory.
allowed-tools: Bash(gh repo view:*), Bash(gh api --method GET *), Bash(gh issue create:*), Bash(gh issue list:*), Bash(open:*)
---

## Context

- Detected repo: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "not detected"`

## Overview

Help the user shape a rough idea into a clear, actionable GitHub issue —
then file it. The goal is to ask just enough questions to write a useful
issue, not to over-formalize or slow them down.

## Step 1: Determine target repository

If `--repo owner/repo` was passed as an argument, use that repo.

Otherwise, use the detected repo above. If detection failed (shows "not
detected"), ask the user: "Which repo should this issue go in? (owner/repo)"

## Step 2: Understand the idea

The user probably gave you a rough description already. Ask only what's
genuinely missing to write a useful issue. Consider these areas — ask only
the ones that are actually unclear:

- **Type**: Bug, feature request, improvement, or question?
- **Core problem or goal**: What's broken, or what outcome do they want?
- **Current vs expected** (bugs): What happens now vs what should happen?
- **Motivation** (features): Why does this matter? What's the use case?
- **Details**: Repro steps, edge cases, constraints, prior art?

Keep it conversational. One or two focused questions is usually enough.
If the user's message is already detailed, skip directly to Step 3.

## Step 3: Check for a repo issue template

Before drafting anything, check whether the target repo defines its own
issue template(s) — always do this, even if the idea already feels
well-formed. Using the repo's own structure beats inventing a generic one.

```bash
gh api --method GET repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE --jq '.[].name'
```

- If this lists one or more files: fetch the one that best matches what the
  user described (match on the template's `name:`/`about:` frontmatter —
  e.g. a task/investigation vs. a bug vs. a feature request). If more than
  one plausibly fits, ask the user which to use.

  ```bash
  gh api --method GET repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE/<file> --jq '.content' | base64 -d
  ```

  Use that template's exact section structure for Step 4 — keep its
  headings, checkbox lists, and HTML comments/placeholders as scaffolding,
  filling them in with the gathered content. Carry over its `title:`
  prefix/labels from the frontmatter if present.
- If the command 404s or returns nothing: no repo-specific template exists.
  Fall back to the generic structure in Step 4.

## Step 4: Draft the issue

Write a title and body based on what you've gathered.

**Title** — specific, actionable, under 72 chars:
- Bug: what goes wrong, e.g. `git remote not detected in monorepo workspaces`
- Feature: verb + what, e.g. `Add --repo flag to github-issue skill`

**Body** — if a repo template was found in Step 3, follow its structure.
Otherwise use this generic structure, omitting sections that don't apply:

```
## Summary
<1-2 sentences: what this is and why it matters>

## Details
<bug: steps to reproduce + current vs expected behavior>
<feature: what "done" looks like, acceptance criteria if helpful>

## Context
<optional: motivation, related issues, links, screenshots>
```

## Step 5: Confirm with the user

Show the full draft (title + body) and ask if they're happy with it.
Let the user edit anything. Proceed only after they confirm.

## Step 6: Create the issue

```bash
gh issue create --repo <owner/repo> --title "<title>" --body "<body>"
```

Display the created issue URL clearly. Ask if the user wants to open it:

```bash
open <url>  # only if they say yes
```
