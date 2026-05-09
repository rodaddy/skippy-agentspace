# Proxmox SSE Agent - Design Document

**Real-time event streaming and bi-directional control for Proxmox clusters**

## Overview

A lightweight agent service running on the Proxmox primary node that:
1. **Streams events** via Server-Sent Events (SSE) - VM/container state changes, task updates, alerts
2. **Accepts commands** via HTTP POST - Execute operations, queue tasks
3. **Eliminates polling** - Push-based real-time updates instead of constant API queries
4. **Enables automation** - React to events instantly (auto-restart failed containers, alert on issues)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Proxmox Node (<PROXMOX_NODE_IP>) - Primary                     │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ SSE Agent Service (Bun)          :3000           │  │
│  │                                                  │  │
│  │  Event Watchers:                                │  │
│  │  ├─ Proxmox API Poller (tasks, VMs, containers) │  │
│  │  ├─ Log Tailer (/var/log/pve/)                  │  │
│  │  ├─ Cluster Event Monitor                       │  │
│  │  └─ Resource Alert Monitor                      │  │
│  │                                                  │  │
│  │  Endpoints:                                      │  │
│  │  ├─ GET  /events  → SSE stream                  │  │
│  │  ├─ POST /command → Execute operation           │  │
│  │  └─ GET  /status  → Agent health check          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                    SSE Stream │ HTTP Commands
                           ↓
┌─────────────────────────────────────────────────────────┐
│ Your Mac - PAI Skill                                    │
│                                                         │
│  tools/monitor-stream.ts                                │
│  ├─ Connects to SSE endpoint                            │
│  ├─ Receives real-time events                           │
│  ├─ Triggers automated responses                        │
│  └─ Sends commands back to agent                        │
└─────────────────────────────────────────────────────────┘
```

---

## Event Types

The SSE agent streams these event types:

### 1. Task Events
```json
{
  "type": "task",
  "event": "started|running|completed|failed",
  "data": {
    "upid": "UPID:proxmox06:00001234:...",
    "type": "vncproxy|backup|vzdump|qmstart",
    "vmid": 100,
    "node": "proxmox06",
    "user": "root@pam",
    "status": "OK|ERROR",
    "exitstatus": "OK",
    "starttime": 1704672000,
    "endtime": 1704672300
  }
}
```

**Use Cases:**
- Wait for VM start to complete before running commands
- Alert when backup fails
- Show progress bars for long-running operations
- Auto-retry failed tasks

### 2. VM/Container State Changes
```json
{
  "type": "vm_state",
  "event": "started|stopped|paused|crashed",
  "data": {
    "vmid": 100,
    "node": "proxmox06",
    "name": "my-vm",
    "previous_state": "stopped",
    "current_state": "running",
    "uptime": 0,
    "timestamp": "2026-01-07T20:15:00Z"
  }
}
```

**Use Cases:**
- Auto-restart crashed containers
- Alert when production VMs stop unexpectedly
- Track uptime metrics
- Trigger post-startup scripts

### 3. Resource Alerts
```json
{
  "type": "alert",
  "severity": "warning|critical|info",
  "data": {
    "source": "node|vm|container",
    "resource_id": "proxmox06",
    "metric": "memory|cpu|disk",
    "value": 95.2,
    "threshold": 90,
    "message": "Node memory usage critical: 95.2%",
    "timestamp": "2026-01-07T20:15:00Z"
  }
}
```

**Use Cases:**
- Send notifications when resources are critical
- Auto-scale by starting additional containers
- Log performance issues
- Trigger automated cleanup

### 4. Cluster Events
```json
{
  "type": "cluster",
  "event": "node_join|node_leave|quorum_lost|quorum_gained",
  "data": {
    "node": "proxmox02",
    "cluster": "my-cluster",
    "nodes_online": 2,
    "nodes_total": 2,
    "quorum": true
  }
}
```

### 5. Log Events (Container/VM Logs)
```json
{
  "type": "log",
  "source": "container|vm|node",
  "data": {
    "vmid": 101,
    "node": "proxmox06",
    "level": "info|warn|error",
    "message": "systemd[1]: Started MySQL Server",
    "timestamp": "2026-01-07T20:15:00Z"
  }
}
```

**Use Cases:**
- Live log streaming to terminal
- Error detection and alerting
- Audit trail aggregation
- Debug container issues in real-time

---

## Agent Implementation

### File Structure
```
/opt/proxmox-sse-agent/
├── agent.ts              # Main SSE server
├── watchers/
│   ├── task-watcher.ts   # Monitor Proxmox tasks
│   ├── vm-watcher.ts     # Monitor VM state changes
│   ├── log-watcher.ts    # Tail logs
│   └── alert-watcher.ts  # Resource monitoring
├── config.json           # Agent configuration
├── package.json
└── proxmox-agent.service # Systemd unit
```

### Main Agent (agent.ts)
```typescript
#!/usr/bin/env bun

