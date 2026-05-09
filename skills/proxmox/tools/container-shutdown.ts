#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();
  const args = process.argv.slice(2).filter(a => !a.startsWith('-'));

  if (args.length < 1) {
    console.error('Usage: container-shutdown <vmid> [--debug] [--quiet]');
    console.error('Example: container-shutdown 101');
    console.error('\nNote: Graceful shutdown. Use container-stop for forced stop.');
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

    logger.info(`🔍 Locating Container ${vmid}...`);
    const location = await discovery.findContainer(vmid);

    logger.info(`📍 Found on node: ${location.node}`);
    logger.info(`🛑 Shutting down Container ${vmid} (graceful)...`);

    const taskId = await apiClient.shutdownContainer(location.node, vmid);

    logger.audit('container-shutdown', {
      vmid,
      node: location.node,
      taskId,
      status: 'success'
    });

    logger.success(`Shutdown command sent (Task: ${taskId})`);
    logger.info(`\nContainer ${vmid} is shutting down gracefully...`);

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

main();
