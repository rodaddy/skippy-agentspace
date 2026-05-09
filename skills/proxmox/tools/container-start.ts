#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();
  const args = process.argv.slice(2).filter(a => !a.startsWith('-'));

  if (args.length < 1) {
    console.error('Usage: container-start <vmid> [--debug] [--quiet]');
    console.error('Example: container-start 101');
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
    logger.debug(`Querying all enabled nodes for Container ${vmid}`);
    const location = await discovery.findContainer(vmid);

    logger.debug(`Container ${vmid} found on ${location.node} (${location.hostname})`);
    logger.info(`📍 Found on node: ${location.node}`);
    logger.info(`🚀 Starting Container ${vmid}...`);

    logger.debug(`Sending start command via API to ${location.node}`);
    const taskId = await apiClient.startContainer(location.node, vmid);
    logger.debug(`API returned task ID: ${taskId}`);

    logger.audit('container-start', {
      vmid,
      node: location.node,
      taskId,
      status: 'success'
    });

    logger.success(`Start command sent (Task: ${taskId})`);
    logger.info(`\nContainer ${vmid} is starting...`);

  } catch (error) {
    logger.error(`Error: ${error}`);
    process.exit(1);
  }
}

main();