import { EventEmitter } from 'events';

const events = new EventEmitter();
const clients = new Set<ReadableStreamDefaultController>();

// SSE endpoint - streams events to clients
Bun.serve({
  port: 3000,

  async fetch(req) {
    const url = new URL(req.url);

    // SSE event stream
    if (url.pathname === '/events') {
      const stream = new ReadableStream({
        start(controller) {
          clients.add(controller);

          // Send initial connection event
          controller.enqueue(`data: ${JSON.stringify({
            type: 'connected',
            agent_version: '1.0.0',
            node: 'proxmox06'
          })}\n\n`);

          // Forward all events to this client
          const eventHandler = (event: any) => {
            try {
              controller.enqueue(`data: ${JSON.stringify(event)}\n\n`);
            } catch (err) {
              clients.delete(controller);
            }
          };

          events.on('event', eventHandler);

          // Cleanup on disconnect
          req.signal.addEventListener('abort', () => {
            events.off('event', eventHandler);
            clients.delete(controller);
          });
        }
      });

      return new Response(stream, {
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      });
    }

    // Command endpoint - execute operations
    if (url.pathname === '/command' && req.method === 'POST') {
      const body = await req.json();
      const result = await handleCommand(body);
      return Response.json(result);
    }

    // Health check
    if (url.pathname === '/status') {
      return Response.json({
        status: 'healthy',
        clients: clients.size,
        uptime: process.uptime()
      });
    }

    return new Response('Not Found', { status: 404 });
  }
});

// Emit events to all connected clients
export function emitEvent(event: any) {
  events.emit('event', {
    ...event,
    timestamp: new Date().toISOString()
  });
}

console.log('✅ Proxmox SSE Agent running on http://localhost:3000');
```

### Task Watcher
```typescript
// watchers/task-watcher.ts
import { exec } from 'child_process';
import { emitEvent } from '../agent.js';

const knownTasks = new Map();

export function startTaskWatcher() {
  setInterval(async () => {
    // Query Proxmox task queue
    exec('pvesh get /cluster/tasks --limit 100', (err, stdout) => {
      if (err) return;

      const tasks = JSON.parse(stdout);

      for (const task of tasks) {
        const key = task.upid;
        const previous = knownTasks.get(key);

        // New task
        if (!previous) {
          emitEvent({
            type: 'task',
            event: 'started',
            data: task
          });
        }
        // Task state changed
        else if (previous.status !== task.status) {
          emitEvent({
            type: 'task',
            event: task.status === 'OK' ? 'completed' : 'failed',
            data: task
          });
        }

        knownTasks.set(key, task);
      }
    });
  }, 2000); // Poll every 2 seconds
}
```

### VM State Watcher
```typescript
// watchers/vm-watcher.ts
import { exec } from 'child_process';
import { emitEvent } from '../agent.js';

const vmStates = new Map();

export function startVMWatcher() {
  setInterval(() => {
    exec('pvesh get /cluster/resources --type vm', (err, stdout) => {
      if (err) return;

      const vms = JSON.parse(stdout);

      for (const vm of vms) {
        const key = `${vm.node}:${vm.vmid}`;
        const previous = vmStates.get(key);

        if (previous && previous.status !== vm.status) {
          emitEvent({
            type: 'vm_state',
            event: vm.status,
            data: {
              vmid: vm.vmid,
              node: vm.node,
              name: vm.name,
              previous_state: previous.status,
              current_state: vm.status,
              uptime: vm.uptime
            }
          });
        }

        vmStates.set(key, vm);
      }
    });
  }, 3000); // Poll every 3 seconds
}
```

### Systemd Service
```ini
# /etc/systemd/system/proxmox-agent.service
[Unit]
Description=Proxmox SSE Event Agent
After=network.target pve-cluster.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/proxmox-sse-agent
ExecStart=/usr/local/bin/bun run agent.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

## Skill Integration

