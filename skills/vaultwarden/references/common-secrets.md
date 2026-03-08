# Common Secrets Reference

Organize your vault secrets by service for quick access with `get_service()`.

## Service Groups

| Service Prefix | What It Contains | Example Call |
|----------------|-----------------|--------------|
| `<your-service>` | Login credentials | `get_service("<your-service>")` |
| `github` | API tokens, SSH keys | `get_service("github")` |
| `docker` | Registry credentials | `get_service("docker")` |

## Naming Convention

Use descriptive names that work with prefix matching:
- `ServiceName - purpose` (e.g., "GitHub - PAT", "Docker - Registry")
- Keep service prefix consistent across related secrets

## Adding Your Secrets

1. Create secrets in your Vaultwarden instance
2. Use consistent naming with service prefixes
3. Update this file with your service groups

> **PAI enhancements available:** In PAI installations, this file contains the actual secret inventory.
