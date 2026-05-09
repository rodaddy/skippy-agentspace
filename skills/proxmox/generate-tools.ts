#!/usr/bin/env bun

// Quick tool generator for common patterns

const tools = {
  // VM Control
  'vm-reboot.ts': {
    type: 'vm-control',
    operation: 'reboot',
    verb: 'Rebooting',
    icon: '🔄',
    apiMethod: 'rebootVM'
  },
  'vm-pause.ts': {
    type: 'vm-control',
    operation: 'pause',
    verb: 'Pausing',
    icon: '⏸️',
    apiMethod: 'pauseVM'
  },
  'vm-resume.ts': {
    type: 'vm-control',
    operation: 'resume',
    verb: 'Resuming',
    icon: '▶️',
    apiMethod: 'resumeVM'
  },

  // Container Control
  'container-start.ts': {
    type: 'container-control',
    operation: 'start',
    verb: 'Starting',
    icon: '🚀',
    apiMethod: 'startContainer'
  },
  'container-stop.ts': {
    type: 'container-control',
    operation: 'stop',
    verb: 'Stopping',
    icon: '⏹️',
    apiMethod: 'stopContainer'
  },
  'container-shutdown.ts': {
    type: 'container-control',
    operation: 'shutdown',
    verb: 'Shutting down',
    icon: '🛑',
    apiMethod: 'shutdownContainer'
  },
  'container-reboot.ts': {
    type: 'container-control',
    operation: 'reboot',
    verb: 'Rebooting',
    icon: '🔄',
    apiMethod: 'rebootContainer'
  },
};

// Generate tools
for (const [filename, config] of Object.entries(tools)) {
  const resourceType = config.type.includes('vm') ? 'VM' : 'Container';
  const resourceKey = config.type.includes('vm') ? 'findVM' : 'findContainer';
  
  const content = `#!/usr/bin/env bun

import { loadConfig } from '../lib/config-loader.js';
import { NodeDiscovery } from '../lib/node-discovery.js';
import { ProxmoxAPIClient } from '../lib/api-client.js';
import { createLogger } from '../lib/logger.js';

async function main() {
  const logger = createLogger();
  const args = process.argv.slice(2).filter(a => !a.startsWith('-'));

  if (args.length < 1) {
    console.error('Usage: ${filename.replace('.ts', '')} <vmid> [--debug] [--quiet]');
    console.error('Example: ${filename.replace('.ts', '')} ${config.type.includes('vm') ? '100' : '101'}');
    process.exit(1);
  }

  const vmid = parseInt(args[0]);

  if (isNaN(vmid)) {
    logger.error(\`Invalid VMID: \${args[0]}\`);
    process.exit(1);
  }

  try {
    logger.debug('Loading configuration...');
    const config = await loadConfig();
    const discovery = new NodeDiscovery(config);
    const apiClient = new ProxmoxAPIClient(config);

    logger.info(\`🔍 Locating ${resourceType} \${vmid}...\`);
    logger.debug(\`Querying all enabled nodes for ${resourceType} \${vmid}\`);
    const location = await discovery.${resourceKey}(vmid);

    if (!location) {
      logger.error(\`${resourceType} \${vmid} not found on any node\`);
      process.exit(1);
    }

    logger.debug(\`${resourceType} \${vmid} found on \${location.node} (\${location.hostname})\`);
    logger.info(\`📍 Found on node: \${location.node}\`);
    logger.info(\`${config.icon} ${config.verb} ${resourceType} \${vmid}...\`);

    logger.debug(\`Sending ${config.operation} command via API to \${location.node}\`);
    const taskId = await apiClient.${config.apiMethod}(location.node, vmid);
    logger.debug(\`API returned task ID: \${taskId}\`);

    // Audit trail
    logger.audit('${filename.replace('.ts', '')}', {
      vmid,
      node: location.node,
      taskId,
      status: 'success'
    });

    logger.success(\`${config.verb.charAt(0).toUpperCase() + config.verb.slice(1)} command sent (Task: \${taskId})\`);
    logger.info(\`\\n${resourceType} \${vmid} is ${config.verb.toLowerCase()}...\`);

  } catch (error) {
    logger.error(\`Error: \${error}\`);
    process.exit(1);
  }
}

main();
`;

  const fs = require('fs');
  const path = require('path');
  const homeDir = require('os').homedir();
  const toolsDir = path.join(homeDir, '.config', 'pai', 'skills', 'proxmox', 'tools');
  const filePath = path.join(toolsDir, filename);
  
  console.log(\`Writing \${filename}...\`);
  fs.writeFileSync(filePath, content, { mode: 0o755 });
}

console.log('✅ Tools generated!');
