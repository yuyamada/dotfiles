# External Integrations

**Analysis Date:** 2026-03-21

## APIs & External Services

**GitHub:**
- GitHub CLI (`gh`) - Primary tool for all GitHub operations
  - PR and issue management (`gh pr`, `gh issue`)
  - Search functionality (`gh search repos`, `gh search prs`, `gh search issues`)
  - GraphQL API access (`gh api graphql`)
  - Project board queries (`gh api repos/{org}/{repo}/projects`)
  - Authentication via `gh auth`
- Used in skills:
  - `commit` - Commit staging and git workflow
  - `pr` - Pull request creation
  - `my-tasks` - Aggregates review requests and assigned issues
  - `plugin-stars` - Repository discovery and star ranking
  - `github-upload-image` - Image CDN upload via GitHub

**Claude Code Plugins:**
- Official plugin marketplace integration
  - AWS documentation MCP server - Cloud service knowledge
  - Google Developer Knowledge MCP server - Google Cloud/API documentation
  - Slack MCP - Channel and user search, message reading
  - Notion MCP - Task and page management
- Plugin installation and updates managed via `settings.json` `enabledPlugins`

**Cloud Services:**
- Google Cloud
  - GOOGLE_API_KEY stored in macOS Keychain
  - Sourced via `config/zsh/claude.sh` if `~/.claude_google_enabled` exists
  - Used by Google Developer Knowledge MCP and Serena plugin
- AWS
  - AWS documentation MCP server available
  - No credentials stored (read-only documentation access)

## Data Storage

**Databases:**
- None configured - Dotfiles repo is static configuration

**File Storage:**
- GitHub CDN - Image uploads via GitHub's attachment system
  - Used by `github-upload-image` skill
  - Creates URLs like `https://github.com/user-attachments/assets/{uuid}`
- Local filesystem - All dotfiles stored in `~/workspace/dotfiles/`

**Session/State Storage:**
- Zsh history - `~/.zsh_history` (local, 50,000 entry max)
- Neovim session persistence - Via `persistence.nvim` plugin
- Claude conversation transcripts - `~/.claude/projects/` (local JSONL format)
- Git worktrees - For parallel branch work

**Caching:**
- None configured

## Authentication & Identity

**Auth Providers:**
- GitHub
  - Method: `gh auth` (OAuth or PAT)
  - Scope: Full repo access, PR review, issue management
  - Status: Stored locally by GitHub CLI
- macOS Keychain
  - Method: `security find-generic-password` commands
  - Keys stored:
    - `anthropic-api-key` - Anthropic API credentials
    - `GOOGLE_API_KEY` (claude-mcp service) - Google API credentials
  - Used by: `config/zsh/claude.sh`
- Claude Code (local)
  - Credentials stored in `~/.claude/settings.json` (local, never committed)
  - MCP server credentials in env vars (GOOGLE_API_KEY via keychain)

**Implementation:**
- Custom authentication sourcing in `config/zsh/claude.sh`
- Conditional env var loading based on flag files:
  - `~/.claude_anthropic_enabled` - Enables ANTHROPIC_API_KEY loading
  - `~/.claude_google_enabled` - Enables GOOGLE_API_KEY loading
- macOS Keychain integration for credential storage (no plaintext secrets in dotfiles)

## Monitoring & Observability

**Error Tracking:**
- None configured - This is a local dotfiles repository

**Logs:**
- Claude Code tool access logging:
  - `~/.claude/tool-access.log` - All tool invocations logged via PostToolUse hook
  - Command: `bash -c '{ cat; echo; } >> ~/.claude/tool-access.log'`
- Session hooks:
  - `~/.claude/hooks/gsd-context-monitor.js` - Monitors context usage (PostToolUse)
  - `~/.claude/hooks/gsd-check-update.js` - Checks for GSD command updates (SessionStart)
  - `~/.claude/hooks/gsd-prompt-guard.js` - Validates edits before execution (PreToolUse)
- Zsh history - Shell command history in `~/.zsh_history`

**Status monitoring:**
- `~/.claude/statusline.py` - Real-time status display showing:
  - Current working directory and git branch
  - Model name
  - Context window usage percentage
  - Session cost in USD

## CI/CD & Deployment

**Hosting:**
- GitHub - Repository hosting
  - URL: `https://github.com/yuyamada/workspace/dotfiles`
  - Primary branch: `master`
  - Current branch: `main`

**CI Pipeline:**
- None configured - Dotfiles is configuration-only, no CI tests

**Git Workflow:**
- GitHub worktrees - For parallel branch development
- Conventional Commits - Enforced commit message format
  - Format: `<type>(<scope>): <description>`
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`

## Environment Configuration

**Required env vars:**
- `EDITOR=nvim` - Set in `config/zsh/env.sh`
- `LANG=en_US.utf-8` - Set in `config/zsh/env.sh`
- `PATH` - Enhanced with:
  - `$HOME/.local/bin` (first priority)
  - Homebrew curl bin (for Neovim avante compatibility)
  - Standard system paths

**Conditional env vars:**
- `ANTHROPIC_API_KEY` - Sourced from macOS Keychain if flag exists
- `GOOGLE_API_KEY` - Sourced from macOS Keychain if flag exists
- `STARSHIP_CONFIG` - Points to `~/.config/starship/starship.toml`

**Secrets location:**
- macOS Keychain - Secure storage for API credentials
- `.env*` files - Not committed (as per `.gitignore`)
- `~/.claude/settings.local.json` - Machine-specific settings (not in repo)

## Webhooks & Callbacks

**Incoming:**
- None configured - Dotfiles does not expose services

**Outgoing:**
- GitHub GraphQL queries - Via `gh api graphql` (read-only)
- GitHub REST API - Via `gh api` for:
  - PR creation and updates
  - Issue management
  - Project board queries
  - Image asset uploads to CDN
- Notion API - Via Notion MCP for task/note management
- Slack API - Via Slack MCP for channel and message access
- Google APIs - Via Google Developer Knowledge MCP
- AWS APIs - Via AWS documentation MCP (read-only)

## Claude Code MCP Servers

**Configured in `config/claude/settings.json`:**

**AWS Documentation:**
- Command: `uvx awslabs.aws-documentation-mcp-server@latest`
- Type: Direct process
- Tools: Search and read AWS documentation
- Permissions: Read-only

**Google Developer Knowledge:**
- URL: `https://developerknowledge.googleapis.com/mcp`
- Type: HTTP
- Auth: `X-Goog-Api-Key` header with `${GOOGLE_API_KEY}`
- Tools: Search, fetch, and batch-get Google documentation
- Permissions: Read-only (requires GOOGLE_API_KEY in env)

## Plugin Marketplaces

**Official marketplace (`claude-plugins-official`):**
- slack - Slack workspace integration
- context7 - Code context management
- serena - Semantic code analysis
- playwright - Browser automation
- pr-review-toolkit - Code review assistance
- notion - Notion workspace integration
- skill-creator - Create new skills
- superpowers - Extended capabilities
- code-simplifier - Code refactoring
- feature-dev - Feature development workflow
- chrome-devtools-mcp - Browser developer tools
- ralph-loop - Autonomous iteration
- code-review - Code review automation

**Custom marketplace (`claude-code-plugins`):**
- Source: `git@github.com:anthropics/claude-code`
- Only plugin: `code-review@claude-code-plugins`

---

*Integration audit: 2026-03-21*
