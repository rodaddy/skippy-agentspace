#!/usr/bin/env bash

# Proxmox SSE Agent Installer
# Installs the real-time event streaming agent on Proxmox nodes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTALL_DIR="/opt/proxmox-sse-agent"
SERVICE_NAME="proxmox-sse-agent"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Proxmox SSE Agent - Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if running on Proxmox
if [ ! -f /etc/pve/.version ]; then
  echo -e "${RED}✗ This script must be run on a Proxmox VE node${NC}"
  exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}✗ This script must be run as root${NC}"
  echo "Please run: sudo $0"
  exit 1
fi

echo -e "${YELLOW}[1/6] Checking Prerequisites${NC}"
echo ""

# Check for bun
if ! command -v bun &> /dev/null; then
  echo -e "${YELLOW}Bun not found. Installing...${NC}"
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"

  # Add to bashrc for persistence
  echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
  echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc

  echo -e "${GREEN}✓${NC} Bun installed"
else
  echo -e "${GREEN}✓${NC} Bun already installed"
fi

echo ""
echo -e "${YELLOW}[2/6] Creating Installation Directory${NC}"
echo ""

# Create installation directory
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/watchers"
mkdir -p "$INSTALL_DIR/logs"

echo -e "${GREEN}✓${NC} Created $INSTALL_DIR"

echo ""
echo -e "${YELLOW}[3/6] Installing Agent Files${NC}"
echo ""

# Copy agent files (assuming they're in current directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/agent.ts" ]; then
  cp "$SCRIPT_DIR/agent.ts" "$INSTALL_DIR/"
  echo -e "${GREEN}✓${NC} Copied agent.ts"
else
  echo -e "${YELLOW}⚠${NC} agent.ts not found, creating minimal version..."
  cat > "$INSTALL_DIR/agent.ts" << 'EOF'
#!/usr/bin/env bun
// Proxmox SSE Agent - Minimal Version
console.log('✅ Proxmox SSE Agent starting...');

Bun.serve({
  port: 3000,
  fetch(req) {
    const url = new URL(req.url);

    if (url.pathname === '/status') {
      return Response.json({
        status: 'healthy',
        version: '1.0.0',
        node: process.env.HOSTNAME
      });
    }

    if (url.pathname === '/events') {
      const stream = new ReadableStream({
        start(controller) {
          controller.enqueue(`data: ${JSON.stringify({
            type: 'connected',
            timestamp: new Date().toISOString()
          })}\n\n`);
        }
      });

      return new Response(stream, {
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      });
    }

    return new Response('Proxmox SSE Agent', { status: 200 });
  }
});

console.log('🚀 Agent running on http://localhost:3000');
EOF
  chmod +x "$INSTALL_DIR/agent.ts"
fi

# Copy watchers if they exist
if [ -d "$SCRIPT_DIR/watchers" ]; then
  cp -r "$SCRIPT_DIR/watchers/"* "$INSTALL_DIR/watchers/" 2>/dev/null || true
  echo -e "${GREEN}✓${NC} Copied watcher modules"
fi

# Create package.json
cat > "$INSTALL_DIR/package.json" << 'EOF'
{
  "name": "proxmox-sse-agent",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {}
}
EOF

echo -e "${GREEN}✓${NC} Created package.json"

echo ""
echo -e "${YELLOW}[4/6] Creating Systemd Service${NC}"
echo ""

# Create systemd service file
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Proxmox SSE Event Streaming Agent
After=network.target pve-cluster.service
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=$(which bun) run agent.ts
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓${NC} Created systemd service"

echo ""
echo -e "${YELLOW}[5/6] Configuring Firewall${NC}"
echo ""

# Open port 3000 in Proxmox firewall
if command -v ufw &> /dev/null; then
  ufw allow 3000/tcp comment "Proxmox SSE Agent"
  echo -e "${GREEN}✓${NC} Opened port 3000 in UFW"
elif command -v firewall-cmd &> /dev/null; then
  firewall-cmd --permanent --add-port=3000/tcp
  firewall-cmd --reload
  echo -e "${GREEN}✓${NC} Opened port 3000 in firewalld"
else
  echo -e "${YELLOW}⚠${NC} No firewall detected, port 3000 may need manual configuration"
fi

echo ""
echo -e "${YELLOW}[6/6] Starting Agent Service${NC}"
echo ""

# Reload systemd
systemctl daemon-reload

# Enable and start service
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"

# Wait a moment for service to start
sleep 2

# Check if service is running
if systemctl is-active --quiet "${SERVICE_NAME}"; then
  echo -e "${GREEN}✓${NC} Service started successfully"

  # Test the agent
  echo ""
  echo "Testing agent..."
  if curl -s http://localhost:3000/status | grep -q "healthy"; then
    echo -e "${GREEN}✓${NC} Agent responding correctly"
  else
    echo -e "${RED}✗${NC} Agent not responding (may still be starting)"
  fi
else
  echo -e "${RED}✗${NC} Service failed to start"
  echo "Check logs with: journalctl -u ${SERVICE_NAME} -n 50"
  exit 1
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   ✓ Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "The Proxmox SSE Agent is now running!"
echo ""
echo "Service commands:"
echo -e "  ${BLUE}systemctl status ${SERVICE_NAME}${NC}  - Check status"
echo -e "  ${BLUE}systemctl restart ${SERVICE_NAME}${NC} - Restart agent"
echo -e "  ${BLUE}systemctl stop ${SERVICE_NAME}${NC}    - Stop agent"
echo -e "  ${BLUE}journalctl -u ${SERVICE_NAME} -f${NC}  - View logs"
echo ""
echo "Test endpoints:"
echo -e "  ${BLUE}curl http://localhost:3000/status${NC}  - Health check"
echo -e "  ${BLUE}curl http://localhost:3000/events${NC}  - Event stream"
echo ""
echo "Connect from PAI skill:"
echo -e "  ${BLUE}bun run tools/monitor-stream.ts${NC}"
echo ""
