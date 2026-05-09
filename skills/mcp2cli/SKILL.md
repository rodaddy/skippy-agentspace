---
name: mcp2cli
description: MCP tool bridge CLI -- auth, RBAC, daemon management, web UI. USE WHEN invoking MCP tools via CLI, managing daemon auth/tokens, or using the web management UI.
triggers:
  - /mcp2cli
  - mcp2cli auth
  - daemon tokens
  - mcp2cli management
user-invocable: true
---

# mcp2cli -- MCP Tool Bridge

CLI bridge for invoking MCP server tools. Supports RBAC auth with tokens.json, web management UI, and remote daemon deployment.

## Quick Reference

- **Daemon:** mcp2cli container at `<MCP2CLI_IP>:9500` (see HOSTMAP.md for CT ID)
- **Config:** `/etc/mcp2cli/services.json` (daemon), `~/.config/mcp2cli/services.json` (local)
- **Tokens:** `~/.config/mcp2cli/tokens.json` (local), Vaultwarden `mcp2cli-token-*`
- **Web UI:** `http://<MCP2CLI_IP>:9500/`
- **Env file (daemon):** `/etc/mcp2cli/env`

## Common Commands

```bash
mcp2cli <service> <tool> --params '{}'     # invoke a tool
mcp2cli <service> --help                    # list tools for service
mcp2cli schema <service>.<tool>             # input schema
mcp2cli services                            # list configured services
mcp2cli grep "pattern"                      # search across services
mcp2cli <service> <tool> --format table     # human-readable output
mcp2cli generate-skills <service>           # regenerate skill files
```

## Auth Setup

### Token-based RBAC (tokens.json)

```json
{
  "tokens": [
    { "id": "admin", "token": "xxx", "role": "admin" },
    { "id": "skippy", "token": "yyy", "role": "agent" },
    { "id": "test01", "token": "zzz", "role": "viewer" }
  ]
}
```

**Roles:** admin (full), agent (tools + read), viewer (read-only). See `references/auth-rbac.md`.

### Legacy single-token

Set `MCP2CLI_AUTH_TOKEN` env var -- treated as admin. Falls back to this if no tokens.json.

## Web Management UI

Browse to `http://<MCP2CLI_IP>:9500/` -- login with your token. Admin role sees add/edit/remove/import controls. Agents and viewers see read-only dashboard.

## Gotchas

1. **CLI auth requires env var, not flag.** Set `MCP2CLI_AUTH_TOKEN=<token>` before `mcp2cli` commands. No `--token` CLI flag exists.
2. **Remote daemon needs DAEMON_URL.** Local CLI defaults to unix socket. For remote: `MCP2CLI_DAEMON_URL=http://<MCP2CLI_IP>:9500`
3. **Both env vars needed for remote auth:** `MCP2CLI_AUTH_TOKEN` AND `MCP2CLI_DAEMON_URL` must be set together.
4. **tokens.json permissions.** Must be `chmod 600` -- owner-only read/write. Contains secrets.
5. **Token precedence.** `tokens.json` wins over `MCP2CLI_AUTH_TOKEN` env var. If tokens.json exists, the env var is ignored.
6. **Web UI login uses sessionStorage.** Token survives page refresh but clears on tab close. No cookies.
7. **403 vs 401.** 401 = no/invalid token. 403 = valid token but insufficient role for the action.
8. **Service config changes require daemon restart** on the mcp2cli container (until Phase 5 code is deployed). Web UI hot-reload is new code.

## References

- `references/auth-rbac.md` -- Roles, permissions matrix, token config details
- `references/daemon-management.md` -- Web UI, API endpoints, deployment
- `references/cli-commands.md` -- Full command reference with examples

## Notes

- Tokens stored in Vaultwarden under `mcp2cli-token-*` prefix
- Current users: admin (admin), skippy (agent), test01 (viewer)
- Provider interface is pluggable -- OAuth/OIDC can replace TokenAuthProvider later
