---
name: vaultwarden-secrets
description: Vaultwarden secret management via MCP. USE WHEN needing credentials, API keys, passwords, tokens, or any secret. Also handles snapshot refresh, creating, updating, and deleting secrets.
---

# Vaultwarden Secrets

**Always available** via MCP (`mcp_servers.json`). No skill loading needed — tools are present in every session.

## Triggers

- "get password", "get credentials", "get secret"
- "API key for", "token for"
- "what's the login for"
- "vault", "vaultwarden", "bitwarden"
- "snapshot stale", "secrets not found", "can't find credential"
- "add secret", "create credential", "store password"

## Available MCP Tools

### Read Tools
| Tool | Purpose | Use When |
|------|---------|----------|
| `search_secrets` | Fuzzy name search | You know part of the name |
| `get_secret` | Get password/value by name | You need the primary credential |
| `get_secret_fields` | Get ALL fields (user, pass, uri, notes) | You need full login details |
| `list_secrets` | List all secrets with optional filter | Browsing or filtering by substring |
| `snapshot_info` | Check snapshot age and staleness | Troubleshooting missing secrets |

### Write Tools (Infrastructure folder only)
| Tool | Purpose | Confirmation |
|------|---------|-------------|
| `refresh_snapshot` | Force snapshot refresh from live vault | No |
| `create_secret` | Create a new secret (auto-scoped to Infrastructure) | No |
| `update_secret` | Update an existing secret | **Yes (destructiveHint)** |
| `delete_secret` | Delete a secret | **Yes (destructiveHint)** |

## Lookup Workflow

**Standard credential lookup:**
1. `search_secrets("service name")` — find the exact entry name
2. `get_secret_fields("exact name")` — get all fields (username, password, URI, notes)

**When a secret isn't found:**
1. `snapshot_info` — check if snapshot is stale
2. If stale: `refresh_snapshot` — triggers a live vault sync
3. Retry the search after refresh

## Folder Scoping

**All MCP access is restricted to the Infrastructure folder.** Secrets outside this folder are invisible to MCP clients. New secrets created via `create_secret` are automatically placed in Infrastructure. This is controlled by the `SECURITY_PROFILE` setting (`im-aware` profile).

## Important Notes

- **Snapshot-based:** Read data comes from a cached export, refreshed every 15 minutes by systemd timer on LXC 214.
- **Write ops are live:** `create_secret`, `update_secret`, `delete_secret` hit the BW CLI directly, then auto-refresh the snapshot.
- **Notes field:** Some entries store extra data (API tokens, token IDs) in the `notes` field — always use `get_secret_fields` to see everything.
- **Duplicates exist:** Some service names appear multiple times (different accounts). Use `search_secrets` first to see all matches.

## Architecture

- **Server:** LXC 214 / <YOUR_IP>
- **REST API:** port 3000 (Hono)
- **MCP endpoint:** port 3001 (`/mcp`, Streamable HTTP transport)
- **Auth:** Bearer token per client
- **Profile:** `im-aware` (writes enabled, destructive confirmation required, Infrastructure folder scoped)
- **Snapshot refresh:** systemd timer every 15 min (`vw-snapshot.timer`)
- **Session refresh:** systemd timer every 15 min (`vw-session-refresh.timer`)
- **Source code:** `<DEV_DIR>/vaultwarden-secrets/`

## Examples

**Get Proxmox credentials:**
```
search_secrets("proxmox01")
→ get_secret_fields("proxmox01")
→ { username, password, uri, notes (contains API token) }
```

**Create a new secret:**
```
create_secret(name: "my-new-service", username: "admin", password: "s3cret", uri: "https://service.local")
→ { created: true, id: "...", name: "my-new-service" }
```

**Update a secret's password:**
```
update_secret(name: "my-new-service", password: "new-password")
→ { updated: true, id: "...", name: "my-new-service" }
```

**Troubleshoot missing secret:**
```
snapshot_info → { isStale: true, createdAt: "2026-02-08..." }
→ refresh_snapshot
→ { refreshed: true, itemCount: 1065, isStale: false }
→ Retry search
```
