#!/usr/bin/env bash
# fzf-search.sh - ペイン内容を fzf で検索してコピーモードでジャンプ

HISTORY_LIMIT="${1:-32768}"
TMPFILE=$(mktemp /tmp/tmux-fzf-search.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

# ペイン内容を取得（ANSI エスケープを除去）
if [ "$HISTORY_LIMIT" = "screen" ]; then
    tmux capture-pane -J -p -e 2>/dev/null | sed 's/\x1B\[[0-9;]*[mK]//g' > "$TMPFILE"
else
    tmux capture-pane -J -p -e -S -"$HISTORY_LIMIT" 2>/dev/null | sed 's/\x1B\[[0-9;]*[mK]//g' > "$TMPFILE"
fi

TOTAL=$(wc -l < "$TMPFILE")

# fzf で選択（クエリが空の場合は候補・プレビューを表示しない）
selected=$(echo "" | fzf-tmux -w 100% -h 50% --reverse \
    --bind "change:reload:if [ -n '{q}' ]; then tac '$TMPFILE' | grep -v '^$' | nl -ba -w4 -s': '; else echo; fi" \
    --preview "~/.config/tmux/fzf-search-preview.sh {} $TMPFILE $TOTAL {q}" \
    --preview-window "right:50%:wrap" \
    | sed 's/^ *[0-9]*: //')
[ -z "$selected" ] && exit

# 選択行を正規表現エスケープして検索
escaped=$(echo "$selected" | head -c 100 | sed 's/[]\/$*.^[]/\\&/g')

# コピーモードに入って選択行を検索
tmux copy-mode
tmux send-keys -X search-backward "$escaped"
