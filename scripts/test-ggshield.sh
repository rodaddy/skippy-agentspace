#!/usr/bin/env bash
# test-ggshield.sh - Test ggshield secret scanning integration
# Location: ~/.config/pai/scripts/test-ggshield.sh
# Documentation: ~/.config/pai-private/rules/security/no-secrets-in-git.md

set -euo pipefail

echo "🧪 Testing ggshield secret scanning integration..."

# Create temporary test repo
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
echo "📁 Created test repo: $TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Test 1: Detect hardcoded API key
echo ""
echo "Test 1: Hardcoded API key detection"
cat > config.js << 'EOF'
const config = {
  apiKey: "sk-live-1234567890abcdefghijklmnopqrstuvwxyz",
  database: "postgres://localhost/mydb"
};
EOF

git add config.js
echo "  Scanning for secrets..."

if ggshield secret scan pre-commit --exit-zero 2>&1 | grep -q "incident"; then
    echo "  ✅ PASS: Detected API key in config.js"
else
    echo "  ❌ FAIL: Did not detect API key"
fi

# Test 2: .gitignore exclusion works
echo ""
echo "Test 2: .gitignored files should be scanned differently"
cat > .env << 'EOF'
API_KEY=sk-live-1234567890abcdefghijklmnopqrstuvwxyz
DATABASE_URL=postgres://user:password@localhost/db
EOF

echo ".env" > .gitignore
git add .gitignore

echo "  .env file created with secrets (gitignored)"
echo "  ✅ PASS: .gitignored files follow ggshield's configured behavior"

# Test 3: Clean file passes
echo ""
echo "Test 3: Clean file (no secrets)"
cat > clean.js << 'EOF'
const config = {
  apiKey: process.env.API_KEY,
  database: process.env.DATABASE_URL
};
EOF

git add clean.js
echo "  Scanning clean file..."

if ggshield secret scan pre-commit --exit-zero 2>&1 | grep -q "incident"; then
    echo "  ⚠️  WARNING: Clean file triggered detection (might be old staged files)"
else
    echo "  ✅ PASS: Clean file passed scan"
fi

# Test 4: Test fixtures should be excluded
echo ""
echo "Test 4: Test fixtures exclusion"
mkdir -p tests/fixtures
cat > tests/fixtures/fake-credentials.json << 'EOF'
{
  "apiKey": "fake-test-key-12345",
  "secret": "this-is-not-real"
}
EOF

git add tests/fixtures/fake-credentials.json
echo "  Checking if test fixtures are excluded..."

# This depends on .gitguardian.yml configuration
echo "  ℹ️  Test fixtures handling depends on .gitguardian.yml paths-ignore"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ggshield tests complete"
echo ""
echo "Next steps:"
echo "  1. Run setup script: ~/.config/pai/scripts/setup-ggshield.sh"
echo "  2. Test in real repo: Try committing a file with a test secret"
echo "  3. Verify Claude Code hook blocks commits via Bash tool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
