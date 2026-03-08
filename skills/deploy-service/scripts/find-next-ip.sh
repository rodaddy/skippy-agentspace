#!/usr/bin/env bash
set -euo pipefail

# Find next available matching IP on both networks
# Returns just the host octet (e.g., 14)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../config.env"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: config.env not found at $CONFIG" >&2
    echo "  Copy config.env.example to config.env and fill in your values." >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG"

: "${DEPLOY_NET1:?DEPLOY_NET1 not set in config.env}"
: "${DEPLOY_NET2:?DEPLOY_NET2 not set in config.env}"

# Validate IP prefix format (e.g., 10.71.1 or 192.168.1)
_ip_prefix_re='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
if [[ ! "$DEPLOY_NET1" =~ $_ip_prefix_re ]]; then
    echo "Error: DEPLOY_NET1='$DEPLOY_NET1' is not a valid IP prefix (expected e.g., 10.71.1)" >&2
    exit 1
fi
if [[ ! "$DEPLOY_NET2" =~ $_ip_prefix_re ]]; then
    echo "Error: DEPLOY_NET2='$DEPLOY_NET2' is not a valid IP prefix (expected e.g., 10.71.20)" >&2
    exit 1
fi

for i in {13..254}; do
  # Check if IP is free on BOTH networks
  if ! ping -c 1 -W 1 "${DEPLOY_NET1}.${i}" >/dev/null 2>&1 && \
     ! ping -c 1 -W 1 "${DEPLOY_NET2}.${i}" >/dev/null 2>&1; then
    echo "$i"
    exit 0
  fi
done

echo "ERROR: No available IPs found" >&2
exit 1
