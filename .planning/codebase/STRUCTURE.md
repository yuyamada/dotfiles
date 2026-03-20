# Codebase Structure

**Analysis Date:** 2026-03-21

## Directory Layout

```
dotfiles/
├── config/                 # Central configuration repository for all tools
│   ├── claude/            # Claude Code IDE settings, agents, skills, rules
│   ├── nvim/              # Neovim editor configuration with Lua
│   ├── zsh/               # Zsh shell configuration with modular sourcing
│   ├── tmux/              # tmux multiplexer configuration with plugins
│   ├── karabiner/         # macOS Karabiner keyboard remapping
│   ├── ghostty/           # Ghostty terminal emulator config
│   ├── wezterm/           # WezTerm terminal configuration
│   ├── starship/          # Shell prompt configuration
│   ├── sheldon/           # Shell plugin manager configuration
│   ├── serena/            # Serena semantic coding tools config
│   ├── cursor/            # Cursor IDE settings and permissions
│   └── bat/               # Bat syntax highlighting configuration
├── .claude/               # Local Claude Code runtime data (not in .gitignore)
│   └── worktrees/         # Git worktree directories for parallel branches
├── .planning/             # Planning documents and analysis
│   └── codebase/          # Codebase analysis documents (ARCHITECTURE.md, etc.)
├── docs/                  # Project documentation
│   └── superpowers/       # Claude Code workflow specifications
│       ├── plans/         # Implementation plans
│       └── specs/         # Design specifications
├── .memsearch/            # Memory index system for context persistence
│   └── memory/            # Memory files for lessons learned
├── .playwright-mcp/       # Playwright MCP (Model Context Protocol) setup
├── .worktrees/            # Git worktree cache directory
├── tmp/                   # Temporary files and build artifacts
├── .git/                  # Git repository metadata
├── README.md              # Project overview
└── install.sh             # Setup script for symlinking configs
```

## Directory Purposes

**config/:**
- Purpose: Version-controlled source for all application configurations
- Contains: Tool-specific config files, JSON, Lua, shell scripts, YAML
- Key files: `claude/CLAUDE.md` (rules entry point), `nvim/init.lua`, `zsh/zshrc`, `tmux/tmux.conf`

**config/claude/:**
- Purpose: Claude Code editor customization and automation
- Contains: Settings, rules, agents, skills for Claude workflows
- Key files:
  - `settings.json` - Permissions, hooks, MCP plugin configuration
  - `CLAUDE.md` - Master rules file with @imports to rules/
  - `statusline.py` - Custom status bar display script
  - `agents/` - 22 agents for various GSD workflows
  - `skills/` - 8 automation skills (commit, pr, retrospect, etc.)
  - `rules/` - 5 rule modules imported by CLAUDE.md

**config/claude/agents/:**
- Purpose: Long-form instructions for specialized Claude workflows
- Contains: Agent definitions with YAML front-matter
- Key agents:
  - `gsd-codebase-mapper.md` - Analyzes codebases, writes documentation
  - `gsd-planner.md` - Creates implementation plans
  - `gsd-executor.md` - Executes implementation phases
  - `gsd-debugger.md` - Diagnoses and fixes bugs
  - Performance, UI, security reviewers for code quality

**config/claude/skills/:**
- Purpose: Automated workflows triggered by user commands
- Contains: `SKILL.md` with allowed-tools, scripts, and context injection
- Skill directories:
  - `commit/` - Stage, commit, optionally push changes
  - `pr/` - Create or update pull requests
  - `retrospect/` - Record lessons learned in project memory
  - `ralph-loop/` - Iterative refinement with up to 5 iterations
  - `parallel-review/` - Run multiple review agents in parallel
  - `my-tasks/` - Notion-based task management integration

**config/claude/rules/:**
- Purpose: Development practices and operation guidelines
- Contains: Markdown rule modules imported by CLAUDE.md
- Rules:
  - `workflow.md` - Plan mode, sub-agents, self-improvement, verification
  - `skills.md` - Skill creation and deployment guidelines
  - `git.md` - Commit messages, branch management, PR standards
  - `tools.md` - Tool preference ordering (shell > Python)
  - `permissions.md` - Proactive permission management

**config/nvim/:**
- Purpose: Neovim IDE configuration with plugin management
- Contains: Lua configuration files organized by purpose
- Key files:
  - `init.lua` - Entry point, loads config modules and plugins
  - `lua/config/general.lua` - Core editor settings
  - `lua/config/keymaps.lua` - Key bindings
  - `lua/config/appearance.lua` - Visual theme and UI
  - `lua/config/lazy.lua` - Lazy.nvim plugin manager bootstrap
  - `lua/plugins/` - 20+ plugin specifications (lsp, completion, git, etc.)
  - `lazy-lock.json` - Plugin version lock file

**config/zsh/:**
- Purpose: Zsh shell configuration with modular organization
- Contains: Separate shell script modules sourced in sequence
- Key files:
  - `zshrc` - Entry point, sources Sheldon and module files
  - `env.sh` - Environment variables, PATH setup
  - `aliases.sh` - Command aliases
  - `theme.sh` - Starship prompt theme configuration
  - `tmux.sh` - Tmux auto-start logic
  - `claude.sh` - Claude Code specific settings
  - `go.sh`, `bun.sh`, `gcloud.sh` - Tool-specific environment
  - `zle.sh` - Zsh line editor key bindings

