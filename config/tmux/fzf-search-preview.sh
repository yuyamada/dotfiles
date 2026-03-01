#!/usr/bin/env bash
# fzf-search-preview.sh - fzf-search.sh のプレビュー用スクリプト

SELECTED="$1"
TMPFILE="$2"
TOTAL="$3"
QUERY="$4"

# クエリが空の場合は何も表示しない
[ -z "$QUERY" ] && exit

# 行番号を取得してジャンプ先を計算
rev_line=$(echo "$SELECTED" | grep -o '^ *[0-9]*' | tr -d ' ')
line=$(( TOTAL - rev_line + 1 ))
start=$(( line > 10 ? line - 10 : 1 ))

# 前後10行を取得
content=$(sed -n "${start},$((line+10))p" "$TMPFILE" | head -20)

# クエリをハイライト（全行表示しつつマッチ部分を緑に）
escaped=$(echo "$QUERY" | sed 's/[.[\*^$()+?{|]/\\&/g')
echo "$content" | GREP_COLOR='0;32' grep --color=always -iE "($escaped|$)"
