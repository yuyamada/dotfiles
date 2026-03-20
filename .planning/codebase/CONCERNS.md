# Codebase Concerns

**Analysis Date:** 2026-03-21

## Tech Debt

**Circular symlink in ralph-loop skill:**
- Issue: `/Users/yuyamada/workspace/dotfiles/config/claude/skills/ralph-loop/ralph-loop` is a symlink that points to its parent directory, creating a circular reference
- Files: `config/claude/skills/ralph-loop/ralph-loop`
- Impact: Tool invocation may fail or behave unexpectedly when resolving paths; could cause infinite loops in directory traversal utilities
- Fix approach: Remove the circular symlink and verify the actual script entry point for ralph-loop initialization

**Unversioned GSD agents:**
- Issue: Many GSD agents in `config/claude/agents/` are dynamically generated (prefixed with `gsd-`) and added to `.gitignore`, creating a maintenance gap where agent definitions are not version-controlled
- Files: `.gitignore` (ignores `config/claude/agents/gsd-*.md`), `config/claude/agents/` (contains 22 agent files)
- Impact: Agent definitions cannot be reviewed in git history; changes to agents are lost across installations; no collaborative review possible
- Fix approach: Either commit agent definitions or document a clear process for agent regeneration and validation

**External MCP dependency without fallback:**
- Issue: `settings.json` configures `google-developer-knowledge` MCP server with HTTP endpoint and `${GOOGLE_API_KEY}` environment variable, but no validation or error handling if API key is missing
- Files: `config/claude/settings.json` (lines 173-179)
- Impact: If `GOOGLE_API_KEY` is not set in environment, the MCP server will fail to initialize silently or with cryptic errors
- Fix approach: Add pre-flight validation in settings or document required environment setup; consider adding fallback to local documentation

**AWS MCP server via uvx with no version pinning:**
- Issue: `settings.json` uses `uvx` to run AWS documentation MCP server with `@latest` version specifier (line 167)
- Files: `config/claude/settings.json` (lines 164-171)
- Impact: Breaking changes in MCP server could silently affect Claude Code functionality; no reproducibility across machines with different installation times
- Fix approach: Pin to specific version (e.g., `awslabs.aws-documentation-mcp-server@1.2.3`) or document expected compatibility versions

## Known Issues

**Graphql Query Construction in fetch_stars.py:**
- Symptoms: Script constructs GraphQL aliases dynamically but uses numeric prefixes (`r0`, `r1`, etc.) which could fail if GraphQL validation changes
- Files: `config/claude/skills/plugin-stars/scripts/fetch_stars.py` (lines 64-69)
- Trigger: Running `/plugin-stars` skill with >100 repos
- Workaround: Currently batches in chunks of 80 (line 107) to stay under GraphQL alias limit; conservative but safe

**Hard-coded subprocess paths:**
- Symptoms: Multiple scripts assume `git`, `gh`, `tmux`, `fzf-tmux` are in PATH without checking existence first
- Files: `config/claude/statusline.py` (line 25), `config/claude/skills/ralph-loop/SKILL.md` (execution path), `config/tmux/fzf-search.sh` (lines 10, 29)
- Trigger: Running on system where tools are not in standard PATH locations
- Workaround: Set `$PATH` correctly or use full paths; no explicit validation in scripts

## Security Considerations

**API key in environment variable without masking:**
- Risk: `GOOGLE_API_KEY` passed through `settings.json` to MCP server; if settings file is accidentally exposed or logged, API key could be revealed
- Files: `config/claude/settings.json` (line 177)
- Current mitigation: File ownership/permissions (user-readable only), `settings.json` not committed to git
- Recommendations: Use system keychain integration where possible; document that `settings.json` should never be shared; consider encrypted environment variable storage

**Keychain storage of Anthropic API key:**
- Risk: `install.sh` prompts for and stores Anthropic API key in macOS Keychain (lines 99-104), but no validation that the password was actually stored successfully
- Files: `install.sh` (lines 99-104)
- Current mitigation: Keychain is OS-managed and reasonably secure
- Recommendations: Add error handling if `security add-generic-password` fails; consider using environment variable with CI/CD or documentation for headless systems

**Unquoted shell variables in path expansion:**
- Risk: `install.sh` contains unquoted variables in several places (`$DOTFILES_DIR`, `$dir`, `$dst`) that could cause word-splitting or globbing issues if paths contain spaces
- Files: `install.sh` (multiple lines: 29, 43, 50, etc.)
- Current mitigation: Set -e will fail on missing directory, but doesn't protect against expansion issues
- Recommendations: Quote all variable expansions (`"$var"`) throughout script; use safe path handling

**Temporary file in /tmp without TMPDIR override:**
- Risk: `config/tmux/fzf-search.sh` creates temp file in hardcoded `/tmp` directory (line 5) instead of respecting `$TMPDIR`
- Files: `config/tmux/fzf-search.sh` (line 5)
- Current mitigation: File is cleaned up with trap (line 6)
- Recommendations: Use `${TMPDIR:-/tmp}` for portable temp directory selection

## Performance Bottlenecks

**Plugin stars script with sequential GitHub API calls:**
- Problem: `fetch_stars.py` makes multiple sequential `gh search` calls (lines 97-100), then batches GraphQL calls (lines 107-109), creating latency for large result sets
- Files: `config/claude/skills/plugin-stars/scripts/fetch_stars.py`
- Cause: Sequential queries for multiple search terms before batching; no parallel processing
- Improvement path: Batch search queries across all search terms in parallel, or cache results with expiration

