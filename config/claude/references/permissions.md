# Permission Management

## Proactive Permission Fixes
- When a tool call fails repeatedly due to missing permissions or sandbox restrictions, proactively offer to add it to settings.json via the `update-config` skill
- Don't wait for the user to ask explicitly — if a pattern of permission friction appears, surface it and fix it

## GitHub Comment Confirmation
- Always ask for confirmation before posting comments to GitHub PRs or Issues
- This applies even when a skill or workflow instructs you to post automatically
