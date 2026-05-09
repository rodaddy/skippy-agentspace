---
name: proxmox-mcp
description: Proxmox VE via MCP server (proxmox-plus Python server). Compare with /proxmox (REST API).
---

# Proxmox MCP Skill

**Auto-loads:** Proxmox MCP server for infrastructure management

## Triggers

- "proxmox"
- "manage vm"
- "container"
- "virtual machine"
- "infrastructure"
- "homelab"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/proxmox.json`

This skill enables the Proxmox MCP server which provides:
- VM management (start, stop, status, create, delete)
- Container (LXC) management
- Node status and monitoring
- Storage management
- Resource allocation
- Snapshot management

## Available Tools

Once loaded, you'll have access to:
- `mcp__proxmox__*` - All Proxmox MCP tools

## Usage Examples

**List VMs:**
```
User: Show me all running VMs in Proxmox
→ Queries Proxmox for VM status
```

**Start a VM:**
```
User: Start the Ubuntu VM
→ Uses Proxmox API to start specified VM
```

**Check node resources:**
```
User: What's the CPU and RAM usage on the Proxmox node?
→ Retrieves node resource statistics
```

## Technical Details

- **Host:** <PROXMOX_NODE_IP>:8006
- **Authentication:** API token (claude-mcp)
- **User:** root@pam
- **SSL Verification:** Disabled (homelab environment)
- **Binary:** `<DEV_DIR>/mcp/bin/proxmox-mcp-server`

## Notes

- Requires Proxmox VE instance accessible at <PROXMOX_NODE_IP>
- API token must have appropriate permissions
- MCP server only loads when this skill is invoked
- SSL verification disabled for local homelab use
