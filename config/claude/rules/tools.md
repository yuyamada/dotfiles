# Tool Usage

## Shell Commands

- Always use shell commands (`grep`, `sed`, `awk`, `find`, `jq`, `git`, `ls`, `diff`, etc.) — never use Python or other interpreters
- **Do not use `python` or `python3` under any circumstances**, even if there is no obvious shell alternative — find a shell-based solution instead
- Goal: minimize unnecessary approval prompts by staying within pre-approved commands
- **Always use `--method GET` with `gh api` for read operations** — this matches the auto-approval pattern in `permissions.allow`; omitting it will trigger a permission prompt
- **Never include newlines in Bash commands** — newlines trigger a security prompt that bypasses `permissions.allow` and blocks auto-approval. Use `&&` or `;` to chain commands, and keep all arguments (including `--jq` filters) on a single line
