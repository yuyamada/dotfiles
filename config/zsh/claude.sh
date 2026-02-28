export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.claude_anthropic_enabled" ]; then
  export ANTHROPIC_API_KEY="$(security find-generic-password -s "anthropic-api-key" -w 2>/dev/null)"
fi
