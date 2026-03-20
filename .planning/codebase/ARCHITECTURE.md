# Architecture

**Analysis Date:** 2026-03-21

## Pattern Overview

**Overall:** Distributed symlink-based configuration management with specialized subsystems

**Key Characteristics:**
- Configuration stored centrally in `config/` directory
- Symlinks distributed to standard Unix/XDG locations at setup time
- Modular tool-specific configurations (zsh, tmux, nvim, etc.)
- Claude Code extensions through agents and skills
- Hook-based monitoring and automation for development workflows

## Layers

**Configuration Layer:**
- Purpose: Central repository for all dotfiles organized by tool
- Location: `config/`
- Contains: Tool-specific config files, settings, rules, agents, skills
- Depends on: Operating system shell environments, application standard locations
- Used by: Installation script (`install.sh`) to create symlinks

**Symlink Distribution Layer:**
- Purpose: Deploy configurations to standard locations (~/.config, ~/.zshrc, ~/.claude, etc.)
- Location: `install.sh`
- Contains: Symlink creation logic, validation, interactive setup
- Depends on: File system operations, user interaction
- Used by: Initial setup process

**Shell Configuration Layer:**
- Purpose: Set up shell environment variables, aliases, hooks
- Location: `config/zsh/` with separate module files
- Contains: `zshrc` (entry point), `env.sh`, `aliases.sh`, `theme.sh`, `tmux.sh`, `claude.sh`, `go.sh`, `bun.sh`, `gcloud.sh`, `zle.sh`
- Depends on: Sheldon plugin manager, Mise tool manager, Rancher Desktop, tmux
- Used by: macOS zsh shell at startup

**Editor Configuration Layer:**
- Purpose: Neovim IDE and plugin management
- Location: `config/nvim/`
- Contains: `init.lua` (entry point), `lua/config/` (general, keymaps, appearance), `lua/plugins/` (plugin definitions), `lazy-lock.json`
- Depends on: Lazy.nvim plugin manager, various LSP and tools
- Used by: Neovim instances for development

**Terminal Multiplexer Layer:**
- Purpose: tmux session and window management with plugins
- Location: `config/tmux/`
- Contains: `tmux.conf` (main), theme configs, helper scripts (short-path.sh, fzf-search.sh, open-url.sh)
- Depends on: TPM (tmux plugin manager), tmux plugins (resurrect, continuum, pain-control, fzf-url)
- Used by: tmux sessions during terminal usage

**Claude Code Integration Layer:**
- Purpose: Configure Claude Code editor with agents, skills, and rules
- Location: `config/claude/`
- Contains: `settings.json` (permissions and hooks), `CLAUDE.md` (rules via imports), rules files, agents (workflow definitions), skills (automation scripts), `statusline.py`
- Depends on: Claude Code application, MCP plugins, git, various CLI tools
- Used by: Claude Code IDE for AI-assisted development

**Rules and Workflow Layer:**
- Purpose: Define development practices and tool permissions
- Location: `config/claude/rules/`
- Contains: `workflow.md`, `skills.md`, `git.md`, `tools.md`, `permissions.md`
- Depends on: User conventions and best practices
- Used by: Claude Code for enforcing patterns and restricting operations

## Data Flow

**Initialization Flow:**

1. User runs `./install.sh`
2. Script checks for existing configs at target locations
3. For each tool directory in `config/`:
   - Creates symlink to `~/.config/{tool}` (except claude, agents, cursor)
   - Creates tool-specific symlinks (e.g., `~/.zshrc`, `~/.claude/settings.json`)
3. Script creates skill symlinks in `~/.claude/skills/`
4. Script creates rule and agent symlinks in `~/.claude/`
5. Cursor rules file is copied (not symlinked) to `~/.cursorrules`
6. Optional: User is prompted to store Anthropic API key in macOS Keychain

**Shell Startup Flow:**

1. Shell loads `~/.zshrc` (symlinked to `config/zsh/zshrc`)
2. `zshrc` sources Sheldon plugin manager configuration
3. Sheldon loads configured shell plugins
4. Shell sources `config/zsh/*.sh` files for environment setup
5. If not in tmux: tmux is auto-started with default session
6. Shell is ready with aliases, environment variables, and plugins

