#!/usr/bin/env bun

/**
 * Proxmox SSE Agent
 * Real-time event streaming for Proxmox VE clusters
 */

import { spawn } from 'child_process';

interface ProxmoxEvent {
  type: string;
  event: string;
  data: any;
  timestamp: string;
}

// Connected SSE clients
const clients = new Set<ReadableStreamDefaultController>();

// Emit event to all connected clients
function emitEvent(event: Omit<ProxmoxEvent, 'timestamp'>) {
  const fullEvent: ProxmoxEvent = {
    ...event,
    timestamp: new Date().toISOString()
  };

  const message = `data: ${JSON.stringify(fullEvent)}\n\n`;

  for (const client of clients) {
    try {
      client.enqueue(message);
    } catch (err) {
      // Client disconnected, will be cleaned up
      clients.delete(client);
    }
  }

  // Also log to console for debugging
  console.log(`[${fullEvent.timestamp}] ${fullEvent.type}.${fullEvent.event}:`, fullEvent.data);
}

// Watch Proxmox tasks
let lastTasks = new Map<string, any>();

function watchTasks() {
  setInterval(() => {
    const proc = spawn('pvesh', ['get', '/cluster/tasks', '--limit', '50', '--output-format', 'json']);
    let output = '';

    proc.stdout.on('data', (data) => {
      output += data.toString();
    });

    proc.on('close', (code) => {
      if (code !== 0) return;

      try {
        const tasks = JSON.parse(output);

        for (const task of tasks) {
          const key = task.upid;
          const prev = lastTasks.get(key);

          // New task
          if (!prev) {
            emitEvent({
              type: 'task',
              event: 'started',
              data: {
                upid: task.upid,
                type: task.type,
                vmid: task.id,
                node: task.node,
                user: task.user,
                status: task.status
              }
            });
          }
          // Task completed/failed
          else if (prev.status !== task.status && task.status) {
            emitEvent({
              type: 'task',
              event: task.status === 'OK' ? 'completed' : 'failed',
              data: {
                upid: task.upid,
                type: task.type,
                vmid: task.id,
                node: task.node,
                status: task.status,
                exitstatus: task.exitstatus
              }
            });
          }

          lastTasks.set(key, task);
        }

        // Cleanup old tasks (keep last 100)
        if (lastTasks.size > 100) {
          const keys = Array.from(lastTasks.keys());
          for (let i = 0; i < keys.length - 100; i++) {
            lastTasks.delete(keys[i]);
          }
        }
      } catch (err) {
        console.error('Error parsing tasks:', err);
      }
    });
  }, 3000); // Check every 3 seconds
}

// Watch VM/Container states
let lastStates = new Map<string, string>();

function watchVMStates() {
  setInterval(() => {
    const proc = spawn('pvesh', ['get', '/cluster/resources', '--type', 'vm', '--output-format', 'json']);
    let output = '';

    proc.stdout.on('data', (data) => {
      output += data.toString();
    });

    proc.on('close', (code) => {
      if (code !== 0) return;

      try {
        const vms = JSON.parse(output);

        for (const vm of vms) {
          const key = `${vm.node}:${vm.vmid}`;
          const prev = lastStates.get(key);

          if (prev && prev !== vm.status) {
            emitEvent({
              type: 'vm_state',
              event: vm.status,
              data: {
                vmid: vm.vmid,
                node: vm.node,
                name: vm.name,
                type: vm.type, // qemu or lxc
                previous_state: prev,
                current_state: vm.status,
                uptime: vm.uptime
              }
            });
          }

          lastStates.set(key, vm.status);
        }
      } catch (err) {
        console.error('Error parsing VM states:', err);
      }
    });
  }, 5000); // Check every 5 seconds
}

// Start watchers
console.log('🔍 Starting event watchers...');
watchTasks();
watchVMStates();
console.log('✅ Watchers started');

// HTTP Server
const server = Bun.serve({
  port: 3000,
  hostname: '0.0.0.0',

  async fetch(req) {
    const url = new URL(req.url);

    // SSE Event Stream
    if (url.pathname === '/events') {
      const stream = new ReadableStream({
        start(controller) {
          // Add to clients
          clients.add(controller);

          // Send connection event
          const connectEvent = {
            type: 'connected',
            event: 'agent_ready',
            data: {
              agent_version: '1.0.0',
              node: process.env.HOSTNAME || 'unknown',
              watchers: ['tasks', 'vm_states']
            },
            timestamp: new Date().toISOString()
          };

          controller.enqueue(`data: ${JSON.stringify(connectEvent)}\n\n`);

          console.log(`✅ Client connected (total: ${clients.size})`);

          // Cleanup on disconnect
          req.signal.addEventListener('abort', () => {
            clients.delete(controller);
            console.log(`❌ Client disconnected (total: ${clients.size})`);
          });
        }
      });

      return new Response(stream, {
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    // Health Check
    if (url.pathname === '/status') {
      return Response.json({
        status: 'healthy',
        version: '1.0.0',
        node: process.env.HOSTNAME || 'unknown',
        uptime: process.uptime(),
        clients: clients.size,
        watchers: {
          tasks: lastTasks.size,
          states: lastStates.size
        }
      });
    }

    // Command Execution (future feature)
    if (url.pathname === '/command' && req.method === 'POST') {
      const body = await req.json();

      return Response.json({
        error: 'Command execution not yet implemented',
        received: body
      }, { status: 501 });
    }

    // Root
    return new Response(`Proxmox SSE Agent v1.0.0

Endpoints:
  GET  /events  - SSE event stream
  GET  /status  - Health check
  POST /command - Execute command (TBD)

Connected clients: ${clients.size}
Uptime: ${Math.floor(process.uptime())}s
`, {
      headers: { 'Content-Type': 'text/plain' }
    });
  },

  error(error) {
    console.error('Server error:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
});

console.log(`
🚀 Proxmox SSE Agent Running

  Listening: http://0.0.0.0:${server.port}

  Endpoints:
    - GET  /events  → SSE event stream
    - GET  /status  → Health check
    - POST /command → Execute commands

  Press Ctrl+C to stop
`);

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n⏹️  Shutting down gracefully...');

  // Close all client connections
  for (const client of clients) {
    try {
      client.close();
    } catch (err) {
      // Ignore errors during shutdown
    }
  }

  server.stop();
  process.exit(0);
});
