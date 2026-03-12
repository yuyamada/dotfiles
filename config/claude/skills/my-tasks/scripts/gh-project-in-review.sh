#!/bin/bash
# Usage: gh-project-in-review.sh <org> <project_number>
set -euo pipefail

ORG="${1:?Usage: $0 <org> <project_number>}"
PROJECT_NUMBER="${2:?Usage: $0 <org> <project_number>}"

gh api graphql -f query="
{
  organization(login: \"${ORG}\") {
    projectV2(number: ${PROJECT_NUMBER}) {
      title
      items(first: 100) {
        nodes {
          fieldValueByName(name: \"Status\") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            ... on Issue { title number url assignees(first: 5) { nodes { login } } repository { nameWithOwner } }
            ... on PullRequest { title number url assignees(first: 5) { nodes { login } } repository { nameWithOwner } }
          }
        }
      }
    }
  }
}" --jq '.data.organization.projectV2 | { title: .title, items: [.items.nodes[] | select(.fieldValueByName.name == "In review") | .content | { repo: .repository.nameWithOwner, number: .number, title: .title, assignees: [.assignees.nodes[].login], url: .url }] }'