### Monitoring Tool (tools/monitor-stream.ts)
```typescript
#!/usr/bin/env bun

import { createLogger } from '../lib/logger.js';
import { loadConfig } from '../lib/config-loader.js';

async function main() {
  const logger = createLogger();
  const config = await loadConfig();

  // Find primary node
  const primaryNode = config.cluster.nodes.find(n =>
    n.roles.includes('primary') && n.enabled
  );

  if (!primaryNode) {
    logger.error('No primary node configured');
    process.exit(1);
  }

  const sseUrl = `http://${primaryNode.hostname}:3000/events`;
  logger.info(`📡 Connecting to SSE agent at ${sseUrl}...`);

  // Connect to SSE stream
  const response = await fetch(sseUrl);
  const reader = response.body?.getReader();
  const decoder = new TextDecoder();

  logger.success('✅ Connected! Streaming events...\n');

  while (true) {
    const { done, value } = await reader!.read();
    if (done) break;

    const chunk = decoder.decode(value);
    const lines = chunk.split('\n');

    for (const line of lines) {
      if (!line.startsWith('data:')) continue;

      const eventData = JSON.parse(line.slice(5));
      handleEvent(eventData, logger);
    }
  }
}

function handleEvent(event: any, logger: any) {
  switch (event.type) {
    case 'connected':
      logger.info(`🔗 Agent version: ${event.agent_version}`);
      break;

    case 'task':
      if (event.event === 'failed') {
        logger.error(`❌ Task failed: ${event.data.type} on VM ${event.data.vmid}`);
        logger.audit('task-failed', event.data);
      } else if (event.event === 'completed') {
        logger.success(`✅ Task completed: ${event.data.type} on VM ${event.data.vmid}`);
      }
      break;

    case 'vm_state':
      logger.info(`🖥️  VM ${event.data.vmid} (${event.data.name}): ${event.data.previous_state} → ${event.data.current_state}`);
      logger.audit('vm-state-change', event.data);

      // Auto-restart crashed VMs
      if (event.data.current_state === 'stopped' && event.data.previous_state === 'running') {
        logger.warn(`⚠️  VM ${event.data.vmid} stopped unexpectedly!`);
        // Could trigger auto-restart here
      }
      break;

    case 'alert':
      const icon = event.severity === 'critical' ? '🚨' : '⚠️';
      logger.warn(`${icon} ${event.data.message}`);
      logger.audit('resource-alert', event.data);
      break;

    case 'log':
      if (event.data.level === 'error') {
        logger.error(`📋 [${event.data.vmid}] ${event.data.message}`);
      }
      break;

    default:
      logger.debug(`Event: ${event.type}`);
  }
}

main();
```

### Usage Examples
```bash
# Stream all events
bun run tools/monitor-stream.ts

# Stream with automated responses
bun run tools/monitor-stream.ts --auto-restart

# Stream only errors
bun run tools/monitor-stream.ts --filter=error

# Log everything to file
bun run tools/monitor-stream.ts >> events.log
```

---

## Advanced Features

### 1. Bi-Directional Commands
```typescript
// Send command to agent
const response = await fetch('http://<PROXMOX_NODE_IP>:3000/command', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    action: 'vm-start',
    vmid: 100
  })
});

// Agent executes and returns result
const result = await response.json();
// { taskId: 'UPID:...', status: 'started' }
```

### 2. Event Filtering
```typescript
// Agent supports query params for filtering
GET /events?type=task&severity=error&vmid=100
```

### 3. Webhook Integration
```typescript
// Agent can forward events to webhooks
{
  "webhooks": [
    {
      "url": "https://discord.com/api/webhooks/...",
      "events": ["task.failed", "alert.critical"]
    }
  ]
}
```

### 4. Historical Events
```typescript
// Agent stores last N events
GET /events/history?limit=100&since=2026-01-07T00:00:00Z
```

---

## Deployment Steps

```bash
# 1. Install on Proxmox node
ssh root@<PROXMOX_NODE_IP>
mkdir /opt/proxmox-sse-agent
cd /opt/proxmox-sse-agent

# 2. Copy agent files
# (Upload agent.ts, watchers/, package.json)

# 3. Install dependencies
bun install

# 4. Create systemd service
cp proxmox-agent.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable proxmox-agent
systemctl start proxmox-agent

# 5. Test
curl http://localhost:3000/status

# 6. Use from skill
bun run tools/monitor-stream.ts
```

---

## Benefits

✅ **Real-Time** - No more polling, events arrive instantly
✅ **Low Overhead** - Single persistent connection vs. constant API queries
✅ **Automation** - React to events automatically (auto-restart, alerts, etc.)
✅ **Debugging** - Live log streaming without SSH
✅ **Monitoring** - Track task progress in real-time
✅ **Scalable** - Multiple clients can connect to same agent
✅ **Audit Trail** - All events logged automatically

---

## Next Steps

1. Build basic SSE agent with task/VM watchers
2. Deploy to proxmox06 as systemd service
3. Create `monitor-stream.ts` tool
4. Test with live events
5. Add automated response capabilities
6. Expand to log streaming, resource alerts
7. Add webhook forwarding for Discord/Slack

**Want me to build this?** It's a separate mini-project but would integrate perfectly with the skill!
