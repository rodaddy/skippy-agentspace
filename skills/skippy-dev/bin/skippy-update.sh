#!/usr/bin/env bash
set -euo pipefail

# skippy-update -- Check GSD and PAUL repos for upstream changes
# Usage: skippy-update.sh

UPSTREAM_DIR="${SKIPPY_CACHE_DIR:-${HOME}/.cache/skippy-upstream}"
# Resolve SKILL_DIR: prefer CLAUDE_SKILL_DIR, fall back to script's own directory
SKILL_DIR="${CLAUDE_SKILL_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
VERSIONS_FILE="${SKILL_DIR}/.versions"
GSD_REPO="https://github.com/gsd-build/get-shit-done.git"
PAUL_REPO="https://github.com/ChristopherKahler/paul.git"

mkdir -p "$UPSTREAM_DIR"

# Initialize versions file if missing
if [[ ! -f "$VERSIONS_FILE" ]]; then
    echo "gsd_hash=none" > "$VERSIONS_FILE"
    echo "paul_hash=none" >> "$VERSIONS_FILE"
    echo "last_check=never" >> "$VERSIONS_FILE"
fi

# Load known versions
source "$VERSIONS_FILE"

echo "=== skippy-update ==="
echo ""

# --- GSD ---
echo "--- GSD (get-shit-done) ---"
if [[ -d "$UPSTREAM_DIR/gsd/.git" ]]; then
    cd "$UPSTREAM_DIR/gsd"
    git fetch origin --quiet 2>/dev/null
    git reset --hard origin/main --quiet 2>/dev/null
else
    echo "Cloning GSD..."
    git clone --quiet "$GSD_REPO" "$UPSTREAM_DIR/gsd" 2>/dev/null
    cd "$UPSTREAM_DIR/gsd"
fi

GSD_CURRENT=$(git rev-parse --short HEAD)
echo "  Known:   ${gsd_hash:-none}"
echo "  Current: $GSD_CURRENT"

if [[ "${gsd_hash:-none}" == "$GSD_CURRENT" ]]; then
    echo "  Status:  No changes"
else
    echo "  Status:  CHANGES DETECTED"
    if [[ "${gsd_hash:-none}" != "none" ]]; then
        echo ""
        echo "  Changed files:"
        git diff --name-only "${gsd_hash}..HEAD" 2>/dev/null | sed 's/^/    /' || echo "    (full diff unavailable -- old hash may be gone)"
        echo ""
        echo "  Recent commits:"
        git log --oneline "${gsd_hash}..HEAD" 2>/dev/null | head -10 | sed 's/^/    /' || echo "    (log unavailable)"
    else
        echo "  (First run -- no baseline to diff against)"
    fi
fi

echo ""

# --- PAUL ---
echo "--- PAUL ---"
if [[ -d "$UPSTREAM_DIR/paul/.git" ]]; then
    cd "$UPSTREAM_DIR/paul"
    git fetch origin --quiet 2>/dev/null
    git reset --hard origin/main --quiet 2>/dev/null
else
    echo "Cloning PAUL..."
    git clone --quiet "$PAUL_REPO" "$UPSTREAM_DIR/paul" 2>/dev/null
    cd "$UPSTREAM_DIR/paul"
fi

PAUL_CURRENT=$(git rev-parse --short HEAD)
echo "  Known:   ${paul_hash:-none}"
echo "  Current: $PAUL_CURRENT"

if [[ "${paul_hash:-none}" == "$PAUL_CURRENT" ]]; then
    echo "  Status:  No changes"
else
    echo "  Status:  CHANGES DETECTED"
    if [[ "${paul_hash:-none}" != "none" ]]; then
        echo ""
        echo "  Changed files:"
        git diff --name-only "${paul_hash}..HEAD" 2>/dev/null | sed 's/^/    /' || echo "    (full diff unavailable)"
        echo ""
        echo "  Recent commits:"
        git log --oneline "${paul_hash}..HEAD" 2>/dev/null | head -10 | sed 's/^/    /' || echo "    (log unavailable)"
    else
        echo "  (First run -- no baseline to diff against)"
    fi
fi

echo ""

# --- Update stored versions ---
cat > "$VERSIONS_FILE" <<EOF
gsd_hash=$GSD_CURRENT
paul_hash=$PAUL_CURRENT
last_check=$(date +%Y-%m-%d)
EOF

echo "=== Versions saved to $VERSIONS_FILE ==="
echo "Review changes above. Absorb what's useful -- no auto-merge."
