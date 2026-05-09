<!-- Extracted from SKILL.md -- load on demand -->

# Daemon Management Reference

## Deployment

- **Container:** mcp2cli LXC on Proxmox (see HOSTMAP.md for CT ID)
- **IP:** <MCP2CLI_IP>
- **Port:** 9500
- **User:** `mcp2cli` (service account)
- **Binary:** `/usr/local/bin/mcp2cli`
- **Service:** `systemctl status mcp2cli-daemon`
- **Env file:** `/etc/mcp2cli/env`
- **Config:** `/etc/mcp2cli/services.json`

## Web Management UI

**URL:** `http://<MCP2CLI_IP>:9500/`

Features:
- Service dashboard with connection status (green/gray dots)
- Add/edit/delete services (admin only)
- Import from URL or GitHub repo
- Reload config from disk
- Live polling (5s refresh)
- Token-based login (sessionStorage)
- Role-aware controls (non-admin users see read-only view)

## API Endpoints

### Auth-exempt (no token needed)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Web UI HTML |
| GET | `/health` | Health check + memory stats |
| GET | `/metrics` | Prometheus metrics |

### Tool endpoints (agent+ role)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/call` | Invoke a tool `{ service, tool, params }` |
| POST | `/list-tools` | List tools for service `{ service }` |
| POST | `/schema` | Get tool schema `{ service, tool }` |

### Management API (mixed roles)

| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | `/api/services` | viewer+ | List all services with connection status |
| GET | `/api/services/:name/status` | viewer+ | Service health + tool count |
| GET | `/api/auth/me` | any authed | Current user identity and role |
| POST | `/api/services` | admin | Add service `{ name, config }` |
| PUT | `/api/services/:name` | admin | Update service `{ config }` |
| DELETE | `/api/services/:name` | admin | Remove and disconnect service |
| POST | `/api/services/reload` | admin | Reload config from disk |
| POST | `/api/services/import` | admin | Import from URL (see below) |
| POST | `/shutdown` | admin | Graceful shutdown |

### Import API

```bash
# Direct URL
curl -X POST http://<MCP2CLI_IP>:9500/api/services/import \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://raw.githubusercontent.com/user/repo/main/services.json", "mode": "merge"}'

# GitHub shorthand
curl -X POST http://<MCP2CLI_IP>:9500/api/services/import \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"repo": "user/repo", "branch": "main", "path": "services.json", "mode": "merge"}'
```

**Modes:**
- `merge` (default) -- add new services, update existing, keep unlisted
- `replace` -- full replacement of all services

## Config Manager

Runtime CRUD with disk persistence. Changes are:
1. Validated via Zod schema
2. Written to disk immediately
3. Existing connections closed for updated/removed services
4. Pool lazily reconnects on next request with new config

## Systemd Service

```ini
[Service]
Type=simple
User=mcp2cli
Group=mcp2cli
EnvironmentFile=/etc/mcp2cli/env
ExecStart=/usr/local/bin/mcp2cli
Restart=on-failure
RestartSec=5
```

Key env vars in `/etc/mcp2cli/env`:
- `MCP2CLI_DAEMON=1` -- enable daemon mode
- `MCP2CLI_LISTEN_HOST=0.0.0.0` / `MCP2CLI_LISTEN_PORT=9500`
- `MCP2CLI_AUTH_TOKEN=<token>` -- legacy auth (will be replaced by tokens.json)
- `MCP2CLI_CONFIG=/etc/mcp2cli/services.json`
- `MCP2CLI_POOL_MAX=50`
- `MCP2CLI_TOOL_TIMEOUT=30000`
