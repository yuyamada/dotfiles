#!/bin/sh
# Fetch all Claude model prices from LiteLLM and push to Prometheus Pushgateway

PUSHGATEWAY="${PUSHGATEWAY_URL:-http://pushgateway:9091}"
LITELLM_URL="https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"

echo "$(date): fetching prices from LiteLLM..."
PRICES=$(curl -sf --max-time 15 "$LITELLM_URL") || {
  echo "$(date): ERROR: failed to fetch prices from LiteLLM"
  exit 1
}

# Emit Prometheus metrics for one model
# Args: <litellm_key> <otel_label>
emit_model() {
  litellm_key="$1"
  otel_label="$2"

  for mapping in \
    "input:input_cost_per_token" \
    "output:output_cost_per_token" \
    "cacheRead:cache_read_input_token_cost" \
    "cacheCreation:cache_creation_input_token_cost"
  do
    type_name="${mapping%%:*}"
    json_key="${mapping##*:}"
    val=$(printf '%s' "$PRICES" | jq -r ".\"${litellm_key}\".${json_key} // empty | . * 1000000")
    [ -n "$val" ] && printf \
      'claude_token_price_usd_per_mtok{model="%s",type="%s"} %s\n' \
      "$otel_label" "$type_name" "$val"
  done
}

{
  printf '# HELP claude_token_price_usd_per_mtok Token price in USD per million tokens\n'
  printf '# TYPE claude_token_price_usd_per_mtok gauge\n'

  # All bare Claude models from LiteLLM (no provider prefix, no versioning suffix like v1:0)
  # These cover date-versioned models Claude Code uses for auxiliary calls
  for model in $(printf '%s' "$PRICES" \
    | jq -r 'keys[] | select(
        test("^claude-") and
        (contains("/") | not) and
        (contains("v1:0") | not)
      )')
  do
    emit_model "$model" "$model"
  done


} | curl -sf --data-binary @- "${PUSHGATEWAY}/metrics/job/claude_prices"

echo "$(date): pushed $(printf '%s' "$PRICES" | jq '[keys[] | select(test("^claude-") and (contains("/") | not) and (contains("v1:0") | not))] | length') models to ${PUSHGATEWAY}"