**Claude Code Startup Flow:**

1. Claude Code reads `~/.claude/settings.json` (symlinked to `config/claude/settings.json`)
2. Settings loads permissions from `permissions` field
3. Rules are imported from `~/.claude/rules/` (symlinked to `config/claude/rules/`)
4. Agents are loaded from `~/.claude/agents/` (symlinked to `config/claude/agents/`)
5. Skills are loaded from `~/.claude/skills/` (symlinked to individual skill directories)
6. Pre/Post tool use hooks are registered for monitoring and validation
7. GSD agents are available for workflow automation

**State Management:**

- **Configuration state:** Immutable at `config/` level, deployed via symlinks to live locations
- **Terminal state:** Managed by tmux sessions, persisted by tmux-resurrect/tmux-continuum plugins
- **Claude state:** Stored in `~/.claude/` with symlinks back to dotfiles for version control
- **Development state:** Projects tracked in `~/.claude/projects/` with separate git worktrees in `.worktrees/`

## Key Abstractions

**Configuration Module:**
- Purpose: Logically grouped settings for a single tool
- Examples: `config/zsh/`, `config/nvim/`, `config/tmux/`, `config/claude/`
- Pattern: Each tool has dedicated directory with entry point file

**Skill:**
- Purpose: Automation script with specific allowed permissions and workflow
- Examples: `config/claude/skills/commit/`, `config/claude/skills/pr/`, `config/claude/skills/retrospect/`
- Pattern: SKILL.md front-matter with allowed-tools, context injection via `\!` commands

**Agent:**
- Purpose: Long-form Claude instructions for specialized workflows
- Examples: `config/claude/agents/gsd-codebase-mapper.md`, `config/claude/agents/gsd-planner.md`
- Pattern: YAML front-matter (name, description, tools, color) followed by role and instructions

**Hook:**
- Purpose: Automated action triggered by Claude Code events
- Examples: PostToolUse logging, SessionStart version checks, Notification for permission prompts
- Pattern: Defined in `settings.json` hooks section with matcher and command

## Entry Points

**Installation Entry Point:**
- Location: `install.sh`
- Triggers: User runs during initial setup
- Responsibilities: Create symlinks, validate configs, prompt for optional setup (API key)

**Shell Entry Point:**
- Location: `config/zsh/zshrc`
- Triggers: New terminal session started
- Responsibilities: Load plugins, set environment, configure shell behavior

**Editor Entry Points:**
- Neovim: `config/nvim/init.lua`
- Claude Code: `config/claude/settings.json` (settings) and `config/claude/CLAUDE.md` (rules)

**Automation Entry Points:**
- Skill execution: User triggers via `/skillname` or natural language
- Agent execution: User triggers via `/agentname` or GSD commands
- Hooks: Triggered automatically by Claude Code events

## Error Handling

**Strategy:** Graceful degradation with user prompts and validation

**Patterns:**
- `install.sh` prompts user before overwriting existing configs
- `zshrc` uses conditional checks before sourcing (e.g., Rancher Desktop, Homebrew paths)
- Hooks use `|| true` and timeout handling to prevent failures
- Symlink validation checks for existing symlinks before attempting creation

## Cross-Cutting Concerns

**Logging:**
- Claude Code hooks log tool usage to `~/.claude/tool-access.log`
- GSD context monitoring via `gsd-context-monitor.js` hook
- Manual logging via `zsh` history and tmux session logs

**Configuration Management:**
- Centralized in version-controlled `config/` directory
- Deployed via symlinks to avoid duplication
- Tool-specific formats preserved (JSON, Lua, tmux, shell scripts)

**Authentication:**
- API keys stored in macOS Keychain (optional setup in `install.sh`)
- Environment variables configured per-tool (e.g., AWS credentials in env.sh)
- Claude Code permissions managed via `settings.json` allow/deny lists

**Plugin Management:**
- Shell: Sheldon for plugin organization
- Neovim: Lazy.nvim for plugin management with lock file
- tmux: TPM (tmux plugin manager) with configured plugins
- Claude Code: MCP plugins configured in settings.json

---

*Architecture analysis: 2026-03-21*
