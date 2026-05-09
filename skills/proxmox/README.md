# Proxmox VE Cluster Management Skill

> Comprehensive Proxmox VE cluster management with full LXC container support, real-time command execution, and multi-node orchestration.

Built for [PAI (Personal AI Infrastructure)](https://github.com/anthropics/claude-code) to provide seamless Proxmox cluster management through natural language commands and programmatic tools.

## Why This Exists

The existing Proxmox MCP has limitations:
- ❌ No LXC container command execution (API doesn't support `pct exec`)
- ❌ Requires querying API to find which node has each container
- ❌ Complex multi-node coordination
- ❌ No real-time streaming output

This skill solves these problems:
- ✅ **Full LXC Support**: Execute any command in containers with real-time streaming
- ✅ **Zero Discovery Overhead**: Connect to primary node, Proxmox cluster routes everything
- ✅ **Real-Time Output**: See apt progress bars, interactive output, streaming logs
- ✅ **Cluster-Aware**: Automatic resource discovery across all nodes
- ✅ **Production Ready**: Secure credential management, proper error handling

## Features

### Core Capabilities

- **LXC Container Execution**: Run commands in any container with real-time output streaming
- **Multi-Node Discovery**: List containers/VMs across entire cluster in parallel
- **Cluster Health Monitoring**: Real-time status of nodes, memory, CPU, resources
- **Hybrid API + SSH**: Best of both worlds - API for queries, SSH for execution
- **Secure by Design**: Dedicated SSH keys, API token auth, proper file permissions

### Architecture Highlights

**Traditional Approach** (Complex):
```
1. Query API: "Which node has container 101?"
2. SSH to that specific node
3. Execute command
```

**This Skill** (Simple):
```
1. SSH to primary node
2. Run: pct exec 101 <command>
3. Proxmox cluster routes automatically!
```

**Why It Works**: Proxmox cluster keeps all nodes synchronized. Any `pct` command works from any node - the cluster handles routing to the correct physical host.

## Quick Start

### 1. Installation

```bash
cd ~/.config/pai/skills/
git clone https://github.com/yourusername/proxmox-skill.git proxmox
cd proxmox
bun install
```

### 2. Setup

```bash
./setup.sh
```

This interactive wizard will:
- Generate dedicated SSH key pair (Ed25519)
- Copy `.env.example` to `.env`
- Prompt for API credentials
- Test connectivity to all nodes
- Create secure configuration files

**Or manually**: Copy `.env.example` to `.env` and fill in your credentials

### 3. Deploy SSH Key

Add the generated public key to each Proxmox node:

```bash
# On each Proxmox node:
echo "ssh-ed25519 AAAA... pai-proxmox-skill" >> ~/.ssh/authorized_keys
```

The setup script will show you the exact command.

### 4. Configure

Edit `config.json` with your cluster details:

```json
{
  "cluster": {
    "name": "my-cluster",
    "nodes": [
      {
        "name": "pve1",
        "hostname": "10.0.0.1",
        "roles": ["primary", "containers", "vms"],
        "enabled": true
      }
    ]
  }
}
```

**Important**: Set one node with `"primary"` role - all SSH commands route through it.

### 5. Test

```bash
# List all containers
bun run tools/container-list.ts

# Check cluster status
bun run tools/cluster-status.ts

# Execute command in container
bun run tools/container-exec.ts 101 "free -h"
```

## Example Output

### Container List

```
📦 LXC Containers

pve1:
  ✅ 101  (app-server) running    2.1 GB / 4.0 GB     25.0%    5d 3h
  ✅ 102  (database)  running     3.8 GB / 8.0 GB     47.5%    12d 8h
  ⏹️  103  (backup)    stopped    -                   -        -

pve2:
  ✅ 201  (web-proxy) running     512 MB / 2.0 GB     25.0%    30d 2h

📊 Total: 4 containers (3 running, 1 stopped)
```

### Cluster Status

```
🖥️  Proxmox Cluster: production

Nodes:
  pve1    (10.0.0.1)  ✅ Online   16.2 GB / 32.0 GB (51%)  CPU: 12%
  pve2    (10.0.0.2)  ✅ Online   8.1 GB / 16.0 GB (51%)   CPU: 8%

Resources:
  VMs:         5 total (4 running, 1 stopped)
  Containers:  12 total (11 running, 1 stopped)
  Memory:      24.3 GB / 48.0 GB (51%)

Health: ✅ All systems operational
```

### Real-Time Command Execution

```bash
$ bun run tools/container-exec.ts 101 "apt update && apt upgrade -y"

Hit:1 http://deb.debian.org/debian bookworm InRelease
Get:2 http://deb.debian.org/debian bookworm-updates InRelease [55.4 kB]
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
12 packages can be upgraded. Run 'apt list --upgradable' to see them.

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Calculating upgrade... Done
The following packages will be upgraded:
  base-files curl libcurl4 ...
12 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
Need to get 8,234 kB of archives.
After this operation, 12.3 kB of additional disk space will be used.
Get:1 http://deb.debian.org/debian bookworm/main amd64 base-files amd64 12.4 [70.2 kB]
...
(Reading database ... 28234 files and directories currently installed.)
Preparing to unpack .../base-files_12.4_amd64.deb ...
Unpacking base-files (12.4) over (12.3) ...
Setting up base-files (12.4) ...
...
```

**Note**: Real-time streaming works! You see apt progress bars as they happen.

## Available Tools

### Container Operations

**List All Containers**
```bash
bun run tools/container-list.ts
```
Shows all LXC containers across the cluster with status, memory, CPU, uptime.

**Execute Commands** (with streaming)
```bash
# Simple command
bun run tools/container-exec.ts 101 "uptime"

# Complex command with pipes
bun run tools/container-exec.ts 101 "apt update && apt upgrade -y"

# Interactive output (progress bars work!)
bun run tools/container-exec.ts 101 "apt install -y nginx"
```

### Cluster Management

**Cluster Status**
```bash
bun run tools/cluster-status.ts
```
Shows complete cluster overview: nodes, VMs, containers, memory, CPU, health.

## Configuration

### Cluster Configuration (`config.json`)

```json
{
  "cluster": {
    "name": "your-cluster-name",
    "nodes": [
      {
        "name": "pve1",
        "hostname": "10.0.0.1",
        "api_port": 8006,
        "ssh_port": 22,
        "ssh_user": "root",
        "roles": ["primary", "containers", "vms"],
        "enabled": true
      }
    ]
  },
  "api": {
    "verify_ssl": false,
    "timeout": 30000,
    "retry_attempts": 3,
    "retry_delay": 2000
  },
  "ssh": {
    "key_path": "~/.config/pai/skills/proxmox/ssh/proxmox_id_rsa",
    "connect_timeout": 10,
    "command_timeout": 300,
    "strict_host_key_checking": false
  },
  "defaults": {
    "container_template": "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst",
    "storage": "local-lvm",
    "network_bridge": "vmbr0"
  }
}
```

### Credentials (`.env`)

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Then edit `.env`:

```bash
PROXMOX_API_USER=root@pam
PROXMOX_API_TOKEN_NAME=pai-skill
PROXMOX_API_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Creating API Token in Proxmox:**
1. Datacenter → Permissions → API Tokens
2. Add → User: `root@pam`, Token ID: `pai-skill`
3. Uncheck "Privilege Separation" for full access
4. Copy token secret to `.env`

## Project Structure

```
~/.config/pai/skills/proxmox/
├── README.md             # This file (GitHub documentation)
├── SKILL.md              # PAI-specific documentation
├── LICENSE               # MIT License
├── setup.sh              # Interactive setup wizard
├── .gitignore            # Protects secrets from git
├── config.json           # Cluster configuration
├── .env.example          # Credentials template (committed to git)
├── .env                  # Actual credentials (gitignored)
├── package.json          # Dependencies
├── lib/                  # Core libraries
│   ├── config-loader.ts  # Configuration management
│   ├── api-client.ts     # Proxmox API wrapper
│   ├── ssh-client.ts     # SSH with streaming support
│   └── node-discovery.ts # Multi-node resource discovery
├── tools/                # Executable commands
│   ├── container-list.ts # List all containers
│   ├── container-exec.ts # Execute with streaming
│   └── cluster-status.ts # Cluster health check
└── ssh/                  # SSH keys (gitignored)
    ├── proxmox_id_rsa
    └── proxmox_id_rsa.pub
```

## API Reference

### SSH Client

```typescript
import { SSHClient } from './lib/ssh-client.js';
import { loadConfig } from './lib/config-loader.js';

const config = await loadConfig();
const ssh = new SSHClient(config);

// Execute command (buffered)
const result = await ssh.containerExec(101, 'free -h');
console.log(result.stdout);

// Execute with streaming (real-time)
await ssh.containerExecStream(
  101,
  'apt update',
  (data, isError) => {
    if (isError) {
      console.error(data);
    } else {
      console.log(data);
    }
  }
);
```

### API Client

```typescript
import { ProxmoxAPIClient } from './lib/api-client.js';

const client = new ProxmoxAPIClient(config);

// List containers on a node
const containers = await client.listContainers('pve1');

// Get container status
const status = await client.getContainerStatus('pve1', 101);

// Start/stop container
await client.startContainer('pve1', 101);
await client.stopContainer('pve1', 101);
```

### Node Discovery

```typescript
import { NodeDiscovery } from './lib/node-discovery.js';

const discovery = new NodeDiscovery(config);

// Find container across cluster
const location = await discovery.findContainer(101);
console.log(`Container 101 is on ${location.node}`);

// List all containers cluster-wide
const allContainers = await discovery.listAllContainers();
```

## Security

### Best Practices

1. **Dedicated SSH Keys**
   - Skill uses its own Ed25519 key pair
   - Stored in `~/.config/pai/skills/proxmox/ssh/`
   - Permissions: `600` (private key), `644` (public key)
   - Can be revoked independently from personal keys

2. **API Token Authentication**
   - Token-based auth (not password)
   - Stored in `.env` file (gitignored)
   - Never committed to version control
   - Scoped permissions possible

3. **File Permissions**
   ```bash
   chmod 600 .env ssh/proxmox_id_rsa
   chmod 644 config.json ssh/proxmox_id_rsa.pub
   ```

4. **Network Security**
   - SSL verification configurable
   - Disable for internal networks (default)
   - Enable for remote access

## Troubleshooting

### SSH Connection Failed

**Issue**: `All configured authentication methods failed`

**Solution**: Ensure SSH key is added to Proxmox nodes:
```bash
ssh-copy-id -i ~/.config/pai/skills/proxmox/ssh/proxmox_id_rsa.pub user@<proxmox-host>
```

### Container Not Found

**Issue**: `Container 101 not found on any node`

**Solution**: Container may be stopped or VMID incorrect. List all containers:
```bash
bun run tools/container-list.ts
```

### API Authentication Failed

**Issue**: `401 Unauthorized`

**Solution**: Check API token in `.env`:
```bash
# Verify token works:
curl -k -H "Authorization: PVEAPIToken=root@pam!pai-skill=<token>" \
  https://<proxmox-host>:8006/api2/json/nodes
```

### Permission Denied on pct exec

**Issue**: `sudo: no tty present and no askpass program specified`

**Solution**: Ensure your SSH user has passwordless sudo for `pct`:
```bash
# On Proxmox node:
echo "your-user ALL=(ALL) NOPASSWD: /usr/sbin/pct" | sudo tee /etc/sudoers.d/pct-access
```

## Advanced Usage

### Custom Tools

Build your own tools using the libraries:

```typescript
#!/usr/bin/env bun
import { loadConfig } from '../lib/config-loader.js';
import { SSHClient } from '../lib/ssh-client.js';

const config = await loadConfig();
const ssh = new SSHClient(config);

// Update all containers
const containerIds = [101, 102, 103];

for (const vmid of containerIds) {
  console.log(`Updating container ${vmid}...`);
  await ssh.containerExecStream(
    vmid,
    'apt update && apt upgrade -y',
    (data) => process.stdout.write(data)
  );
}
```

### Bulk Operations

```bash
# Update all containers
for id in 101 102 103; do
  bun run tools/container-exec.ts $id "apt update && apt upgrade -y"
done
```

## Requirements

- **Proxmox VE**: 8.x or newer
- **Bun**: Latest version (for running TypeScript)
- **SSH Access**: To all Proxmox nodes
- **API Token**: From Proxmox web interface

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test with live Proxmox cluster
4. Submit pull request

## License

MIT License - Free to use, modify, and distribute.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/proxmox-skill/issues)
- **Documentation**: [SKILL.md](SKILL.md) for detailed PAI integration docs
- **Community**: PAI Skills Discord

---

**Built with**: TypeScript, Bun, ssh2, axios
**Tested on**: Proxmox VE 8.x
**Version**: 1.0.0

**Created for [PAI](https://github.com/anthropics/claude-code)** - Personal AI Infrastructure powered by Claude Code
