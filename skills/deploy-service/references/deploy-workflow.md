# Deploy Service Workflow — Exact Patterns

All paths relative to `projects/pai-infra/ansible/` in the infrastructure repo.

## Pre-Flight (run BEFORE presenting the plan)

```bash
NODE_IP="<target proxmox node IP>"

# Template exists on shared storage
ssh root@$NODE_IP "pveam list TN01_lxc_nvme | grep debian-13"

# pve-container supports Debian 13
ssh root@$NODE_IP "dpkg -l pve-container | awk '/pve-container/{print \$3}'"
# Need >= 6.0.10

# Node container count + memory
ssh root@$NODE_IP "echo 'Containers:' && pct list | tail -n+2 | wc -l && free -h | head -2"

# Storage space on target node
ssh root@$NODE_IP "pvesm status -storage local-lvm"

# VMID free cluster-wide
for N in <PX01_IP> <PX02_IP> <PX03_IP> <PX04_IP>; do
  ssh -o ConnectTimeout=3 root@$N "pct list 2>/dev/null" | grep "^<VMID> " && echo "VMID CONFLICT on $N"
done

# IP free
ping -c1 -W1 <VLAN20_PREFIX>.<XX> && echo "IP IN USE" || echo "IP FREE"
```

## Step 1: Plan — Find Next Available VMID + IP

Scan existing inventory to determine next free IP and VMID:

```bash
# Check what's in use (from hosts.yml)
grep 'ansible_host:' inventory/hosts.yml | sort

# Check what VMIDs exist on target node
ssh root@<NODE_IP> "pct list"

# Ping-check candidate IPs
ping -c1 -W1 <VLAN20_PREFIX>.<XX> && echo "IN USE" || echo "FREE"
ping -c1 -W1 <VLAN1_PREFIX>.<XX> && echo "IN USE" || echo "FREE"
```

**Conventions:**
- VMID: Generally 200 + last octet, but just pick next free VMID
- Use same last octet for both VLANs (e.g., `.66` on both <VLAN20_PREFIX> and <VLAN1_PREFIX>)

Present this table to user for confirmation:

```
Service:     <name>
VMID:        <vmid>
Node:        <proxmox node>
VLAN 20 IP:  <VLAN20_PREFIX>.<XX>
VLAN 1 IP:   <VLAN1_PREFIX>.<XX>
Port:        <port>
User:        <service-user>
RAM:         <MB>
Disk:        <GB>
Cores:       <N>
Subdomain:   <name>.your-domain.example
```

## Step 2: Create LXC

```bash
ssh root@<NODE_IP> "pct create <VMID> TN01_lxc_nvme:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst \
  --hostname <SERVICE_NAME> \
  --memory <RAM> \
  --swap 512 \
  --cores <CORES> \
  --net0 name=eth0,bridge=vmbr0,ip=<VLAN20_PREFIX>.<XX>/24,gw=<GATEWAY_IP>,tag=20,type=veth \
  --net1 name=eth1,bridge=vmbr0,ip=<VLAN1_PREFIX>.<XX>/24,type=veth \
  --rootfs <STORAGE>:<DISK> \
  --nameserver '<PIHOLE1_IP> <PIHOLE2_IP> 1.1.1.1' \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1 \
  --start 1"
```

**Storage selection** (CRITICAL — varies by node):
- px01, px02, px03: `--rootfs local-lvm:<DISK>`
- px04: `--rootfs tank-nvme:<DISK>`

**Single NIC variant** (VLAN 20 only — omit `--net1`):
```bash
  --net0 name=eth0,bridge=vmbr0,ip=<VLAN20_PREFIX>.<XX>/24,gw=<GATEWAY_IP>,tag=20,type=veth \
```

**After `pct create` — bootstrap root SSH key via `pct exec`:**

Fresh containers have NO authorized_keys. Ansible cannot reach them. This step is mandatory.

```bash
# Get your public key
PUBKEY="$(cat ~/.ssh/id_rsa.pub)"

# Deploy to container via pct exec on the Proxmox node
ssh root@<NODE_IP> "
  pct exec <VMID> -- mkdir -p /root/.ssh
  pct exec <VMID> -- chmod 700 /root/.ssh
  echo '$PUBKEY' | pct exec <VMID> -- tee /root/.ssh/authorized_keys > /dev/null
  pct exec <VMID> -- chmod 600 /root/.ssh/authorized_keys
"

# For multiple containers, loop:
for VMID in <VMID1> <VMID2>; do
  ssh root@<NODE_IP> "
    pct exec $VMID -- mkdir -p /root/.ssh
    pct exec $VMID -- chmod 700 /root/.ssh
    echo '$PUBKEY' | pct exec $VMID -- tee /root/.ssh/authorized_keys > /dev/null
    pct exec $VMID -- chmod 600 /root/.ssh/authorized_keys
  "
  echo "CT $VMID: root SSH key deployed"
done
```

