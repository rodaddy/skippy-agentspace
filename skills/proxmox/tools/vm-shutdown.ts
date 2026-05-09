#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.error('Usage: vm-shutdown <vmid>');
    console.error('Example: vm-shutdown 100');
    console.error('\nNote: Graceful shutdown (requires guest agent). Use vm-stop for forced shutdown.');
    process.exit(1);
  }

  const vmid = parseInt(args[0]);

  if (isNaN(vmid)) {
    console.error(`❌ Invalid VMID: ${args[0]}`);
    process.exit(1);
  }

  try {
    const config = await loadConfig();
    const discovery = new NodeDiscovery(config);
    const apiClient = new ProxmoxAPIClient(config);

    console.log(`🔍 Locating VM ${vmid}...`);
    const location = await discovery.findVM(vmid);

    console.log(`📍 Found on node: ${location.node}`);
    console.log(`🛑 Shutting down VM ${vmid} (graceful)...`);

    const taskId = await apiClient.shutdownVM(location.node, vmid);
    console.log(`✅ Shutdown command sent (Task: ${taskId})`);
    console.log(`\nVM ${vmid} is shutting down gracefully...`);

  } catch (error) {
    console.error(`❌ Error: ${error}`);
    process.exit(1);
  }
}

main();
