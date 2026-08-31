# herdr のタブ名/ペイン名を管理（config/zsh/tmux.sh の herdr 版）
if [ -n "$HERDR_ENV" ]; then
  _herdr_focused() {
    herdr pane get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.pane.focused'
  }

  # コマンド実行中: プロセス名をペインタイトルに（フォーカス中のペインならタブ名も更新）
  _herdr_set_process() {
    local cmd="${1%% *}"        # 最初のスペースで切って実行コマンド名だけ取る
    local name="${cmd##*/}"     # パスが含まれる場合、ベース名だけ取る
    herdr pane rename "$HERDR_PANE_ID" "$name" >/dev/null 2>&1
    [ "$(_herdr_focused)" = "true" ] && herdr tab rename "$HERDR_TAB_ID" "$name" >/dev/null 2>&1
  }
  preexec_functions+=(_herdr_set_process)

  # コマンド終了後: カレントディレクトリをペインタイトルに（フォーカス中のペインならタブ名も更新）
  _herdr_set_path() {
    local short="${PWD/#$HOME/~}"
    local dir=$(dirname "$short")
    local base=$(basename "$short")
    local abbr=$(echo "$dir" | sed 's|/\([^/]\)[^/]*|/\1|g')
    local cwd_label="${abbr}/${base}"
    herdr pane rename "$HERDR_PANE_ID" "$cwd_label" >/dev/null 2>&1
    [ "$(_herdr_focused)" = "true" ] && herdr tab rename "$HERDR_TAB_ID" "$cwd_label" >/dev/null 2>&1
  }
  precmd_functions+=(_herdr_set_path)
fi
