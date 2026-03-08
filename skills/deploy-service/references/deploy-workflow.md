# Deploy Service Workflow

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
IP_NET1="<your-network-1>.${NEXT_IP}"
IP_NET2="<your-network-2>.${NEXT_IP}"
VMID=$((200 + NEXT_IP))
```

### 2. Create LXC

```bash
ssh root@<your-server-ip> "pct create ${VMID} local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname ${SERVICE_NAME} \
  --memory ${RAM:-512} \
  --swap 512 \
  --net0 name=eth0,bridge=vmbr0,ip=${IP_NET1}/24,gw=<your-gateway>,type=veth \
  --net1 name=eth1,bridge=vmbr0,ip=${IP_NET2}/24,tag=20,type=veth \
  --rootfs local-lvm:${DISK:-2} \
  --unprivileged 1 \
  --features nesting=1 \
  --nameserver '<your-dns-servers>' \
  --start 1"
```

### 3. Install Base Stack

```bash
ssh root@<your-server-ip> "pct push ${VMID} scripts/install-base-stack.sh /tmp/install.sh && \
  pct exec ${VMID} -- bash /tmp/install.sh"
```

### 4. Deploy Tarball (if provided)

```bash
if [[ -n "$TARBALL" ]]; then
  scp "$TARBALL" root@<your-server-ip>:/tmp/service.tar.gz
  ssh root@<your-server-ip> "pct push ${VMID} /tmp/service.tar.gz /root/service.tar.gz && \
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
scp /tmp/${SERVICE_NAME}.conf root@<your-server-ip>:/tmp/
ssh root@<your-server-ip> "pct push <your-proxy-vmid> /tmp/${SERVICE_NAME}.conf /etc/nginx/sites-available/${SERVICE_NAME}.conf && \
  pct exec <your-proxy-vmid> -- ln -sf /etc/nginx/sites-available/${SERVICE_NAME}.conf /etc/nginx/sites-enabled/ && \
  pct exec <your-proxy-vmid> -- nginx -t && \
  pct exec <your-proxy-vmid> -- systemctl reload nginx"
```

### 7. Add DNS to All DNS Servers

Auto-discover DNS servers and add entry:

```bash
# Find all DNS servers (e.g., pihole instances)
DNS_SERVERS=$(ssh root@<your-server-ip> "pct list" | grep -i pihole | awk '{print $1}')

for SERVER in $DNS_SERVERS; do
  ssh root@<your-server-ip> "pct exec ${SERVER} -- bash -c 'echo \"<your-proxy-ip> ${SERVICE_NAME}.<your-domain>\" >> /etc/pihole/custom.list' && \
    pct exec ${SERVER} -- pihole reloaddns"
done
```

### 8. Verify Deployment

```bash
echo "Testing deployment..."
sleep 5
dig +short ${SERVICE_NAME}.<your-domain>
curl -s https://${SERVICE_NAME}.<your-domain>/health || \
  curl -I https://${SERVICE_NAME}.<your-domain>
```

## Output

```
Service deployed successfully!

LXC: ${VMID} (${SERVICE_NAME})
IPs: ${IP_NET1} / ${IP_NET2}
URL: https://${SERVICE_NAME}.<your-domain>
Backend: ${IP_NET2}:${PORT}

Next steps:
1. Configure service in LXC ${VMID}
2. Set up authentication
3. Test endpoint: curl https://${SERVICE_NAME}.<your-domain>
```
