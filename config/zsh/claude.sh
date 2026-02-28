export PATH="$HOME/.local/bin:$PATH"
export ANTHROPIC_API_KEY="$(security find-generic-password -s "anthropic-api-key" -w 2>/dev/null)"
