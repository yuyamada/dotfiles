#!/bin/bash
# Claude Code statusline — ccusage + monthly cost

CACHE=/tmp/ccusage_monthly_cache
NOW=$(date +%s)

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

cat - \
  | ccusage statusline --timezone UTC --cost-source cc \
  | sed "s|today|today / \$${monthly_fmt} mo|" \
  | perl -CS -pe '
    s/[^\x00-\x7F](\s?)/$2/g;
    s/\$(\d+\.\d)\d+/\$$1/g;
    s| / \$[\d.]+ block \(\dh \d+m left\)||;
    if (/(\d[\d,]+) \((\d+)%\)/) {
      my $pct = $2;
      my $c = $pct < 20 ? "" : $pct < 40 ? "\x1b[32m" : $pct < 60 ? "\x1b[33m" : "\x1b[31m";
      my $r = $c ? "\x1b[0m" : "";
      my $f = int($pct * 8 / 100 + 0.5);
      my $bar = "\x{2501}" x $f . "\x{2500}" x (8 - $f);
      s/(\d[\d,]+) \((\d+)%\)/${c}|$bar| $2%${r}/;
    }
  '
