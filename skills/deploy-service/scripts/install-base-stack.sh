#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../config.env"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: config.env not found at $CONFIG" >&2
    echo "  Copy config.env.example to config.env and fill in your values." >&2
    exit 1
fi

# Safe config load: only export KEY=VALUE lines (no arbitrary code execution)
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    key="${key## }"; key="${key%% }"
    value="${value## }"; value="${value%% }"
    value="${value#\"}"; value="${value%\"}"
    value="${value#\'}"; value="${value%\'}"
    export "$key=$value"
done < "$CONFIG"

: "${DEPLOY_VAULTWARDEN_URL:?DEPLOY_VAULTWARDEN_URL not set in config.env}"

echo "Installing base packages..."
apt-get update
apt-get install -y curl wget unzip ca-certificates

echo "Installing bun runtime..."
curl -fsSL https://bun.sh/install > /tmp/install-bun.sh
bash /tmp/install-bun.sh

echo "Installing bitwarden CLI..."
curl -fsSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o /tmp/bw.zip
cd /tmp && unzip -o bw.zip
mv bw /usr/local/bin/
chmod +x /usr/local/bin/bw

echo "Configuring bitwarden CLI..."
/usr/local/bin/bw config server "https://${DEPLOY_VAULTWARDEN_URL}"

echo "Base stack installed successfully!"
echo "Installed:"
echo "  - curl, wget, unzip, ca-certificates"
echo "  - bun: $(/root/.bun/bin/bun --version 2>/dev/null || echo 'check PATH')"
echo "  - bw: $(/usr/local/bin/bw --version 2>/dev/null || echo 'check install')"
