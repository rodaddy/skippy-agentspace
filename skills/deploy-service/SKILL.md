---
name: deploy-service
description: Deploy a new service to LXC with full infrastructure - LXC creation, dual NIC, base stack, Ansible inventory + playbooks, Caddy reverse proxy, DNS on primary Pi-hole, Ansible template updates. ALL steps are mandatory -- no step is optional.
allowed-tools: "Read,Write,Edit,Bash,Grep,Glob,Agent"
metadata:
  version: 2.1.0
  author: community
  category: domain
---

# Deploy Service - Ansible-First LXC Deployment

Orchestrates a complete service deployment through the existing Ansible infrastructure.
Does NOT use raw SSH for configuration — all host setup goes through Ansible playbooks.

## Infrastructure Context

| Component | Location |
|-----------|----------|
| Ansible root | `projects/pai-infra/ansible/` (relative to infrastructure repo) |
| Inventory | `inventory/hosts.yml` |
| Global vars | `inventory/group_vars/all.yml` |
| Caddy template | `templates/Caddyfile.j2` |
| Prometheus template | `templates/prometheus.yml.j2` |
| Pi-hole playbook | `playbooks/pihole.yml` (DNS entries in `custom.list` blockinfile) |
| Baseline playbook | `playbooks/lxc-baseline.yml` |
| Node exporter | `playbooks/node-exporter.yml` |
| Reverse proxy | `playbooks/reverse_proxy.yml` |
| Run command | `cd <ansible-root> && ansible-playbook -i inventory/hosts.yml playbooks/<name>.yml` |

| Infra Target | Value |
|-------------|-------|
| Domain | `your-domain.example` |
| VLAN 20 prefix | `<VLAN20_PREFIX>` (containers/services) |
| VLAN 1 prefix | `<VLAN1_PREFIX>` (management — only if dual NIC requested) |
| Gateway | `<GATEWAY_IP>` |
| DNS servers | Pi-hole primary (px03) + Pi-hole secondary (px02) — see HOSTMAP.md for IPs/CT IDs |
| Caddy proxy | Caddy reverse proxy container — see HOSTMAP.md for IP/CT ID |
| Shared template storage | `TN01_lxc_nvme` (NFS, visible from all nodes) |
| Default template | `TN01_lxc_nvme:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst` |

**Proxmox nodes:**

| Node | IP | CPU | RAM | Storage | Best For |
|------|-----|-----|-----|---------|----------|
| px01 | <PX01_IP> | Ryzen 7 8C/16T | 32GB DDR5 | LVM thin 816GB | Heavy — already most loaded |
| px02 | <PX02_IP> | i5 8C/12T | 32GB DDR4 | LVM thin 1.67TB | Medium workloads |
| px03 | <PX03_IP> | N95 4C/4T | 8GB | LVM thin 141GB | Light/DNS only — limited RAM |
| px04 | <PX04_IP> | Ryzen 7 8C/16T | 32GB DDR5 | ZFS ~1TB | Heavy workloads, fewer containers |

<HARD-GATE>
Do NOT create LXC containers, modify Ansible files, or update DNS until you have:
1. Run the PRE-FLIGHT CHECKS below
2. Presented the FULL deployment plan (service name, VMID, IPs, port, user, node, Caddy route, DNS entries, Prometheus target)
3. Listed ALL files that will be modified
4. Received explicit user confirmation to proceed
Infrastructure changes are hard to reverse. No exceptions.
</HARD-GATE>

## Pre-Flight Checks (MANDATORY before Step 1)

Run ALL of these before presenting the plan. Any failure = stop and resolve first.

```bash
# 1. Template exists on shared storage
ssh root@<NODE_IP> "pveam list TN01_lxc_nvme | grep debian-13"

# 2. pve-container supports Debian 13 (need >= 6.0.10)
ssh root@<NODE_IP> "dpkg -l pve-container | awk '/pve-container/{print \$3}'"

# 3. Node has capacity (check container count + resource usage)
ssh root@<NODE_IP> "pct list | wc -l && free -h | head -2"

# 4. Target VMID is free CLUSTER-WIDE (not just on target node)
for NODE in <PX01_IP> <PX02_IP> <PX03_IP> <PX04_IP>; do
  ssh root@$NODE "pct list 2>/dev/null" | grep "^<VMID> " && echo "CONFLICT on $NODE"
done

# 5. Target IP is free
ping -c1 -W1 <VLAN20_PREFIX>.<XX> && echo "IP IN USE" || echo "IP FREE"

# 6. Storage has space on target node
ssh root@<NODE_IP> "pvesm status -storage local-lvm"
```

## Parameters (from natural language)

