#!/usr/bin/env bash
# Generate images via LiteLLM proxy using Gemini 3 image model
# Usage: generate-image.sh --prompt "description" --output path/to/file.png [--model image]

set -euo pipefail

LITELLM_URL="${LITELLM_URL:-http://<LITELLM_IP>:4000}"
LITELLM_MODEL="${LITELLM_MODEL:-image}"
PROMPT=""
OUTPUT=""
MODEL=""
PREVIEW=false

usage() {
    cat <<'USAGE'
Usage: generate-image.sh [OPTIONS]

Options:
  --prompt TEXT     Image description (required)
  --output PATH    Output file path (required, e.g., public/images/hero.png)
  --model NAME     LiteLLM model alias (default: image)
  --preview        Show what would be generated without actually generating
  -h, --help       Show this help

Auth (auto-resolved in this order):
  1. LITELLM_API_KEY env var (if already set)
  2. vaultwarden-secrets MCP via mcp-cli (auto-fetched)

Environment:
  LITELLM_URL      Proxy URL (default: http://<LITELLM_IP>:4000)

Examples:
  generate-image.sh --prompt "flat illustration of a rocket, white background" --output public/images/hero.png
  generate-image.sh --preview --prompt "test prompt" --output test.png
USAGE
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt)  PROMPT="$2"; shift 2 ;;
        --output)  OUTPUT="$2"; shift 2 ;;
        --model)   MODEL="$2"; shift 2 ;;
        --preview) PREVIEW=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$PROMPT" ]] && { echo "ERROR: --prompt is required"; exit 1; }
[[ -z "$OUTPUT" ]] && { echo "ERROR: --output is required"; exit 1; }

# Auto-resolve API key: env var first, then vaultwarden-secrets MCP
if [[ -z "${LITELLM_API_KEY:-}" ]]; then
    if command -v mcp-cli &>/dev/null; then
        echo "Fetching API key from vaultwarden-secrets..."
        LITELLM_API_KEY=$(mcp-cli call vaultwarden-secrets/get_secret_fields '{"name": "LiteLLM"}' 2>/dev/null \
            | jq -r '.password // empty' 2>/dev/null || true)
    fi
    if [[ -z "${LITELLM_API_KEY:-}" ]]; then
        echo "ERROR: Could not resolve LiteLLM API key"
        echo "Set LITELLM_API_KEY env var or ensure vaultwarden-secrets MCP is available"
        exit 1
    fi
    export LITELLM_API_KEY
fi

MODEL="${MODEL:-$LITELLM_MODEL}"

if $PREVIEW; then
    echo "=== PREVIEW MODE ==="
    echo "Prompt:  $PROMPT"
    echo "Output:  $OUTPUT"
    echo "Model:   $MODEL"
    echo "URL:     $LITELLM_URL"
    echo "=== Would generate image with these settings ==="
    exit 0
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

echo "Generating image..."
echo "  Prompt: $PROMPT"
echo "  Output: $OUTPUT"
echo "  Model:  $MODEL"

# Call LiteLLM chat completions endpoint with image generation request
# Gemini 3 image models return inline image data in the response
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "${LITELLM_URL}/v1/chat/completions" \
    -H "Authorization: Bearer ${LITELLM_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg model "$MODEL" \
        --arg prompt "Generate an image: $PROMPT. Return ONLY the image, no text." \
        '{
            model: $model,
            messages: [{role: "user", content: $prompt}],
            max_tokens: 4096
        }'
    )")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "ERROR: API returned HTTP $HTTP_CODE"
    echo "$BODY" | jq -r '.error.message // .detail // .' 2>/dev/null || echo "$BODY"
    exit 1
fi

# Extract base64 image data from the response
# LiteLLM returns Gemini image data in: .choices[0].message.images[0].image_url.url
# Format: "data:image/png;base64,<base64data>"
IMAGE_DATA=""

# Method 1: LiteLLM images array (primary path for Gemini image models)
IMAGE_DATA=$(echo "$BODY" | jq -r '
    .choices[0].message.images[0].image_url.url // empty
' 2>/dev/null)

# Method 2: Check for inline_data in content parts (alternative format)
if [[ -z "$IMAGE_DATA" ]]; then
    IMAGE_DATA=$(echo "$BODY" | jq -r '
        .choices[0].message.content
        | if type == "array" then
            .[] | select(.type == "image_url" or .type == "image" or has("inline_data"))
            | (.image_url.url // .inline_data.data // .url // empty)
        else
            empty
        end
    ' 2>/dev/null | head -1)
fi

# Method 3: Check if content contains a base64 data URI string
if [[ -z "$IMAGE_DATA" ]]; then
    CONTENT=$(echo "$BODY" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
    if [[ "$CONTENT" == data:image/* ]]; then
        IMAGE_DATA="$CONTENT"
    fi
fi

# Strip data URI prefix to get raw base64
RAW_BASE64="${IMAGE_DATA}"
RAW_BASE64="${RAW_BASE64#data:image/png;base64,}"
RAW_BASE64="${RAW_BASE64#data:image/jpeg;base64,}"
RAW_BASE64="${RAW_BASE64#data:image/webp;base64,}"

if [[ -z "$RAW_BASE64" ]]; then
    echo "ERROR: No image data found in response"
    echo "Response structure:"
    echo "$BODY" | jq '{
        model: .model,
        content_type: (.choices[0].message.content | type),
        has_images: (.choices[0].message.images != null),
        images_count: (.choices[0].message.images | length // 0),
        message_keys: (.choices[0].message | keys),
        finish_reason: .choices[0].finish_reason
    }' 2>/dev/null || echo "$BODY" | head -20
    exit 1
fi

# Decode and save
echo "$RAW_BASE64" | base64 -d > "$OUTPUT" 2>/dev/null

# Validate the output file
if [[ ! -s "$OUTPUT" ]]; then
    echo "ERROR: Output file is empty or decode failed"
    rm -f "$OUTPUT"
    exit 1
fi

FILE_TYPE=$(file -b --mime-type "$OUTPUT" 2>/dev/null || echo "unknown")
FILE_SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')

if [[ "$FILE_TYPE" != image/* ]]; then
    echo "WARNING: Output file type is '$FILE_TYPE', expected image/*"
    echo "File may not be a valid image"
fi

echo "SUCCESS: Image saved to $OUTPUT"
echo "  Type: $FILE_TYPE"
echo "  Size: ${FILE_SIZE} bytes"
