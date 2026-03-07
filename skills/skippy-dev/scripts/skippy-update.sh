#!/usr/bin/env bash
set -uo pipefail

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

# Load known versions -- safe key=value parsing (no source)
gsd_hash="none"
paul_hash="none"
last_check="never"
if [[ -f "$VERSIONS_FILE" ]]; then
    while IFS='=' read -r key value; do
        case "$key" in
            gsd_hash)   gsd_hash="$value" ;;
            paul_hash)  paul_hash="$value" ;;
            last_check) last_check="$value" ;;
        esac
    done < "$VERSIONS_FILE"
fi

echo "=== skippy-update ==="
echo ""

# --- Fetch or clone a repo ---
# Usage: fetch_repo <name> <url> <dir>
# Returns 0 on success, 1 on failure. Cwd changes to repo dir on success.
fetch_repo() {
    local name="$1" url="$2" dir="$3"
    if [[ -d "$dir/.git" ]]; then
        cd "$dir" || return 1
        if ! git fetch origin --quiet 2>/dev/null; then
            echo "  WARNING: Failed to fetch $name -- network error or repo unavailable"
            return 1
        fi
        git reset --hard origin/main --quiet 2>/dev/null || true
    else
        echo "Cloning $name..."
        if ! git clone --quiet "$url" "$dir" 2>/dev/null; then
            echo "  WARNING: Failed to clone $name -- network error or repo unavailable"
            return 1
        fi
        cd "$dir" || return 1
    fi
    return 0
}

# --- Report changes between known and current hash ---
# Usage: report_changes <known_hash> <current_hash>
# Prints comparison output. Must be called from within the repo directory.
report_changes() {
    local known_hash="$1" current_hash="$2"

    echo "  Known:   ${known_hash:0:10}"
    echo "  Current: ${current_hash:0:10}"

    if [[ "$known_hash" == "$current_hash" ]]; then
        echo "  Status:  No changes"
    else
        echo "  Status:  CHANGES DETECTED"
        if [[ "$known_hash" != "none" ]]; then
            echo ""
            echo "  Changed files:"
            git diff --name-only "${known_hash}..HEAD" 2>/dev/null | sed 's/^/    /' || echo "    (full diff unavailable -- old hash may be gone)"
            echo ""
            echo "  Recent commits:"
            git log --oneline "${known_hash}..HEAD" 2>/dev/null | head -10 | sed 's/^/    /' || echo "    (log unavailable)"
        else
            echo "  (First run -- no baseline to diff against)"
        fi
    fi
}

# --- GSD ---
GSD_CURRENT="$gsd_hash"
echo "--- GSD (get-shit-done) ---"
if fetch_repo "GSD" "$GSD_REPO" "$UPSTREAM_DIR/gsd"; then
    GSD_CURRENT=$(git rev-parse HEAD)
    report_changes "$gsd_hash" "$GSD_CURRENT"
else
    echo "  Skipping GSD -- will retry next run"
fi

echo ""

# --- PAUL ---
PAUL_CURRENT="$paul_hash"
echo "--- PAUL ---"
if fetch_repo "PAUL" "$PAUL_REPO" "$UPSTREAM_DIR/paul"; then
    PAUL_CURRENT=$(git rev-parse HEAD)
    report_changes "$paul_hash" "$PAUL_CURRENT"
else
    echo "  Skipping PAUL -- will retry next run"
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
