# dotfiles

個人の開発環境設定を管理するリポジトリ。

## 構成

```
config/
├── claude/
│   ├── CLAUDE.md       # ~/.claude/CLAUDE.md にシンボリックリンク（.cursorrules にもコピー）
│   ├── settings.json   # ~/.claude/settings.json にシンボリックリンク
│   └── skills/         # ~/.claude/skills/<name> にシンボリックリンク
├── nvim/               # ~/.config/nvim にシンボリックリンク
├── zsh/                # ~/.config/zsh にシンボリックリンク（zshrc は ~/.zshrc にも）
├── tmux/               # ~/.config/tmux にシンボリックリンク
├── ghostty/            # ~/.config/ghostty にシンボリックリンク
└── ...
install.sh              # セットアップスクリプト（シンボリックリンク作成）
Brewfile                # Homebrew パッケージ一覧
```

## セットアップ

```bash
./install.sh
```

## 注意

- `~/.claude/settings.local.json` はマシン固有の設定のため dotfiles に含めない
- 会社固有の情報を含む Claude スキルは意図的に dotfiles に含めていない
- スキルは `config/claude/skills/<name>/` をディレクトリごとシンボリックリンクで管理
