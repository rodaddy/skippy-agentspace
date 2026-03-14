# Deploy Service Workflow

**Prerequisites:** Source `config.env` before executing these commands. See `config.env.example` for setup.

## Input Parameters (extract from natural language)

- `SERVICE_NAME` - Service name (becomes subdomain)
- `PORT` - Backend port
- `RAM` - Optional, default 512MB
- `DISK` - Optional, default 2GB
- `TARBALL` - Optional, path to service tarball
- `SYSTEMD_SERVICE` - Optional, systemd service name

## Workflow

### 1. Find Next Available IP

```bash
NEXT_IP=$(bash scripts/find-next-ip.sh)
IP_NET1="${DEPLOY_NET1}.${NEXT_IP}"
IP_NET2="${DEPLOY_NET2}.${NEXT_IP}"
VMID=$((200 + NEXT_IP))
```

### 2. Create LXC

```bash
ssh root@${DEPLOY_SERVER_IP} "pct create ${VMID} local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname ${SERVICE_NAME} \
  --memory ${RAM:-512} \
  --swap 512 \
  --net0 name=eth0,bridge=vmbr0,ip=${IP_NET1}/24,gw=${DEPLOY_GATEWAY},type=veth \
  --net1 name=eth1,bridge=vmbr0,ip=${IP_NET2}/24,tag=20,type=veth \
  --rootfs local-lvm:${DISK:-2} \
  --unprivileged 1 \
  --features nesting=1 \
  --nameserver '${DEPLOY_DNS_VMIDS}' \
  --start 1"
```

### 3. Install Base Stack

```bash
ssh root@${DEPLOY_SERVER_IP} "pct push ${VMID} scripts/install-base-stack.sh /tmp/install.sh && \
  pct exec ${VMID} -- bash /tmp/install.sh"
```

### 4. Deploy Tarball (if provided)

```bash
if [[ -n "$TARBALL" ]]; then
  scp "$TARBALL" root@${DEPLOY_SERVER_IP}:/tmp/service.tar.gz
  ssh root@${DEPLOY_SERVER_IP} "pct push ${VMID} /tmp/service.tar.gz /root/service.tar.gz && \
    pct exec ${VMID} -- tar xzf /root/service.tar.gz -C /root/"
fi
```

### 5. Configure systemd (if service provided)

Uses `references/systemd-service.service` template with variable substitution:
- `{{SERVICE_NAME}}`
- `{{PORT}}`
- `{{WORKING_DIR}}`

### 6. Add nginx Proxy

```bash
cat references/nginx-proxy.conf | \
  sed "s/{{SERVICE_NAME}}/${SERVICE_NAME}/g" | \
  sed "s/{{BACKEND_IP}}/${IP_NET2}/g" | \
  sed "s/{{PORT}}/${PORT}/g" > /tmp/${SERVICE_NAME}.conf

# Deploy to proxy host
scp /tmp/${SERVICE_NAME}.conf root@${DEPLOY_SERVER_IP}:/tmp/
ssh root@${DEPLOY_SERVER_IP} "pct push ${DEPLOY_PROXY_VMID} /tmp/${SERVICE_NAME}.conf /etc/nginx/sites-available/${SERVICE_NAME}.conf && \
  pct exec ${DEPLOY_PROXY_VMID} -- ln -sf /etc/nginx/sites-available/${SERVICE_NAME}.conf /etc/nginx/sites-enabled/ && \
  pct exec ${DEPLOY_PROXY_VMID} -- nginx -t && \
  pct exec ${DEPLOY_PROXY_VMID} -- systemctl reload nginx"
```

### 7. Add DNS to All DNS Servers

Add the DNS entry to all Pi-hole instances listed in `DEPLOY_DNS_VMIDS`.

**IMPORTANT GOTCHAS:**
- Pi-hole instances may be on **different Proxmox nodes** -- `DEPLOY_SERVER_IP` only discovers
  containers on one node. Use `DEPLOY_DNS_VMIDS` from config.env and search all nodes.
