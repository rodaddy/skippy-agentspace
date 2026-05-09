# Proxmox Skill - Tool Manifest

Complete inventory of all tools needed for comprehensive Proxmox management.

**Legend:**
- ✅ Implemented and tested
- 🚧 Partially implemented
- ⏳ Planned
- 🔴 Blocked (API limitation, requires workaround)

---

## 1. CLUSTER MANAGEMENT (6 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `cluster-status.ts` | ✅ | P0 | `GET /cluster/status` | Shows overall cluster health |
| `cluster-resources.ts` | ⏳ | P1 | `GET /cluster/resources` | List all resources across cluster |
| `cluster-tasks.ts` | ⏳ | P1 | `GET /cluster/tasks` | Monitor cluster-wide async tasks |
| `task-wait.ts` | ⏳ | P1 | `GET /nodes/{node}/tasks/{upid}/status` | Poll task until completion |
| `cluster-config.ts` | ⏳ | P2 | `GET /cluster/config` | View cluster configuration |
| `cluster-backup-schedule.ts` | ⏳ | P2 | `GET /cluster/backup` | List backup jobs |

---

## 2. NODE MANAGEMENT (8 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `node-list.ts` | ⏳ | P0 | `GET /nodes` | List all nodes |
| `node-status.ts` | ⏳ | P0 | `GET /nodes/{node}/status` | CPU/RAM/Disk/uptime |
| `node-network.ts` | ⏳ | P2 | `GET /nodes/{node}/network` | Network interface config |
| `node-tasks.ts` | ⏳ | P1 | `GET /nodes/{node}/tasks` | Tasks on specific node |
| `node-reboot.ts` | ⏳ | P2 | `POST /nodes/{node}/status` | Reboot node |
| `node-logs.ts` | ⏳ | P2 | `GET /nodes/{node}/syslog` | Retrieve syslog entries |
| `node-subscription.ts` | ⏳ | P3 | `GET /nodes/{node}/subscription` | Check subscription status |
| `node-certificates.ts` | ⏳ | P3 | `GET /nodes/{node}/certificates` | SSL certificate info |

---

## 3. VM LIFECYCLE (10 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `vm-list.ts` | ✅ | P0 | `GET /nodes/{node}/qemu` | List VMs cluster-wide |
| `vm-status.ts` | ⏳ | P0 | `GET /nodes/{node}/qemu/{vmid}/status/current` | Detailed VM status |
| `vm-start.ts` | ✅ | P0 | `POST /nodes/{node}/qemu/{vmid}/status/start` | Start VM |
| `vm-stop.ts` | ✅ | P0 | `POST /nodes/{node}/qemu/{vmid}/status/stop` | Force stop VM |
| `vm-shutdown.ts` | ✅ | P0 | `POST /nodes/{node}/qemu/{vmid}/status/shutdown` | Graceful shutdown |
| `vm-reboot.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/status/reboot` | Reboot VM |
| `vm-pause.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/status/suspend` | Pause VM |
| `vm-resume.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/status/resume` | Resume paused VM |
| `vm-reset.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/status/reset` | Hard reset VM |
| `vm-delete.ts` | ⏳ | P1 | `DELETE /nodes/{node}/qemu/{vmid}` | Delete VM and disks |

---

## 4. VM CONFIGURATION (12 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `vm-config-get.ts` | ⏳ | P1 | `GET /nodes/{node}/qemu/{vmid}/config` | Get full VM config |
| `vm-config-set.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/config` | Update VM config |
| `vm-cpu-set.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/config` | Change CPU cores/sockets |
| `vm-memory-set.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/config` | Change RAM allocation |
| `vm-disk-resize.ts` | ⏳ | P1 | `PUT /nodes/{node}/qemu/{vmid}/resize` | Resize disk |
| `vm-disk-add.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/config` | Add new disk |
| `vm-disk-remove.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/config` | Remove disk |
| `vm-network-add.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/config` | Add network interface |
| `vm-network-remove.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/config` | Remove network interface |
| `vm-boot-order.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/config` | Change boot order |
| `vm-rename.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/config` | Rename VM |
| `vm-description.ts` | ⏳ | P3 | `POST /nodes/{node}/qemu/{vmid}/config` | Set description/notes |

---

## 5. VM ADVANCED (8 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `vm-create.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu` | Create new VM |
| `vm-clone.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/clone` | Clone existing VM |
| `vm-migrate.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/migrate` | Live migrate to another node |
| `vm-agent-exec.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/agent/exec` | Execute command via QEMU agent |
| `vm-agent-status.ts` | ⏳ | P2 | `GET /nodes/{node}/qemu/{vmid}/agent` | Check agent availability |
| `vm-console.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/vncproxy` | Get VNC console URL |
| `vm-send-key.ts` | ⏳ | P3 | `PUT /nodes/{node}/qemu/{vmid}/sendkey` | Send keyboard input |
| `vm-template-convert.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/template` | Convert VM to template |

