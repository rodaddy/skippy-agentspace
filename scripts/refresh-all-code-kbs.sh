#!/usr/bin/env bash
# Refresh all indexed code KBs
# Runs at 3am daily via launchd, or manually on-demand
#
# Usage:
#   refresh-all-code-kbs.sh           # Sequential (default for scheduled)
#   refresh-all-code-kbs.sh --parallel # Parallel (faster for manual)

set -euo pipefail

# Parse arguments
PARALLEL=false
if [[ "${1:-}" == "--parallel" ]]; then
    PARALLEL=true
fi

KB_DIR="$HOME/.config/pai-private/knowledge/code"
TOOLS_DIR="$HOME/.config/pai/Tools"
LOG_DIR="$HOME/.config/pai/logs"
LOG_FILE="$LOG_DIR/kb-refresh-$(date +%Y%m%d-%H%M%S).log"

echo "🔄 Code KB Refresh - $(date)" | tee -a "$LOG_FILE"
echo "════════════════════════════════════════" | tee -a "$LOG_FILE"

# Find all repos with existing KBs
REPOS=()
for kb_path in "$KB_DIR"/*/architecture-v2.json; do
    if [ -f "$kb_path" ]; then
        repo_name=$(basename "$(dirname "$kb_path")")
        # Skip metadata files
        if [[ "$repo_name" != "repos" && "$repo_name" != "repos.json" ]]; then
            REPOS+=("$repo_name")
        fi
    fi
done

if [ ${#REPOS[@]} -eq 0 ]; then
    echo "❌ No indexed repos found" | tee -a "$LOG_FILE"
    exit 0
fi

echo "📊 Found ${#REPOS[@]} indexed repos:" | tee -a "$LOG_FILE"
for repo in "${REPOS[@]}"; do
    echo "   - $repo" | tee -a "$LOG_FILE"
done
echo "" | tee -a "$LOG_FILE"

if $PARALLEL; then
    echo "⚡ Running in PARALLEL mode" | tee -a "$LOG_FILE"
else
    echo "📝 Running in SEQUENTIAL mode" | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# Track success/failure
SUCCESS_COUNT=0
FAILED_REPOS=()

if $PARALLEL; then
    # Parallel execution - start all repos at once
    PIDS=()
    REPO_PATHS=()

    for repo in "${REPOS[@]}"; do
        KB_FILE="$KB_DIR/$repo/architecture-v2.json"
        REPO_PATH=$(jq -r '.repositoryPath' "$KB_FILE" 2>/dev/null || echo "")

        if [ -z "$REPO_PATH" ] || [ ! -d "$REPO_PATH" ]; then
            echo "⚠️  Skipping $repo: Repository path not found" | tee -a "$LOG_FILE"
            FAILED_REPOS+=("$repo (path missing)")
            continue
        fi

        echo "🔍 Starting: $repo (path: $REPO_PATH)" | tee -a "$LOG_FILE"

        # Start extraction in background (with enrichment)
        (cd "$TOOLS_DIR/.." && bun Tools/code-kb-extract-v2.ts "$REPO_PATH" --enrich > "$LOG_DIR/kb-refresh-$repo-$(date +%Y%m%d-%H%M%S).log" 2>&1) &
        PIDS+=($!)
        REPO_PATHS+=("$repo")
    done

    echo "" | tee -a "$LOG_FILE"
    echo "⏳ Waiting for ${#PIDS[@]} parallel extractions to complete..." | tee -a "$LOG_FILE"

    # Wait for all background jobs and check exit codes
    for i in "${!PIDS[@]}"; do
        pid="${PIDS[$i]}"
        repo="${REPO_PATHS[$i]}"

        if wait "$pid"; then
            echo "   ✅ $repo - Success" | tee -a "$LOG_FILE"
            ((SUCCESS_COUNT++))
        else
            echo "   ❌ $repo - Failed" | tee -a "$LOG_FILE"
            FAILED_REPOS+=("$repo")
        fi
    done

else
    # Sequential execution - one at a time
    for repo in "${REPOS[@]}"; do
        echo "🔍 Refreshing: $repo" | tee -a "$LOG_FILE"

        # Read existing KB to get repository path
        KB_FILE="$KB_DIR/$repo/architecture-v2.json"
        REPO_PATH=$(jq -r '.repositoryPath' "$KB_FILE" 2>/dev/null || echo "")

        if [ -z "$REPO_PATH" ] || [ ! -d "$REPO_PATH" ]; then
            echo "   ⚠️  Skipping: Repository path not found ($REPO_PATH)" | tee -a "$LOG_FILE"
            FAILED_REPOS+=("$repo (path missing)")
            continue
        fi

        # Run extraction (with enrichment)
        echo "   Path: $REPO_PATH" | tee -a "$LOG_FILE"
        if cd "$TOOLS_DIR/.." && bun Tools/code-kb-extract-v2.ts "$REPO_PATH" --enrich >> "$LOG_FILE" 2>&1; then
            echo "   ✅ Success" | tee -a "$LOG_FILE"
            ((SUCCESS_COUNT++))
        else
            echo "   ❌ Failed" | tee -a "$LOG_FILE"
            FAILED_REPOS+=("$repo")
        fi
        echo "" | tee -a "$LOG_FILE"
    done
fi

# Summary
echo "════════════════════════════════════════" | tee -a "$LOG_FILE"
echo "📊 Refresh Summary:" | tee -a "$LOG_FILE"
echo "   Total repos: ${#REPOS[@]}" | tee -a "$LOG_FILE"
echo "   Successful: $SUCCESS_COUNT" | tee -a "$LOG_FILE"
echo "   Failed: ${#FAILED_REPOS[@]}" | tee -a "$LOG_FILE"

if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "⚠️  Failed repos:" | tee -a "$LOG_FILE"
    for repo in "${FAILED_REPOS[@]}"; do
        echo "   - $repo" | tee -a "$LOG_FILE"
    done
fi

echo "" | tee -a "$LOG_FILE"
echo "📝 Full log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "✅ Refresh complete - $(date)" | tee -a "$LOG_FILE"
