# Proxmox Skill - Complete Deployment Guide

Two-part installation: **PAI Skill (your Mac)** + **SSE Agent (Proxmox server)**

---

## Part 1: Install PAI Skill (Mac/Local)

### Quick Install

```bash
# Clone or copy to skills directory
cd ~/.config/pai/skills/
git clone <repo-url> proxmox
cd proxmox

# Run interactive setup
./setup.sh
```

### What setup.sh Does

1. **Generates SSH key** - Ed25519 key pair in `ssh/`
2. **Creates .env** - Copies `.env.example` and prompts for credentials
3. **Installs dependencies** - Runs `bun install`
4. **Tests connectivity** - Verifies SSH to all nodes

### Manual Setup (Alternative)

```bash
# 1. Install dependencies
bun install

# 2. Create credentials
cp .env.example .env
# Edit .env with your Proxmox API token

# 3. Generate SSH key
ssh-keygen -t ed25519 -f ssh/proxmox_id_rsa -C "pai-proxmox-skill" -N ""

# 4. Deploy SSH key to Proxmox nodes
ssh-copy-id -i ssh/proxmox_id_rsa.pub root@<PROXMOX_NODE_IP>
ssh-copy-id -i ssh/proxmox_id_rsa.pub root@<PROXMOX_NODE_IP>

# 5. Edit config.json
# Set your cluster name, node IPs, mark one node as "primary"

# 6. Test
bun run tools/cluster-status.ts
```

### Required Configuration

**config.json** - Cluster topology:
```json
{
  "cluster": {
    "name": "your-cluster",
    "nodes": [
      {
        "name": "proxmox06",
        "hostname": "<PROXMOX_NODE_IP>",
        "roles": ["primary", "containers"],
        "enabled": true
      }
    ]
  }
}
```

**.env** - Credentials (from Proxmox web UI → Permissions → API Tokens):
```bash
PROXMOX_API_USER=root@pam
PROXMOX_API_TOKEN_NAME=pai-skill
PROXMOX_API_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Part 2: Install SSE Agent (Proxmox Server)

### Quick Install

```bash
# 1. Copy agent files to Proxmox node
scp -r agent/ root@<PROXMOX_NODE_IP>:/tmp/proxmox-agent

# 2. SSH to Proxmox node
ssh root@<PROXMOX_NODE_IP>

# 3. Run installer
cd /tmp/proxmox-agent
chmod +x install-agent.sh
./install-agent.sh
```

### What install-agent.sh Does

1. **Checks prerequisites** - Verifies Proxmox VE, installs Bun if needed
2. **Creates directories** - `/opt/proxmox-sse-agent/`
3. **Copies agent files** - `agent.ts`, watchers
4. **Creates systemd service** - Auto-start on boot
5. **Opens firewall** - Port 3000
6. **Starts agent** - Runs and tests connectivity

### Manual Install (Alternative)

```bash
# On Proxmox node
mkdir -p /opt/proxmox-sse-agent
cd /opt/proxmox-sse-agent

# Copy agent.ts to this directory

# Install Bun (if not already installed)
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"

# Create package.json
cat > package.json << 'EOF'
{
  "name": "proxmox-sse-agent",
  "version": "1.0.0",
  "type": "module"
}
EOF

# Create systemd service
cat > /etc/systemd/system/proxmox-sse-agent.service << 'EOF'
[Unit]
Description=Proxmox SSE Event Streaming Agent
After=network.target pve-cluster.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/proxmox-sse-agent
ExecStart=/root/.bun/bin/bun run agent.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl daemon-reload
systemctl enable proxmox-sse-agent
systemctl start proxmox-sse-agent

# Check status
systemctl status proxmox-sse-agent

# Test
curl http://localhost:3000/status
```

### Firewall Configuration

```bash
# If using UFW
ufw allow 3000/tcp comment "Proxmox SSE Agent"

# If using firewalld
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --reload

