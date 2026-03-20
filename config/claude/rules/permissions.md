# Permission Management

## Proactive Permission Fixes
- When a tool call fails repeatedly due to missing permissions or sandbox restrictions, proactively offer to add it to settings.json via the `update-config` skill
- Don't wait for the user to ask explicitly — if a pattern of permission friction appears, surface it and fix it
