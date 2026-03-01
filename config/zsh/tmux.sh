# tmux のウィンドウ名を管理
if [ -n "$TMUX" ]; then
  # コマンド実行中: プロセス名をペインタイトルに（アクティブペインならウィンドウ名も更新）
  _tmux_set_process() {
    local cmd="${1%% *}"        # 最初のスペースで切って実行コマンド名だけ取る
    local name="${cmd##*/}"     # パスが含まれる場合、ベース名だけ取る
    /opt/homebrew/bin/tmux select-pane -T "$name"
    [ "$(/opt/homebrew/bin/tmux display-message -p '#{pane_active}')" = "1" ] && \
      /opt/homebrew/bin/tmux rename-window "$name"
  }
  preexec_functions+=(_tmux_set_process)

  # コマンド終了後: カレントディレクトリをペインタイトルに（アクティブペインならウィンドウ名も更新）
  _tmux_set_path() {
    local short="${PWD/#$HOME/~}"
    local dir=$(dirname "$short")
    local base=$(basename "$short")
    local abbr=$(echo "$dir" | sed 's|/\([^/]\)[^/]*|/\1|g')
    local path="${abbr}/${base}"
    /opt/homebrew/bin/tmux select-pane -T "$path"
    [ "$(/opt/homebrew/bin/tmux display-message -p '#{pane_active}')" = "1" ] && \
      /opt/homebrew/bin/tmux rename-window "$path"
  }
  precmd_functions+=(_tmux_set_path)
fi
