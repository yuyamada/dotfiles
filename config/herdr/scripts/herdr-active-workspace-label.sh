#!/bin/bash
# herdr-active-workspace-label.sh - tab_bar_right 用。フォーカス中の workspace の label を出力
export PATH="/opt/homebrew/bin:$PATH"
herdr workspace list | jq -r --arg id "$HERDR_ACTIVE_WORKSPACE_ID" '.result.workspaces[] | select(.workspace_id == $id) | .label'
