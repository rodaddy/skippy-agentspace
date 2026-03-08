# Access Patterns Reference

Detailed examples and edge cases for vaultwarden-secrets MCP tools.

## Tool Decision Tree

```
Need a credential?
  |
  +-- Know the name? --> get_credential(query: "exact name")
  |     |
  |     +-- Need specific field? --> get_credential(query: "name", field: "login.username")
  |     +-- Just the password? --> get_secret("name")
  |
  +-- Know the service? --> get_service("prefix")
  |
  +-- Don't know the name? --> search_secrets("keyword")
```

## Common Patterns

### Single credential with all fields
```
get_credential(query: "My Service")
# Returns: name, username, password, URI, notes, custom fields
```

### Specific field extraction
```
get_credential(query: "My Service", field: "login.username")
# Returns: just the username
```

### All credentials for a service
```
get_service("myservice")
# Returns: every secret whose name starts with "myservice"
```

### Fuzzy search when unsure
```
search_secrets("partial name")
# Returns: matching names with confidence scores
```

## Edge Cases

- **Duplicate names:** `get_secret` returns the first match. Use more specific names.
- **Case sensitivity:** `get_secret` is case-sensitive. `search_secrets` is not.
- **Missing secrets:** If `get_secret` returns nothing, try `search_secrets` with partial name.
- **Custom fields:** Access via dot notation: `get_credential(query: "name", field: "custom.fieldname")`

## Anti-patterns

- **NEVER** chain search -> get_fields -> get_secret (3 calls when 1 will do)
- **NEVER** hardcode credentials in scripts
- **NEVER** echo secrets to terminal output
- **NEVER** store secrets in git-tracked files
