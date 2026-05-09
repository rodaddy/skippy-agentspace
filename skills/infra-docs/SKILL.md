---
name: infra-docs
description: Update service documentation when infrastructure configs change. Ensures service READMEs stay current alongside config modifications.
triggers:
  - /infra-docs
  - update service docs
  - sync service docs
  - update docs for
---

# Infra Docs - Service Documentation Updater

Keep service READMEs current when configs change. Triggered manually or suggested by the post-infra-doc-reminder hook after SSH modifications.

## When to Use

- After modifying a service config (ports, paths, dependencies)
- After upgrading a service
- After discovering a new gotcha
- When the reminder hook flags a stale README

## Workflow

### Step 1: Identify the Service

Determine which service(s) need doc updates from:
- The user's request (e.g., "update docs for vaultwarden")
- Recent SSH activity (which container was modified)
- File path context (e.g., editing `services/litellm/config.yaml`)

Map to the service directory:

> Container IDs and IPs are environment-specific. Run `/hostmap` or check `infrastructure/HOSTMAP.md` for your deployment.

| Service | Directory |
|---------|-----------|
| Caddy | `services/caddy/` |
| PostgreSQL | `services/postgresql/` |
| Grafana | `services/grafana/` |
| Prometheus | `services/prometheus/` |
| n8n | `services/n8n/` |
| SiYuan | `services/siyuan/` |
| LiteLLM | `services/litellm/` |
| Sonarr | `services/sonarr/` |
| Radarr | `services/radarr/` |
| Lidarr | `services/lidarr/` |
| Prowlarr | `services/prowlarr/` |
| Plex | `services/plex/` |
| qBittorrent | `services/qbittorrent/` |
| Pi-hole | `services/pihole/` |
| Homebridge | `services/homebridge/` |
| Vaultwarden | `services/vaultwarden/` |
| PBS | `services/pbs/` |

### Step 2: Read Current README

```
Read("services/<service>/README.md")
```

If no README exists, use `services/TEMPLATE.md` as the starting point.

### Step 3: Gather Fresh State (if needed)

If the change affects ports, paths, versions, or dependencies, SSH to verify:

```bash
ssh root@<ip> "systemctl status <service> && ss -tlnp | grep <port>"
```

### Step 4: Update the README

Edit only the sections affected by the change:
- **Config change** -- update "Config files" and possibly "Gotchas"
- **Port change** -- update header IP:Port, "How It Works", and "Gotchas"
- **Version upgrade** -- update "How It Works" (version), add upgrade notes to "Update/Upgrade Procedure"
- **New gotcha** -- append to "Gotchas" section
- **Credential change** -- update "Credentials" section (entry name only, never values)

### Step 5: Validate Structure

Ensure the README still has all required sections:
- Header block (Container, IP, SSH, Reverse Proxy)
- How It Works
- Update/Upgrade Procedure
- Gotchas
- Credentials

### Step 6: Stage for Commit

Tell the user the doc is updated and should be committed alongside the config change:

```
Doc updated: services/<service>/README.md
Commit this alongside your config changes.
```

## Template Reference

See `services/TEMPLATE.md` for the standard README structure.

## Error Handling

| Issue | Action |
|-------|--------|
| README doesn't exist | Create from TEMPLATE.md, fill what's known |
| SSH fails | Update from known context, mark uncertain fields as "TBD - verify via SSH" |
| Service not in mapping | Ask user for container info, create new entry |