| Parameter | Required | Default | Example |
|-----------|----------|---------|---------|
| Service name | Yes | - | `vault`, `myapp` |
| Port | Yes | - | `3000`, `8080` |
| Proxmox node | Ask user | - | `proxmox04` |
| RAM (MB) | No | 512 | `4096` |
| Disk (GB) | No | 4 | `16` |
| Cores | No | 2 | `4` |
| Service user | No | service name | `bulk` |
| User UID | No | next available 2xxx | `2023` |
| User primary group | No | `collab` | `trading` |
| User extra groups | No | `database,builds` | `ai-services,builds` |
| Dual NIC | No | Single (VLAN 20 only) | `dual` for both VLANs |
| Instance count | No | 1 | `2` for prod+UAT |

### Multi-Instance Pattern (prod + UAT)

When user requests two instances (extremely common), create both in one flow:
- Same specs, same user, separate VMIDs/IPs
- Convention: `<name>-prod` and `<name>-uat` subdomains
- Steps 2-9 apply to BOTH — don't do one container then the other,
  batch each step across both containers.

## Deployment Workflow (10 Steps — ALL MANDATORY)

Every step below is required. Skipping any step produces an incomplete deployment.
See `references/deploy-workflow.md` for exact file patterns and commands.

### Step 1: Plan
- Run pre-flight checks
- Scan `inventory/hosts.yml` for existing IPs and VMIDs to find next available
- Check container counts per node to recommend the least-loaded node
- Ask user which node (present load data, don't assume)
- Check if service user already exists in `group_vars/all.yml`
- Present full plan to user, get confirmation

### Step 2: Create LXC
- SSH to Proxmox node, run `pct create` (see workflow.md for exact command)
- Start the container
- **CRITICAL: Bootstrap root SSH key via `pct exec`** — fresh containers have NO
  SSH keys. Ansible cannot reach them until this is done:
  ```bash
  PUBKEY="$(cat ~/.ssh/id_rsa.pub)"
  ssh root@<NODE_IP> "pct exec <VMID> -- mkdir -p /root/.ssh && \
    pct exec <VMID> -- chmod 700 /root/.ssh && \
    echo '$PUBKEY' | pct exec <VMID> -- tee /root/.ssh/authorized_keys > /dev/null && \
    pct exec <VMID> -- chmod 600 /root/.ssh/authorized_keys"
  ```
- **Clear stale known_hosts entries** (critical when recreating containers):
  ```bash
  ssh-keygen -R <VLAN20_PREFIX>.<XX>
  ```
- Verify SSH connectivity:
  ```bash
  ssh -o StrictHostKeyChecking=accept-new root@<VLAN20_PREFIX>.<XX> "hostname"
  ```

### Step 3: Add to Ansible Inventory
- Add host entry to `inventory/hosts.yml` under the appropriate group
- Include: `ansible_host`, `app_subdomain`, and `vlan1_ip` if dual-NIC
- Use underscores in inventory hostname, hyphens in `app_subdomain`

### Step 4: Add Service User (if new)
- Add group to `homelab_groups` in `group_vars/all.yml` if needed
- Add user to `homelab_users` in `group_vars/all.yml` if not already there
- User UID convention: 2xxx for service users, 3xxx for human/collab users

### Step 5: Run lxc-baseline.yml
- `ansible-playbook -i inventory/hosts.yml playbooks/lxc-baseline.yml --limit <hostname>`
- This handles: apt update + dist-upgrade, timezone, locale, journald, tools
  (vim/btop/curl/jq/zsh/tree), sudo, all homelab users/groups, user SSH +
  passwordless sudo, unattended-upgrades
- Verify after: `ssh user@<IP>` works, `sudo` works, timezone is America/New_York

### Step 6: Service User SSH Keys
- Check if keypair exists: `ls ~/.ssh/homelab/<service-name>*`
- Generate if missing: `ssh-keygen -t ed25519 -f ~/.ssh/homelab/<service-name> -N "" -C "<service-name>@homelab"`
- Deploy public key + .ssh dir + sudoers.d entry to container
- Verify: `ssh -i ~/.ssh/homelab/<service-name> <user>@<IP> "sudo whoami"`

### Step 7: Caddy Reverse Proxy
- Add route block to `templates/Caddyfile.j2`
- Deploy: `ansible-playbook -i inventory/hosts.yml playbooks/reverse_proxy.yml`
- **NOTE:** This playbook needs `cloudflare_tunnel_token` vault var. If unavailable,
  commit the Caddyfile.j2 change and note it needs deploying when vault is available.
  The Caddy config may already be live from a prior deployment.

### Step 8: DNS
- Add entries to the `blockinfile` block in `playbooks/pihole.yml`
- All entries point to `<PROXY_IP>` (Caddy proxy), NOT the backend IP
- Deploy: `ansible-playbook -i inventory/hosts.yml playbooks/pihole.yml`
- **NOTE:** This playbook needs `lxc_root_password` vault var. Same caveat as Step 7.

### Step 9: Prometheus Monitoring
- Deploy node-exporter: `ansible-playbook -i inventory/hosts.yml playbooks/node-exporter.yml -e "target=<hostname>"`
- **IMPORTANT:** Must use `-e "target=<hostname>"` — the default target is `second_brain`,
  which does NOT include `apps` group. Without this flag the playbook silently does nothing.
- Add scrape target to `templates/prometheus.yml.j2`
- Deploy config: `ansible monitoring -i inventory/hosts.yml -m template -a "src=templates/prometheus.yml.j2 dest=/etc/prometheus/prometheus.yml owner=prometheus group=prometheus mode=0644"`
- Reload: `ssh root@<MONITORING_IP> "systemctl reload prometheus"`

### Step 10: Verify
Run ALL checks, report as a table. Every row must pass.

```bash
# DNS
dig +short <subdomain>.your-domain.example @<PIHOLE_IP>

# Caddy (502 = route works, app not deployed yet — this is OK)
curl -sI https://<subdomain>.your-domain.example 2>&1 | head -3

# SSH as user
ssh -o ConnectTimeout=5 user@<VLAN20_PREFIX>.<XX> "echo OK && sudo whoami"

# SSH as service user
ssh -o ConnectTimeout=5 -i ~/.ssh/homelab/<service-name> <user>@<VLAN20_PREFIX>.<XX> "echo OK && sudo whoami"

# Node exporter
curl -s http://<VLAN20_PREFIX>.<XX>:9100/metrics | head -1

# Container basics
ssh root@<VLAN20_PREFIX>.<XX> "cat /etc/debian_version && timedatectl | head -1 && locale | head -1 && id <user> && which vim btop zsh jq curl"
```

Present results as:

| Check | Expected | Actual |
|-------|----------|--------|
| DNS | <PROXY_IP> | |
| Caddy | 200 or 502 | |
| SSH (user) | OK + root | |
| SSH (service) | OK + root | |
| Node exporter | metrics flowing | |
| Debian | 13.x | |
| Timezone | EDT/EST | |
| Locale | en_US.UTF-8 | |
| User ID | correct UID/groups | |
| Tools | all present | |

## Gotchas

### Fresh LXC has NO SSH keys
This is the #1 deployment blocker. After `pct create`, the container has no authorized_keys.
You MUST deploy root's SSH key via `pct exec` on the Proxmox node before Ansible can reach it.
Step 2 documents the exact commands. Do NOT skip this.

### known_hosts stale entries
When recreating a container at the same IP, SSH will reject the connection due to changed host
keys. Run `ssh-keygen -R <IP>` BEFORE attempting SSH. Use `StrictHostKeyChecking=accept-new`.

### Caddy — NOT nginx
The reverse proxy is Caddy with Cloudflare DNS ACME, NOT nginx. The Caddyfile template
is Ansible-managed. Never edit the Caddyfile directly on the Caddy container — it will be overwritten.
Run `/hostmap` or check `infrastructure/HOSTMAP.md` for the Caddy container ID and IP.

### Pi-hole DNS — Ansible-managed custom.list
DNS entries are in the `blockinfile` block in `playbooks/pihole.yml`, NOT edited directly
on Pi-hole containers. All entries point to `<PROXY_IP>` (Caddy proxy IP).

### lxc-baseline.yml is NON-NEGOTIABLE
Every container MUST have lxc-baseline run. It installs sudo, creates user with passwordless
sudo and SSH key, sets timezone/locale, installs standard tools, runs dist-upgrade.
Without it, the container is an unconfigured Debian shell with root-only SSH.

### node-exporter silently skips non-default targets
The playbook defaults to `hosts: second_brain`. Containers in `apps`, `trading`, `agents`,
etc. are silently skipped. ALWAYS use `-e "target=<hostname>"` for non-second_brain hosts.

### Vault secrets for Caddy and DNS playbooks
`reverse_proxy.yml` requires `cloudflare_tunnel_token`. `pihole.yml` requires
`lxc_root_password`. If these aren't available, commit the template/playbook changes and
note they need deploying. The Caddy config may already be live from a prior deploy.

### Storage per node
- px01, px02, px03: `local-lvm` (LVM thin)
- px04: `tank-nvme` (ZFS) — use `tank-nvme` in pct create `--rootfs` flag
All nodes: `TN01_lxc_nvme` for templates (NFS shared)

### Debian 13 requires pve-container 6.0.10+
Debian 13 (Trixie) containers fail to start with "unsupported debian version" if the
Proxmox `pve-container` package is older than 6.0.10. Pre-flight check #2 catches this.

### Cloned LXC = duplicate MAC
If using `pct clone`, the MAC address is copied. MUST regenerate: `pct set <vmid> -net0 ...`
(omit hwaddr). Duplicate MACs cause ARP conflicts.

### VMID conventions
- 100-199: Legacy/infrastructure
- 200-299: Second Brain + apps
- 300-399: Projects/trading

## References

- `references/deploy-workflow.md` — Exact file modification patterns and commands
- `references/systemd-service.service` — systemd unit file template (for app services)
