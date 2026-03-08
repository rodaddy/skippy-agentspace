#!/usr/bin/env bash
set -euo pipefail

# Find next available matching IP on both networks
# Returns just the host octet (e.g., 14)
#
# Configure these for your environment:
NET1="<your-network-1>"  # e.g., 10.0.1
NET2="<your-network-2>"  # e.g., 10.0.2

for i in {13..254}; do
  # Check if IP is free on BOTH networks
  if ! ping -c 1 -W 1 "${NET1}.${i}" >/dev/null 2>&1 && \
     ! ping -c 1 -W 1 "${NET2}.${i}" >/dev/null 2>&1; then
    echo "$i"
    exit 0
  fi
done

echo "ERROR: No available IPs found" >&2
exit 1
