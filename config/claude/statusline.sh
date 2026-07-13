#!/bin/bash
# Claude Code statusline — ccusage + monthly cost

CACHE=/tmp/ccusage_monthly_cache
DAILY_CACHE=/tmp/ccusage_daily_cache
NOW=$(date +%s)

# Read stdin once up front so it can be reused for both ccusage and the turn-cost calc below.
input=$(cat)

transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# USD per million tokens. Update when https://platform.claude.com/docs/en/about-claude/pricing changes.
# cache_creation is billed as a 5-minute write (1.25x) unless Claude Code used the 1h cache;
# current_usage doesn't expose that split, so this assumes the common 5m case.
turn_cost=$(echo "$input" | jq -r '
  def price:
    if . == "claude-opus-4-8" or . == "claude-opus-4-7" or . == "claude-opus-4-6" or . == "claude-opus-4-5" then {in:5,out:25}
    elif . == "claude-sonnet-5" then {in:2,out:10}
    elif . == "claude-sonnet-4-6" or . == "claude-sonnet-4-5" then {in:3,out:15}
    elif . == "claude-haiku-4-5" then {in:1,out:5}
    else {in:2,out:10} end;
  (.model.id // "claude-sonnet-5") as $m
  | ($m | price) as $p
  | (.context_window.current_usage) as $u
  | if $u == null then ""
    else (
      (($u.input_tokens // 0) * $p.in
        + ($u.cache_creation_input_tokens // 0) * $p.in * 1.25
        + ($u.cache_read_input_tokens // 0) * $p.in * 0.1
        + ($u.output_tokens // 0) * $p.out) / 1000000
    ) | tostring
    end
' 2>/dev/null)

# /clear (aliases /reset, /new) starts a fresh conversation but keeps the same session file,
# so conversation cost is summed only from entries after the last such boundary.
conv_cost=""
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
  boundary=$(grep -n '"content":"<command-name>/\(clear\|reset\|new\)</command-name>' "$transcript_path" 2>/dev/null | tail -1 | cut -d: -f1)
  conv_cost=$(tail -n "+${boundary:-1}" "$transcript_path" 2>/dev/null | jq -s -r '
    def price:
      if . == "claude-opus-4-8" or . == "claude-opus-4-7" or . == "claude-opus-4-6" or . == "claude-opus-4-5" then {in:5,out:25}
      elif . == "claude-sonnet-5" then {in:2,out:10}
      elif . == "claude-sonnet-4-6" or . == "claude-sonnet-4-5" then {in:3,out:15}
      elif . == "claude-haiku-4-5" then {in:1,out:5}
      else {in:2,out:10} end;
    map(select(.type == "assistant" and .message.usage != null))
    | unique_by(.message.id)
    | map(
        (.message.model | price) as $p
        | .message.usage as $u
        | ($u.input_tokens // 0) * $p.in
          + ($u.cache_creation_input_tokens // 0) * $p.in * 1.25
          + ($u.cache_read_input_tokens // 0) * $p.in * 0.1
          + ($u.output_tokens // 0) * $p.out
      )
    | (add // 0) / 1000000
  ' 2>/dev/null)
fi

# Branch or worktree name from the project directory
branch=$(git branch --show-current 2>/dev/null)
if [[ -z "$branch" ]]; then
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -n "$toplevel" ]] && branch=$(basename "$toplevel")
fi

# 月次コストを 60 秒キャッシュ
if [[ -f "$CACHE" ]]; then
  cached_at=$(head -1 "$CACHE")
  if (( NOW - cached_at < 60 )); then
    monthly=$(tail -1 "$CACHE")
  fi
fi

if [[ -z "$monthly" ]]; then
  this_month=$(TZ=UTC date +%Y-%m)
  monthly=$(ccusage monthly --json --timezone UTC 2>/dev/null \
    | grep -A1 "\"period\": \"$this_month\"" \
    | grep '"totalCost"' \
    | grep -o '[0-9.]*' | head -1)
  printf '%s\n%s\n' "$NOW" "${monthly:-0}" > "$CACHE"
fi

monthly_fmt=$(printf '%.1f' "${monthly:-0}")

# 日次コストを 60 秒キャッシュ（ccusage statusline 自体の `today` は cost-source を問わず常に 0 を返すため自前集計）
if [[ -f "$DAILY_CACHE" ]]; then
  cached_at=$(head -1 "$DAILY_CACHE")
  if (( NOW - cached_at < 60 )); then
    today=$(tail -1 "$DAILY_CACHE")
  fi
fi

if [[ -z "$today" ]]; then
  this_day=$(TZ=UTC date +%Y-%m-%d)
  today=$(ccusage daily --json --timezone UTC 2>/dev/null \
    | jq -r --arg d "$this_day" '.daily[]? | select(.period == $d) | .totalCost' | head -1)
  printf '%s\n%s\n' "$NOW" "${today:-0}" > "$DAILY_CACHE"
fi

today_fmt=$(printf '%.1f' "${today:-0}")

turn_fmt=""
[[ -n "$turn_cost" ]] && turn_fmt=$(printf ' (+$%.3f)' "$turn_cost")

conv_fmt=""
[[ -n "$conv_cost" ]] && conv_fmt=$(printf '%.1f' "$conv_cost")

echo "$input" \
  | ccusage statusline --timezone UTC --cost-source cc \
  | perl -CS -pe '
    s/[^\x00-\x7F](\s?)/$2/g;
    s/\$(\d+\.\d)\d+/\$$1/g;
    s/ \| \$[\d.]+\/hr//;
    s| / \$[\d.]+ block \((\d+h )?\d+m left\)||;
    if (/(\d[\d,]+) \((\d+)%\)/) {
      my $raw = $1;
      my $pct = $2;
      (my $num = $raw) =~ s/,//g;
      my $tok = $num >= 1000 ? sprintf("%.1f", $num / 1000) . "k" : $num;
      my $c = $num < 50000 ? "" : $num < 100000 ? "\x1b[32m" : $num < 150000 ? "\x1b[33m" : $num < 200000 ? "\x1b[38;5;208m" : "\x1b[31m";
      my $r = $c ? "\x1b[0m" : "";
      # Target is a fixed 200k reference, not the real context window size.
      my $target = 200000;
      my $newpct = int($num / $target * 100 + 0.5);
      my $f = $newpct >= 100 ? 8 : int($newpct * 8 / 100 + 0.5);
      my $bar = "\x{2501}" x $f . "\x{2500}" x (8 - $f);
      s/(\d[\d,]+) \((\d+)%\)/${c}$tok\/200k |$bar| ${newpct}%${r}/;
    }
  ' \
  | awk -v tf="${today_fmt}" -v mf="${monthly_fmt}" -v cf="${conv_fmt}" -v tc="${turn_fmt}" -v b="${branch}" '
    {
      # ccusage statusline itself always reports $0.00 for "today" regardless of --cost-source;
      # tf is computed separately above via `ccusage daily --json`.
      gsub(/\$[0-9.]+ today/, "$" tf " today")
      # ccusage session cost accumulates for the whole process, not the current
      # conversation; cf is the /clear-boundary-scoped cost computed separately above.
      if (cf != "") gsub(/\$[0-9.]+ session/, "$" cf " session")
      gsub(/ \//, " |")
      gsub(/session/, "conv" tc)
      sub(/today/, "today | $" mf " mo")
      gsub(/today/, "day")
      if (b != "") { $0 = $0 " [" b "]" }
      print
    }
  '
