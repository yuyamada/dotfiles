#!/bin/bash
# Usage: gh-project-in-review.sh <org> <project_number>
set -euo pipefail

# Ensure gh only ever sees a readonly-scoped token when this script is run
# standalone (it already inherits GH_TOKEN when called from fetch-status.sh).
if [[ -z "${GH_TOKEN:-}" ]]; then
  exec ghtkn exec -e GH_TOKEN:readonly -- "$0" "$@"
fi

ORG="${1:?Usage: $0 <org> <project_number>}"
PROJECT_NUMBER="${2:?Usage: $0 <org> <project_number>}"

# --paginate doesn't support combining --jq with --slurp, and a single page
# is capped at 100 items (this board has ~1000), so pages are fetched raw and
# combined/filtered with a separate jq pass afterward.
gh api graphql --paginate -f query="
query(\$endCursor: String) {
  organization(login: \"${ORG}\") {
    projectV2(number: ${PROJECT_NUMBER}) {
      title
      items(first: 100, after: \$endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          fieldValueByName(name: \"Status\") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            ... on Issue { title number url state updatedAt assignees(first: 5) { nodes { login } } repository { nameWithOwner } }
            ... on PullRequest { title number url state updatedAt assignees(first: 5) { nodes { login } } repository { nameWithOwner } }
          }
        }
      }
    }
  }
}" | jq -s '{
    title: .[0].data.organization.projectV2.title,
    items: [.[].data.organization.projectV2.items.nodes[]
      | select(.fieldValueByName.name == "In review" and .content.state == "OPEN")
      | .content
      | { repo: .repository.nameWithOwner, number: .number, title: .title, assignees: [.assignees.nodes[].login], url: .url, updatedAt: .updatedAt }]
  }'
