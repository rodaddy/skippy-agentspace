#!/usr/bin/env bash

# Proxmox Skill Setup Script
# Interactive wizard to configure Proxmox cluster management

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_DIR="$SKILL_DIR/ssh"
CONFIG_FILE="$SKILL_DIR/config.json"
ENV_FILE="$SKILL_DIR/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Proxmox VE Cluster Management - Setup Wizard${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Generate SSH key
echo -e "${YELLOW}[1/5] SSH Key Generation${NC}"
echo ""

if [ -f "$SSH_DIR/proxmox_id_rsa" ]; then
  echo -e "${GREEN}✓${NC} SSH key already exists at $SSH_DIR/proxmox_id_rsa"
else
  echo "Generating dedicated Ed25519 SSH key pair..."
  mkdir -p "$SSH_DIR"
  ssh-keygen -t ed25519 -f "$SSH_DIR/proxmox_id_rsa" -C "pai-proxmox-skill" -N ""
  chmod 600 "$SSH_DIR/proxmox_id_rsa"
  chmod 644 "$SSH_DIR/proxmox_id_rsa.pub"
  echo -e "${GREEN}✓${NC} SSH key generated successfully"
fi

echo ""
PUBLIC_KEY=$(cat "$SSH_DIR/proxmox_id_rsa.pub")
echo -e "${BLUE}Public Key:${NC}"
echo "$PUBLIC_KEY"
echo ""
echo -e "${YELLOW}⚠ IMPORTANT:${NC} You must add this key to each Proxmox node!"
echo ""
echo "Run this command on each Proxmox node:"
echo -e "${GREEN}echo \"$PUBLIC_KEY\" >> ~/.ssh/authorized_keys${NC}"
echo ""
read -p "Press Enter when you've added the key to all nodes..."

# Step 2: Check if config.json exists
echo ""
echo -e "${YELLOW}[2/5] Cluster Configuration${NC}"
echo ""

if [ -f "$CONFIG_FILE" ]; then
  echo -e "${GREEN}✓${NC} Configuration file already exists at $CONFIG_FILE"
  echo "If you need to modify it, edit the file directly."
else
  echo -e "${RED}✗${NC} No config.json found!"
  echo ""
  echo "Please create $CONFIG_FILE with your cluster configuration."
  echo "See README.md for examples."
  exit 1
fi

# Step 3: API Credentials
echo ""
echo -e "${YELLOW}[3/5] API Credentials${NC}"
echo ""

if [ -f "$ENV_FILE" ]; then
  echo -e "${GREEN}✓${NC} Credentials file already exists at $ENV_FILE"
  read -p "Do you want to update credentials? (y/N): " UPDATE_CREDS
  if [[ ! "$UPDATE_CREDS" =~ ^[Yy]$ ]]; then
    echo "Keeping existing credentials"
  else
    rm "$ENV_FILE"
  fi
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Creating API credentials from template..."

  # Copy .env.example if it doesn't exist
  if [ -f "$SKILL_DIR/.env.example" ] && [ ! -f "$ENV_FILE" ]; then
    cp "$SKILL_DIR/.env.example" "$ENV_FILE"
    echo -e "${GREEN}✓${NC} Created .env from .env.example template"
  fi

  echo ""
  echo -e "${BLUE}To create an API token in Proxmox:${NC}"
  echo "1. Datacenter → Permissions → API Tokens"
  echo "2. Add → User: root@pam, Token ID: pai-skill"
  echo "3. Uncheck 'Privilege Separation' for full access"
  echo "4. Copy the token secret"
  echo ""

  read -p "API User [root@pam]: " API_USER
  API_USER=${API_USER:-root@pam}

  read -p "API Token Name [pai-skill]: " API_TOKEN_NAME
  API_TOKEN_NAME=${API_TOKEN_NAME:-pai-skill}

  read -p "API Token Secret: " API_TOKEN_SECRET

  if [ -z "$API_TOKEN_SECRET" ]; then
    echo -e "${RED}✗${NC} API Token Secret is required!"
    exit 1
  fi

  # Create .env file
  cat > "$ENV_FILE" << EOF
PROXMOX_API_USER=$API_USER
PROXMOX_API_TOKEN_NAME=$API_TOKEN_NAME
PROXMOX_API_TOKEN_SECRET=$API_TOKEN_SECRET
EOF

  chmod 600 "$ENV_FILE"
  echo -e "${GREEN}✓${NC} Credentials saved to $ENV_FILE"
fi

# Step 4: Install dependencies
echo ""
echo -e "${YELLOW}[4/5] Installing Dependencies${NC}"
echo ""

if command -v bun &> /dev/null; then
  echo -e "${GREEN}✓${NC} Bun is installed"
  cd "$SKILL_DIR"
  echo "Installing npm packages..."
  bun install
  echo -e "${GREEN}✓${NC} Dependencies installed"
else
  echo -e "${RED}✗${NC} Bun is not installed!"
  echo ""
  echo "Please install Bun first:"
  echo "curl -fsSL https://bun.sh/install | bash"
  exit 1
fi

# Step 5: Test connectivity
echo ""
echo -e "${YELLOW}[5/5] Testing Connectivity${NC}"
echo ""

# Parse config.json to get nodes
NODES=$(cat "$CONFIG_FILE" | grep -o '"hostname": "[^"]*"' | cut -d'"' -f4)

ALL_CONNECTED=true

for NODE in $NODES; do
  echo -n "Testing SSH to $NODE... "
  if ssh -i "$SSH_DIR/proxmox_id_rsa" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
       -o BatchMode=yes "$NODE" "echo 'Connected'" &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    echo "  Failed to connect. Make sure SSH key is deployed."
    ALL_CONNECTED=false
  fi
done

echo ""

if [ "$ALL_CONNECTED" = true ]; then
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}   ✓ Setup Complete!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Your Proxmox skill is ready to use!"
  echo ""
  echo "Try these commands:"
  echo -e "  ${BLUE}bun run tools/cluster-status.ts${NC}  - Check cluster health"
  echo -e "  ${BLUE}bun run tools/container-list.ts${NC}  - List all containers"
  echo -e "  ${BLUE}bun run tools/container-exec.ts <vmid> <command>${NC}  - Execute command"
  echo ""
else
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}   ⚠ Setup Incomplete${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Some nodes failed connectivity tests."
  echo ""
  echo "Make sure you've run this command on each Proxmox node:"
  echo -e "${GREEN}echo \"$PUBLIC_KEY\" >> ~/.ssh/authorized_keys${NC}"
  echo ""
  echo "Then run this setup script again to verify."
  echo ""
fi
