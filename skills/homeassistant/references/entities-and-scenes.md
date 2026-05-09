<!-- Extracted from SKILL.md -- load on demand -->

# Entity Inventory & Scene Reference

## Naming Convention

**Pattern:** `domain.room_device_qualifier`
**Friendly names:** Title Case matching entity structure

## Key Entities

### Lights

| Entity ID | Room | Device |
|-----------|------|--------|
| `light.office_desk_lamp` | Office | Desk lamp |
| `light.office_desk_overhead_left` | Office | Overhead left |
| `light.office_desk_overhead_right` | Office | Overhead right |
| `light.office_bar_light` | Office | Bar light |
| `light.office_couch_light_left` | Office | Couch left |
| `light.office_couch_light_right` | Office | Couch right |
| `light.office_ambient_strip` | Office | Ambient LED strip |
| `light.office_bathroom_overhead` | Office | Bathroom |
| `light.entry_buffet_left` | Entry Way | Buffet left |
| `light.entry_buffet_right` | Entry Way | Buffet right |
| `light.entry_overhead` | Entry Way | Overhead |
| `light.family_room_main` | Family Room | Main light |

### Switches

| Entity ID | Room | Device |
|-----------|------|--------|
| `switch.office_plug_04` | Office | Smart plug 04 |
| `switch.office_smart_plug` | Office | Smart plug |
| `switch.laundry_game_room` | Laundry Room | Game room |

### Presence/Motion Sensors

| Entity ID | Platform | Notes |
|-----------|----------|-------|
| `binary_sensor.lnlinkha_e04b4101a4d20000000000009cac0000*` | LinpTech | eMotion Ultra, 8 zones. NOT `emotion_ultra_*` |
| `binary_sensor.presence_multi_sensor_fp300_occupancy` | Matter | FP300 occupancy (safe -- binary_sensor not in HomeKit) |
| `sensor.presence_multi_sensor_fp300_temperature` | Matter | FP300 temp (exclude from HomeKit) |
| `sensor.presence_multi_sensor_fp300_humidity` | Matter | FP300 humidity (exclude from HomeKit) |
| `sensor.presence_multi_sensor_fp300_illuminance` | Matter | FP300 lux -- MOST SPAMMY (exclude from HomeKit) |

### People

| Entity ID | Person |
|-----------|--------|
| `person.your_name` | You (NOT `person.short_name`) |
| `person.family_member_1` | Family member 1 |
| `person.family_member_2` | Family member 2 |
| `person.family_member_3` | Family member 3 |

### Button Events (Aqara 3-button)

| Button | Entity | Action |
|--------|--------|--------|
| Button 1 | `event.aqara_sensor_w_buttons_button_3` | Night TV scene |
| Button 2 | `event.aqara_sensor_w_buttons_button_4` | Work'n scene |
| Button 3 | `event.aqara_sensor_w_buttons_button_5` | Work'n Darker scene |

Event type: `multi_press_1`

## Areas (7 Total)

Office, Living Room, Kitchen, Main Bedroom, Entry Way, Family Room, Laundry Room

Removed areas (from full rebuild): HomeAssist, rTech HomePod Mini, rTech Office AppleTv, JJ's HomePod Mini, Main Bedroom (2)

## Scene Architecture

### Composable vs Monolithic Scenes (CRITICAL)

HA scenes are **snapshots, not layers**. Every entity listed in a scene gets overwritten when activated. If a scene lists all 7 room lights, it's a full room takeover -- no coexistence with other scenes.

**Rule: Only include entities the scene actually needs to change.** Omitted entities stay at their current state. This makes scenes composable -- you can layer "Making A Drink" (bar light only) on top of "Work'n" (desk/overhead focus) without conflict.

**Scene types:**
- **Room takeover** (Work'n, Night TV, etc.) -- sets ALL lights, defines the full room mood. These are mutually exclusive by design.
- **Additive/overlay** (Making A Drink) -- sets only specific lights, layers on top of whatever room state is active. These can coexist with any room scene.

**When creating new scenes, ask:** Does this need to control the whole room, or just a specific zone? If it's a zone, only include those entities.

### Active Scenes (9)

**Room takeover scenes** (set all 7 office lights):
- Work'n -- warm desk/overhead focus, low couch/bar accent
- Work'n Darker -- dimmer version of Work'n
- Night TV -- very dim reds, ambient low
- User Away -- all office OFF, entry buffets ON
- Office Full Bright -- everything maxed
- Office Desk Focus -- desk on, bar/couch off
- Office Ambient Only -- desk off, ambient/bar/couch on low
- Office Night Light -- minimal across the board

**Additive/overlay scenes** (touch only what they need):
- Making A Drink -- bar light full brightness (255) only

Scene config: `config/scenes/office_scenes.yaml` + `config/scenes/homekit_migration.yaml`

## Key Integrations

| Integration | Details |
|-------------|---------|
| **ZHA** | SLZB-06P7 coordinator (Zigbee) |
| **Matter** | FP300 Presence Multi Sensor |
| **LinpTech** | eMotion Ultra multi-zone presence |
| **Flic** | Button platform on localhost:5551 |
| **HomeKit Bridge** | Port 21064 (HA-native, separate from HomeMCPBridge) |
