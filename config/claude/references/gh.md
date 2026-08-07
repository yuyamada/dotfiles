# GitHub CLI (gh) Usage

`gh` is wrapped with [ghtkn](https://github.com/suzuki-shunsuke/ghtkn) to issue
short-lived, scope-limited tokens. Two commands are available with different
permissions; choose based on the operation.

## Command Selection

| Command    | Token    | Use for                                                |
|------------|----------|--------------------------------------------------------|
| `gh`       | readonly | PR/Issue/Actions inspection, status checks, log reads  |
| `gh-write` | write    | PR/Issue creation, merges, comments, label/release ops |

## Rules
- Default to `gh` for any read operation
- Use `gh-write` only when the user explicitly asks for a write operation; do
  not switch to it autonomously after a read failure
- A write attempt through `gh` may surface as `Could not resolve to a
  Repository with the name '...'` — this is a permissions error, not a typo.
  Do not investigate or rename the repository when this happens
- When using `gh api`, the same split applies: `GET` goes through `gh`, any
  mutating method (`POST`/`PATCH`/`PUT`/`DELETE`) goes through `gh-write`
