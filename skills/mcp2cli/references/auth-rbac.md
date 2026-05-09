<!-- Extracted from SKILL.md -- load on demand -->

# Auth & RBAC Reference

## Architecture

```
Request --> isAuthExempt? --> AuthProvider.authenticate() --> AuthContext --> checkPermission() --> Route
               |                     |                          |
           /, /health,         TokenAuthProvider            { userId, role }
           /metrics              (pluggable)
```

The `AuthProvider` interface is designed for swap-in replacement. Current: `TokenAuthProvider`. Future: OAuth/OIDC provider behind the same interface.

## Roles & Permissions

| Permission | admin | agent | viewer |
|-----------|-------|-------|--------|
| List services | Yes | Yes | Yes |
| Service status | Yes | Yes | Yes |
| Call tools | Yes | Yes | -- |
| List tools / schema | Yes | Yes | -- |
| Add service | Yes | -- | -- |
| Update service | Yes | -- | -- |
| Remove service | Yes | -- | -- |
| Import from URL | Yes | -- | -- |
| Reload config | Yes | -- | -- |
| Shutdown daemon | Yes | -- | -- |

## Token Config File

**Path:** `~/.config/mcp2cli/tokens.json` (local) or `MCP2CLI_TOKENS_FILE` env override.

```json
{
  "tokens": [
    {
      "id": "admin",
      "token": "N/sJ7AgXbNsaXQ+...",
      "role": "admin",
      "description": "Admin - full admin access"
    },
    {
      "id": "skippy",
      "token": "Qr1K24819DzADz...",
      "role": "agent",
      "description": "Skippy - agent access"
    },
    {
      "id": "test01",
      "token": "D9Y/r7vzmtn2fw...",
      "role": "viewer",
      "description": "Test user - read-only"
    }
  ]
}
```

**Validation rules:**
- Each entry must have `id` (string), `token` (string), `role` (admin|agent|viewer)
- `description` is optional
- No duplicate `id` values
- No duplicate `token` values
- File permissions should be `600`

## Auth Precedence

1. `tokens.json` (if exists) -- multi-user RBAC
2. `MCP2CLI_AUTH_TOKEN` env var -- legacy single admin token
3. No auth -- all requests treated as admin (development only)

## Auth-Exempt Paths

| Path | Why |
|------|-----|
| `/` | UI HTML shell (login form handles auth client-side) |
| `/health` | Load balancer probes |
| `/metrics` | Prometheus scraping |

All other paths (`/call`, `/api/*`, `/shutdown`, etc.) require bearer token.

## HTTP Auth Header

```
Authorization: Bearer <token>
```

Timing-safe comparison used for all token validation. Checks against ALL configured tokens to prevent timing leaks.

## Error Responses

| Status | Meaning |
|--------|---------|
| 401 | No token, invalid token, or malformed Authorization header |
| 403 | Valid token but insufficient role for the requested action |

## Vaultwarden Secrets

Tokens are stored in Vaultwarden with prefix `mcp2cli-token-`:
- `mcp2cli-token-admin` (admin)
- `mcp2cli-token-skippy` (agent)
- `mcp2cli-token-test01` (viewer)

## Future: OAuth/OIDC

The `AuthProvider` interface supports drop-in replacement:

```typescript
interface AuthProvider {
  authenticate(req: Request): AuthContext | null;
  readonly enabled: boolean;
}
```

An `OAuthAuthProvider` would implement the same interface, extracting `AuthContext` from OAuth tokens instead of bearer tokens. Route handlers and permission checks remain unchanged.