# If using Proxmox firewall (via web UI)
# Datacenter → Firewall → Add Rule
# Direction: in, Action: ACCEPT, Protocol: tcp, Dest port: 3000
```

---

## Verification & Testing

### Test Skill (Mac)

```bash
cd ~/.config/pai/skills/proxmox

# List VMs
bun run tools/vm-list.ts

# List containers
bun run tools/container-list.ts

# Cluster status
bun run tools/cluster-status.ts

# Execute command in container
bun run tools/container-exec.ts 101 "uptime"
```

### Test SSE Agent (Proxmox)

```bash
# On Proxmox node

# Check service
systemctl status proxmox-sse-agent

# View logs
journalctl -u proxmox-sse-agent -f

# Test HTTP endpoint
curl http://localhost:3000/status

# Test SSE stream
curl http://localhost:3000/events
# Should see: data: {"type":"connected",...}
```

### Test Real-Time Streaming (Mac → Proxmox)

```bash
# Terminal 1: Start monitor
bun run tools/monitor-stream.ts

# Terminal 2: Trigger events
bun run tools/vm-start.ts 100

# Terminal 1 should show:
# [20:15:30] 🚀 Task started: qmstart on VM 100 (proxmox06)
# [20:15:32] ✅ Task completed: qmstart on VM 100
# [20:15:32] ✅ VM 100: stopped → running
```

---

## Post-Installation

### Enable Auto-Start (Both Sides)

**Skill (Mac):**
Already works - tools run on-demand

**Agent (Proxmox):**
```bash
# Already done by install-agent.sh
systemctl enable proxmox-sse-agent
```

### Security Hardening

**Skill Side:**
- ✅ SSH keys have proper permissions (600)
- ✅ .env is gitignored
- ✅ Audit logs enabled by default

**Agent Side:**
```bash
# Restrict port 3000 to local network only
ufw delete allow 3000/tcp
ufw allow from <YOUR_SUBNET> to any port 3000 proto tcp

# Or add authentication (future enhancement)
```

### Monitoring

**Check Agent Health:**
```bash
# Via HTTP
curl http://<PROXMOX_NODE_IP>:3000/status

# Via systemd
systemctl is-active proxmox-sse-agent

# View stats
journalctl -u proxmox-sse-agent --since "1 hour ago"
```

**Check Skill Logs:**
```bash
# Audit trail
tail -f ~/.config/pai/skills/proxmox/logs/audit.log

# Query recent operations
cat logs/audit.log | jq -r '.operation' | sort | uniq -c
```

---

## Troubleshooting

### Skill Won't Connect to Proxmox

```bash
# Test SSH manually
ssh -i ~/.config/pai/skills/proxmox/ssh/proxmox_id_rsa root@<PROXMOX_NODE_IP>

# Test API
curl -k -H "Authorization: PVEAPIToken=root@pam!pai-skill=<token>" \
  https://<PROXMOX_NODE_IP>:8006/api2/json/nodes

# Check config
bun run tools/cluster-status.ts --debug
```

### SSE Agent Won't Start

```bash
# Check logs
journalctl -u proxmox-sse-agent -n 50 --no-pager

# Test manually
cd /opt/proxmox-sse-agent
bun run agent.ts

# Check Bun installation
which bun
bun --version

# Reinstall Bun if needed
curl -fsSL https://bun.sh/install | bash
```

### Monitor Stream Can't Connect

```bash
# Check agent is running
ssh root@<PROXMOX_NODE_IP> 'systemctl status proxmox-sse-agent'

# Test from Proxmox node
ssh root@<PROXMOX_NODE_IP> 'curl http://localhost:3000/status'

# Test from Mac
curl http://<PROXMOX_NODE_IP>:3000/status

# Check firewall
ssh root@<PROXMOX_NODE_IP> 'ufw status'
```

### Container Exec Fails

```bash
# Check SSH to primary node
ssh -i ~/.config/pai/skills/proxmox/ssh/proxmox_id_rsa root@<PROXMOX_NODE_IP>

