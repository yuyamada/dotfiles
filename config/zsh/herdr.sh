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

  # カレントディレクトリを ~/w/dotfiles のような略記に変換（/ と home 直下の境界ケースを個別に処理）
  _herdr_abbreviate_cwd() {
    local short="${PWD/#$HOME/~}"
    if [ "$short" = "~" ] || [ "$short" = "/" ]; then
      echo "$short"
      return
    fi
    local dir=$(dirname "$short")
    local base=$(basename "$short")
    local abbr
    if [ "$dir" = "~" ] || [ "$dir" = "/" ]; then
      abbr="$dir"
    else
      abbr=$(echo "$dir" | sed 's|/\([^/]\)[^/]*|/\1|g')
    fi
    case "$abbr" in
      "/") echo "/${base}" ;;
      "~") echo "~/${base}" ;;
      *) echo "${abbr}/${base}" ;;
    esac
  }

  # コマンド終了後: カレントディレクトリをペインタイトルに（フォーカス中のペインならタブ名も更新）
  _herdr_set_path() {
    local cwd_label=$(_herdr_abbreviate_cwd)
    herdr pane rename "$HERDR_PANE_ID" "$cwd_label" >/dev/null 2>&1
    [ "$(_herdr_focused)" = "true" ] && herdr tab rename "$HERDR_TAB_ID" "$cwd_label" >/dev/null 2>&1
  }
  precmd_functions+=(_herdr_set_path)
fi
