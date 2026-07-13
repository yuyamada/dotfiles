#!/bin/bash
# PostToolUse フック: ツール実行ごとのコスト増分を tool-cost.log に1行ずつ記録する。
# transcript は非同期で書き込まれ、直前のツール呼び出し分がまだ反映されていないことがあるため、
# 前回読んだ行の続きから読み、未確定分は次回の呼び出しに繰り越す（自己修復するので取りこぼしはない）。

set -euo pipefail

INPUT=$(cat)
transcript_path=$(jq -r '.transcript_path // empty' <<< "$INPUT")
session_id=$(jq -r '.session_id // empty' <<< "$INPUT")
tool_name=$(jq -r '.tool_name // "unknown"' <<< "$INPUT")

[[ -n "$transcript_path" && -f "$transcript_path" ]] || exit 0

STATE="/tmp/claude-tool-cost-state-${session_id}"
cursor=0
last_id=""
cumulative=0
if [[ -f "$STATE" ]]; then
  cursor=$(sed -n '1p' "$STATE")
  last_id=$(sed -n '2p' "$STATE")
  cumulative=$(sed -n '3p' "$STATE")
fi

total_lines=$(wc -l < "$transcript_path" | tr -d ' ')

# USD per million tokens. Update when https://platform.claude.com/docs/en/about-claude/pricing changes.
result=$(tail -n "+$((cursor + 1))" "$transcript_path" 2>/dev/null | jq -s -r --arg last_id "$last_id" '
  def price:
    if . == "claude-opus-4-8" or . == "claude-opus-4-7" or . == "claude-opus-4-6" or . == "claude-opus-4-5" then {in:5,out:25}
    elif . == "claude-sonnet-5" then {in:2,out:10}
    elif . == "claude-sonnet-4-6" or . == "claude-sonnet-4-5" then {in:3,out:15}
    elif . == "claude-haiku-4-5" then {in:1,out:5}
    else {in:2,out:10} end;
  map(select(.type == "assistant" and .message.usage != null)) as $entries
  | ($entries | unique_by(.message.id) | map(select(.message.id != $last_id))) as $fresh
  | ($fresh | map(
      (.message.model | price) as $p
      | .message.usage as $u
      | ($u.input_tokens // 0) * $p.in
        + ($u.cache_creation_input_tokens // 0) * $p.in * 1.25
        + ($u.cache_read_input_tokens // 0) * $p.in * 0.1
        + ($u.output_tokens // 0) * $p.out
    ) | (add // 0) / 1000000) as $cost
  | ($entries | if length > 0 then .[-1].message.id else $last_id end) as $newLastId
  | "\($cost)\t\($newLastId)"
' 2>/dev/null)

delta=$(cut -f1 <<< "${result:-0}")
new_last_id=$(cut -f2 <<< "${result:-}")
delta="${delta:-0}"

cumulative=$(awk -v a="$cumulative" -v b="$delta" 'BEGIN { printf "%.6f", a + b }')

printf '%s\n%s\n%s\n' "$total_lines" "$new_last_id" "$cumulative" > "$STATE"

mkdir -p ~/.claude/logs
printf '%s\t%s\t%s\t+$%.4f\t($%.2f total)\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$session_id" "$tool_name" "$delta" "$cumulative" \
  >> ~/.claude/logs/tool-cost.log

exit 0
