# Tool Usage

## Shell Commands

- Prefer already-permitted shell commands (`grep`, `sed`, `awk`, `find`, `jq`, `git`, `ls`, `diff`, etc.) over Python or other interpreters
- Before reaching for `python` or `python3`, ask: "can I solve this with permitted shell tools?"
- Only use Python when there is genuinely no shell-based alternative — this will require an approval prompt and that's acceptable
- Goal: minimize unnecessary approval prompts by staying within pre-approved commands
