---
name: unifi
description: UniFi Network MCP integration - manage network devices, clients, configuration
---

# UniFi Network Skill

**Auto-loads:** UniFi MCP server for network management

## Triggers

- "unifi"
- "network"
- "wifi"
- "clients"
- "access point"
- "network devices"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/unifi.json`

This skill enables the UniFi MCP server which provides:
- Network device management
- Client listing and monitoring
- WiFi configuration
- Port management
- Network statistics
- Firewall rules

## Available Tools

Once loaded, you'll have access to:
- `mcp__unifi__*` - All UniFi MCP tools

## Usage Examples

**List connected clients:**
```
User: Show me all devices connected to the network
→ Queries UniFi controller for active clients
```

**Check access point status:**
```
User: What's the status of my WiFi access points?
→ Retrieves AP status from UniFi controller
```

**Network statistics:**
```
User: Show network bandwidth usage
→ Gets statistics from UniFi controller
```

## Technical Details

- **Controller:** <UNIFI_IP> (Proxy controller)
- **Authentication:** Username/password (claudemcp)
- **Protocol:** HTTPS (SSL verification disabled)
- **Runtime:** uv + Python
- **Source:** `<DEV_DIR>/mcp/unifi-network-mcp`

## Notes

- Requires UniFi controller accessible at <UNIFI_IP>
- Uses proxy controller type
- MCP server only loads when this skill is invoked
- SSL verification disabled for local homelab use
