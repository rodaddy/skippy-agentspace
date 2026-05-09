---
name: applescript
description: AppleScript Automator MCP - execute AppleScript for Mac automation
---

# AppleScript Automator Skill

**Auto-loads:** AppleScript MCP server for Mac automation

## Triggers

- "applescript"
- "mac automation"
- "control mac app"
- "automate [app name]"
- "run applescript"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/applescript-automator.json`

This skill enables the AppleScript MCP server which provides:
- AppleScript execution
- Mac application control
- System automation
- UI scripting
- Application interaction

## Available Tools

Once loaded, you'll have access to:
- `mcp__applescript-automator__*` - All AppleScript MCP tools

## Usage Examples

**Control applications:**
```
User: Open Safari and navigate to google.com
→ Executes AppleScript to control Safari
```

**Automate workflows:**
```
User: Create a new reminder in Reminders app
→ Uses AppleScript to interact with Reminders
```

**System control:**
```
User: Set system volume to 50%
→ Runs AppleScript to adjust volume
```

## Technical Details

- **Runtime:** Node.js
- **Source:** `<DEV_DIR>/mcp/servers/applescript-automator/dist/index.js`
- **Platform:** macOS only

## Notes

- macOS-specific skill
- Can control any scriptable Mac application
- Requires appropriate permissions for UI automation
- MCP server only loads when this skill is invoked