---

## 6. CONTAINER LIFECYCLE (10 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `container-list.ts` | ✅ | P0 | `GET /nodes/{node}/lxc` | List containers cluster-wide |
| `container-status.ts` | ⏳ | P0 | `GET /nodes/{node}/lxc/{vmid}/status/current` | Detailed container status |
| `container-start.ts` | ⏳ | P0 | `POST /nodes/{node}/lxc/{vmid}/status/start` | Start container |
| `container-stop.ts` | ⏳ | P0 | `POST /nodes/{node}/lxc/{vmid}/status/stop` | Force stop container |
| `container-shutdown.ts` | ⏳ | P0 | `POST /nodes/{node}/lxc/{vmid}/status/shutdown` | Graceful shutdown |
| `container-reboot.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/status/reboot` | Reboot container |
| `container-pause.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/status/suspend` | Pause container |
| `container-resume.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/status/resume` | Resume paused container |
| `container-delete.ts` | ⏳ | P1 | `DELETE /nodes/{node}/lxc/{vmid}` | Delete container |
| `container-exec.ts` | ✅ | P0 | SSH: `pct exec` | Execute command (SSH-based) |

---

## 7. CONTAINER CONFIGURATION (10 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `container-config-get.ts` | ⏳ | P1 | `GET /nodes/{node}/lxc/{vmid}/config` | Get full container config |
| `container-config-set.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/config` | Update container config |
| `container-cpu-set.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/config` | Change CPU cores |
| `container-memory-set.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/config` | Change RAM allocation |
| `container-disk-resize.ts` | ⏳ | P1 | `PUT /nodes/{node}/lxc/{vmid}/resize` | Resize root filesystem |
| `container-network-add.ts` | ⏳ | P2 | `POST /nodes/{node}/lxc/{vmid}/config` | Add network interface |
| `container-network-remove.ts` | ⏳ | P2 | `POST /nodes/{node}/lxc/{vmid}/config` | Remove network interface |
| `container-hostname.ts` | ⏳ | P2 | `POST /nodes/{node}/lxc/{vmid}/config` | Change hostname |
| `container-mount-add.ts` | ⏳ | P2 | `POST /nodes/{node}/lxc/{vmid}/config` | Add mount point |
| `container-mount-remove.ts` | ⏳ | P2 | `POST /nodes/{node}/lxc/{vmid}/config` | Remove mount point |

---

## 8. CONTAINER ADVANCED (6 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `container-create.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc` | Create new container |
| `container-clone.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/clone` | Clone existing container |
| `container-migrate.ts` | ⏳ | P1 | `POST /nodes/{node}/lxc/{vmid}/migrate` | Migrate to another node |
| `container-exec-interactive.ts` | 🔴 | P2 | SSH: `pct enter` | Interactive shell (SSH TTY) |
| `container-file-read.ts` | 🔴 | P2 | SSH: `pct exec` + cat | Read file from container |
| `container-file-write.ts` | 🔴 | P2 | SSH: `pct exec` + tee | Write file to container |

---

## 9. SNAPSHOT MANAGEMENT (6 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `snapshot-list.ts` | ⏳ | P1 | `GET /nodes/{node}/qemu/{vmid}/snapshot` | List VM snapshots |
| `snapshot-list-container.ts` | ⏳ | P1 | `GET /nodes/{node}/lxc/{vmid}/snapshot` | List container snapshots |
| `snapshot-create.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/snapshot` | Create snapshot |
| `snapshot-delete.ts` | ⏳ | P1 | `DELETE /nodes/{node}/qemu/{vmid}/snapshot/{snapname}` | Delete snapshot |
| `snapshot-rollback.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback` | Restore snapshot |
| `snapshot-config.ts` | ⏳ | P2 | `GET /nodes/{node}/qemu/{vmid}/snapshot/{snapname}/config` | View snapshot config |

---

