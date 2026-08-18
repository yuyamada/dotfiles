#!/bin/bash
# fzf-session-switch.sh - シェルの s エイリアスと同じ挙動（sesh + fzf）でセッションを切り替える

SELECTED=$(sesh list -t | fzf-tmux -w 100% -h 100% --reverse)

[ -z "$SELECTED" ] && exit

sesh connect "$SELECTED"