**Clear stale known_hosts and verify SSH:**
```bash
ssh-keygen -R <VLAN20_PREFIX>.<XX>
ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 root@<VLAN20_PREFIX>.<XX> "hostname && cat /etc/debian_version"
```

## Step 3: Add to Ansible Inventory

Edit `inventory/hosts.yml`. Add host under the appropriate group.

**Pattern for `apps` group (most common):**
```yaml
    apps:
      hosts:
        # ... existing hosts ...
        <service_name>:                    # underscores, not hyphens
          ansible_host: <VLAN20_PREFIX>.<XX>
          vlan1_ip: <VLAN1_PREFIX>.<XX>           # only if dual NIC
          app_subdomain: <service-name>    # hyphens for subdomain
```

**The inventory hostname uses underscores** (Ansible convention), but `app_subdomain` uses hyphens (DNS convention).

**Other groups to consider:**
- `trading:` — trading/finance apps
- `agents:` — AI agent containers (need cc_user vars)
- `cc_cluster:` — Claude Code dev environments
- `infra:` — infrastructure services

## Step 4: Add Service User (if new)

Check if user exists in `inventory/group_vars/all.yml`:

```bash
grep '<username>' inventory/group_vars/all.yml
```

**If user doesn't exist, add to `homelab_users` list:**
```yaml
homelab_users:
  # ... existing users ...
  - { name: <username>, uid: <NEXT_UID>, group: <primary_group>, groups: "<extra_groups>" }
```

**UID conventions:**
- 2000-2099: Service/system users (media, postgres, caddy, etc.)
- 3000-3099: Human/admin users (admin, user2, user3, etc.)

**If a new group is needed, add to `homelab_groups`:**
```yaml
homelab_groups:
  # ... existing groups ...
  - { name: <group_name>, gid: <NEXT_GID> }
```

## Step 5: Run lxc-baseline.yml

```bash
cd projects/pai-infra/ansible
ansible-playbook -i inventory/hosts.yml playbooks/lxc-baseline.yml --limit <hostname>
```

This configures:
- Timezone: America/New_York
- Locale: en_US.UTF-8
- Journald: 200M max, 30-day retention
- Tools: vim, btop, curl, jq, zsh, tree
- All homelab groups and users from all.yml (with correct UIDs/GIDs)
- sudo installed
- user: passwordless sudo + SSH authorized_key
- Unattended security upgrades
- Shell aliases (bash + zsh)

**Verify after:**
```bash
ssh user@<VLAN20_PREFIX>.<XX> "sudo whoami && date && locale"
# Should output: root, correct timezone, en_US.UTF-8
```

## Step 6: Service User SSH Keys

**Generate keypair locally (on your Mac):**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/homelab/<service-name> -N "" -C "<service-name>@homelab"
```

**Deploy public key to container:**
```bash
# As root (since user has sudo)
ssh root@<VLAN20_PREFIX>.<XX> "mkdir -p /home/<user>/.ssh && \
  chmod 700 /home/<user>/.ssh && \
  chown <user>:<primary_group> /home/<user>/.ssh"

# Copy the public key
cat ~/.ssh/homelab/<service-name>.pub | \
  ssh root@<VLAN20_PREFIX>.<XX> "tee /home/<user>/.ssh/authorized_keys && \
  chmod 600 /home/<user>/.ssh/authorized_keys && \
  chown <user>:<primary_group> /home/<user>/.ssh/authorized_keys"
```

**If service user needs passwordless sudo:**
```bash
ssh root@<VLAN20_PREFIX>.<XX> "echo '<user> ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/<user> && \
  chmod 440 /etc/sudoers.d/<user>"
```

**Add SSH key to inventory (for Ansible to use):**
If this host will be managed via the service user (not root), update hosts.yml:
```yaml
        <service_name>:
          ansible_host: <VLAN20_PREFIX>.<XX>
          ansible_user: <user>
          ansible_ssh_private_key_file: ~/.ssh/homelab/<service-name>
```

**Verify:**
```bash
ssh -i ~/.ssh/homelab/<service-name> <user>@<VLAN20_PREFIX>.<XX> "whoami && id"
```

## Step 7: Caddy Reverse Proxy

Edit `templates/Caddyfile.j2`. Add route block in the appropriate section.

**Standard route:**
```
<subdomain>.{{ domain }} {
    reverse_proxy <VLAN20_PREFIX>.<XX>:<PORT>
}
```

**With headers (for apps that need real IP):**
```
<subdomain>.{{ domain }} {
    reverse_proxy <VLAN20_PREFIX>.<XX>:<PORT> {
        header_up X-Real-IP {remote_host}
    }
}
```

**With WebSocket support:**
```
<subdomain>.{{ domain }} {
    reverse_proxy <VLAN20_PREFIX>.<XX>:<PORT> {
        header_up X-Real-IP {remote_host}
        transport http {
            keepalive 30s
        }
    }
}
```

**Deploy:**
```bash
cd projects/pai-infra/ansible
ansible-playbook -i inventory/hosts.yml playbooks/reverse_proxy.yml
```

**Vault secret required:** `cloudflare_tunnel_token`. If the playbook fails with
"undefined variable", the Caddyfile.j2 change is still committed and will deploy
next time the playbook runs with vault access. Verify the route is live:
`curl -sI https://<subdomain>.your-domain.example` — if it returns anything (200/502), Caddy is working.

