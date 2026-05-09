---
name: homeassistant
description: Home Assistant & HomeMCPBridge operations -- server access, HomeKit bridge config, registry edits, deploy workflow, entity conventions, and gotchas. USE WHEN working with HA config, HomeKit filtering, MCP tools, entities, or troubleshooting HA/HomeKit issues.
triggers:
  - /homeassistant
  - /ha
  - home assistant
  - homekit bridge
  - ha config
user-invocable: true
---

# Home Assistant & HomeMCPBridge Operations

Quick-reference for all HA operations. Prevents reverse-engineering the setup every session.

## Quick Reference

| Item | Value |
|------|-------|
| **HA VM** | Proxmox VM 103, HAOS, `<HA_IP>` |
| **SSH** | `root@<HA_IP>` |
| **HA URL** | `http://<HA_IP>:8123` |
| **HomeKit Bridge** | Port 21064, entry ID `<ENTRY_ID>` |
| **HomeMCPBridge** | HTTP `127.0.0.1:9234`, app at `/Applications/HomeMCPBridge.app` |
| **Dev repo** | `<DEV_DIR>/HomeAssistant/` |
| **Deploy repo** | `<DEV_DIR>/home-assistant-config/` |
| **No Python on HAOS** | Use jq/shell only for server-side edits |

## Common Operations

```bash
# Restart / Stop / Start
ssh root@<HA_IP> 'ha core restart'
ssh root@<HA_IP> 'ha core stop'
ssh root@<HA_IP> 'ha core start'

# View logs (log file may be empty -- use this instead)
ssh root@<HA_IP> 'ha logs follow'

# Find entities by pattern
ssh root@<HA_IP> 'cat /config/.storage/core.entity_registry | jq -r ".data.entities[] | select(.entity_id | test(\"PATTERN\")) | {entity_id, platform, disabled_by}"'

# Check HomeKit bridge config
ssh root@<HA_IP> 'cat /config/.storage/core.config_entries | jq ".data.entries[] | select(.domain==\"homekit\")"'

# Validate config locally
cd <DEV_DIR>/HomeAssistant && uv run ha-manager validate

# Deploy (validate + sync + commit + push -- THE proper way)
cd <DEV_DIR>/HomeAssistant && uv run ha-manager deploy "commit message"

# Deploy options
uv run ha-manager deploy "message" --skip-validate   # skip validation (not recommended)
uv run ha-manager deploy "message" --sync-only        # sync files only, no commit/push
```

## Deploy SOP (CRITICAL -- ALWAYS follow this)

**Before ANY deploy (SCP, ha-manager, etc.), run MD5 checks on both sides:**

```bash
# 1. Hash local files you're about to deploy
md5 -q <DEV_DIR>/HomeAssistant/config/<file1> <file2> ...

# 2. Hash same files on HA server
ssh root@<HA_IP> 'md5sum /config/<file1> /config/<file2> ...'

# 3. Compare -- only deploy files that actually differ
# 4. After SCP, re-hash server files to confirm transfer
ssh root@<HA_IP> 'md5sum /config/<file1> /config/<file2> ...'
```

This prevents: blind overwrites, deploying unchanged files, missing failed transfers. **No exceptions.**

## Registry Edit Process (CRITICAL)

HA overwrites `.storage/` on shutdown. **MUST stop core first.**

```bash
ssh root@<HA_IP> 'ha core stop'
# Backup, edit with jq, then:
ssh root@<HA_IP> 'ha core start'
```

See **references/registry-and-homekit.md** for full process, HomeKit filter modification, and .storage file reference.

## Entity Conventions

**Pattern:** `domain.room_device_qualifier`
**Person:** `person.your_name` (NOT `person.short_name`)
**eMotion Ultra:** `binary_sensor.lnlinkha_*` (NOT `emotion_ultra_*`)
**FP300:** `sensor.presence_multi_sensor_fp300_*` (Matter device)
**Areas (7):** Office, Living Room, Kitchen, Main Bedroom, Entry Way, Family Room, Laundry Room

See **references/entities-and-scenes.md** for full entity list and scene inventory.

## Gotchas

1. **NEVER add `sensor` domain to HomeKit bridge.** Was exposing ~100 sensors (eMotion zones, smart plug power, weather, phone batteries, FP300 environmental, Mac sensors) -- all firing constantly. Killed Apple Watch battery. Removed 2026-02-28. Include domains should be: light, media_player, switch, vacuum, scene ONLY.
2. **No Python on HAOS.** Use jq for JSON edits. No pip, no python3.
3. **person.your_name** not `person.short_name`. Automations silently fail with wrong entity.
4. **eMotion Ultra** uses `lnlinkha_*` prefix, not `emotion_ultra_*`.
5. **HA log file may be 0 bytes.** Use `ha logs follow` instead of reading the file.
6. **HomeMCPBridge has no throttling.** Every state change propagates immediately.
7. **Scenes are snapshots, not layers.** Every entity listed gets overwritten. To make a scene composable (layer on top of another), only include the entities it needs to change. Omitted entities keep their current state. See entities-and-scenes.md for the composable vs monolithic pattern.

See **references/troubleshooting.md** for detailed troubleshooting and expanded gotchas.

## References

- **references/registry-and-homekit.md** -- Registry edit process, HomeKit bridge filters, .storage files
- **references/entities-and-scenes.md** -- Full entity inventory, naming conventions, scenes
- **references/homemcpbridge.md** -- HomeMCPBridge architecture, MCP tools, supported types, plugin system
- **references/deploy-and-cli.md** -- Deploy workflow, ha-manager CLI commands, config structure
- **references/troubleshooting.md** -- Expanded gotchas, known issues, fixes

## Notes

- Load reference docs via haiku explore agent -- don't read into main context.
- Append new discoveries to the relevant reference file, especially `troubleshooting.md`.
- HomeKit bridge entry ID may change if integration is re-added. Verify with the check command above.
