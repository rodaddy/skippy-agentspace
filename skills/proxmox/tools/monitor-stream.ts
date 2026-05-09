#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();

  try {
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

    if (!response.ok) {
      logger.error(`Failed to connect: ${response.status} ${response.statusText}`);
      logger.info('\n💡 Make sure the SSE agent is installed and running on the Proxmox node:');
      logger.info(`   ssh root@${primaryNode.hostname}`);
      logger.info(`   systemctl status proxmox-sse-agent`);
      process.exit(1);
    }

    const reader = response.body?.getReader();
    if (!reader) {
      logger.error('No response body available');
      process.exit(1);
    }

    const decoder = new TextDecoder();

    logger.success('✅ Connected! Streaming events...\n');
    logger.info('Press Ctrl+C to stop\n');

    // Read stream
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        logger.warn('Stream ended');
        break;
      }

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (!line.startsWith('data:')) continue;

        try {
          const eventData = JSON.parse(line.slice(5).trim());
          handleEvent(eventData, logger);
        } catch (err) {
          logger.debug(`Failed to parse event: ${line}`);
        }
      }
    }

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

function handleEvent(event: any, logger: any) {
  const timestamp = new Date(event.timestamp).toLocaleTimeString();

  switch (event.type) {
    case 'connected':
      logger.success(`🔗 Connected to agent v${event.data.agent_version} on ${event.data.node}`);
      logger.info(`   Watchers: ${event.data.watchers.join(', ')}`);
      console.log('');
      break;

    case 'task':
      handleTaskEvent(event, timestamp, logger);
      break;

    case 'vm_state':
      handleVMStateEvent(event, timestamp, logger);
      break;

    case 'alert':
      handleAlertEvent(event, timestamp, logger);
      break;

    case 'log':
      handleLogEvent(event, timestamp, logger);
      break;

    default:
      logger.debug(`[${timestamp}] Unknown event type: ${event.type}`);
  }
}

function handleTaskEvent(event: any, timestamp: string, logger: any) {
  const { data } = event;

  switch (event.event) {
    case 'started':
      logger.info(`[${timestamp}] 🚀 Task started: ${data.type} on VM ${data.vmid} (${data.node})`);
      logger.audit('task-started', data);
      break;

    case 'completed':
      logger.success(`[${timestamp}] ✅ Task completed: ${data.type} on VM ${data.vmid}`);
      logger.audit('task-completed', data);
      break;

    case 'failed':
      logger.error(`[${timestamp}] ❌ Task failed: ${data.type} on VM ${data.vmid}`);
      logger.error(`   Exit status: ${data.exitstatus}`);
      logger.audit('task-failed', data);
      break;
  }
}

function handleVMStateEvent(event: any, timestamp: string, logger: any) {
  const { data } = event;
  const icon = getStateIcon(data.current_state);

  logger.info(
    `[${timestamp}] ${icon} ${data.type.toUpperCase()} ${data.vmid} (${data.name || 'unnamed'}): ` +
    `${data.previous_state} → ${data.current_state}`
  );

  logger.audit('vm-state-change', data);

  // Alert on unexpected stops
  if (data.previous_state === 'running' && data.current_state === 'stopped') {
    logger.warn(`   ⚠️  VM stopped unexpectedly!`);
  }
}

function handleAlertEvent(event: any, timestamp: string, logger: any) {
  const { data, severity } = event;
  const icon = severity === 'critical' ? '🚨' : severity === 'warning' ? '⚠️' : 'ℹ️';

  logger.warn(`[${timestamp}] ${icon} ${data.message}`);
  logger.audit('alert', { severity, ...data });
}

function handleLogEvent(event: any, timestamp: string, logger: any) {
  const { data } = event;
  const icon = data.level === 'error' ? '❌' : data.level === 'warn' ? '⚠️' : '📋';

  if (data.level === 'error') {
    logger.error(`[${timestamp}] ${icon} [${data.source}:${data.vmid}] ${data.message}`);
  } else {
    logger.info(`[${timestamp}] ${icon} [${data.source}:${data.vmid}] ${data.message}`);
  }
}

function getStateIcon(state: string): string {
  const icons: Record<string, string> = {
    'running': '✅',
    'stopped': '⏹️',
    'paused': '⏸️',
    'crashed': '💥',
    'unknown': '❓'
  };

  return icons[state] || '❓';
}

main();
