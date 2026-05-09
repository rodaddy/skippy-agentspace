---
name: infra-sync
description: Sync infrastructure inventory with live state from Proxmox, TrueNAS, and network gear. Pulls actual container/service data and updates INVENTORY.md.
---

# infra-sync - Infrastructure Inventory Sync

Pulls live state from infrastructure and updates the inventory.

## Usage

```
/infra-sync              # Full sync (all sources)
/infra-sync proxmox      # Proxmox only
/infra-sync services     # Service status only
```

## What It Does

1. Pull container/VM list from Proxmox (MCP preferred, SSH fallback)
2. Get IPs for each container
3. Check key service status
4. Update `INVENTORY.md` with current state
5. Flag discrepancies (new containers, changed IPs, down services)

## Access Methods

**Primary — `/proxmox` skill** (LiteLLM MCP gateway):
    ~/.config/pai/Skills/proxmox/pve-call get_containers '{"payload":{}}'
    ~/.config/pai/Skills/proxmox/pve-call get_nodes

**Fallback — SSH** when LiteLLM/MCP is down:
- proxmox01: `ssh root@<PROXMOX_NODE_IP>`
- proxmox02: `ssh root@<PROXMOX_NODE_IP>`
- proxmox03: `ssh root@<PROXMOX_NODE_IP>`

## Implementation

### Step 1: Pull Proxmox State

**Via `/proxmox` skill (preferred):**

    ~/.config/pai/Skills/proxmox/pve-call get_containers '{"payload":{}}'
    ~/.config/pai/Skills/proxmox/pve-call get_vms

**SSH fallback:**

    ssh root@<PROXMOX_NODE_IP> "pct list"
    ssh root@<PROXMOX_NODE_IP> "qm list"
    ssh root@<PROXMOX_NODE_IP> "pct list"
    ssh root@<PROXMOX_NODE_IP> "pct list"

### Step 2: Check Key Services

```bash
# Monitoring
ssh root@<YOUR_IP> "systemctl is-active grafana-server prometheus"

# LiteLLM
ssh root@<LITELLM_IP> "systemctl is-active litellm"

# Media stack
ssh root@<YOUR_IP> "systemctl is-active sonarr radarr lidarr prowlarr"
```

### Step 3: Update INVENTORY.md

Compare live state to current inventory:
- New containers → Add to inventory
- Missing containers → Mark or remove
- IP changes → Update
- Service status → Update

### Step 4: Report Changes

Output summary of what changed:
```
✅ Synced inventory with live state
  - 14 containers on proxmox06
  - 4 containers on proxmox02
  - 2 new: <names>
  - 1 IP changed: <name> <old-IP> → <new-IP>
```

## Output Location

Updates: `<DEV_DIR>/infrastructure/INVENTORY.md`
