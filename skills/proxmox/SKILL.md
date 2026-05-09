---
name: proxmox
description: Proxmox VE cluster management via LiteLLM MCP gateway. List/start/stop VMs and containers, manage snapshots, backups, storage. Zero context cost until invoked.
---

# Proxmox Skill

Manage Proxmox VE cluster through LiteLLM's MCP REST gateway. The proxmox-plus MCP server runs on LXC 215 and is registered in LiteLLM — this skill calls it via REST so no MCP tool definitions load into context.

## How to call

All calls go through LiteLLM's MCP REST endpoint. Use the helper script:

    ~/.config/pai/Skills/proxmox/pve-call <tool_name> [json_args]

Examples:

    ~/.config/pai/Skills/proxmox/pve-call get_nodes
    ~/.config/pai/Skills/proxmox/pve-call get_containers '{"payload":{}}'
    ~/.config/pai/Skills/proxmox/pve-call get_containers '{"payload":{"node":"proxmox01"}}'
    ~/.config/pai/Skills/proxmox/pve-call start_container '{"selector":"215"}'
    ~/.config/pai/Skills/proxmox/pve-call get_node_status '{"node":"proxmox01"}'
    ~/.config/pai/Skills/proxmox/pve-call get_cluster_status

## Available tools

### Read operations
| Tool | Args | Description |
|------|------|-------------|
| get_nodes | (none) | List all cluster nodes with status and resources |
| get_node_status | node | Detailed status for a specific node |
| get_vms | (none) | List all VMs across cluster |
| get_containers | node (optional) | List LXC containers with live stats |
| get_storage | (none) | List storage pools |
| get_cluster_status | (none) | Overall cluster health |
| list_snapshots | node, vmid, vm_type | List snapshots for a VM/CT |
| list_backups | node, storage, vmid (all optional) | List available backups |
| list_isos | node, storage (optional) | List ISO images |
| list_templates | node, storage (optional) | List OS templates |

### Container operations
| Tool | Args | Description |
|------|------|-------------|
| start_container | selector | Start containers (selector: '123', 'pve1:123', 'name') |
| stop_container | selector, graceful, timeout_seconds | Stop containers |
| restart_container | selector | Restart containers |
| create_container | node, vmid, ostemplate, hostname, cores, memory, ... | Create new LXC |
| delete_container | selector, force | Delete container |
| update_container_resources | selector, cores, memory, swap, disk_gb | Resize container |

### VM operations
| Tool | Args | Description |
|------|------|-------------|
| start_vm | node, vmid | Start a VM |
| stop_vm | node, vmid | Force stop a VM |
| shutdown_vm | node, vmid | Graceful shutdown |
| reset_vm | node, vmid | Reset (restart) a VM |
| create_vm | node, vmid, name, cpus, memory, disk_size | Create new VM |
| delete_vm | node, vmid, force | Delete a VM |
| execute_vm_command | node, vmid, command | Run command via QEMU agent |

### Snapshot operations
| Tool | Args | Description |
|------|------|-------------|
| create_snapshot | node, vmid, snapname, description, vmstate, vm_type | Create snapshot |
| delete_snapshot | node, vmid, snapname, vm_type | Delete snapshot |
| rollback_snapshot | node, vmid, snapname, vm_type | Rollback to snapshot |

### Backup operations
| Tool | Args | Description |
|------|------|-------------|
| create_backup | node, vmid, storage, compress, mode, notes | Create backup |
| restore_backup | node, archive, vmid, storage, unique | Restore from backup |
| delete_backup | node, storage, volid | Delete a backup |

### ISO operations
| Tool | Args | Description |
|------|------|-------------|
| download_iso | node, storage, url, filename, checksum | Download ISO |
| delete_iso | node, storage, filename | Delete ISO/template |

## Architecture

    /proxmox skill → pve-call script → LiteLLM REST gateway → proxmox-plus MCP (LXC 215)

- LiteLLM: <LITELLM_IP>:4000
- Proxmox MCP: LXC 215 (<YOUR_IP>:8000)
- Server ID: b9545520-09a2-43d2-8bc4-c754dbeb3abb
- No credentials needed — LiteLLM API key is in the helper script, Proxmox auth is in the MCP server config
- NOTE: get_containers requires a "payload" wrapper: '{"payload":{}}' or '{"payload":{"node":"proxmox01"}}'

## Fallback

If LiteLLM or the MCP server is down, SSH to a Proxmox node directly:

    ssh root@<PROXMOX_NODE_IP>   # proxmox01
    ssh root@<PROXMOX_NODE_IP>   # proxmox02

From there use `pvesh`, `pct`, `qm`, and other Proxmox CLI tools natively.
