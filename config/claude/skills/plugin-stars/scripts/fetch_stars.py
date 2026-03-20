#!/usr/bin/env python3
"""Fetch and rank Claude Code plugin GitHub repos by star count."""

import json
import subprocess
import sys
from typing import Optional


SEARCH_QUERIES = [
    "claude code",       # broad query - covers most plugin/marketplace repos by stars
    "claude plugins",    # catches repos without "code" in description
]

# Repos to exclude from results (add here if noise becomes a problem)
DENYLIST: set[str] = set()

# Repos that may not appear in search results but are known to be relevant
PINNED_REPOS = [
    "anthropics/claude-plugins-official",
    "affaan-m/everything-claude-code",
    "ChromeDevTools/chrome-devtools-mcp",
    "microsoft/playwright-mcp",
    "upstash/context7",
    "oraios/serena",
    "zilliztech/memsearch",
    "obra/superpowers-marketplace",
]


def gh(*args: str) -> Optional[dict]:
    result = subprocess.run(
        ["gh", *args],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Warning: gh command failed: {result.stderr.strip()}", file=sys.stderr)
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None


def search_repos(query: str, limit: int = 100) -> list[str]:
    data = gh(
        "search", "repos", query,
        "--sort", "stars",
        "--limit", str(limit),
        "--json", "fullName",
    )
    if not data:
        return []
    return [r["fullName"] for r in data]


def fetch_stars_batch(repos: list[str]) -> dict[str, int]:
    """Fetch star counts for up to 100 repos using GraphQL."""
    if not repos:
        return {}

    # GraphQL aliases must be valid identifiers
    aliases = {f"r{i}": repo for i, repo in enumerate(repos)}
    fields = "\n".join(
        f'  {alias}: repository(owner:"{repo.split("/")[0]}", name:"{repo.split("/")[1]}") {{ stargazerCount }}'
        for alias, repo in aliases.items()
    )
    query = f"{{ {fields} }}"

    result = subprocess.run(
        ["gh", "api", "graphql", "-f", f"query={query}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Warning: GraphQL failed: {result.stderr.strip()}", file=sys.stderr)
        return {}

    try:
        data = json.loads(result.stdout).get("data", {})
    except json.JSONDecodeError:
        return {}

    return {
        aliases[alias]: info["stargazerCount"]
        for alias, info in data.items()
        if info and "stargazerCount" in info
    }


def main() -> None:
    print("Searching GitHub for Claude Code plugin repos...", file=sys.stderr)

    # Collect unique repos across all queries
    found: set[str] = set(PINNED_REPOS)
    for query in SEARCH_QUERIES:
        repos = search_repos(query, limit=100)
        found.update(repos)
        print(f"  [{query}] {len(repos)} repos found", file=sys.stderr)

    all_repos = [r for r in found if r not in DENYLIST]
    print(f"\nFetching star counts for {len(all_repos)} repos...", file=sys.stderr)

    # Batch in chunks of 100 (GraphQL alias limit)
    stars: dict[str, int] = {}
    for i in range(0, len(all_repos), 80):
        chunk = all_repos[i:i + 80]
        stars.update(fetch_stars_batch(chunk))

    # Sort and print
    ranked = sorted(stars.items(), key=lambda x: -x[1])
    top100 = ranked[:100]

    print(f"\n{'Rank':>4}  {'Stars':>7}  Repository")
    print("-" * 50)
    for rank, (repo, count) in enumerate(top100, 1):
        print(f"{rank:>4}. {count:>7,} ⭐  {repo}")


if __name__ == "__main__":
    main()
