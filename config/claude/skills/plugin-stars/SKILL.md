---
name: plugin-stars
description: Show a star ranking of Claude Code plugin-related GitHub repositories. Use this skill when the user asks about "plugin stars", "star ranking", "popular plugins", "which plugins are trending", or wants to discover Claude Code plugin repos. Automatically fetches top repos from GitHub search.
allowed-tools: Bash
---

## Steps

Run the fetch script to search GitHub and display the star ranking:

```bash
python3 /Users/yuyamada/.claude/skills/plugin-stars/scripts/fetch_stars.py
```

The script searches GitHub for Claude Code plugin repos across multiple queries, deduplicates, fetches star counts, and prints a ranked list of the top 100.

**IMPORTANT: Always display the full output as a markdown table directly in your response. Never summarize or truncate — show all 100 rows.**

Format each row as: `| {rank} | {stars} | {url} |`

## Interpreting results

After showing the full table, offer to:
- Dig into any specific repo (open in browser, show recent commits, etc.)
- Filter by category (marketplaces, individual plugins, MCP servers, etc.)
- Re-run to get fresh data