- **Pi-hole v6** uses `pihole.toml` (`dns.hosts` array), NOT `custom.list`. Entries added to
  `custom.list` alone will NOT resolve. You must edit `/etc/pihole/pihole.toml`.
- The `pihole` binary is at `/usr/local/bin/pihole` -- not in default PATH for `pct exec`.
- After editing `pihole.toml`, you must **restart pihole-FTL** (`systemctl restart pihole-FTL`),
  not just `pihole reloaddns`. The TOML config is read on FTL startup.
- When editing `pihole.toml` via sed through SSH+pct layers, quoting is unreliable. Push a
  script file to the container and execute it instead.

```bash
# Proxmox nodes to search for DNS server containers
PROXMOX_NODES=("10.71.1.5" "10.71.1.6" "10.71.1.8")

for VMID in ${DEPLOY_DNS_VMIDS}; do
  # Find which Proxmox node hosts this VMID
  NODE_IP=""
  for NODE in "${PROXMOX_NODES[@]}"; do
    if ssh root@${NODE} "pct status ${VMID}" &>/dev/null; then
      NODE_IP="${NODE}"
      break
    fi
  done

  if [[ -z "$NODE_IP" ]]; then
    echo "WARNING: Could not find VMID ${VMID} on any Proxmox node"
    continue
  fi

  echo "Adding DNS to VMID ${VMID} on ${NODE_IP}..."

  # Find the last entry line in dns.hosts array and insert after it
  # Push a script to avoid SSH+pct quoting issues
  cat > /tmp/add_dns_${VMID}.sh << 'INNERSCRIPT'
#!/usr/bin/env bash
ENTRY="PLACEHOLDER_ENTRY"
# Check if entry already exists in pihole.toml
if grep -q "$ENTRY" /etc/pihole/pihole.toml; then
  echo "Entry already exists, skipping"
  exit 0
fi
# Find the line with ] ### CHANGED in the dns.hosts section and insert before it
# Add comma to current last entry, then add new entry
LAST_LINE=$(grep -n '^\s*"10\.' /etc/pihole/pihole.toml | tail -1 | cut -d: -f1)
sed -i "${LAST_LINE}s/\"$/\",/" /etc/pihole/pihole.toml
sed -i "${LAST_LINE}a\\    \"${ENTRY}\"" /etc/pihole/pihole.toml
INNERSCRIPT

  # Replace placeholder with actual entry
  sed -i "s|PLACEHOLDER_ENTRY|${DEPLOY_PROXY_IP} ${SERVICE_NAME}.${DEPLOY_DOMAIN}|" /tmp/add_dns_${VMID}.sh

  scp /tmp/add_dns_${VMID}.sh root@${NODE_IP}:/tmp/
  ssh root@${NODE_IP} "pct push ${VMID} /tmp/add_dns_${VMID}.sh /tmp/add_dns.sh && \
    pct exec ${VMID} -- bash /tmp/add_dns.sh && \
    pct exec ${VMID} -- systemctl restart pihole-FTL"

  echo "DNS added to VMID ${VMID}"
done
```

### 8. Verify Deployment

```bash
echo "Testing deployment..."
sleep 5
dig +short ${SERVICE_NAME}.${DEPLOY_DOMAIN}
curl -s https://${SERVICE_NAME}.${DEPLOY_DOMAIN}/health || \
  curl -I https://${SERVICE_NAME}.${DEPLOY_DOMAIN}
```

## Output

```
Service deployed successfully!

LXC: ${VMID} (${SERVICE_NAME})
IPs: ${IP_NET1} / ${IP_NET2}
URL: https://${SERVICE_NAME}.${DEPLOY_DOMAIN}
Backend: ${IP_NET2}:${PORT}

Next steps:
1. Configure service in LXC ${VMID}
2. Set up authentication
3. Test endpoint: curl https://${SERVICE_NAME}.${DEPLOY_DOMAIN}
```
