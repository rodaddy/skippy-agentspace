#!/usr/bin/env bash
set -euo pipefail

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
# Configure for your vaultwarden instance:
/usr/local/bin/bw config server https://<your-vaultwarden-url>

echo "Base stack installed successfully!"
echo "Installed:"
echo "  - curl, wget, unzip, ca-certificates"
echo "  - bun: $(/root/.bun/bin/bun --version 2>/dev/null || echo 'check PATH')"
echo "  - bw: $(/usr/local/bin/bw --version 2>/dev/null || echo 'check install')"
