#!/bin/bash
# Wrapper for bark-notify.sh that loads credentials from settings.local.json
SETTINGS=~/.claude/settings.local.json
export BARK_DEVICE_KEY=$(jq -r '.env.BARK_DEVICE_KEY // empty' "$SETTINGS")
export BARK_ENCRYPT_KEY=$(jq -r '.env.BARK_ENCRYPT_KEY // empty' "$SETTINGS")
export BARK_ENCRYPT_IV=$(jq -r '.env.BARK_ENCRYPT_IV // empty' "$SETTINGS")
exec ~/.claude/hooks/bark-notify.sh
