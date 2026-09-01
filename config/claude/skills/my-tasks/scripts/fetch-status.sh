#!/bin/bash
# Usage: fetch-status.sh
# Fetches review-requested PRs, assigned issues, own open PRs (with review/CI
# status), and each configured project's "In review" items, then writes the
# combined result to $HOME/.cache/my-tasks/status.json.
set -euo pipefail

# Ensure gh only ever sees a readonly-scoped token, whether this script is run
# interactively, from launchd, or from cron (none of which pick up the `gh`
# shell wrapper defined for interactive shells).
if [[ -z "${GH_TOKEN:-}" ]]; then
  exec ghtkn exec -e GH_TOKEN:readonly -- "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"
OUTPUT_DIR="${HOME}/.cache/my-tasks"
OUTPUT_FILE="${OUTPUT_DIR}/status.json"

mkdir -p "$OUTPUT_DIR"

ORG=$(jq -r '.org' "$CONFIG_FILE")
PROJECT_NUMBERS=$(jq -r '.projects[]' "$CONFIG_FILE")
MY_LOGIN=$(gh api graphql -f query='{viewer{login}}' --jq '.data.viewer.login')

review_requested_raw=$(gh search prs --review-requested=@me --state=open --owner "$ORG" \
  --json repository,title,number,url,author,updatedAt --limit 30)

# Enrich with the date of my last review on each PR, if any.
review_requested=$(echo "$review_requested_raw" | jq -c '.[]' | while IFS= read -r pr; do
  repo=$(echo "$pr" | jq -r '.repository.nameWithOwner')
  number=$(echo "$pr" | jq -r '.number')
  detail=$(gh pr view "$number" -R "$repo" --json latestReviews 2>/dev/null || echo '{}')
  echo "$pr" | jq -c --argjson d "$detail" --arg me "$MY_LOGIN" '
    . + {
      myLastReviewAt: (($d.latestReviews // []) | map(select(.author.login == $me)) | last | .submittedAt // null)
    }'
done | jq -sc '.')

assigned_issues=$(gh search issues --assignee=@me --state=open --owner "$ORG" \
  --json repository,title,number,url,author,updatedAt --limit 30)

my_prs_raw=$(gh search prs --author=@me --state=open --owner "$ORG" \
  --json repository,title,number,url,updatedAt,isDraft --limit 30)

my_prs=$(echo "$my_prs_raw" | jq -c '.[]' | while IFS= read -r pr; do
  repo=$(echo "$pr" | jq -r '.repository.nameWithOwner')
  number=$(echo "$pr" | jq -r '.number')
  detail=$(gh pr view "$number" -R "$repo" \
    --json reviewDecision,mergeable,statusCheckRollup,latestReviews 2>/dev/null || echo '{}')
  echo "$pr" | jq -c --argjson d "$detail" '. + {
    reviewDecision: ($d.reviewDecision // null),
    mergeable: ($d.mergeable // null),
    checks: ([$d.statusCheckRollup[]?.conclusion] | unique),
    lastReviewAt: (($d.latestReviews // []) | sort_by(.submittedAt) | last | .submittedAt // null)
  }'
done | jq -sc '.')

projects=$(for n in $PROJECT_NUMBERS; do
  "${SCRIPT_DIR}/gh-project-in-review.sh" "$ORG" "$n"
done | jq -sc '.')

jq -n \
  --arg fetchedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson reviewRequested "$review_requested" \
  --argjson assignedIssues "$assigned_issues" \
  --argjson myPullRequests "$my_prs" \
  --argjson projectsInReview "$projects" \
  '{
    fetchedAt: $fetchedAt,
    reviewRequested: $reviewRequested,
    assignedIssues: $assignedIssues,
    myPullRequests: $myPullRequests,
    projectsInReview: $projectsInReview
  }' > "$OUTPUT_FILE"

echo "Wrote $OUTPUT_FILE"
