# Technology Stack

**Analysis Date:** 2026-03-21

## Languages

**Primary:**
- Shell (Bash/Zsh) - Configuration, automation scripts, installation
- Lua - Neovim editor configuration
- Python - Utility scripts (statusline, GitHub integration)
- TOML - Configuration files (Sheldon, Starship, Lazy.nvim)

**Supporting:**
- Markdown - Documentation and skill definitions
- JSON - Configuration (Claude settings, Karabiner, Cursor)
- YAML - Configuration files (Serena)

## Runtime

**Environment:**
- macOS (Darwin 23.5.0) - Target platform
- Zsh shell - Default shell environment
- Python 3 - Script execution

**Package Manager:**
- Homebrew - Primary macOS package manager
- Brewfile - Dependency management (tracked in repo)
- Sheldon - Zsh plugin manager
- NPM (implicit) - For Claude Code plugins and marketplace

## Frameworks

**Editor:**
- Neovim (latest) - Primary text editor
- Lazy.nvim (lazy-lock.json) - Plugin manager for Neovim

**Developer Tools:**
- Ghostty - Terminal emulator (cask)
- WezTerm (nightly) - Alternative terminal emulator
- Gitify - GitHub notifications client
- Tmux - Terminal multiplexer with tmux-continuum plugin

**Shell:**
- Sheldon - Plugin/theme manager
- Starship - Prompt
- Z - Directory navigation

**Claude Code:**
- Claude Code Plugin SDK - Plugin development
- MCP (Model Context Protocol) - Integration framework
- AWS documentation MCP server
- Google Developer Knowledge MCP server

## Key Dependencies

**Critical:**
- Homebrew packages (Brewfile):
  - `neovim` - Text editor
  - `tmux` - Terminal multiplexer
  - `fzf` - Fuzzy finder (used by snacks.nvim)
  - `ripgrep` (rg) - Fast search tool (required by snacks.nvim picker)
  - `fd` - Fast file finder (recommended by snacks.nvim)
  - `sheldon` - Shell plugin manager
  - `starship` - Cross-shell prompt
  - `z` - Jump around directories
  - `chafa` - Terminal image display

**Terminal/UI:**
- `ghostty` - Modern terminal emulator
- `wezterm@nightly` - Alternative terminal
- `gitify` - GitHub notifications

**Shell plugins (via Sheldon in `config/sheldon/plugins.toml`):**
- `zsh-autosuggestions` - Shell autocomplete
- `zsh-syntax-highlighting` - Syntax highlighting
- `z` - Directory navigation
- `starship` - Prompt initialization

**Neovim plugins (via Lazy in `config/nvim/lazy-lock.json`):**
- `avante.nvim` - AI assistant integration
- `snacks.nvim` - UI utilities and picker
- `blink.cmp` - Completion engine
- `nvim-lspconfig` - LSP client configuration
- `mason.nvim` - Language server manager
- `mason-lspconfig.nvim` - Bridge between Mason and LSP config
- `nvim-treesitter` - Parser library for syntax highlighting
- `gitsigns.nvim` - Git decorations
- `diffview.nvim` - Git diff viewer
- `trouble.nvim` - Diagnostics viewer
- `lualine.nvim` - Status line
- `nvim-autopairs` - Bracket pairing
- `nvim-surround` - Surround text objects
- `mini.ai` - Text objects
- `nui.nvim` - UI component library
- `plenary.nvim` - Common Lua utilities
- `lazydev.nvim` - Lua development utilities
- `ansi.nvim` - ANSI color support
- `persistence.nvim` - Session management
- `iceberg.vim` - Color scheme
- `guess-indent.nvim` - Auto indentation detection
- `nvim-web-devicons` - File type icons

## Configuration

**Environment:**
- `~/.zshrc` - Zsh configuration (symlinked from `config/zsh/zshrc`)
- `~/.config/zsh/` - Zsh plugins and settings
  - `env.sh` - Environment variables and Zsh options
  - `aliases.sh` - Command aliases
  - `zle.sh` - Zsh line editing config
  - `theme.sh` - Prompt theme
  - `tmux.sh` - Tmux integration
  - `claude.sh` - Claude Code API key setup (sourced from macOS keychain)
  - `gcloud.sh` - Google Cloud SDK
  - `go.sh` - Go environment
  - `bun.sh` - Bun package manager
- Claude Code secrets sourced from macOS Keychain:
  - `ANTHROPIC_API_KEY` - Sourced if `~/.claude_anthropic_enabled` exists
  - `GOOGLE_API_KEY` - Sourced if `~/.claude_google_enabled` exists

**Editor:**
- `~/.config/nvim/init.lua` - Neovim entry point
- `~/.config/nvim/lua/config/` - Neovim configuration modules
  - `general.lua` - General settings
  - `keymaps.lua` - Key mappings
  - `lazy.lua` - Lazy.nvim setup
  - `appearance.lua` - UI customization
- `~/.config/nvim/lua/plugins/` - Plugin specifications

**Claude Code:**
- `config/claude/settings.json` - Main Claude Code settings (symlinked to `~/.claude/settings.json`)
  - Environment variables
  - Tool permissions
  - MCP servers configuration
  - Plugin marketplace configuration
  - Sandbox settings (enabled with network/filesystem restrictions)
  - Post-tool hooks for logging and monitoring
- `config/claude/rules/` - Claude behavior rules (imported via @-syntax)
  - `workflow.md` - Workflow guidelines
  - `skills.md` - Skill creation rules
  - `git.md` - Git operation guidelines
  - `tools.md` - Tool usage preferences
  - `permissions.md` - Permission management strategy
- `config/claude/skills/` - Custom Claude skills
  - Each skill has `SKILL.md` definition + optional scripts
- `config/claude/agents/` - Specialist agents for parallel review

**System:**
- `Brewfile` - Homebrew package specifications
- `config/starship/starship.toml` - Starship prompt configuration
- `config/sheldon/plugins.toml` - Shell plugin management
- `config/karabiner/karabiner.json` - Keyboard remapping
- `config/ghostty/` - Ghostty terminal configuration
- `config/tmux/` - Tmux configuration with plugins
- `config/serena/serena_config.yml` - Serena (MCP plugin) configuration
- `config/cursor/permissions.json` - Cursor IDE permissions

**Build/Installation:**
- `install.sh` - Dotfiles installation script
  - Creates symlinks from `config/` to `~/.config/`
  - Links Claude configuration to `~/.claude/`
  - Links Zsh configuration to `~/.zshrc`

## Platform Requirements

**Development:**
- macOS (Monterey or later recommended)
- Homebrew installed
- Git
- Python 3 (for scripts)

**Production:**
- macOS (Monterey or later recommended)
- Homebrew installed

## Special Features

**Claude Code Integration:**
- Custom skills for git workflow (`commit`, `pr`)
- GitHub task aggregation (`my-tasks`)
- Parallel code review orchestration (`parallel-review`)
- Plugin discovery (`plugin-stars`)
- Self-improvement loop (`retrospect`)
- Autonomous loop execution (`ralph-loop`)
- Image upload to GitHub (`github-upload-image`)

**Sandbox Security:**
- Network restricted to GitHub API, npm, and Google/AWS documentation
- Filesystem writes limited to specific paths (dotfiles .git, skills, projects)
- Tool permissions granularly controlled via settings.json

---

*Stack analysis: 2026-03-21*
