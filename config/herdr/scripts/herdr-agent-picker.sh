#!/bin/bash
# herdr-agent-picker.sh - agent 一覧を fzf でファジー検索してフォーカス
set -euo pipefail

abbreviate_path() {
  local target_path="$1"
  if [ "$target_path" = "$HOME" ]; then
    printf '~'
    return
  fi
  local tilde='~' short dir base abbr
  short="${target_path/#$HOME/$tilde}"
  if [ "$short" = "/" ]; then
    printf '/'
    return
  fi
  dir=$(dirname "$short")
  base=$(basename "$short")
  if [ "$dir" = "~" ] || [ "$dir" = "/" ]; then
    abbr="$dir"
  else
    abbr=$(echo "$dir" | sed 's|/\([^/]\)[^/]*|/\1|g')
  fi
  case "$abbr" in
    "/") printf '/%s' "$base" ;;
    "~") printf '~/%s' "$base" ;;
    *) printf '%s/%s' "$abbr" "$base" ;;
  esac
}

rows=$(herdr agent list | jq -r '.result.agents[] | [.pane_id, .agent_status, .agent, .cwd] | @tsv')
[ -n "$rows" ] || exit 0

lines=""
while IFS=$'\t' read -r pane_id status agent cwd; do
  [ -n "$pane_id" ] || continue
  label="[$status] $(abbreviate_path "$cwd") $agent"
  lines="${lines}${pane_id}	${label}
"
done <<< "$rows"

selected=$(printf '%s' "$lines" | fzf --prompt="agent> " --delimiter='	' --with-nth=2)
[ -n "$selected" ] || exit 0

pane_id="${selected%%$'\t'*}"
herdr agent focus "$pane_id" >/dev/null