## 10. BACKUP OPERATIONS (8 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `backup-list-jobs.ts` | ⏳ | P1 | `GET /cluster/backup` | List backup jobs |
| `backup-create-job.ts` | ⏳ | P1 | `POST /cluster/backup` | Create backup schedule |
| `backup-delete-job.ts` | ⏳ | P1 | `DELETE /cluster/backup/{id}` | Delete backup job |
| `backup-run.ts` | ⏳ | P1 | `POST /nodes/{node}/vzdump` | Manual backup (async) |
| `backup-list-files.ts` | ⏳ | P1 | `GET /nodes/{node}/storage/{storage}/content` | List backup files |
| `backup-restore.ts` | ⏳ | P1 | `POST /nodes/{node}/qemu` | Restore from backup |
| `backup-delete-file.ts` | ⏳ | P2 | `DELETE /nodes/{node}/storage/{storage}/content/{volume}` | Delete backup file |
| `backup-download.ts` | ⏳ | P2 | `GET /nodes/{node}/storage/{storage}/download-url` | Get download URL |

---

## 11. STORAGE MANAGEMENT (10 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `storage-list.ts` | ⏳ | P0 | `GET /storage` | List all storage pools |
| `storage-status.ts` | ⏳ | P1 | `GET /nodes/{node}/storage/{storage}/status` | Pool usage/health |
| `storage-content.ts` | ⏳ | P1 | `GET /nodes/{node}/storage/{storage}/content` | List contents (images, ISOs) |
| `storage-create.ts` | ⏳ | P2 | `POST /storage` | Add storage pool |
| `storage-delete.ts` | ⏳ | P2 | `DELETE /storage/{storage}` | Remove storage pool |
| `storage-update.ts` | ⏳ | P2 | `PUT /storage/{storage}` | Modify storage config |
| `iso-upload.ts` | ⏳ | P2 | `POST /nodes/{node}/storage/{storage}/upload` | Upload ISO file |
| `iso-list.ts` | ⏳ | P1 | `GET /nodes/{node}/storage/{storage}/content` | List ISO files |
| `iso-delete.ts` | ⏳ | P2 | `DELETE /nodes/{node}/storage/{storage}/content/{volume}` | Delete ISO |
| `template-download.ts` | ⏳ | P2 | `POST /nodes/{node}/aplinfo` | Download CT template |

---

## 12. NETWORK MANAGEMENT (8 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `network-list.ts` | ⏳ | P2 | `GET /nodes/{node}/network` | List network interfaces |
| `network-config.ts` | ⏳ | P2 | `GET /nodes/{node}/network/{iface}` | Get interface config |
| `bridge-create.ts` | ⏳ | P2 | `POST /nodes/{node}/network` | Create network bridge |
| `bridge-delete.ts` | ⏳ | P2 | `DELETE /nodes/{node}/network/{iface}` | Remove bridge |
| `vlan-create.ts` | ⏳ | P2 | `POST /nodes/{node}/network` | Create VLAN interface |
| `vlan-delete.ts` | ⏳ | P2 | `DELETE /nodes/{node}/network/{iface}` | Remove VLAN |
| `dns-set.ts` | ⏳ | P2 | `PUT /nodes/{node}/dns` | Configure DNS servers |
| `network-apply.ts` | ⏳ | P2 | `POST /nodes/{node}/network` | Apply pending network changes |

---

## 13. FIREWALL & SECURITY (7 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `firewall-rules-list.ts` | ⏳ | P2 | `GET /cluster/firewall/rules` | List cluster firewall rules |
| `firewall-rules-vm.ts` | ⏳ | P2 | `GET /nodes/{node}/qemu/{vmid}/firewall/rules` | List VM firewall rules |
| `firewall-rule-add.ts` | ⏳ | P2 | `POST /cluster/firewall/rules` | Add firewall rule |
| `firewall-rule-delete.ts` | ⏳ | P2 | `DELETE /cluster/firewall/rules/{pos}` | Delete rule |
| `firewall-enable.ts` | ⏳ | P2 | `PUT /nodes/{node}/qemu/{vmid}/firewall/options` | Enable VM firewall |
| `firewall-disable.ts` | ⏳ | P2 | `PUT /nodes/{node}/qemu/{vmid}/firewall/options` | Disable VM firewall |
| `security-groups.ts` | ⏳ | P3 | `GET /cluster/firewall/groups` | List security groups |

---

