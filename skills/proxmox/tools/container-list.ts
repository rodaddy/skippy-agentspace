#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';

function formatBytes(bytes: number): string {
  const gb = bytes / (1024 ** 3);
  return `${gb.toFixed(1)} GB`;
}

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  return `${days}d ${hours}h`;
}

async function main() {
  try {
    const config = await loadConfig();
    const discovery = new NodeDiscovery(config);

    console.log('\n📦 LXC Containers\n');

    const containers = await discovery.listAllContainers();

    if (containers.length === 0) {
      console.log('No containers found');
      return;
    }

    // Group by node
    const byNode = containers.reduce((acc, c) => {
      const node = c.node || 'unknown';
      if (!acc[node]) acc[node] = [];
      acc[node].push(c);
      return acc;
    }, {} as Record<string, typeof containers>);

    // Display grouped by node
    for (const [nodeName, nodeContainers] of Object.entries(byNode)) {
      console.log(`\n${nodeName}:`);

      for (const container of nodeContainers) {
        const status = container.status === 'running' ? '✅' : '⏹️ ';
        const memory = container.maxmem
          ? `${formatBytes(container.mem || 0)} / ${formatBytes(container.maxmem)}`
          : '-';
        const cpu = container.cpus
          ? `${((container.cpus || 0) * 100).toFixed(1)}%`
          : '-';
        const uptime = container.uptime
          ? formatUptime(container.uptime)
          : '-';

        console.log(
          `  ${status} ${container.vmid.toString().padEnd(4)} (${container.name?.padEnd(20) || 'unnamed'.padEnd(20)}) ` +
          `${container.status.padEnd(10)} ${memory.padEnd(20)} ${cpu.padEnd(8)} ${uptime}`
        );
      }
    }

    console.log(`\n📊 Total: ${containers.length} containers\n`);
  } catch (error) {
    console.error(`❌ Error: ${error}`);
    process.exit(1);
  }
}

main();
