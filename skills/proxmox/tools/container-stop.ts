#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();
  const args = process.argv.slice(2).filter(a => !a.startsWith('-'));

  if (args.length < 1) {
    console.error('Usage: container-stop <vmid> [--debug] [--quiet]');
    console.error('Example: container-stop 101');
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
    logger.info(`⏹️  Stopping Container ${vmid} (forced)...`);

    const taskId = await apiClient.stopContainer(location.node, vmid);

    logger.audit('container-stop', {
      vmid,
      node: location.node,
      taskId,
      status: 'success'
    });

    logger.success(`Stop command sent (Task: ${taskId})`);
    logger.info(`\nContainer ${vmid} is stopping...`);

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

main();
