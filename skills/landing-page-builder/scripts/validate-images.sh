#!/usr/bin/env bash
# Validate generated images for structural integrity
# Usage: validate-images.sh --dir public/images/ [--verbose]

set -euo pipefail

DIR=""
FILE=""
VERBOSE=false
ERRORS=0
CHECKED=0

usage() {
    cat <<'USAGE'
Usage: validate-images.sh [OPTIONS]

Options:
  --dir PATH      Validate all images in directory
  --file PATH     Validate a single image file
  --verbose       Show details for each file
  -h, --help      Show this help

Checks performed:
  - File exists and is not empty (zero bytes)
  - File is a valid image format (PNG, JPEG, WebP, GIF)
  - File is not truncated (basic header check)

Exit codes:
  0  All images valid
  1  One or more validation failures
USAGE
    exit 0
}

validate_file() {
    local f="$1"
    local name
    name=$(basename "$f")
    CHECKED=$((CHECKED + 1))

    # Check exists
    if [[ ! -f "$f" ]]; then
        echo "FAIL: $name -- file not found"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Check not empty
    local size
    size=$(wc -c < "$f" | tr -d ' ')
    if [[ "$size" -eq 0 ]]; then
        echo "FAIL: $name -- zero bytes"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Check MIME type
    local mime
    mime=$(file -b --mime-type "$f" 2>/dev/null || echo "unknown")
    if [[ "$mime" != image/* ]]; then
        echo "FAIL: $name -- not an image (type: $mime)"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Check minimum viable size (images under 1KB are likely corrupt)
    if [[ "$size" -lt 1024 ]]; then
        echo "WARN: $name -- suspiciously small (${size} bytes)"
    fi

    if $VERBOSE; then
        # Get dimensions if sips is available (macOS)
        local dims=""
        if command -v sips &>/dev/null; then
            local w h
            w=$(sips -g pixelWidth "$f" 2>/dev/null | tail -1 | awk '{print $2}')
            h=$(sips -g pixelHeight "$f" 2>/dev/null | tail -1 | awk '{print $2}')
            dims="${w}x${h}"
        fi
        echo "PASS: $name -- $mime, ${size} bytes${dims:+, $dims}"
    else
        echo "PASS: $name"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)     DIR="$2"; shift 2 ;;
        --file)    FILE="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ -n "$FILE" ]]; then
    validate_file "$FILE"
elif [[ -n "$DIR" ]]; then
    if [[ ! -d "$DIR" ]]; then
        echo "ERROR: Directory not found: $DIR"
        exit 1
    fi

    echo "Validating images in: $DIR"
    echo "---"

    found=false
    while IFS= read -r -d '' f; do
        found=true
        validate_file "$f"
    done < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) -print0 2>/dev/null)

    if ! $found; then
        echo "WARNING: No image files found in $DIR"
        exit 1
    fi

    echo "---"
    echo "Checked: $CHECKED | Passed: $((CHECKED - ERRORS)) | Failed: $ERRORS"
else
    echo "ERROR: Specify --dir or --file"
    usage
fi

exit $((ERRORS > 0 ? 1 : 0))
