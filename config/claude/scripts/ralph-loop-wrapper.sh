#!/bin/bash
# Wrapper for ralph-loop setup script that adds --max-iterations 5 by default.

DEFAULT_MAX_ITERATIONS=5

# Add default --max-iterations if not specified by user
if [[ ! "$*" == *"--max-iterations"* ]]; then
  set -- "--max-iterations" "$DEFAULT_MAX_ITERATIONS" "$@"
fi

# Find the plugin's setup script
RALPH_SCRIPT=$(find ~/.claude/plugins/cache -name "setup-ralph-loop.sh" 2>/dev/null | grep "ralph-loop" | head -1)

if [[ -z "$RALPH_SCRIPT" ]]; then
  echo "❌ Error: ralph-loop plugin not found in ~/.claude/plugins/cache" >&2
  exit 1
fi

exec "$RALPH_SCRIPT" "$@"
