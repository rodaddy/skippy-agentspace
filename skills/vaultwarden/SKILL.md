---
name: vaultwarden
description: Fast credential lookup via vaultwarden-secrets MCP. One call, not three.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
  category: utility
---

# Vaultwarden Secrets Management

Fast credential access via vaultwarden-secrets MCP. One call, not three.

## Quick Reference

- **MCP server:** `vaultwarden-secrets`
- **NEVER** do: search -> get_fields -> get_secret (3 round trips)
- **ALWAYS** do: `get_secret("name")` or `get_service("prefix")` (1 call)

## Workflow

### Step 1: Identify What You Need

Determine the service/credential needed from the user's request context.

### Step 2: Direct Access (ONE call)

Pick the right tool based on what you know:

| You Know | Tool | Example |
|----------|------|---------|
| Anything (DEFAULT) | `get_credential` | `get_credential(query: "service name")` |
| Need specific field | `get_credential` (with field) | `get_credential(query: "service", field: "login.username")` |
| Service name, want everything | `get_service` | `get_service("service-prefix")` |
| Exact name, just the password | `get_secret` | `get_secret("service name")` |

### Step 3: Use the Value

Pass the retrieved value to wherever it's needed. Never echo secrets to terminal output.

## Access Patterns

### Smart Lookup (preferred -- 1 call, handles everything)
```
get_credential(query: "service name")                          # exact match, returns value + all fields
get_credential(query: "service", field: "login.password")      # fuzzy match, specific field
```

### Direct Get (when you only need the password)
```
get_secret("Service Name")           # returns password only
get_secret("service.login.password") # dot notation for specific field
```

### Service Group (1 call for everything)
```
get_service("prefix")       # ALL secrets matching prefix
```

### Search (last resort -- only when you don't know the name)
```
search_secrets("keyword")  # fuzzy match, returns names + scores
```

### Create/Update
```
create_secret(name: "New Service", type: 1, username: "user", password: "pass")
update_secret(name: "Existing", password: "new-pass")
```

## Gotchas

- `get_secret` returns the password/main value. Use dot notation for other fields.
- `get_service` matches by prefix -- "n8n" gets all n8n-related secrets.
- Secret names are case-sensitive for `get_secret`, case-insensitive for `search`.
- Create/update/delete only work on secrets in the configured folder.
- `list_secrets` with filter is like search but returns all matches -- use for browsing.

## References

- `references/common-secrets.md` -- Known secret names grouped by service
- `references/access-patterns.md` -- Detailed examples and edge cases

## Notes

- This skill exists because the 3-call pattern (search -> fields -> get) wastes tokens and time.
- `get_credential` is the default -- exact match + fuzzy fallback + all fields in one call.
- When in doubt, `get_credential("name")` for one secret, `get_service("prefix")` for a whole service.
- If a secret doesn't exist yet, use `create_secret` -- don't ask the user to create it manually.

> **PAI enhancements available:** When installed in PAI, references/common-secrets.md contains your actual secret names grouped by service.
