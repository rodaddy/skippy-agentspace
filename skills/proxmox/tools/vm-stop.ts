#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.error('Usage: vm-stop <vmid>');
    console.error('Example: vm-stop 100');
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
    console.log(`⏹️  Stopping VM ${vmid} (forced)...`);

    const taskId = await apiClient.stopVM(location.node, vmid);
    console.log(`✅ Stop command sent (Task: ${taskId})`);
    console.log(`\nVM ${vmid} is stopping...`);

  } catch (error) {
    console.error(`❌ Error: ${error}`);
    process.exit(1);
  }
}

main();
