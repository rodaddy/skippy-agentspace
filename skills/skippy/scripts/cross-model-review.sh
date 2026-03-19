#!/usr/bin/env bash
# cross-model-review.sh -- Send a review prompt to a non-Claude model via LiteLLM
#
# Usage:
#   cross-model-review.sh <model> <prompt-file> [--diff <diff-file>]
#   cross-model-review.sh gemini-3.1-pro /tmp/review-prompt.md --diff /tmp/changes.diff
#
# Models: gemini-3.1-pro (default/recommended), gemini-3-flash (fast/cheap)
# Output: Review response to stdout
#
# Requires: LITELLM_API_KEY in environment, jq installed

set -euo pipefail

LITELLM_URL="${LITELLM_BASE_URL:-http://10.71.1.33:4000}/v1/chat/completions"
MODEL="${1:?Usage: cross-model-review.sh <model> <prompt-file> [--diff <diff-file>]}"
PROMPT_FILE="${2:?Usage: cross-model-review.sh <model> <prompt-file> [--diff <diff-file>]}"
DIFF_FILE=""

# Parse optional --diff flag
shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --diff) DIFF_FILE="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Validate inputs
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    exit 1
fi

if [[ -z "${LITELLM_API_KEY:-}" ]]; then
    echo "Error: LITELLM_API_KEY not set" >&2
    exit 1
fi

# Build the user message
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

if [[ -n "$DIFF_FILE" && -f "$DIFF_FILE" ]]; then
    DIFF_CONTENT=$(cat "$DIFF_FILE")
    USER_MSG="${PROMPT_CONTENT}

## Code Changes to Review

\`\`\`diff
${DIFF_CONTENT}
\`\`\`"
else
    USER_MSG="$PROMPT_CONTENT"
fi

# Build JSON payload -- use jq to handle escaping
PAYLOAD=$(jq -n \
    --arg model "$MODEL" \
    --arg content "$USER_MSG" \
    '{
        model: $model,
        messages: [
            {
                role: "system",
                content: "You are an adversarial code reviewer from a different AI model family. Your job is to find issues that the implementing model (Claude) might systematically miss. Focus on: incorrect assumptions, overcomplicated solutions, missing edge cases, security gaps, and architectural concerns. Be direct and specific. No pleasantries."
            },
            {
                role: "user",
                content: $content
            }
        ],
        max_tokens: 4096,
        temperature: 0.3
    }')

# Call LiteLLM
RESPONSE=$(curl -s --max-time 120 \
    "$LITELLM_URL" \
    -H "Authorization: Bearer $LITELLM_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

# Check for errors
ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
if [[ -n "$ERROR" ]]; then
    echo "Error from LiteLLM: $ERROR" >&2
    exit 1
fi

# Extract and output the response
echo "$RESPONSE" | jq -r '.choices[0].message.content // "No response received"'
