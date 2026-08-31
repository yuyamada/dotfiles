#!/bin/bash
# herdr-session-switch.sh - sesh 相当。パス指定 or 無指定(fzf、既定値はカレントディレクトリ/未知なら home)で herdr workspace を作成/切り替え
set -euo pipefail

workspace_id_by_label() {
  herdr workspace list | jq -r --arg l "$1" '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1
}

open_path() {
  local target_path label existing_id
  target_path=$(cd "$1" && pwd)
  if [ "$target_path" = "$HOME" ]; then
    label="~"
  else
    label=$(basename "$target_path")
  fi
  existing_id=$(workspace_id_by_label "$label")
  if [ -n "$existing_id" ]; then
    herdr workspace focus "$existing_id" >/dev/null
  else
    herdr workspace create --cwd "$target_path" --label "$label" --focus >/dev/null
  fi
}

if [ $# -ge 1 ]; then
  open_path "$1"
else
  existing_labels=$(herdr workspace list | jq -r '.result.workspaces[].label')
  candidates=$(printf '%s\n' "$existing_labels" | awk 'NF' | sort -u)

  if [ "$PWD" = "$HOME" ]; then
    cwd_label="~"
  else
    cwd_label=$(basename "$PWD")
  fi
  if printf '%s\n' "$existing_labels" | grep -qxF -- "$cwd_label"; then
    default_query="$cwd_label"
  else
    default_query="~"
  fi

  selected=$(printf '%s\n' "$candidates" | fzf --prompt="workspace> " --query="$default_query")
  if [ -n "$selected" ]; then
    existing_id=$(workspace_id_by_label "$selected")
    if [ -n "$existing_id" ]; then
      herdr workspace focus "$existing_id" >/dev/null
    elif [ -d "$selected" ]; then
      open_path "$selected"
    fi
  fi
fi

# herdr ペインの外（$HERDR_ENV 無し）から呼ばれた場合は、この端末自体を herdr にアタッチする
if [ -z "${HERDR_ENV:-}" ]; then
  exec herdr
fi
