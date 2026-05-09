<!-- Extracted from SKILL.md -- load on demand -->

# HomeMCPBridge Architecture & Reference

## Overview

Mac Catalyst app that exposes Apple HomeKit devices via MCP protocol.
Separate from HA's native HomeKit bridge integration (port 21064).

| Property | Value |
|----------|-------|
| **App** | `/Applications/HomeMCPBridge.app` |
| **Source** | `<DEV_DIR>/mcp/servers/homekit-bridge/` |
| **LaunchAgent** | `~/Library/LaunchAgents/com.user.HomeMCPBridge.plist` |
| **HTTP transport** | Port 9234 (`http://127.0.0.1:9234/mcp`) |
| **Stdio** | Works when stdin is a pipe |
| **Request timeout** | 120 seconds |
| **Max payload** | 1MB |

## Supported HomeKit Service Types

Only these types are exposed through MCP (filtered in `accessoryToDict()`):

| Service Type | Capabilities |
|-------------|-------------|
| Lightbulb | on/off, brightness, color (hue/saturation) |
| Switch | on/off |
| Outlet | on/off |
| Fan | on/off |
| Garage Door Opener | open/close |
| Lock Mechanism | lock/unlock |
| Thermostat | read-only |
| Temperature Sensor | read values |

**NOT exposed:** Motion sensors, occupancy sensors, contact sensors, binary sensors.

## MCP Tools

### Device Control
- `list_devices` -- List all devices from HomeKit and enabled plugins
- `get_device_state` -- Current state (on/off, brightness, color, etc.)
- `control_device` -- Actions: on, off, toggle, brightness, color, lock, unlock, open, close
- `list_rooms` -- All rooms in all HomeKit homes
- `list_homes` -- All HomeKit homes

### Cameras
- `list_cameras` -- All HomeKit cameras
- `capture_snapshot` -- Snapshot from HomeKit camera (base64 JPEG)

### Motion/Events
- `list_motion_sensors` -- Motion sensors, occupancy sensors, doorbells
- `get_motion_state` -- Current motion detection state
- `subscribe_events` -- Enable motion event buffering
- `get_pending_events` -- Retrieve buffered events (with optional since filter)

### Scrypted NVR
- `scrypted_list_cameras` -- Cameras from Scrypted with capabilities
- `scrypted_capture_snapshot` -- Snapshot from Scrypted camera
- `scrypted_get_camera_state` -- State including motion detection

## Plugin System

Unified device model supporting multiple sources:

| Plugin | Auth | Control |
|--------|------|---------|
| **HomeKit** | Built-in, always enabled | Native HomeKit API |
| **Govee** | API key authentication | REST API, color via `{r, g, b}` |
| **Scrypted NVR** | HTTP + MQTT | Camera snapshots, motion state |

Devices can be linked to deduplicate (same device in both HomeKit and Govee).

## MCPPost Event Broadcasting

Broadcasts real-time sensor events to custom HTTP endpoint:
- **Supported:** Motion detected/cleared, occupancy changes, doorbell rings, door/window open/close
- **Configuration:** Webhooks tab in app preferences
- **Payload:** JSON with event_id, type, source, timestamp, sensor info, state

## Key Source Files

| File | Purpose |
|------|---------|
| `HomeMCPBridge/main.swift` | Primary app code (~2000 lines) |
| `HomeMCPBridge/MCPHTTPServer.swift` | HTTP server using NWListener |
| `HomeMCPBridge/MCPTransport.swift` | Abstraction for stdio vs HTTP |
| `HomeMCPBridge.entitlements` | HomeKit + Keychain permissions |

## Important Limitations

- **No debounce/throttling** on state changes -- every update propagates immediately
- Activity log capped at 100 entries
- Logs written to stderr
- 30-second ping timer for Scrypted MQTT connections

## MCP Configuration in HA Project

In `.mcp.json`:
```json
{
  "homekit": {
    "url": "http://127.0.0.1:9234/mcp"
  }
}
```

The `home-assistant` MCP server is separate (uses `uvx ha-mcp` via stdio).
