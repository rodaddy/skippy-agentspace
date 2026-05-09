<!-- Extracted from SKILL.md -- load on demand -->

# Troubleshooting & Known Issues

Append new discoveries here as they come up. This is the living knowledge base.

## Apple Watch Battery Drain (2026-02-28)

**Symptom:** Apple Watch battery drains rapidly after HA/HomeKit changes.

**Root cause:** FP300 Presence Multi Sensor (Matter device) reports temperature, humidity, and illuminance continuously. The `sensor` domain was in the HomeKit bridge `include_domains`, exposing all FP300 sensors to HomeKit. Each state change propagated: FP300 -> Matter -> HA -> HomeKit Bridge -> HomeKit Hub -> Apple Watch.

**Fix:** Added all 6 FP300 sensor entities to the HomeKit bridge exclude list:
- `sensor.presence_multi_sensor_fp300_temperature`
- `sensor.presence_multi_sensor_fp300_humidity`
- `sensor.presence_multi_sensor_fp300_illuminance`
- `sensor.presence_multi_sensor_fp300_battery`
- `sensor.presence_multi_sensor_fp300_battery_voltage`
- `sensor.presence_multi_sensor_fp300_battery_type`

**Prevention:** When adding new sensors, always check if they'll be caught by the `sensor` domain include. Environmental sensors that update frequently should be explicitly excluded.

## HA Log File Empty

**Symptom:** `/config/home-assistant.log` is 0 bytes.

**Fix:** Use `ha logs follow` or `ha logs` instead of reading the file directly.

## Wrong Person Entity

**Symptom:** Automations using `person.short_name` silently fail.

**Fix:** The correct entity is `person.your_name`. Always verify entity IDs with:
```bash
ssh root@<HA_IP> 'cat /config/.storage/core.entity_registry | jq -r ".data.entities[] | select(.entity_id | test(\"person\")) | .entity_id"'
```

## eMotion Ultra Entity Naming

**Symptom:** Can't find eMotion Ultra entities using `emotion_ultra` pattern.

**Fix:** The platform is LinpTech. Entities use `binary_sensor.lnlinkha_e04b4101a4d20000000000009cac0000` prefix. Multi-zone (8 zones).

## Registry Edit Overwrites

**Symptom:** Changes to `.storage/` files are lost after restart.

**Cause:** HA writes its in-memory state to `.storage/` on shutdown. If you edit while HA is running, your changes get overwritten.

**Fix:** ALWAYS `ha core stop` before editing, then `ha core start` after.

## Matter Device Frequent Updates

**Symptom:** Matter-connected sensors (like FP300) generate far more state changes than Zigbee equivalents.

**Why:** Matter protocol has its own update frequency that may not respect HA's polling settings. Environmental sensors (temp, humidity, illuminance) can fire hundreds of times per hour.

**Mitigation:**
- Exclude from HomeKit bridge
- Use template sensors with `delay_off` for debouncing in automations
- Don't include in recorder if history isn't needed

## HomeMCPBridge Not Responding

**Check:**
1. Is the app running? `pgrep -f HomeMCPBridge`
2. Is port 9234 listening? `lsof -i :9234`
3. Check LaunchAgent: `launchctl list | grep HomeMCPBridge`
4. Restart: `launchctl kickstart -k gui/$(id -u)/com.user.HomeMCPBridge`

## Deploy Fails / Git Pull Not Picking Up Changes

**Check:**
1. Is deploy repo on main branch? `cd <DEV_DIR>/home-assistant-config && git branch`
2. Was push successful? `git log --oneline -3`
3. Is Git Pull add-on enabled? Check HA UI > Settings > Add-ons > Git Pull
4. Force pull: Restart Git Pull add-on from HA UI

---

## Sensor Domain Nuked from HomeKit Bridge (2026-02-28)

**Symptom:** Apple Watch battery drain continued after excluding FP300 sensors.

**Root cause:** Excluding FP300 wasn't enough. The `sensor` domain in HomeKit bridge include_domains was exposing ~100 sensors total:
- eMotion Ultra: 22 zone sensors firing on every presence change
- Smart plug power/current/voltage: 16 entities updating every few seconds
- OpenWeatherMap: 16 weather sensors updating frequently
- Phone/Watch battery sensors: updating on every % change
- Aqara/W100 temperature/humidity: environmental spam
- SleepNumber pressure/sleep number: updating during sleep
- Mac Mini: frontmost app, audio output, BSSID changing constantly
- Printer: page counters, toner levels

**Fix:** Removed `sensor` from include_domains entirely. Bridge now only has: `light`, `media_player`, `switch`, `vacuum`, `scene`.

**Rule:** NEVER re-add `sensor` domain to HomeKit bridge. If a specific sensor is needed in HomeKit, add it as include_entities (not include_domains) and verify its update frequency first.

---

## HomeKit Bridge Caches Removed Accessories (2026-02-28)

**Symptom:** Changed HomeKit bridge filter (removed sensor domain) but sensors still show in Apple Home under the HASS Bridge.

**Root cause:** The HA HomeKit bridge maintains an accessory ID cache in `.storage/homekit.<entry_id>.aids` and `.iids`. Changing the filter config does NOT remove already-cached accessories. They persist in HomeKit even though HA is no longer sending updates for them.

**Fix:**
```bash
ha core stop
# Backup then delete the cache files
cp /config/.storage/homekit.<ENTRY_ID>.aids /config/.storage/homekit.<ENTRY_ID>.aids.bak
cp /config/.storage/homekit.<ENTRY_ID>.iids /config/.storage/homekit.<ENTRY_ID>.iids.bak
rm /config/.storage/homekit.<ENTRY_ID>.aids
rm /config/.storage/homekit.<ENTRY_ID>.iids
ha core start
```

Bridge rebuilds its accessory list from current filter config on next startup. Cached entries are purged.

**Rule:** After ANY HomeKit bridge filter change, always clear the aids/iids cache and restart. Filter changes alone are NOT enough.

---

*Last updated: 2026-02-28*
*Add new issues below this line:*
