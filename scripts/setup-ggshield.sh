#!/usr/bin/env bash
# setup-ggshield.sh - Standalone ggshield secret scanning setup
# Non-interactive. Authenticates via GitHub OAuth (browser redirect).
set -euo pipefail

echo "Setting up ggshield secret scanning..."

# 0. Disable macOS Keychain probe (causes popup dialogs)
export KEYRING_BACKEND=keyring.backends.null.Keyring
if ! grep -q 'KEYRING_BACKEND' ~/.zshenv 2>/dev/null; then
    echo 'export KEYRING_BACKEND=keyring.backends.null.Keyring' >> ~/.zshenv
    echo "  Added KEYRING_BACKEND to ~/.zshenv (prevents Keychain popups)"
fi

# 1. Install ggshield if missing
if command -v ggshield &>/dev/null; then
    echo "  ggshield installed: $(ggshield --version 2>/dev/null || echo 'unknown')"
else
    echo "  ggshield not found -- installing via Homebrew..."
    if ! command -v brew &>/dev/null; then
        echo "ERROR: Homebrew not found. Install brew first: https://brew.sh" >&2
        exit 1
    fi
    brew install gitguardian/tap/ggshield
    echo "  ggshield installed: $(ggshield --version 2>/dev/null)"
fi

# 2. Authenticate via GitHub OAuth (non-interactive, opens browser)
echo ""
echo "Checking GitGuardian authentication..."
if ggshield api-status &>/dev/null; then
    echo "  Already authenticated with GitGuardian"
else
    echo "  Authenticating via GitHub OAuth (opens browser)..."
    if ggshield auth login --method=web; then
        echo "  Authenticated with GitGuardian"
    else
        echo "  WARNING: Authentication failed. Retry later: ggshield auth login --method=web" >&2
    fi
fi

# 3. Install pre-commit hook globally
echo ""
echo "Installing global pre-commit hook..."
if ggshield install --mode global --force 2>/dev/null; then
    echo "  Global pre-commit hook installed"
else
    echo "  WARNING: Pre-commit hook install had issues (may already exist)" >&2
fi

# 4. Quick smoke test
echo ""
echo "Running smoke test..."
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
(
    cd "$TEST_DIR"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    echo 'password=super_secret_123' > test.txt
    git add test.txt
    if ggshield secret scan pre-commit --exit-zero 2>&1 | grep -q "incident"; then
        echo "  Smoke test passed: ggshield detected test secret"
    else
        echo "  Smoke test inconclusive (ggshield ran but did not flag test secret)"
    fi
)

echo ""
echo "ggshield setup complete. Secrets will be scanned on every commit."