# Test pct exec manually
ssh root@<PROXMOX_NODE_IP> 'sudo pct exec 101 -- uptime'

# Check sudo permissions
ssh root@<PROXMOX_NODE_IP> 'sudo -l | grep pct'
```

---

## Upgrading

### Upgrade Skill

```bash
cd ~/.config/pai/skills/proxmox
git pull
bun install
```

### Upgrade Agent

```bash
# Copy new agent.ts to Proxmox
scp agent/agent.ts root@<PROXMOX_NODE_IP>:/opt/proxmox-sse-agent/

# Restart service
ssh root@<PROXMOX_NODE_IP> 'systemctl restart proxmox-sse-agent'
```

---

## Uninstallation

### Remove Skill

```bash
# Remove skill directory
rm -rf ~/.config/pai/skills/proxmox

# Clean up SSH keys from Proxmox nodes
ssh root@<PROXMOX_NODE_IP> 'sed -i "/pai-proxmox-skill/d" ~/.ssh/authorized_keys'
```

### Remove Agent

```bash
# On Proxmox node
systemctl stop proxmox-sse-agent
systemctl disable proxmox-sse-agent
rm /etc/systemd/system/proxmox-sse-agent.service
systemctl daemon-reload
rm -rf /opt/proxmox-sse-agent
ufw delete allow 3000/tcp
```

---

## Multi-Node Deployment

For clusters with multiple nodes:

1. **Install skill once** (on your Mac)
2. **Install agent on primary node** (e.g., proxmox06)
3. **Optional:** Install agent on other nodes for redundancy

**High Availability Setup:**
- Install agent on all nodes
- Use load balancer or failover DNS
- Monitor tool connects to any available agent

**Current Limitation:**
Agent currently watches local node only. For multi-node events, install agent on each node and run multiple monitor streams (or wait for cluster-wide event aggregation feature).

---

## Production Checklist

### Before Going Live

**Skill Side:**
- [ ] SSH keys deployed to all nodes
- [ ] API token tested and working
- [ ] config.json has all nodes listed
- [ ] At least one node marked as "primary"
- [ ] Test all essential tools (vm-start, container-exec, etc.)
- [ ] Audit logging working (`logs/audit.log` exists)

**Agent Side:**
- [ ] Service running and enabled
- [ ] Port 3000 accessible from your Mac
- [ ] Events streaming (test with monitor-stream.ts)
- [ ] Logs clean (no errors in journalctl)
- [ ] Health endpoint responding (`/status`)

### Recommended Next Steps

1. Set up automated monitoring
2. Configure alerting (Discord/Slack webhooks)
3. Add snapshot automation
4. Build custom workflows
5. Contribute tools back to project!

---

## Quick Reference

**Skill Commands:**
```bash
./setup.sh                              # Interactive setup
bun run tools/cluster-status.ts         # Cluster health
bun run tools/vm-list.ts                # List VMs
bun run tools/container-list.ts         # List containers
bun run tools/container-exec.ts 101 cmd # Execute command
bun run tools/monitor-stream.ts         # Real-time events
```

**Agent Commands:**
```bash
systemctl status proxmox-sse-agent      # Check status
systemctl restart proxmox-sse-agent     # Restart
journalctl -u proxmox-sse-agent -f      # View logs
curl http://localhost:3000/status       # Health check
```

**Files:**
```
Skill:  ~/.config/pai/skills/proxmox/
Agent:  /opt/proxmox-sse-agent/
Logs:   ~/.config/pai/skills/proxmox/logs/audit.log
        journalctl -u proxmox-sse-agent
```

---

## Support

**Documentation:**
- README.md - Overview and features
- SKILL.md - PAI-specific usage
- TOOL_MANIFEST.md - Complete tool inventory
- EXPANSION_GUIDE.md - Adding new tools
- SSE_AGENT_DESIGN.md - Real-time architecture

**Issues:**
GitHub Issues: <repo-url>/issues

**Community:**
PAI Skills Discord
