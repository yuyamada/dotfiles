#!/bin/bash
# Notification フック: permission_prompt 時に alerter 通知を送る
# クリックで Ghostty + tmux ペーンにテレポート、番号選択で承認/拒否

set -euo pipefail

# ──────────────────────────────────────────────────
# __worker モード: alerter 実行とアクション処理（デタッチプロセス）
# ──────────────────────────────────────────────────
if [ "${1:-}" = "__worker" ]; then
    # CCN_CHOICES (改行区切り "num\tlabel") → alerter --actions カンマ区切り文字列
    ACTIONS=""
    while IFS=$'\t' read -r num label; do
        [ -n "$num" ] || continue
        label=$(printf '%s' "$label" | tr ',' ';' | cut -c1-50)
        label="${num}: ${label}"
        ACTIONS="${ACTIONS:+${ACTIONS},}${label}"
    done <<< "${CCN_CHOICES:-}"
    [ -z "$ACTIONS" ] && ACTIONS="Open"

    ALERTER_ARGS=(
        --title "${CCN_TITLE:-Claude Code}"
        --message "${CCN_BODY:-Claude is waiting for your input}"
        --timeout 120
        --close-label "Dismiss"
        --actions "$ACTIONS"
    )
    [ -n "${CCN_SUBTITLE:-}" ] && ALERTER_ARGS+=(--subtitle "$CCN_SUBTITLE")

    RESULT=$(alerter "${ALERTER_ARGS[@]}" 2>/dev/null || echo "")

    # CCN_SOCK 経由で正しい tmux サーバーに接続
    tmux_cmd() { tmux -S "${CCN_SOCK}" "$@" 2>/dev/null || true; }

    case "$RESULT" in
        "@CONTENTCLICKED"|Open)
            # 本体クリック or "Open" ボタン → テレポート
            open -b "com.mitchellh.ghostty"
            tmux_cmd switch-client -t "${CCN_SESSION}"
            tmux_cmd select-window -t "${CCN_SESSION}:${CCN_WIN_INDEX}"
            tmux_cmd select-pane -t "${CCN_PANE}"
            ;;
        Dismiss|"@TIMEOUT"|"@CLOSED")
            : # 何もしない
            ;;
        *)
            # 番号付きラベル ("1: Yes" など) → 先頭の数字を抽出して tmux に送信
            NUM=$(printf '%s' "$RESULT" | sed -nE 's/^([0-9]+):.*/\1/p')
            if [ -n "$NUM" ]; then
                tmux_cmd send-keys -t "${CCN_PANE}" -l "$NUM"
                tmux_cmd send-keys -t "${CCN_PANE}" Enter
            else
                # 認識できない応答 → テレポートにフォールバック
                open -b "com.mitchellh.ghostty"
                tmux_cmd select-pane -t "${CCN_PANE}"
            fi
            ;;
    esac
    exit 0
fi

# ──────────────────────────────────────────────────
# メインフック処理
# ──────────────────────────────────────────────────
INPUT=$(cat)

# tmux 外: osascript フォールバックのみ
if [ -z "${TMUX_PANE:-}" ]; then
    CWD=$(jq -r '.cwd // ""' <<< "$INPUT" 2>/dev/null || echo "")
    BODY="Claude is waiting for your input"
    osascript -e "display notification \"${BODY}\" with title \"Claude Code\" sound name \"Ping\""
    exit 0
fi

# suppression チェック: 既にそのペーンを見ていれば通知不要
SESSION_ATTACHED=$(tmux display-message -t "$TMUX_PANE" -p '#{session_attached}' 2>/dev/null || echo 0)
PANE_ACTIVE=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_active}' 2>/dev/null || echo 0)
WINDOW_ACTIVE=$(tmux display-message -t "$TMUX_PANE" -p '#{window_active}' 2>/dev/null || echo 0)
if [[ $SESSION_ATTACHED != 0 && $PANE_ACTIVE == 1 && $WINDOW_ACTIVE == 1 ]]; then
    FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "")
    [[ "$(echo "$FRONTMOST" | tr '[:upper:]' '[:lower:]')" == "ghostty" ]] && exit 0
fi

# tmux セッション・ウィンドウ情報の収集
SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#S' 2>/dev/null || echo "")
WIN_INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#I' 2>/dev/null || echo "")
WIN_NAME=$(tmux display-message -t "$TMUX_PANE" -p '#W' 2>/dev/null || echo "")
CWD=$(jq -r '.cwd // ""' <<< "$INPUT" 2>/dev/null || echo "")
PROJECT=$(basename "$CWD")
TMUX_INFO="${SESSION}"
[ -n "$WIN_INDEX" ] && [ -n "$WIN_NAME" ] && TMUX_INFO="${SESSION} w${WIN_INDEX} > ${WIN_NAME}"
if [ -n "$TMUX_INFO" ] && [ -n "$PROJECT" ]; then
    SUBTITLE="${TMUX_INFO} · ${PROJECT}"
elif [ -n "$TMUX_INFO" ]; then
    SUBTITLE="$TMUX_INFO"
else
    SUBTITLE="$PROJECT"
fi

# stash ファイルからツール名・コマンドを読み込み（読み込み後に削除）
PANE_ID="${TMUX_PANE#%}"
STASH="/tmp/ccnotifs/cmd_${PANE_ID}"
TOOL_DISPLAY=""
if [ -f "$STASH" ]; then
    STASH_TOOL=$(cut -f1 "$STASH")
    STASH_CMD=$(cut -f2- "$STASH")
    [ -n "$STASH_TOOL" ] && TOOL_DISPLAY="${STASH_TOOL}: ${STASH_CMD}"
    rm -f "$STASH"
fi

# BODY は TOOL_DISPLAY 確定後に定義
BODY="${TOOL_DISPLAY:-Claude is waiting for your input}"

# tmux ペーンのスナップショットから番号付き選択肢を抽出
SNAPSHOT=$(tmux capture-pane -p -e -J -t "$TMUX_PANE" -S -120 2>/dev/null || echo "")
CHOICES=$(printf '%s\n' "$SNAPSHOT" \
    | perl -pe 's/\e\[[0-9;?]*[@-~]//g; s/\r//g' \
    | sed -nE 's/^[[:space:]]*([0-9]+)\.[[:space:]]+(.*)$/\1\t\2/p')

# alerter が使えるか確認
ALERTER_BIN=$(command -v alerter 2>/dev/null || echo "")
if [ -z "$ALERTER_BIN" ]; then
    # フォールバック: osascript（テレポートなし）
    osascript -e "display notification \"${BODY//\"/\\\"}\" with title \"Claude Code\" sound name \"Ping\""
    exit 0
fi

# alerter worker をデタッチ起動（環境変数でコンテキストを渡す）
TMUX_SOCK="${TMUX%%,*}"
env \
    CCN_PANE="$TMUX_PANE" \
    CCN_SOCK="$TMUX_SOCK" \
    CCN_SESSION="$SESSION" \
    CCN_WIN_INDEX="$WIN_INDEX" \
    CCN_TITLE="Claude Code — Needs Input" \
    CCN_BODY="$BODY" \
    CCN_SUBTITLE="$SUBTITLE" \
    CCN_CHOICES="$CHOICES" \
    nohup "$0" __worker >/dev/null 2>&1 &
exit 0
