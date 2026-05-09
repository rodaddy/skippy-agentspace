#!/usr/bin/env bash
# List available LiteLLM models from live endpoint
# Usage: list-models.sh [--raw]

LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
KEY="${LITELLM_API_KEY:?Error: Set LITELLM_API_KEY env var}"

if [[ "$1" == "--raw" ]]; then
  curl -s "${LITELLM_URL}/v1/models" \
    -H "Authorization: Bearer ${KEY}" | jq '.data[].id'
  exit $?
fi

# Formatted output: separate aliases from raw model IDs
models_json=$(curl -s "${LITELLM_URL}/v1/models" \
  -H "Authorization: Bearer ${KEY}")

if echo "$models_json" | jq -e '.error' &>/dev/null; then
  echo "Error: $(echo "$models_json" | jq -r '.error.message')" >&2
  exit 1
fi

echo "=== LiteLLM Available Models ==="
echo ""
echo "Aliases (use these):"
echo "$models_json" | jq -r '.data[].id' | grep -v '/' | grep -v '@' | grep -v '\.' | sort | while read -r m; do
  printf "  %-20s\n" "$m"
done

echo ""
echo "Full model IDs:"
echo "$models_json" | jq -r '.data[].id' | grep -E '[@./]' | sort | while read -r m; do
  printf "  %s\n" "$m"
done