## 14. MONITORING & DIAGNOSTICS (10 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `monitor-resources.ts` | ⏳ | P1 | `GET /cluster/resources` | CPU/RAM/disk cluster-wide |
| `monitor-node-stats.ts` | ⏳ | P1 | `GET /nodes/{node}/rrd` | Node performance history |
| `monitor-vm-stats.ts` | ⏳ | P1 | `GET /nodes/{node}/qemu/{vmid}/rrd` | VM performance history |
| `monitor-container-stats.ts` | ⏳ | P1 | `GET /nodes/{node}/lxc/{vmid}/rrd` | Container performance history |
| `monitor-alerts.ts` | ⏳ | P2 | Custom logic | System alerts and warnings |
| `monitor-events.ts` | ⏳ | P2 | `GET /cluster/log` | Recent cluster events |
| `monitor-summary.ts` | ⏳ | P1 | Multiple endpoints | Overall cluster health |
| `logs-vm.ts` | ⏳ | P2 | `GET /nodes/{node}/qemu/{vmid}/log` | VM console logs |
| `logs-container.ts` | ⏳ | P2 | SSH: `pct exec` | Container syslog |
| `performance-report.ts` | ⏳ | P2 | Multiple endpoints | Comprehensive performance data |

---

## 15. TEMPLATE & ISO MANAGEMENT (6 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `template-list.ts` | ⏳ | P1 | `GET /nodes/{node}/storage/{storage}/content` | List CT templates |
| `template-download-list.ts` | ⏳ | P2 | `GET /nodes/{node}/aplinfo` | Available templates |
| `template-download.ts` | ⏳ | P2 | `POST /nodes/{node}/aplinfo` | Download template |
| `template-delete.ts` | ⏳ | P2 | `DELETE /nodes/{node}/storage/{storage}/content/{volume}` | Remove template |
| `template-from-vm.ts` | ⏳ | P2 | `POST /nodes/{node}/qemu/{vmid}/template` | Convert VM to template |
| `template-from-container.ts` | ⏳ | P2 | `POST /nodes/{node}/lxc/{vmid}/template` | Convert container to template |

---

## 16. HA & REPLICATION (6 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `ha-resources.ts` | ⏳ | P3 | `GET /cluster/ha/resources` | List HA resources |
| `ha-add.ts` | ⏳ | P3 | `POST /cluster/ha/resources` | Add HA to VM/container |
| `ha-remove.ts` | ⏳ | P3 | `DELETE /cluster/ha/resources/{sid}` | Remove HA |
| `ha-status.ts` | ⏳ | P3 | `GET /cluster/ha/status` | HA status overview |
| `replication-list.ts` | ⏳ | P3 | `GET /cluster/replication` | List replication jobs |
| `replication-create.ts` | ⏳ | P3 | `POST /cluster/replication` | Create replication |

---

## 17. USER & PERMISSION MANAGEMENT (7 tools)

| Tool | Status | Priority | API Endpoint | Notes |
|------|--------|----------|--------------|-------|
| `user-list.ts` | ⏳ | P3 | `GET /access/users` | List users |
| `user-create.ts` | ⏳ | P3 | `POST /access/users` | Create user |
| `user-delete.ts` | ⏳ | P3 | `DELETE /access/users/{userid}` | Delete user |
| `role-list.ts` | ⏳ | P3 | `GET /access/roles` | List roles |
| `permission-list.ts` | ⏳ | P3 | `GET /access/acl` | List ACLs |
| `permission-set.ts` | ⏳ | P3 | `PUT /access/acl` | Set permissions |
| `token-create.ts` | ⏳ | P3 | `POST /access/users/{userid}/token/{tokenid}` | Create API token |

---

## Implementation Priority

**Phase 1: Essential Operations (P0)** - 8 tools
- cluster-status ✅
- vm-list ✅
- vm-start ✅
- vm-stop ✅
- vm-shutdown ✅
- container-list ✅
- container-exec ✅
- storage-list

**Phase 2: Core Lifecycle (P1)** - 25 tools
- All basic VM/container control
- Snapshots (create, list, delete, rollback)
- Backup operations
- Task monitoring
- Configuration get/set

**Phase 3: Advanced Features (P2)** - 35 tools
- VM/container creation
- Cloning and migration
- Network management
- Storage advanced
- Monitoring/diagnostics

**Phase 4: Enterprise Features (P3)** - 15+ tools
- HA and replication
- User/permission management
- Advanced security
- Audit and compliance

---

## Current Status

**Implemented**: 7 tools (cluster-status, vm-list, vm-start, vm-stop, vm-shutdown, container-list, container-exec)
**In Progress**: 3 tools (vm-reboot, vm-pause, vm-resume)
**Remaining**: 73+ tools

**Core Libraries Complete**:
- ✅ config-loader.ts
- ✅ api-client.ts (needs extension for all endpoints)
- ✅ ssh-client.ts
- ✅ node-discovery.ts
- ✅ logger.ts (with audit trail)

**Next Steps**:
1. Complete Phase 1 (P0 tools) - 1 remaining
2. Add missing API methods to api-client.ts
3. Build Phase 2 tools systematically
4. Add container lifecycle API methods
5. Build snapshot management tools
