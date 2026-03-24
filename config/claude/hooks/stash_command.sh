#!/bin/bash
# PreToolUse フック: ツール名・コマンドを一時ファイルに保存
# perm-notify.sh が通知本文に使用する

set -euo pipefail

# tmux 外では何もしない
[ -n "${TMUX_PANE:-}" ] || exit 0

INPUT=$(cat)
PANE_ID="${TMUX_PANE#%}"           # "%3" → "3"
TOOL=$(jq -r '.tool_name // ""' <<< "$INPUT" 2>/dev/null || echo "")
CMD=$(jq -r '(.tool_input.command // .tool_input.path // "") | .[0:80]' \
    <<< "$INPUT" 2>/dev/null || echo "")

mkdir -p /tmp/ccnotifs
printf '%s\t%s\n' "$TOOL" "$CMD" > "/tmp/ccnotifs/cmd_${PANE_ID}"
