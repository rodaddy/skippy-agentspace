<!-- Extracted from SKILL.md -- load on demand -->

# Registry Edits & HomeKit Bridge Configuration

## Registry Edit Process

**CRITICAL:** HA overwrites `.storage/` on shutdown. Must stop core before editing.

### Full Procedure

```bash
# 1. Stop HA core
ssh root@<HA_IP> 'ha core stop'

# 2. Backup the file you're editing
ssh root@<HA_IP> 'cp /config/.storage/core.entity_registry /config/.storage/core.entity_registry.bak_$(date +%Y%m%d_%H%M%S)'

# 3. Edit with jq (no Python available on HAOS)
ssh root@<HA_IP> 'jq "<your jq expression>" /config/.storage/core.entity_registry > /tmp/reg.json && mv /tmp/reg.json /config/.storage/core.entity_registry'

# 4. Verify the edit
ssh root@<HA_IP> 'jq ".data.entities[] | select(.entity_id==\"your.entity\")" /config/.storage/core.entity_registry'

# 5. Restart HA
ssh root@<HA_IP> 'ha core start'
```

### Key .storage Files

| File | Contains |
|------|----------|
| `core.config_entries` | Integration configs (HomeKit bridge filters, MCP configs) |
| `core.entity_registry` | Entity names, disabled_by, hidden_by, platform |
| `core.device_registry` | Device info, area assignments |
| `core.area_registry` | Room/area definitions |

## HomeKit Bridge Configuration

### Bridge Details

| Property | Value |
|----------|-------|
| **Entry ID** | `<ENTRY_ID>` |
| **Port** | 21064 |
| **Mode** | bridge |
| **Config location** | `/config/.storage/core.config_entries` |

### Current Include Domains (updated 2026-02-28)

`light`, `media_player`, `switch`, `vacuum`, `scene`

**`sensor` domain REMOVED (2026-02-28)** -- was exposing ~100 sensors to HomeKit causing Apple Watch/iPhone battery drain. eMotion Ultra zones, smart plug power readings, weather, phone batteries, Mac sensors, FP300 environmental -- all firing constantly. Never re-add sensor domain without explicit entity filtering.

### Current Exclude Entities

**Switches (still relevant):**
- `switch.slzb_06p7_disable_leds`, `switch.slzb_06p7_led_night_mode`
- `switch.slzb_06p7_auto_zigbee_update`, `switch.slzb_06p7_vpn_enabled`
- `switch.sleepnumber_master_bedroom_pause_mode`
- `switch.lnlinkha_e04b4101a4d20000000000009cac0000_config_radar_x`

**Sensor excludes (redundant now but left as safety net):**
- Sun sensors, time_of_day, house_occupancy, all FP300 sensors

### Separate Accessory Bridges

| Device | Port | Mode | Entity |
|--------|------|------|--------|
| LG OLED65C3PUA | 21065 | accessory | `media_player.lg_webos_tv_oled65c3pua` |
| Denon AVR-S710W | 21066 | accessory | `media_player.denon_avr_s710w` |

### How to Modify HomeKit Bridge Filters

```bash
# 1. Stop HA
ssh root@<HA_IP> 'ha core stop'

# 2. Backup
ssh root@<HA_IP> 'cp /config/.storage/core.config_entries /config/.storage/core.config_entries.bak_$(date +%Y%m%d_%H%M%S)'

# 3. Add entity to exclude list
ssh root@<HA_IP> 'jq "(.data.entries[] | select(.entry_id==\"<ENTRY_ID>\") | .options.filter.exclude_entities) += [\"sensor.your_entity_here\"]" /config/.storage/core.config_entries > /tmp/ce_updated.json && mv /tmp/ce_updated.json /config/.storage/core.config_entries'

# 4. Verify
ssh root@<HA_IP> 'jq -r ".data.entries[] | select(.entry_id==\"<ENTRY_ID>\") | .options.filter" /config/.storage/core.config_entries'

# 5. Restart
ssh root@<HA_IP> 'ha core start'
```

### Adding a Domain to Include

```bash
ssh root@<HA_IP> 'jq "(.data.entries[] | select(.entry_id==\"<ENTRY_ID>\") | .options.filter.include_domains) += [\"climate\"]" /config/.storage/core.config_entries > /tmp/ce_updated.json && mv /tmp/ce_updated.json /config/.storage/core.config_entries'
```

### Removing an Entity from Exclude

```bash
ssh root@<HA_IP> 'jq "(.data.entries[] | select(.entry_id==\"<ENTRY_ID>\") | .options.filter.exclude_entities) -= [\"sensor.entity_to_remove\"]" /config/.storage/core.config_entries > /tmp/ce_updated.json && mv /tmp/ce_updated.json /config/.storage/core.config_entries'
```
