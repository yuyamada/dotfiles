export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.claude/bark.env" ] && source "$HOME/.claude/bark.env"
if [ -f "$HOME/.claude_anthropic_enabled" ]; then
  export ANTHROPIC_API_KEY="$(security find-generic-password -s "anthropic-api-key" -w 2>/dev/null)"
fi
if [ -f "$HOME/.claude_google_enabled" ]; then
  export GOOGLE_API_KEY="$(security find-generic-password -a "GOOGLE_API_KEY" -s "claude-mcp" -w 2>/dev/null)"
fi
