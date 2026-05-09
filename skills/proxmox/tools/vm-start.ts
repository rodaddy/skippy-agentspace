#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();
  const args = process.argv.slice(2).filter(a => !a.startsWith('-'));

  if (args.length < 1) {
    console.error('Usage: vm-start <vmid> [--debug] [--quiet]');
    console.error('Example: vm-start 100');
    console.error('\nFlags:');
    console.error('  --debug, -d    Show detailed debug output');
    console.error('  --quiet, -q    Minimal output (errors only)');
    process.exit(1);
  }

  const vmid = parseInt(args[0]);

  if (isNaN(vmid)) {
    logger.error(`Invalid VMID: ${args[0]}`);
    process.exit(1);
  }

  try {
    logger.debug(`Loading configuration...`);
    const config = await loadConfig();
    const discovery = new NodeDiscovery(config);
    const apiClient = new ProxmoxAPIClient(config);

    logger.info(`🔍 Locating VM ${vmid}...`);
    logger.debug(`Querying all enabled nodes for VM ${vmid}`);
    const location = await discovery.findVM(vmid);

    if (!location) {
      logger.error(`VM ${vmid} not found on any node`);
      process.exit(1);
    }

    logger.debug(`VM ${vmid} found on ${location.node} (${location.hostname})`);
    logger.info(`📍 Found on node: ${location.node}`);
    logger.info(`🚀 Starting VM ${vmid}...`);

    logger.debug(`Sending start command via API to ${location.node}`);
    const taskId = await apiClient.startVM(location.node, vmid);
    logger.debug(`API returned task ID: ${taskId}`);

    // Audit trail
    logger.audit('vm-start', {
      vmid,
      node: location.node,
      taskId,
      status: 'success'
    });

    logger.success(`Start command sent (Task: ${taskId})`);
    logger.info(`\nVM ${vmid} is starting...`);

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

main();
