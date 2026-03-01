# dotfiles

Personal macOS dotfiles.

## Structure

```
config/
├── claude/       # Claude Code (MCP, permissions, CLAUDE.md)
├── ghostty/      # Ghostty terminal
├── karabiner/    # Karabiner-Elements keybindings
├── nvim/         # Neovim (LazyVim-based)
├── sheldon/      # Shell plugin manager
├── starship/     # Prompt
├── tmux/         # tmux
├── wezterm/      # WezTerm terminal
└── zsh/          # Zsh config
```

## Setup

```sh
git clone https://github.com/yuyamada/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./install.sh
```

`install.sh` creates symlinks from each config file to the appropriate location.

## Dependencies

```sh
brew bundle
```

Key tools: `neovim`, `tmux`, `fzf`, `fd`, `ripgrep`, `starship`, `sheldon`, `sesh`
