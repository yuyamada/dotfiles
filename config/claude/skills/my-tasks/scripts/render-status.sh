#!/bin/bash
# Usage: render-status.sh
# Renders $HOME/.cache/my-tasks/status.json (written by fetch-status.sh) as a
# terminal report with clickable (OSC 8) hyperlinks. `watch -c` only
# interprets SGR color sequences and drops OSC 8, so run this in a plain
# redraw loop instead, e.g.:
#   while true; do clear; ~/.claude/skills/my-tasks/scripts/render-status.sh; sleep 10; done
set -euo pipefail

STATUS_FILE="${HOME}/.cache/my-tasks/status.json"

BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'

hyperlink() {
  local url="$1" text="$2"
  printf '\033]8;;%s\033\\\033[4m%s\033[24m\033]8;;\033\\' "$url" "$text"
}

# Renders an ISO8601 UTC timestamp as "3m ago" / "2h ago" / "5d ago".
relative_time() {
  local iso="$1" epoch now diff
  epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null || date -u -d "$iso" +%s)
  now=$(date -u +%s)
  diff=$(( now - epoch ))
  if (( diff < 60 )); then echo "${diff}s ago"
  elif (( diff < 3600 )); then echo "$(( diff / 60 ))m ago"
  elif (( diff < 86400 )); then echo "$(( diff / 3600 ))h ago"
  else echo "$(( diff / 86400 ))d ago"
  fi
}

if [[ ! -f "$STATUS_FILE" ]]; then
  echo "${RED}status.json が見つかりません: ${STATUS_FILE}${RESET}"
  echo "先に fetch-status.sh を実行してください。"
  exit 1
fi

FETCHED_AT=$(jq -r '.fetchedAt' "$STATUS_FILE")

echo "${BOLD}My Tasks${RESET}  ${DIM}(updated $(relative_time "$FETCHED_AT"), fetched at ${FETCHED_AT})${RESET}"
echo

# --- Review requested ---
review_count=$(jq '.reviewRequested | length' "$STATUS_FILE")
echo "${BOLD}Review requested${RESET} (${review_count})"
if [[ "$review_count" -eq 0 ]]; then
  echo "  (none)"
else
  jq -r '.reviewRequested[] | "\(.repository.nameWithOwner)\t#\(.number)\t\(.title)\t\(.url)\t\(.updatedAt)\t\(.myLastReviewAt // "")"' "$STATUS_FILE" \
    | while IFS=$'\t' read -r repo number title url updated_at review_at; do
    suffix="  ${DIM}(updated $(relative_time "$updated_at"))${RESET}"
    [[ -n "$review_at" ]] && suffix+="  ${DIM}(last review $(relative_time "$review_at"))${RESET}"
    printf "  %s %s  %s%s\n" "$repo" "$(hyperlink "$url" "$number")" "$(hyperlink "$url" "$title")" "$suffix"
  done
fi
echo

# --- Project boards: In review ---
echo "${BOLD}Project boards - In review${RESET}"
proj_count=$(jq '[.projectsInReview[].items[]] | length' "$STATUS_FILE")
if [[ "$proj_count" -eq 0 ]]; then
  echo "  (none)"
else
  jq -r '.projectsInReview[] | . as $p | .items[] | "\($p.title)\t\(.repo)\t#\(.number)\t\(.title)\t\(.url)\t\(.updatedAt)"' "$STATUS_FILE" \
    | while IFS=$'\t' read -r project repo number title url updated_at; do
    printf "  [%s] %s %s  %s  ${DIM}(updated %s)${RESET}\n" "$project" "$repo" "$(hyperlink "$url" "$number")" "$(hyperlink "$url" "$title")" "$(relative_time "$updated_at")"
  done
fi
echo

# --- Assigned issues ---
issue_count=$(jq '.assignedIssues | length' "$STATUS_FILE")
echo "${BOLD}Assigned issues${RESET} (${issue_count})"
if [[ "$issue_count" -eq 0 ]]; then
  echo "  (none)"
else
  jq -r '.assignedIssues[] | "\(.repository.nameWithOwner)\t#\(.number)\t\(.title)\t\(.url)\t\(.updatedAt)"' "$STATUS_FILE" \
    | while IFS=$'\t' read -r repo number title url updated_at; do
    printf "  %s %s  %s  ${DIM}(updated %s)${RESET}\n" "$repo" "$(hyperlink "$url" "$number")" "$(hyperlink "$url" "$title")" "$(relative_time "$updated_at")"
  done
fi
echo

# --- My PRs, ranked by what needs my action first ---
pr_count=$(jq '.myPullRequests | length' "$STATUS_FILE")
echo "${BOLD}My open PRs${RESET} (${pr_count})"
if [[ "$pr_count" -eq 0 ]]; then
  echo "  (none)"
else
  jq -r '
    def priority:
      if .isDraft then
        (if .reviewDecision == "CHANGES_REQUESTED" then 0 else 2 end)
      elif .reviewDecision == "CHANGES_REQUESTED" then 0
      elif .reviewDecision == "APPROVED" and .mergeable == "MERGEABLE" then 1
      else 3
      end;
    def status_label:
      if .isDraft then "DRAFT"
      elif .reviewDecision == "CHANGES_REQUESTED" then "CHANGES REQUESTED"
      elif .reviewDecision == "APPROVED" and .mergeable == "MERGEABLE" then "MERGE NOW"
      elif .mergeable == "CONFLICTING" then "CONFLICT"
      else "AWAITING REVIEW"
      end;
    .myPullRequests
    | map(. + {_priority: priority, _label: status_label})
    | sort_by([._priority, -(.updatedAt | fromdateiso8601)])
    | .[]
    | "\(._priority)\t\(._label)\t\(.repository.nameWithOwner)\t#\(.number)\t\(.title)\t\(.url)\t\(.updatedAt)\t\(.lastReviewAt // "")"
  ' "$STATUS_FILE" | while IFS=$'\t' read -r _prio label repo number title url updated_at review_at; do
    case "$label" in
      "MERGE NOW") color="$GREEN" ;;
      "CHANGES REQUESTED"|"CONFLICT") color="$RED" ;;
      "DRAFT") color="$DIM" ;;
      *) color="$YELLOW" ;;
    esac
    suffix="  ${DIM}(updated $(relative_time "$updated_at"))${RESET}"
    [[ -n "$review_at" ]] && suffix+="  ${DIM}(last review $(relative_time "$review_at"))${RESET}"
    printf "  %s%-18s%s %s ${CYAN}%s${RESET}  %s%s\n" "$color" "[$label]" "$RESET" "$repo" "$(hyperlink "$url" "$number")" "$(hyperlink "$url" "$title")" "$suffix"
  done
fi
