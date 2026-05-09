---
name: remove-service
description: Remove a deployed service - cleans up nginx proxy, DNS entries, optionally LXC. Reverses what deploy-service does.
trigger_keywords: ["remove service", "delete service", "cleanup service"]
---

# Remove Service - Clean Up Deployed Service

Reverses the `deploy-service` skill by removing all traces of a deployed service.

## What it does:

1. **Removes nginx proxy config** - Deletes config from LXC 205, reloads nginx
2. **Removes DNS entries** - Removes from ALL piholes (auto-discovers them)
3. **Optionally destroys LXC** - If requested, stops and deletes the LXC container

## Usage:

**Remove proxy + DNS only (keep LXC):**
```
remove service testdeploy
```

**Remove everything including LXC:**
```
remove service testdeploy and destroy lxc
```

**Specify LXC VMID:**
```
remove service testdeploy lxc 214
```

## What it cleans up:

- ✅ nginx config in `/etc/nginx/sites-available/` and `/etc/nginx/sites-enabled/`
- ✅ DNS entries in all piholes' `/etc/pihole/custom.list`
- ✅ Optionally: LXC container (stops, destroys, removes disk)

## Examples:

```
User: "remove service testdeploy"
Result: Removes nginx + DNS, LXC untouched
```

```
User: "remove service api and destroy lxc 215"
Result: Removes nginx + DNS + destroys LXC 215
```
