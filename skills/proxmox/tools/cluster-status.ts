#!/usr/bin/env bun

import { loadConfig, getEnabledNodes } from '../lib/config-loader.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { NodeDiscovery } from '../lib/node-discovery.js';

function formatBytes(bytes: number): string {
  const gb = bytes / (1024 ** 3);
  return `${gb.toFixed(1)} GB`;
}

function formatPercent(used: number, total: number): string {
  const percent = (used / total) * 100;
  return `${percent.toFixed(0)}%`;
}

async function main() {
  try {
    const config = await loadConfig();
    const apiClient = new ProxmoxAPIClient(config);
    const discovery = new NodeDiscovery(config);

    console.log(`\n🖥️  Proxmox Cluster: ${config.cluster.name}\n`);

    // Get node statuses
    console.log('Nodes:');
    const nodes = getEnabledNodes(config);
    const nodeStatuses = await Promise.all(
      nodes.map(async (node) => {
        try {
          const status = await apiClient.getNodeStatus(node.name);
          return { node, status, online: true };
        } catch (error) {
          return { node, status: null, online: false };
        }
      })
    );

    for (const { node, status, online } of nodeStatuses) {
      if (online && status) {
        // Handle both possible API response formats
        const mem = status.memory?.used || status.mem || 0;
        const maxmem = status.memory?.total || status.maxmem || 0;
        const cpu = status.cpu || 0;
        const maxcpu = status.maxcpu || status.cpuinfo?.cpus || 1;

        const memPercent = maxmem > 0 ? formatPercent(mem, maxmem) : '-';
        const cpuPercent = maxcpu > 0 ? formatPercent(cpu, maxcpu) : '-';

        console.log(
          `  ${node.name.padEnd(12)} (${node.hostname.padEnd(12)}) ✅ Online   ` +
          `${formatBytes(mem).padEnd(10)} / ${formatBytes(maxmem).padEnd(10)} (${memPercent.padEnd(4)})  ` +
          `CPU: ${cpuPercent.padEnd(4)}`
        );
      } else {
        console.log(
          `  ${node.name.padEnd(12)} (${node.hostname.padEnd(12)}) ❌ Offline`
        );
      }
    }

    // Get resource summary
    console.log('\nResources:');

    const [containers, vms] = await Promise.all([
      discovery.listAllContainers(),
      discovery.listAllVMs()
    ]);

    const runningContainers = containers.filter(c => c.status === 'running').length;
    const stoppedContainers = containers.filter(c => c.status === 'stopped').length;
    const runningVMs = vms.filter(v => v.status === 'running').length;
    const stoppedVMs = vms.filter(v => v.status === 'stopped').length;

    console.log(`  VMs:         ${vms.length} total (${runningVMs} running, ${stoppedVMs} stopped)`);
    console.log(`  Containers:  ${containers.length} total (${runningContainers} running, ${stoppedContainers} stopped)`);

    // Calculate total cluster memory
    const totalMem = nodeStatuses.reduce((sum, n) => {
      const max = n.status?.memory?.total || n.status?.maxmem || 0;
      return sum + max;
    }, 0);
    const usedMem = nodeStatuses.reduce((sum, n) => {
      const used = n.status?.memory?.used || n.status?.mem || 0;
      return sum + used;
    }, 0);
    const memPercent = totalMem > 0 ? formatPercent(usedMem, totalMem) : '-';

    console.log(`  Memory:      ${formatBytes(usedMem)} / ${formatBytes(totalMem)} (${memPercent})`);

    // Health check
    const allOnline = nodeStatuses.every(n => n.online);
    const healthStatus = allOnline ? '✅ All systems operational' : '⚠️  Some nodes offline';

    console.log(`\nHealth: ${healthStatus}\n`);

  } catch (error) {
    console.error(`❌ Error: ${error}`);
    process.exit(1);
  }
}

main();
