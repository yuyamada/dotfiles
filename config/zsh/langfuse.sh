# Langfuse (Claude Code のローカル観測基盤) 環境変数を読み込む
# 実体は ~/.claude/langfuse.env (マシン固有、dotfiles 管理外)
# 初期セットアップは bin/langfuse-setup を参照
[ -f "$HOME/.claude/langfuse.env" ] && source "$HOME/.claude/langfuse.env"
