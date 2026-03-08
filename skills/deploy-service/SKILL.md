---
name: deploy-service
description: Deploy a new service to LXC with nginx proxy and DNS setup. Automates container creation, networking, base packages, reverse proxy, and DNS.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: domain
---

# Deploy Service - Automated LXC + Proxy + DNS Setup

Automates the complete deployment of a new service to an LXC container.

## What It Does

1. **Finds next available IP** - Scans networks for next free matching IP
2. **Creates LXC** - Debian 12, dual NICs, configurable RAM/disk
3. **Installs base stack** - curl, wget, unzip, ca-certificates, bun runtime
4. **Configures nginx proxy** - Adds reverse proxy config with SSL
5. **Updates DNS** - Adds entries to all DNS servers (auto-discovers them)
6. **Optional: Deploys service** - If tarball provided, extracts and sets up systemd

## Usage

**Minimal (just infrastructure):**
```
deploy service vault on port 3000
```

**With tarball:**
```
deploy service myapp on port 8080 with tarball /path/to/myapp.tar.gz
```

**Custom specs:**
```
deploy service bigapp on port 9000 with 2GB ram and 10GB disk
```

## Parameters (extracted from natural language)

- **Service name** - Becomes subdomain (e.g., "vault" -> vault.${DEPLOY_DOMAIN})
- **Port** - Backend port the service listens on
- **Tarball** (optional) - Path to service tarball
- **RAM** (optional) - Default: 512MB
- **Disk** (optional) - Default: 2GB
- **Systemd service** (optional) - If provided, creates systemd unit

## What You Get

- LXC created and running
- Service accessible at `https://<name>.${DEPLOY_DOMAIN}`
- DNS resolving from all DNS servers
- nginx reverse proxy with SSL configured
- systemd service (if configured)

## Configuration Required

Before using this skill, set up your environment config:

1. Copy `config.env.example` to `config.env`
2. Fill in all `DEPLOY_*` variables with your infrastructure values
3. `config.env` is gitignored -- your real values stay local

See `config.env.example` for the full variable list with descriptions.

## References

- `references/deploy-workflow.md` -- Full step-by-step deployment workflow
- `references/nginx-proxy.conf` -- nginx reverse proxy config template
- `references/systemd-service.service` -- systemd unit file template
- `scripts/find-next-ip.sh` -- IP discovery helper script
- `scripts/install-base-stack.sh` -- Base packages installer script

> **PAI enhancements available:** In PAI installations, config.env is pre-populated with actual infrastructure values.
