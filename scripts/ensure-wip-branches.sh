#!/usr/bin/env bash
# ensure-wip-branches.sh - Ensure all repos are on WIP branches, never main
# Location: ~/.config/pai/scripts/ensure-wip-branches.sh
# Purpose: Find all git repos and create WIP branches for any stuck on main/master

set -e

echo "🔍 Scanning for git repositories on protected branches..."
echo ""

SEARCH_PATHS=(
  "$HOME/Development"
  "${DEV_DIR:-/Volumes/ThunderBolt/Development}"
)

PROTECTED_BRANCHES=("main" "master" "develop" "production")
REPOS_PROCESSED=0
REPOS_SWITCHED=0

# Find all git repos
for search_path in "${SEARCH_PATHS[@]}"; do
  if [ ! -d "$search_path" ]; then
    continue
  fi

  # Find all .git directories (max depth 3 to avoid going too deep)
  while IFS= read -r git_dir; do
    repo_path=$(dirname "$git_dir")
    repo_name=$(basename "$repo_path")

    REPOS_PROCESSED=$((REPOS_PROCESSED + 1))

    # Get current branch
    current_branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || echo "")

    # Skip if not on a protected branch
    is_protected=0
    for protected in "${PROTECTED_BRANCHES[@]}"; do
      if [ "$current_branch" = "$protected" ]; then
        is_protected=1
        break
      fi
    done

    if [ $is_protected -eq 0 ]; then
      echo "✅ $repo_name: Already on '$current_branch'"
      continue
    fi

    # Check for uncommitted changes
    if ! git -C "$repo_path" diff-index --quiet HEAD -- 2>/dev/null; then
      echo "⚠️  $repo_name: Has uncommitted changes on $current_branch"
      echo "   Creating WIP branch and preserving changes..."

      # Create WIP branch with timestamp
      wip_branch="wip/auto-$(date +%Y%m%d-%H%M%S)"
      git -C "$repo_path" checkout -b "$wip_branch" 2>/dev/null

      echo "   ✅ Created and switched to: $wip_branch"
      REPOS_SWITCHED=$((REPOS_SWITCHED + 1))
    else
      # No uncommitted changes
      echo "📦 $repo_name: Clean working tree on $current_branch"

      # Check if there are unpushed commits
      unpushed=$(git -C "$repo_path" log origin/$current_branch..$current_branch --oneline 2>/dev/null | wc -l || echo "0")

      if [ "$unpushed" -gt 0 ]; then
        echo "   ⚠️  Has $unpushed unpushed commit(s)"
        wip_branch="wip/unpushed-$(date +%Y%m%d-%H%M%S)"
        git -C "$repo_path" checkout -b "$wip_branch" 2>/dev/null
        echo "   ✅ Created and switched to: $wip_branch"
        REPOS_SWITCHED=$((REPOS_SWITCHED + 1))
      else
        # Clean and synced with remote, just create WIP branch
        wip_branch="wip/work"

        # Check if wip/work already exists
        if git -C "$repo_path" rev-parse --verify "$wip_branch" >/dev/null 2>&1; then
          echo "   ℹ️  Branch '$wip_branch' already exists, switching to it"
          git -C "$repo_path" checkout "$wip_branch" 2>/dev/null
        else
          git -C "$repo_path" checkout -b "$wip_branch" 2>/dev/null
          echo "   ✅ Created and switched to: $wip_branch"
        fi
        REPOS_SWITCHED=$((REPOS_SWITCHED + 1))
      fi
    fi

  done < <(find "$search_path" -maxdepth 3 -type d -name ".git" 2>/dev/null)
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Scan complete!"
echo ""
echo "📊 Summary:"
echo "   Repositories scanned: $REPOS_PROCESSED"
echo "   Switched to WIP branches: $REPOS_SWITCHED"
echo ""
echo "All repositories are now on feature/WIP branches."
echo "Protected branches (main/master/develop/production) are no longer active."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
