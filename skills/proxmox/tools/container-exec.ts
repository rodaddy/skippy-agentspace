#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { SSHClient } from '../lib/ssh-client.js';

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.error('Usage: container-exec <vmid> <command>');
    console.error('Example: container-exec 101 "free -h"');
    process.exit(1);
  }

  const vmid = parseInt(args[0]);
  const command = args.slice(1).join(' ').replace(/^["']|["']$/g, ''); // Remove surrounding quotes

  if (isNaN(vmid)) {
    console.error(`❌ Invalid VMID: ${args[0]}`);
    process.exit(1);
  }

  try {
    const config = await loadConfig();
    const ssh = new SSHClient(config);

    // No need to discover - cluster handles routing!
    const exitCode = await ssh.containerExecStream(
      vmid,
      command,
      (data, isError) => {
        if (isError) {
          process.stderr.write(data);
        } else {
          process.stdout.write(data);
        }
      }
    );

    if (exitCode !== 0) {
      process.exit(exitCode);
    }
  } catch (error) {
    console.error(`❌ Error: ${error}`);
    process.exit(1);
  }
}

main();