**statusline.py subprocess call on every context event:**
- Problem: `settings.json` configures statusline to run `python3` process for every context evaluation (line 115), spawning a new Python interpreter each time
- Files: `config/claude/statusline.py`, `config/claude/settings.json` (lines 113-115)
- Cause: Inline shell command for status display; no caching or memoization
- Improvement path: Implement persistent daemon or cache status for N seconds; consider compiled alternative

## Fragile Areas

**install.sh with interactive prompts:**
- Files: `config/install.sh` (lines 21-25, 95-97)
- Why fragile: Uses `read -p` with `-n 1` for single-character confirmation; can hang or fail silently in non-interactive environments (CI/CD, remote SSH)
- Safe modification: Wrap prompts in `if [ -t 0 ]` checks; add `--non-interactive` flag option; document headless setup
- Test coverage: No tests for install.sh; manual testing only

**Cursor CLI config merge with jq dependency:**
- Files: `config/install.sh` (lines 78-92)
- Why fragile: Script checks for `jq` and falls back to string concatenation if missing (line 89), but the fallback produces invalid JSON if `permissions.json` contains certain characters
- Safe modification: Either require `jq` or use proper JSON merging library; validate output JSON
- Test coverage: No validation that created JSON is valid; no tests for edge cases

**Symlink resolution in install.sh:**
- Files: `config/install.sh` (lines 16-27)
- Why fragile: Checks symlink existence with `[ -L "$dst" ]` but doesn't validate that the target actually exists; could create pointing-to-nowhere symlinks
- Safe modification: Add `test -e "$dst"` check after `readlink` to verify target; warn user if symlink target is broken
- Test coverage: No tests for broken symlink scenarios

**GSD agent dependency on external file updates:**
- Files: `config/claude/agents/` (all agent markdown files)
- Why fragile: Agents reference other tools and MCP servers that may be updated externally; no validation that referenced tools still exist or work
- Safe modification: Add simple YAML frontmatter validation in agents; reference specific versions of tools; add agent health check script
- Test coverage: No tests for agent validity; no linting

## Scaling Limits

**Plugin stars search limited to 100 repos per query:**
- Current capacity: 100 repos per search query, batched in chunks of 80 for GraphQL
- Limit: If more than ~400-500 unique repos exist matching queries, results will be truncated
- Scaling path: Implement pagination for `gh search` results; increase batch size if GitHub GraphQL limits allow; cache full result set

**Temporary file exhaustion in fzf-search.sh:**
- Current capacity: Creates one temp file per fzf invocation
- Limit: If multiple fzf searches run simultaneously, `/tmp` could accumulate many temp files (though trap cleanup should prevent this)
- Scaling path: Use named pipes or memory-based temporary storage; implement stricter cleanup

## Dependencies at Risk

**GitHub CLI (gh) without version requirement:**
- Risk: Scripts depend on `gh` command but don't check minimum version; API changes in newer `gh` versions could break tools
- Impact: `fetch_stars.py` (GraphQL queries), `install.sh` (git operations), Cursor permissions sync (jq command)
- Migration plan: Pin to tested `gh` version in Brewfile or document minimum version; add version check in scripts

**Python 3.10+ type hint syntax:**
- Risk: `fetch_stars.py` uses `dict[str, int]` syntax (line 58, 85) which requires Python 3.9+; `statusline.py` uses f-strings (Python 3.6+)
- Impact: Scripts will fail on Python <3.9
- Migration plan: Document minimum Python version requirement; add explicit version check in shebang or script startup

**Deprecated subprocess.run text parameter:**
- Risk: `fetch_stars.py` uses `text=True` parameter (deprecated in favor of `encoding='utf-8'` in newer Python)
- Impact: May produce deprecation warnings in Python 3.10+
- Migration plan: Update to `encoding='utf-8'` for forward compatibility

## Missing Critical Features

**No error recovery in install.sh:**
- Problem: If symlink creation fails partway through, script continues rather than rolling back; user could end up with partial installation
- Blocks: Cannot reliably re-run install.sh to fix broken state
- Recommendation: Add rollback function; validate all symlinks created successfully before declaring success

**No validation of Agent markdown syntax:**
- Problem: Agent definitions are markdown files with YAML frontmatter; no linter validates the format
- Blocks: Invalid agent definitions silently fail to load; hard to debug
- Recommendation: Add agent validator script; integrate into pre-commit hook

**No documentation for MCP server setup:**
- Problem: `settings.json` references two MCP servers (aws-documentation, google-developer-knowledge) but doesn't document how to set up or troubleshoot them
- Blocks: New setup cannot easily configure these services
- Recommendation: Add MCP_SETUP.md with per-server instructions

## Test Coverage Gaps

**install.sh has zero test coverage:**
- What's not tested: Symlink creation logic, permission handling, Cursor JSON merge, Keychain integration
- Files: `config/install.sh`
- Risk: Breaking changes could go undetected until user runs install; no CI validation
- Priority: High

**fetch_stars.py lacks error case tests:**
- What's not tested: Behavior when `gh search` returns no results, GraphQL errors, malformed JSON responses
- Files: `config/claude/skills/plugin-stars/scripts/fetch_stars.py`
- Risk: Script could crash or produce empty output without clear error message
- Priority: Medium

**statusline.py has no tests for malformed input:**
- What's not tested: Missing JSON fields, git command failures, unparseable branch names
- Files: `config/claude/statusline.py`
- Risk: Statusline could crash if input data is unexpected, breaking Claude Code UI
- Priority: High

**ralph-loop wrapper unchecked:**
- What's not tested: Behavior when ralph-loop plugin is not installed, --max-iterations parsing edge cases
- Files: `config/claude/scripts/ralph-loop-wrapper.sh`
- Risk: Silent failures if plugin setup changes; --max-iterations could be misinterpreted
- Priority: Medium

---

*Concerns audit: 2026-03-21*