## Step 8: DNS Entries

Edit `playbooks/pihole.yml`. Add entries to the `blockinfile` block (under the appropriate comment section).

**Pattern — add line to the blockinfile content block:**
```yaml
          # <Section Comment> -> reverse proxy
          <PROXY_IP> <subdomain>.{{ domain }}
```

All entries point to `<PROXY_IP>` (the Caddy proxy), NOT the backend container IP.

**Deploy:**
```bash
cd projects/pai-infra/ansible
ansible-playbook -i inventory/hosts.yml playbooks/pihole.yml
```

This updates both Pi-hole instances via the `pihole_servers` group.

**Vault secret required:** `lxc_root_password`. Same caveat as Caddy — commit the change,
it deploys next time vault is available. Verify DNS independently:
`dig +short <subdomain>.your-domain.example @<PIHOLE_IP>`

## Step 9: Prometheus Monitoring

**First, deploy node exporter to the new container.**

**IMPORTANT:** The playbook defaults to `hosts: second_brain`. Containers in `apps`,
`trading`, `agents`, etc. will be SILENTLY SKIPPED unless you override the target:

```bash
cd projects/pai-infra/ansible
ansible-playbook -i inventory/hosts.yml playbooks/node-exporter.yml -e "target=<hostname>"
```

If deploying to multiple containers:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/node-exporter.yml -e "target=<host1>,<host2>"
```

**Then add scrape target to `templates/prometheus.yml.j2`.**

Add under the `homelab-nodes` job, in the `# --- Applications ---` section (or appropriate section):

```yaml
      - targets:
          - '<VLAN20_PREFIX>.<XX>:9100'   # <service-name> (CT <VMID>)
        labels:
          service: '<service-name>'
          role: 'project'
          layer: 'app'
```

**Deploy updated Prometheus config and reload:**

The monitoring playbook doesn't have a config-only tag, so deploy the template directly:
```bash
cd projects/pai-infra/ansible
ansible monitoring -i inventory/hosts.yml -m template \
  -a "src=templates/prometheus.yml.j2 dest=/etc/prometheus/prometheus.yml owner=prometheus group=prometheus mode=0644"
ssh root@<MONITORING_IP> "systemctl reload prometheus"
```

**Verify target appears:**
```bash
curl -s http://<MONITORING_IP>:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.service == "<service-name>")'
```

## Step 10: Verification Checklist

Run all checks and report results:

```bash
# DNS
dig +short <subdomain>.your-domain.example @<PIHOLE_IP>

# Caddy proxy (may return 502 if app not running yet — that's OK, means Caddy route works)
curl -sI https://<subdomain>.your-domain.example 2>&1 | head -5

# SSH as user
ssh -o ConnectTimeout=5 user@<VLAN20_PREFIX>.<XX> "echo OK"

# SSH as service user
ssh -o ConnectTimeout=5 -i ~/.ssh/homelab/<service-name> <user>@<VLAN20_PREFIX>.<XX> "echo OK"

# Node exporter
curl -s http://<VLAN20_PREFIX>.<XX>:9100/metrics | head -3

# Container basics
ssh root@<VLAN20_PREFIX>.<XX> "timedatectl | head -1 && locale | head -1 && id <user>"
```

**Expected output summary:**
```
DNS:           <PROXY_IP> (Caddy proxy IP)
Caddy:         200 OK or 502 Bad Gateway (route exists, app not deployed yet)
SSH (user):    OK
SSH (service): OK
Node exporter: HELP/TYPE lines visible
Timezone:      America/New_York
Locale:        LANG=en_US.UTF-8
User:          uid=<UID>(<user>) gid=<GID>(<group>) groups=...
```

## Post-Deployment: Application Setup

The skill handles infrastructure only. Application deployment (installing the actual app,
systemd services, database setup, etc.) is a separate step done after this workflow completes.

**For systemd services**, use `references/systemd-service.service` as a template:
- Replace `{{SERVICE_NAME}}`, `{{PORT}}`, `{{WORKING_DIR}}`, `{{EXEC_START}}`
- Deploy to `/etc/systemd/system/<service>.service`
- Enable and start: `systemctl enable --now <service>`
