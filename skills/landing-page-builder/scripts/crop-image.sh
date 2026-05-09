#!/usr/bin/env bash
# Crop/resize images using macOS sips (no dependencies needed)
# Usage: crop-image.sh --input file.png --width 1200 --height 630 [--preview]

set -euo pipefail

INPUT=""
WIDTH=""
HEIGHT=""
OUTPUT=""
PREVIEW=false

usage() {
    cat <<'USAGE'
Usage: crop-image.sh [OPTIONS]

Options:
  --input PATH     Source image file (required)
  --width N        Target width in pixels (required)
  --height N       Target height in pixels (required)
  --output PATH    Output path (default: overwrites input)
  --preview        Show what would happen without modifying files
  -h, --help       Show this help

Uses macOS sips for zero-dependency image manipulation.
Crops from center to target aspect ratio, then resizes.

Common sizes:
  Blog header:     --width 1200 --height 630
  YouTube thumb:   --width 1280 --height 720
  Social square:   --width 1080 --height 1080
  Twitter header:  --width 1500 --height 500
USAGE
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)   INPUT="$2"; shift 2 ;;
        --width)   WIDTH="$2"; shift 2 ;;
        --height)  HEIGHT="$2"; shift 2 ;;
        --output)  OUTPUT="$2"; shift 2 ;;
        --preview) PREVIEW=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$INPUT" ]]  && { echo "ERROR: --input required"; exit 1; }
[[ -z "$WIDTH" ]]  && { echo "ERROR: --width required"; exit 1; }
[[ -z "$HEIGHT" ]] && { echo "ERROR: --height required"; exit 1; }
[[ ! -f "$INPUT" ]] && { echo "ERROR: File not found: $INPUT"; exit 1; }

OUTPUT="${OUTPUT:-$INPUT}"

# Get current dimensions
CUR_W=$(sips -g pixelWidth "$INPUT" 2>/dev/null | tail -1 | awk '{print $2}')
CUR_H=$(sips -g pixelHeight "$INPUT" 2>/dev/null | tail -1 | awk '{print $2}')

if [[ -z "$CUR_W" || -z "$CUR_H" ]]; then
    echo "ERROR: Could not read image dimensions from $INPUT"
    exit 1
fi

echo "Source:  ${CUR_W}x${CUR_H}  ($INPUT)"
echo "Target:  ${WIDTH}x${HEIGHT}  ($OUTPUT)"

# Calculate crop dimensions to match target aspect ratio
TARGET_RATIO=$(echo "scale=4; $WIDTH / $HEIGHT" | bc)
CURRENT_RATIO=$(echo "scale=4; $CUR_W / $CUR_H" | bc)

CROP_W=$CUR_W
CROP_H=$CUR_H

# Determine if we need to crop width or height
WIDER=$(echo "$CURRENT_RATIO > $TARGET_RATIO" | bc)
if [[ "$WIDER" -eq 1 ]]; then
    # Image is wider than target -- crop width
    CROP_W=$(echo "$CUR_H * $TARGET_RATIO / 1" | bc)
    echo "Action:  Crop width to ${CROP_W}x${CROP_H}, then resize to ${WIDTH}x${HEIGHT}"
else
    # Image is taller than target -- crop height
    CROP_H=$(echo "$CUR_W / $TARGET_RATIO / 1" | bc)
    echo "Action:  Crop height to ${CROP_W}x${CROP_H}, then resize to ${WIDTH}x${HEIGHT}"
fi

if $PREVIEW; then
    echo "=== PREVIEW MODE -- no changes made ==="
    exit 0
fi

# If output differs from input, copy first
if [[ "$OUTPUT" != "$INPUT" ]]; then
    mkdir -p "$(dirname "$OUTPUT")"
    cp "$INPUT" "$OUTPUT"
fi

# Crop to target aspect ratio (center crop)
sips --cropToHeightWidth "$CROP_H" "$CROP_W" "$OUTPUT" >/dev/null 2>&1

# Resize to exact target dimensions
sips --resampleHeightWidth "$HEIGHT" "$WIDTH" "$OUTPUT" >/dev/null 2>&1

# Verify result
RESULT_W=$(sips -g pixelWidth "$OUTPUT" 2>/dev/null | tail -1 | awk '{print $2}')
RESULT_H=$(sips -g pixelHeight "$OUTPUT" 2>/dev/null | tail -1 | awk '{print $2}')
RESULT_SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')

echo "Result:  ${RESULT_W}x${RESULT_H} (${RESULT_SIZE} bytes)"
echo "SUCCESS: $OUTPUT"
