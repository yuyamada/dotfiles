# tmux のウィンドウ名をカレントディレクトリ名に自動更新
if [ -n "$TMUX" ]; then
  _tmux_update_path() {
    local short="${PWD/#$HOME/~}"
    local dir=$(dirname "$short")
    local base=$(basename "$short")
    local abbr=$(echo "$dir" | sed 's|/\([^/]\)[^/]*|/\1|g')
    local path="${abbr}/${base}"
    /opt/homebrew/bin/tmux rename-window "$path"
    /opt/homebrew/bin/tmux select-pane -T "$path"
  }
  precmd_functions+=(_tmux_update_path)
fi
