# Testing Patterns

**Analysis Date:** 2026-03-21

## Test Framework

**Status:** Not detected

The codebase does not use automated testing frameworks. There are no test files, no test configuration files (`pytest.ini`, `jest.config.*`, `vitest.config.*`), and no testing libraries installed.

## Testing Strategy

**Manual Testing Only:**
- Scripts are tested manually before committing
- Skills and agents are tested interactively in Claude Code sessions
- Configuration changes are validated by actual use

## Code Verification Approach

Rather than automated tests, the codebase relies on:

1. **Type Hints (Python):**
   - Type annotations in function signatures catch certain classes of errors
   - Example from `fetch_stars.py`:
     ```python
     def fetch_stars_batch(repos: list[str]) -> dict[str, int]:
     ```
   - Type hints provide IDE feedback but are not enforced at runtime

2. **Error Handling Validation:**
   - Return `None` on failure, allowing upstream code to validate success
   - Example from `fetch_stars.py`:
     ```python
     if not data:
         return []
     return [r["fullName"] for r in data]
     ```

3. **Bash Strict Mode:**
   - Scripts use `set -euo pipefail` for early failure detection
   - Example from `gh-project-in-review.sh`:
     ```bash
     set -euo pipefail
     ```
   - This catches undefined variables and command failures immediately

4. **Parameter Validation:**
   - Bash scripts validate required arguments with error messages
   - Example from `gh-project-in-review.sh`:
     ```bash
     ORG="${1:?Usage: $0 <org> <project_number>}"
     ```

5. **External Command Validation:**
   - Check subprocess return codes and error output
   - Example from `fetch_stars.py`:
     ```python
     result = subprocess.run(
         ["gh", *args],
         capture_output=True,
         text=True,
     )
     if result.returncode \!= 0:
         print(f"Warning: gh command failed: {result.stderr.strip()}", file=sys.stderr)
         return None
     ```

## Testable Code Patterns

**Functions designed for testability (without explicit tests):**

**Python - Pure functions (side-effect free):**
- `short_path(path)` in `statusline.py`: string transformation
  ```python
  def short_path(path):
      if not path:
          return ""
      short = path.replace(os.path.expanduser("~"), "~", 1)
      head, tail = os.path.split(short)
      abbr = re.sub(r"/([^/])[^/]*", r"/\1", head)
      return f"{abbr}/{tail}"
  ```
  - Can be verified with various path inputs
  - Output is deterministic

**Python - Stateless data transformers:**
- `search_repos(query, limit)` in `fetch_stars.py`: transforms query string to repo list
  ```python
  def search_repos(query: str, limit: int = 100) -> list[str]:
      data = gh(
          "search", "repos", query,
          "--sort", "stars",
          "--limit", str(limit),
          "--json", "fullName",
      )
      if not data:
          return []
      return [r["fullName"] for r in data]
  ```

**Python - I/O wrapper patterns:**
- `gh(*args)` in `fetch_stars.py`: subprocess wrapper with error handling
  ```python
  def gh(*args: str) -> Optional[dict]:
      result = subprocess.run(
          ["gh", *args],
          capture_output=True,
          text=True,
      )
      if result.returncode \!= 0:
          print(f"Warning: gh command failed: {result.stderr.strip()}", file=sys.stderr)
          return None
      try:
          return json.loads(result.stdout)
      except json.JSONDecodeError:
          return None
  ```
  - Can be manually verified with different subprocess behaviors
  - Error handling is observable through stderr

## Mocking Patterns (Not Used)

No mocking libraries are used. External service calls (GitHub API via `gh` CLI) are executed as real commands.

**Implications:**
- Tests require real GitHub access
- No offline testing capability
- Command-line tool behavior is directly observable

## Integration Points

**External Tools:**
- `gh` CLI: GitHub API client (used in `fetch_stars.py`, `gh-project-in-review.sh`, skills)
- `git`: version control (used in `install.sh`, skills)
- `jq`: JSON query tool (used in `install.sh`, `gh-project-in-review.sh`)

**Manual Verification Approach:**
- Skills are tested by running them in Claude Code sessions
- Scripts are tested by executing them and validating output
- Configuration is tested by using the tools with the config

## Data Validation

**JSON/YAML Parsing:**
- Python: Try-except blocks for JSON parsing
  ```python
  try:
      data = json.loads(result.stdout).get("data", {})
  except json.JSONDecodeError:
      return {}
  ```
- Bash: `jq` validates and transforms JSON
  ```bash
  | jq '.data.organization.projectV2 | ...'
  ```

**Shell Variable Validation:**
- Parameter expansion with defaults and error messages
  ```bash
  ORG="${1:?Usage: $0 <org> <project_number>}"
  ```

## Test Data / Fixtures

No test fixtures or factory patterns are used. Testing relies on:
- Real external data (GitHub repositories)
- Real file system operations (`install.sh`)
- Real git repositories

## Deployment Testing

**Skills Testing Pattern:**
- Skills defined in `config/claude/skills/<name>/SKILL.md`
- Tested by invoking them manually in Claude Code
- Example: `plugin-stars` skill tested by running `/plugin-stars` command
- Configuration tested by verifying the skill works in live sessions

**Agent Testing Pattern:**
- Agents defined in `config/claude/agents/`
- Used in Claude Code workflows
- Verified through actual usage in conversations

## Common Test Scenarios (Manual)

**For `install.sh`:**
1. Fresh system: run script and verify symlinks created
2. Existing symlinks: run script and verify idempotency
3. Existing files: run script and verify prompts user to overwrite

**For `fetch_stars.py`:**
1. Normal operation: `/plugin-stars` command displays ranked list
2. Network failure: verify graceful error handling to stderr
3. Empty results: verify empty list handling

**For Skill scripts:**
1. Correct parameters: script succeeds and produces output
2. Missing parameters: script displays usage error
3. Invalid organization: script handles GitHub API errors gracefully

## Coverage Philosophy

No automated coverage tracking. Implicit coverage goals:
- All error paths are exercised manually (e.g., network failures, missing parameters)
- All code paths are triggered during actual use
- Configuration changes are validated through real operation

## Known Testing Gaps

**Areas without formalized testing:**
- Complex bash string manipulation in `install.sh`
- GraphQL query generation in `fetch_stars.py`
- Multi-step workflows in skills
- Edge cases in path abbreviation logic (`statusline.py`)

These areas rely on:
- Code review before changes
- Manual execution with various inputs
- User feedback when issues occur

## Adding Tests (If Needed)

Should automated testing be introduced:

**Python:**
- Use `pytest` with type hint support
- Place tests in `tests/` directory at repo root
- Test files named `test_<module>.py`
- Example test location: `tests/test_fetch_stars.py` for `fetch_stars.py`

**Bash:**
- Use `bats` (Bash Automated Testing System) or similar
- Place tests in `tests/` directory
- Test files named `*.bats`

**General:**
- Keep test naming consistent with module structure
- Use fixtures for external data (mock GitHub responses)
- Aim for 80%+ line coverage for critical paths

---

*Testing analysis: 2026-03-21*
