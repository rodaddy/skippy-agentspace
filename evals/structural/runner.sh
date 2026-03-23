#!/usr/bin/env bash
set -euo pipefail

# Structural eval runner for skippy-agentspace
# 103 binary pass/fail assertions across 22 categories
# Usage: bash evals/structural/runner.sh
#
# Assertions are split into category files under categories/ for LAW 9 compliance.
# This runner provides the framework (check/assert helpers) and sources all categories.

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

# Log every run to run-log.txt
LOG_FILE="$(dirname "$0")/run-log.txt"
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "================================================================"
echo "  RUN: $(date '+%Y-%m-%d %H:%M:%S')  branch: $(git branch --show-current 2>/dev/null || echo unknown)"
echo "================================================================"

PASS=0
FAIL=0
TOTAL=0
FAILURES=()

check() {
  local id="$1" category="$2" desc="$3"
  shift 3
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    printf "  PASS  #%-3d [%-18s] %s\n" "$id" "$category" "$desc"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  #%-3d [%-18s] %s\n" "$id" "$category" "$desc"
    FAIL=$((FAIL + 1))
    FAILURES+=("#$id: $desc")
  fi
}

# Helper: returns 0 (success) if command output is empty, 1 if non-empty
assert_empty() { [[ -z "$("$@" 2>/dev/null)" ]]; }
assert_not_empty() { [[ -n "$("$@" 2>/dev/null)" ]]; }

echo "=== skippy-agentspace structural eval ==="
echo "    repo: $REPO_ROOT"
echo "    date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Source all category files in order
CATEGORIES_DIR="$(dirname "$0")/categories"
for cat_file in "$CATEGORIES_DIR"/*.sh; do
  [[ -f "$cat_file" ]] || continue
  # shellcheck source=/dev/null
  source "$cat_file"
done

# --- RESULTS ---
echo "========================================="
echo "  SCORE: $PASS/$TOTAL ($(( (PASS * 100) / TOTAL ))%)"
echo "  PASS:  $PASS"
echo "  FAIL:  $FAIL"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "FAILURES:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

echo ""
echo "ALL ASSERTIONS PASSED"
exit 0