**config/tmux/:**
- Purpose: tmux terminal multiplexer configuration and plugins
- Contains: Configuration, themes, and helper scripts
- Key files:
  - `tmux.conf` - Main configuration, plugin definitions, keybindings
  - `appearance.tmux.conf` - Status bar and pane styling
  - `iceberg_minimal.tmux.conf` - Iceberg color theme
  - Helper scripts:
    - `short-path.sh` - Abbreviate current path in window titles
    - `fzf-search.sh` - Fuzzy search integration
    - `open-url.sh` - Open URLs from tmux output

**config/serena/:**
- Purpose: Serena semantic coding tools configuration
- Contains: YAML configuration for symbol-based code navigation
- Key files: `serena_config.yml`

**config/cursor/:**
- Purpose: Cursor IDE settings and CLI permissions
- Contains: Permissions JSON for Cursor CLI operations
- Key files: `permissions.json`

**config/karabiner/:**
- Purpose: macOS keyboard remapping configuration
- Contains: JSON configuration for Karabiner Elements
- Key files: `karabiner.json`

**.claude/:**
- Purpose: Local runtime data for Claude Code (git-tracked but excluded from public dotfiles)
- Contains: Worktree directories, hooks, project-specific memory
- Key files:
  - `worktrees/` - Git worktree branches (recursing-hamilton, etc.)
  - `hooks/` - Custom Node.js hooks for monitoring and context

**.planning/codebase/:**
- Purpose: Analysis documents for codebase understanding
- Contains: Generated documentation by gsd-codebase-mapper
- Key files:
  - `ARCHITECTURE.md` - Architecture patterns and data flows
  - `STRUCTURE.md` - Directory layout and organization
  - `STACK.md` - Technology stack and dependencies
  - `INTEGRATIONS.md` - External services and APIs
  - `CONVENTIONS.md` - Coding style and patterns
  - `TESTING.md` - Test framework and patterns
  - `CONCERNS.md` - Technical debt and issues

**docs/superpowers/:**
- Purpose: Documentation for Claude Code workflow design
- Contains: Implementation plans and specification documents
- Key files:
  - `plans/` - Implementation plan markdown files
  - `specs/` - Design specification documents

## Key File Locations

**Entry Points:**

- `README.md` - Project overview with setup instructions
- `install.sh` - Main setup script for initial symlink creation
- `config/zsh/zshrc` - Shell environment entry point
- `config/nvim/init.lua` - Neovim configuration entry point
- `config/claude/settings.json` - Claude Code settings entry point
- `config/claude/CLAUDE.md` - Claude Code rules master file

**Configuration:**

- `config/claude/settings.json` - Permissions, hooks, MCP plugins
- `config/nvim/lazy-lock.json` - Neovim plugin versions
- `config/starship/starship.toml` - Shell prompt styling
- `config/sheldon/plugins.toml` - Shell plugin manager configuration

**Core Logic:**

- `config/zsh/env.sh` - Environment variable setup
- `config/nvim/lua/config/lazy.lua` - Plugin initialization
- `config/tmux/tmux.conf` - Tmux session management
- `install.sh` - Symlink distribution and validation logic

**Testing/Verification:**

- `.planning/codebase/` - Generated analysis documents
- `docs/superpowers/` - Workflow design and implementation plans

## Naming Conventions

**Files:**

- Configuration files: Use tool-specific extensions (`.lua`, `.json`, `.tmux.conf`, `.sh`)
- Skill definitions: `SKILL.md` with YAML front-matter
- Agent definitions: Named `.md` files in agents directory
- Rules files: Named `.md` files in rules directory
- Documentation: Markdown (`.md`) with ISO date prefixes for versioned docs

**Directories:**

- Tool configs: lowercase tool names (`claude`, `nvim`, `zsh`, `tmux`)
- Subdirectories: descriptive lowercase names (`config/`, `agents/`, `skills/`, `rules/`)
- Special directories: dot-prefixed for non-config (`.claude/`, `.planning/`, `.git/`)

## Where to Add New Code

**New Claude Code Feature:**

1. If it's a workflow: Create `config/claude/agents/<name>.md` with YAML front-matter
2. If it's a shortcut command: Create `config/claude/skills/<name>/SKILL.md` with tooling
3. If it's a rule: Create `config/claude/rules/<new-rule>.md` and import via CLAUDE.md

**New Shell Configuration:**

1. If it's environment setup: Add to or create new file in `config/zsh/` (e.g., `config/zsh/nodejs.sh`)
2. Source it from `config/zsh/zshrc` with a comment indicating purpose
3. Use conditional checks (`if command -v ...`) for optional tool setup

**New Neovim Plugin:**

1. Create plugin definition in `config/nvim/lua/plugins/<name>.lua`
2. Define with Lazy.nvim syntax: `return { "author/repo", ... }`
3. Commit changes, run nvim to auto-download, commit `lazy-lock.json`

**New Tool Configuration:**

1. Create `config/<toolname>/` directory
2. Create main config file with tool's standard name (e.g., `config.toml`, `.conf`)
3. Add symlink logic to `install.sh` if needed (most tools auto-discover in .config/)

## Special Directories

**config/claude/:**
- Purpose: Contains all Claude Code customization
- Generated: No, manually maintained
- Committed: Yes, to version control

**.claude/:**
- Purpose: Local runtime data and worktrees
- Generated: Partially (worktrees created by user)
- Committed: Yes, git-tracked but specific to local machine

**.planning/codebase/:**
- Purpose: Auto-generated analysis documents
- Generated: Yes, by gsd-codebase-mapper agent
- Committed: Yes, treated as documentation

**config/nvim/lazy-lock.json:**
- Purpose: Plugin version pinning for reproducibility
- Generated: Auto-generated by Lazy.nvim
- Committed: Yes, for consistent plugin versions

---

*Structure analysis: 2026-03-21*

