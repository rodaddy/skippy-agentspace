# Remove Service Workflow

## Input Parameters:

- `SERVICE_NAME` - Service name (subdomain to remove)
- `DESTROY_LXC` - Optional, boolean (default: false)
- `VMID` - Optional, LXC VMID to destroy

## Workflow:

### 1. Remove nginx Proxy Config

```bash
ssh root@<PROXMOX_NODE_IP> "pct exec 205 -- rm -f /etc/nginx/sites-enabled/${SERVICE_NAME}.conf && \
  pct exec 205 -- rm -f /etc/nginx/sites-available/${SERVICE_NAME}.conf && \
  pct exec 205 -- nginx -t && \
  pct exec 205 -- systemctl reload nginx"
```

### 2. Remove DNS from ALL Piholes

Auto-discover and clean:

```bash
# Find all piholes
PIHOLES=$(ssh root@<PROXMOX_NODE_IP> "pct list" | grep -i pihole | awk '{print $1}')
PIHOLES+=" <PIHOLE_IP>"  # Bare metal pihole

for PIHOLE in $PIHOLES; do
  if [[ $PIHOLE =~ ^[0-9]+$ ]]; then
    # LXC pihole
    ssh root@<PROXMOX_NODE_IP> "pct exec ${PIHOLE} -- sed -i '/${SERVICE_NAME}.your-domain.example/d' /etc/pihole/custom.list && \
      pct exec ${PIHOLE} -- systemctl restart pihole-FTL"
  else
    # Bare metal pihole
    ssh root@${PIHOLE} "sed -i '/${SERVICE_NAME}.your-domain.example/d' /etc/pihole/custom.list && \
      systemctl restart pihole-FTL"
  fi
done
```

### 3. Optionally Destroy LXC

```bash
if [[ "$DESTROY_LXC" == "true" && -n "$VMID" ]]; then
  ssh root@<PROXMOX_NODE_IP> "pct stop ${VMID} && pct destroy ${VMID}"
fi
```

## Output:

```
✅ Service removed successfully!

Cleaned up:
- nginx config: ${SERVICE_NAME}.conf
- DNS entries: ${SERVICE_NAME}.your-domain.example (removed from all piholes)
$( [[ "$DESTROY_LXC" == "true" ]] && echo "- LXC: ${VMID} destroyed" )
```
