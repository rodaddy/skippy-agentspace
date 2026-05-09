#!/usr/bin/env bun

import { loadConfig, getEnabledNodes } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';

function formatBytes(bytes: number): string {
  const gb = bytes / (1024 ** 3);
  return `${gb.toFixed(1)} GB`;
}

function formatPercent(used: number, total: number): string {
  if (total === 0) return '-';
  const percent = (used / total) * 100;
  return `${percent.toFixed(1)}%`;
}

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  if (days > 0) return `${days}d ${hours}h`;
  return `${hours}h`;
}

async function main() {
  try {
    const config = await loadConfig();
    const discovery = new NodeDiscovery(config);

    console.log('\n🖥️  Virtual Machines\n');

    const vms = await discovery.listAllVMs();

    if (vms.length === 0) {
      console.log('No VMs found.');
      return;
    }

    // Group by node
    const nodes = getEnabledNodes(config);
    for (const node of nodes) {
      const nodeVMs = vms.filter(vm => vm.node === node.name);

      if (nodeVMs.length === 0) continue;

      console.log(`${node.name}:`);

      for (const vm of nodeVMs) {
        const statusIcon = vm.status === 'running' ? '✅' : '⏹️';
        const name = vm.name ? `(${vm.name})` : '';

        if (vm.status === 'running') {
          const memUsed = formatBytes(vm.mem || 0);
          const memMax = formatBytes(vm.maxmem || 0);
          const memPercent = formatPercent(vm.mem || 0, vm.maxmem || 0);
          const cpuPercent = ((vm.cpu || 0) * 100).toFixed(1);
          const uptime = vm.uptime ? formatUptime(vm.uptime) : '-';

          console.log(
            `  ${statusIcon} ${vm.vmid.toString().padEnd(4)} ${name.padEnd(20)} ` +
            `${vm.status.padEnd(8)} ${memUsed.padEnd(10)} / ${memMax.padEnd(10)} ` +
            `${memPercent.padEnd(6)} CPU: ${cpuPercent.padEnd(5)}%  ${uptime}`
          );
        } else {
          console.log(
            `  ${statusIcon} ${vm.vmid.toString().padEnd(4)} ${name.padEnd(20)} ` +
            `${vm.status.padEnd(8)} -                   -        -          -`
          );
        }
      }
    }

    const running = vms.filter(vm => vm.status === 'running').length;
    const stopped = vms.filter(vm => vm.status === 'stopped').length;

    console.log(`\n📊 Total: ${vms.length} VMs (${running} running, ${stopped} stopped)\n`);

  } catch (error) {
    console.error(`❌ Error: ${error}`);
    process.exit(1);
  }
}

main();
