# Coding Conventions

**Analysis Date:** 2026-03-21

## Overview

This codebase is a personal dotfiles repository containing configuration files, shell scripts, Python utilities, and Claude Code skills and agents. The primary code is written in Bash and Python, with extensive YAML and JSON configuration. The conventions reflect both automated tooling and explicit project rules documented in `config/claude/rules/`.

## Naming Patterns

**Files:**
- Bash scripts: lowercase with hyphens (e.g., `install.sh`, `ralph-loop-wrapper.sh`, `gh-project-in-review.sh`)
- Python scripts: lowercase with underscores (e.g., `statusline.py`, `fetch_stars.py`)
- Configuration files: descriptive lowercase with hyphens (e.g., `.gitignore`, `karabiner.json`)
- Skill directories: lowercase with hyphens (e.g., `plugin-stars`, `my-tasks`, `gh-project-in-review`)

**Functions (Bash):**
- Lowercase with underscores (e.g., `link_file`, `short_path`)
- Descriptive names indicating purpose
- Example from `install.sh`: `link_file() { ... }`

**Functions (Python):**
- Lowercase with underscores (e.g., `short_path()`, `fetch_stars_batch()`, `search_repos()`)
- Type hints used in function signatures
- Example from `fetch_stars.py`: `def fetch_stars_batch(repos: list[str]) -> dict[str, int]:`

**Variables:**
- Python: lowercase with underscores for constants and variables
  - Constants in UPPERCASE (e.g., `SEARCH_QUERIES`, `PINNED_REPOS`, `DENYLIST`)
  - Example: `search_queries = [...]` versus `PINNED_REPOS = [...]`
- Bash: descriptive names, often UPPERCASE for configuration (e.g., `DEFAULT_MAX_ITERATIONS`)
  - Local variables: lowercase with underscores (e.g., `api_key`, `src`, `dst`)

**Types (Python):**
- Use type hints in function signatures
- Example from `fetch_stars.py`: `def gh(*args: str) -> Optional[dict]:`
- Use Python 3.10+ syntax: `dict[str, int]` instead of `Dict[str, int]`

## Code Style

**Formatting:**
- No automatic formatter configured (no `.prettierrc`, `eslint`, or `black` in project)
- Python: follows implicit PEP 8 conventions
- Bash: follows conventional bash formatting

**Imports (Python):**
- Standard library imports listed first, separated by blank line
- Third-party imports below
- Example from `fetch_stars.py`:
  ```python
  import json
  import subprocess
  import sys
  from typing import Optional
  ```

**Line Length:**
- Python: implicit limit around 80-100 characters
- Bash: no strict limit observed, but commands are broken into logical lines

**Comments:**
- Docstrings used for functions and modules
- Example from `fetch_stars.py`: `"""Fetch and rank Claude Code plugin GitHub repos by star count."""`
- Single-line comments for inline logic
- Bash scripts include shebang and summary comment at top

## Import Organization (Python)

**Order:**
1. Standard library imports (`json`, `subprocess`, `sys`)
2. Type hints (`from typing import Optional`)
3. Blank line
4. Code begins

**Modules organized by functionality:**
- `fetch_stars.py`: organizes by data flow (search, fetch, display)
- `statusline.py`: organizes by task (parse data, format output)

## Error Handling

**Patterns:**

**Bash:**
- `set -e`: exit immediately if any command exits with non-zero status
- `set -u`: exit if undefined variable is used
- `set -o pipefail`: pipeline fails if any command fails
- Used in: `install.sh`, `gh-project-in-review.sh`
- Example from `gh-project-in-review.sh`:
  ```bash
  set -euo pipefail
  ```

**Python:**
- Try-except blocks for external command execution
- Return `None` on failure rather than raising exceptions
- Errors logged to stderr
- Example from `fetch_stars.py`:
  ```python
  try:
      return json.loads(result.stdout)
  except json.JSONDecodeError:
      return None
  ```
- Error messages printed to stderr: `print(f"Warning: ...", file=sys.stderr)`

**Bash parameter validation:**
- Parameter expansion with error messages
- Example from `gh-project-in-review.sh`:
  ```bash
  ORG="${1:?Usage: $0 <org> <project_number>}"
  ```

## Logging

**Framework:** Print-based (no logging library)

**Patterns:**
- Informational messages to stderr (progress, status)
- Example from `fetch_stars.py`:
  ```python
  print("Searching GitHub for Claude Code plugin repos...", file=sys.stderr)
  print(f"  [{query}] {len(repos)} repos found", file=sys.stderr)
  ```
- Normal output (results) to stdout
- Color codes used in `statusline.py` for formatting:
  ```python
  RESET = "\033[0m"
  GRAY  = "\033[2m"
  ```

## Comments

**When to Comment:**
- Function docstrings for all public functions
- Inline comments for non-obvious logic
- Bash scripts: header comments explaining purpose
- Code organization comments for major sections

**Example from `statusline.py`:**
```python
# Line 1: directory | branch
line1 = f"{GRAY}{dir_name}"
```

**Docstring style:**
- Single-line docstrings for simple functions
- Used in `fetch_stars.py`: `"""Fetch and rank Claude Code plugin GitHub repos by star count."""`

## Function Design

**Size:** Typically small, focused functions (10-30 lines)

**Parameters:**
- Bash: positional parameters with validation
- Python: named parameters with type hints
- Example with varargs from `fetch_stars.py`:
  ```python
  def gh(*args: str) -> Optional[dict]:
  ```

**Return Values:**
- Python: returns `None` on error, dictionary/list on success
- Bash: uses exit codes and stdout for output

## Module Design

**Exports:**
- Python: `if __name__ == "__main__": main()` pattern used
- Bash: functions defined at top, executed at bottom

**Single Responsibility:**
- `statusline.py`: formats status line for Claude Code interface
- `fetch_stars.py`: searches and ranks GitHub repos
- `install.sh`: symlinks dotfiles to home directory
- `ralph-loop-wrapper.sh`: wraps plugin with default arguments

## Command-Line Interfaces

**Bash scripts with arguments:**
- Arguments validated with parameter expansion defaults
- Help text in usage errors
- Example from `gh-project-in-review.sh`:
  ```bash
  ORG="${1:?Usage: $0 <org> <project_number>}"
  ```

**Python scripts:**
- No argument parser library (`argparse`) used
- Stdin/stdout for data flow
- Example from `statusline.py`: reads JSON from stdin

## Data Structures

**Python:**
- Dictionaries for structured data
- Sets for deduplication
- List comprehensions for filtering
- Example from `fetch_stars.py`:
  ```python
  aliases = {f"r{i}": repo for i, repo in enumerate(repos)}
  all_repos = [r for r in found if r not in DENYLIST]
  ```

**JSON/Configuration:**
- Used for settings, configurations, and data exchange
- Example: `config/claude/settings.json`, `config/karabiner/karabiner.json`

## Testing and Validation

**Input Validation:**
- Bash: Parameter validation with defaults
- Python: None checking, type hints
- External command validation: check return codes

## Documentation Standards

**Markdown files:**
- Used for skill descriptions, agent specs, and rules
- YAML frontmatter in skill files:
  ```yaml
  ---
  name: skill-name
  description: What it does
  allowed-tools: Bash
  ---
  ```
- Markdown headings for organization (## for major sections, ### for subsections)

**Skill files (`.planning/codebase/SKILL.md` pattern):**
- Located at `config/claude/skills/<name>/SKILL.md`
- Include steps, configuration instructions, and usage patterns
- Example in `plugin-stars/SKILL.md`: structured steps with command examples

---

*Convention analysis: 2026-03-21*
