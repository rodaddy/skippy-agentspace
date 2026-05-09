# Proxmox Skill - Expansion Guide

Quick reference for adding new tools to the Proxmox skill.

## Architecture Overview

The skill uses a **layered architecture** that makes adding new tools trivial:

```
Tools Layer (tools/*.ts)          ← User-facing commands
    ↓
Discovery Layer (node-discovery.ts) ← Find resources across cluster
    ↓
API Layer (api-client.ts)         ← Proxmox API wrapper
SSH Layer (ssh-client.ts)         ← Direct SSH execution
    ↓
Config Layer (config-loader.ts)   ← Configuration + credentials
```

**Key Design Principles:**
1. **Zero Context Cost**: Each tool is a standalone executable
2. **Audit Trail**: All operations logged to `logs/audit.log`
3. **Debug Mode**: `--debug` flag for troubleshooting
4. **Cluster-Aware**: Auto-discovery across all nodes

---

## Adding a New Tool (3 Steps)

### Step 1: Add API Method (if needed)

**File**: `lib/api-client.ts`

```typescript
async newOperation(nodeName: string, vmid: number, params?: any): Promise<string> {
  const client = this.getClient(nodeName);
  const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/operation`, params);
  return data.data; // Usually returns task ID
}
```

**Common API Patterns:**
- GET for queries: `client.get('/path')`
- POST for actions: `client.post('/path', params)`
- PUT for updates: `client.put('/path', params)`
- DELETE for removals: `client.delete('/path')`

### Step 2: Create Tool File

**File**: `tools/new-tool.ts`

```typescript
#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();
  const args = process.argv.slice(2).filter(a => !a.startsWith('-'));

  if (args.length < 1) {
    console.error('Usage: new-tool <vmid> [--debug] [--quiet]');
    console.error('Example: new-tool 100');
    process.exit(1);
  }

  const vmid = parseInt(args[0]);

  if (isNaN(vmid)) {
    logger.error(`Invalid VMID: ${args[0]}`);
    process.exit(1);
  }

  try {
    logger.debug('Loading configuration...');
    const config = await loadConfig();
    const discovery = new NodeDiscovery(config);
    const apiClient = new ProxmoxAPIClient(config);

    logger.info(`🔍 Locating VM ${vmid}...`);
    const location = await discovery.findVM(vmid); // or findContainer()

    logger.info(`📍 Found on node: ${location.node}`);
    logger.info(`⚡ Performing operation on VM ${vmid}...`);

    const taskId = await apiClient.newOperation(location.node, vmid);

    // Audit trail
    logger.audit('new-tool', {
      vmid,
      node: location.node,
      taskId,
      status: 'success'
    });

    logger.success(`Operation complete (Task: ${taskId})`);

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

main();
```

### Step 3: Make Executable

```bash
chmod +x tools/new-tool.ts
```

Done! Your tool is ready to use.

---

## Tool Templates

### Simple Query Tool (List/Status)

```typescript
#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();

  try {
    const config = await loadConfig();
    const apiClient = new ProxmoxAPIClient(config);

    const results = await apiClient.listSomething('node1');

    results.forEach(item => {
      console.log(`${item.id}: ${item.name}`);
    });

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

main();
```

### Control Tool (Start/Stop/Reboot)

See `tools/vm-start.ts` or `tools/container-start.ts` for full template.

Key pattern:
1. Parse args
2. Find resource with `discovery.findVM()` or `discovery.findContainer()`
3. Call API method
4. Log audit trail
5. Show success message

### Configuration Tool (Get/Set Config)

```typescript
// Get config
const config = await apiClient.getVMConfig(location.node, vmid);
console.log(JSON.stringify(config, null, 2));

// Set config
await apiClient.setVMConfig(location.node, vmid, {
  cores: 4,
  memory: 8192
});
```

### Snapshot Tool

```typescript
// List snapshots
const snapshots = await apiClient.listSnapshots(location.node, vmid);

// Create snapshot
const taskId = await apiClient.createSnapshot(location.node, vmid, {
  snapname: 'backup-2026-01-07',
  description: 'Pre-update snapshot'
});

// Rollback snapshot
await apiClient.rollbackSnapshot(location.node, vmid, 'backup-2026-01-07');
```

---

## Common API Endpoints

### VM Operations
- `GET /nodes/{node}/qemu` - List VMs
- `GET /nodes/{node}/qemu/{vmid}/status/current` - VM status
- `POST /nodes/{node}/qemu/{vmid}/status/{start|stop|shutdown|reboot}` - Control
- `GET /nodes/{node}/qemu/{vmid}/config` - Get config
- `POST /nodes/{node}/qemu/{vmid}/config` - Set config
- `POST /nodes/{node}/qemu/{vmid}/snapshot` - Create snapshot
- `GET /nodes/{node}/qemu/{vmid}/snapshot` - List snapshots

### Container Operations
- `GET /nodes/{node}/lxc` - List containers
- `GET /nodes/{node}/lxc/{vmid}/status/current` - Container status
- `POST /nodes/{node}/lxc/{vmid}/status/{start|stop|shutdown|reboot}` - Control
- `GET /nodes/{node}/lxc/{vmid}/config` - Get config

### Storage Operations
- `GET /storage` - List storage pools
- `GET /nodes/{node}/storage/{storage}/status` - Pool status
- `GET /nodes/{node}/storage/{storage}/content` - List contents

### Cluster Operations
- `GET /cluster/status` - Cluster health
- `GET /cluster/resources` - All resources
- `GET /cluster/tasks` - Running tasks
- `GET /cluster/backup` - Backup jobs

---

## Adding SSH-Based Tools

For operations without API support (like `pct exec` for containers):

```typescript
import { SSHClient } from '../lib/ssh-client.js';

const ssh = new SSHClient(config);

// Buffered execution
const result = await ssh.containerExec(vmid, 'uptime');
console.log(result.stdout);

// Streaming execution
await ssh.containerExecStream(vmid, 'apt update', (data, isError) => {
  if (isError) {
    process.stderr.write(data);
  } else {
    process.stdout.write(data);
  }
});
```

---

## Bulk Tool Generation

For repetitive tools (e.g., all container controls), create a generator script:

```typescript
const operations = [
  { name: 'pause', icon: '⏸️', method: 'pauseContainer' },
  { name: 'resume', icon: '▶️', method: 'resumeContainer' },
];

for (const op of operations) {
  const content = generateToolTemplate(op);
  writeFileSync(`tools/container-${op.name}.ts`, content, { mode: 0o755 });
}
```

---

## Testing New Tools

```bash
# Test with debug output
bun run tools/new-tool.ts 100 --debug

# Test with quiet mode
bun run tools/new-tool.ts 100 --quiet

# Check audit log
tail -f logs/audit.log
```

---

## Documentation Updates

When adding tools, update:

1. **TOOL_MANIFEST.md** - Change status from ⏳ to ✅
2. **README.md** - Add to "Available Commands" section if user-facing
3. **SKILL.md** - Add to API reference if significant

---

## Examples of Each Tool Type

**Query Tool**: `tools/vm-list.ts`, `tools/container-list.ts`
**Control Tool**: `tools/vm-start.ts`, `tools/container-stop.ts`
**Exec Tool**: `tools/container-exec.ts`
**Status Tool**: `tools/cluster-status.ts`

Copy these as templates for new tools!

---

## Quick Reference: Adding 10 Tools in 10 Minutes

1. Identify API endpoint from Proxmox docs
2. Add method to `api-client.ts`
3. Copy existing tool (e.g., `vm-start.ts`)
4. Search/replace operation name
5. Update API method call
6. Update audit operation name
7. `chmod +x`
8. Test with `--debug`
9. Update manifest
10. Done!

**The architecture is designed for rapid expansion - adding new tools is intentionally trivial.**
