#!/bin/bash
# pipe-stage-learn.sh — PostToolUse hook for Claude Code
#
# Companion to pipe-stage-permissions.sh. When the PreToolUse hook passes
# through an unrecognized command and the user approves it (tool executes
# successfully), this hook captures the pattern into approved-patterns.json
# so it's auto-approved next time.
#
# Learning logic:
# - Binary with a slash (path): store the binary path as a glob pattern
#   e.g. /usr/local/cuda/bin/nvcc → /usr/local/cuda/bin/*
# - Env var assignment: store the exact VAR=value pattern
#   e.g. LD_LIBRARY_PATH=/opt/cuda/lib64 → LD_LIBRARY_PATH=/opt/cuda/*

set -eo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${CLAUDE_HOOKS_DATA_DIR:-$HOME/.claude/hooks}"
APPROVED_FILE="$DATA_DIR/approved-patterns.json"
PENDING_DIR="$DATA_DIR/.pending"

INPUT=$(cat)
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // empty')

# Clean up: remove pending files older than 5 minutes
if [ -d "$PENDING_DIR" ]; then
  find "$PENDING_DIR" -name '*.json' -mmin +5 -delete 2>/dev/null || true
fi

# Check if there's a pending approval for this tool_use_id
if [ -z "$TOOL_USE_ID" ] || [ ! -f "$PENDING_DIR/$TOOL_USE_ID.json" ]; then
  exit 0  # nothing pending
fi

PENDING=$(cat "$PENDING_DIR/$TOOL_USE_ID.json")
rm -f "$PENDING_DIR/$TOOL_USE_ID.json"

STAGE=$(echo "$PENDING" | jq -r '.stage // empty')
PENDING_CWD=$(echo "$PENDING" | jq -r '.cwd // empty')

if [ -z "$STAGE" ]; then
  exit 0
fi

# Ensure approved-patterns.json exists
if [ ! -f "$APPROVED_FILE" ]; then
  echo '{"binaries":[],"env_vars":[]}' > "$APPROVED_FILE"
fi

# Determine what to add: env var or binary
added=false

# Check for leading env var assignments — learn each sensitive one
stage_remainder="$STAGE"
while [[ "$stage_remainder" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; do
  var_name="${BASH_REMATCH[1]}"
  assignment="${stage_remainder%%[[:space:]]*}"

  # Only learn sensitive vars (harmless ones don't need allowlisting)
  is_sensitive=false
  for prefix in PATH= LD_ DYLD_ PYTHONPATH= PYTHONHOME= NODE_PATH= GEM_PATH= GEM_HOME= RUBYLIB= PERL5LIB= CLASSPATH= GOPATH=; do
    if [[ "$assignment" == "$prefix"* ]]; then
      is_sensitive=true
      break
    fi
  done

  if [ "$is_sensitive" = true ]; then
    # Extract value and create a directory-level glob pattern
    value="${assignment#*=}"
    # Strip quotes
    value="${value#\"}" ; value="${value%\"}"
    value="${value#\'}" ; value="${value%\'}"

    # Create glob: keep parent dir, wildcard the last component
    # e.g. /opt/cuda/lib64 → /opt/cuda/*
    # For PATH-like (colon-separated), glob each component's parent
    IFS=':' read -ra components <<< "$value"
    for component in "${components[@]}"; do
      [ -z "$component" ] && continue
      parent_dir="$(dirname "$component")"
      glob_pattern="${var_name}=${parent_dir}/*"

      # Check if already present
      if ! jq -e --arg p "$glob_pattern" '.env_vars | index($p)' "$APPROVED_FILE" >/dev/null 2>&1; then
        jq --arg p "$glob_pattern" '.env_vars += [$p]' "$APPROVED_FILE" > "$APPROVED_FILE.tmp" \
          && mv "$APPROVED_FILE.tmp" "$APPROVED_FILE"
        added=true
      fi
    done
  fi

  # Advance past this assignment
  if [[ "$stage_remainder" =~ ^[A-Za-z_][A-Za-z0-9_]*=\"[^\"]*\"[[:space:]]+(.*) ]]; then
    stage_remainder="${BASH_REMATCH[1]}"
  elif [[ "$stage_remainder" =~ ^[A-Za-z_][A-Za-z0-9_]*=\'[^\']*\'[[:space:]]+(.*) ]]; then
    stage_remainder="${BASH_REMATCH[1]}"
  elif [[ "$stage_remainder" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; then
    stage_remainder="${BASH_REMATCH[1]}"
  else
    break
  fi
done

# Check if the remaining command is an unrecognized binary (has a slash)
binary="${stage_remainder%% *}"
if [[ "$binary" == */* ]]; then
  # Create glob: directory/* pattern
  binary_dir="$(dirname "$binary")"
  glob_pattern="${binary_dir}/*"

  # Check if already present
  if ! jq -e --arg p "$glob_pattern" '.binaries | index($p)' "$APPROVED_FILE" >/dev/null 2>&1; then
    jq --arg p "$glob_pattern" '.binaries += [$p]' "$APPROVED_FILE" > "$APPROVED_FILE.tmp" \
      && mv "$APPROVED_FILE.tmp" "$APPROVED_FILE"
    added=true
  fi
fi

exit 0
