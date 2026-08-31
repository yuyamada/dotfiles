#!/bin/bash
# herdr-session-switch.sh - sesh 相当。パス指定 or 無指定(fzf)で herdr workspace を作成/切り替え
set -euo pipefail

Z_FILE="$HOME/.z"

workspace_id_by_label() {
  herdr workspace list | jq -r --arg l "$1" '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1
}

open_path() {
  local target_path label existing_id
  target_path=$(cd "$1" && pwd)
  label=$(basename "$target_path")
  existing_id=$(workspace_id_by_label "$label")
  if [ -n "$existing_id" ]; then
    herdr workspace focus "$existing_id" >/dev/null
  else
    herdr workspace create --cwd "$target_path" --label "$label" --focus >/dev/null
  fi
}

if [ $# -ge 1 ]; then
  open_path "$1"
  exit 0
fi

existing_labels=$(herdr workspace list | jq -r '.result.workspaces[].label')
z_dirs=$(sort -t'|' -k2 -rn "$Z_FILE" 2>/dev/null | cut -d'|' -f1)

selected=$(printf '%s\n%s\n' "$existing_labels" "$z_dirs" | awk 'NF' | sort -u | fzf --prompt="workspace> ")
[ -n "$selected" ] || exit 0

existing_id=$(workspace_id_by_label "$selected")
if [ -n "$existing_id" ]; then
  herdr workspace focus "$existing_id" >/dev/null
elif [ -d "$selected" ]; then
  open_path "$selected"
fi
