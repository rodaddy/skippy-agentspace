---
name: shortcuts
description: Enhanced Shortcuts MCP - run macOS Shortcuts with advanced capabilities
---

# Enhanced Shortcuts Skill

**Auto-loads:** Enhanced Shortcuts MCP server for macOS Shortcuts automation

## Triggers

- "shortcuts"
- "run shortcut"
- "mac shortcut"
- "automation"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/enhanced-shortcuts.json`

This skill enables the Enhanced Shortcuts MCP server which provides:
- macOS Shortcuts execution
- Shortcut listing and discovery
- Parameter passing to shortcuts
- Result handling
- Shortcut creation assistance

## Available Tools

Once loaded, you'll have access to:
- `mcp__enhanced-shortcuts__*` - All Enhanced Shortcuts MCP tools

## Usage Examples

**Run a shortcut:**
```
User: Run my "Morning Routine" shortcut
→ Executes the specified macOS Shortcut
```

**List shortcuts:**
```
User: What shortcuts do I have available?
→ Lists all installed macOS Shortcuts
```

**Pass parameters:**
```
User: Run the "Send Message" shortcut with text "Hello"
→ Executes shortcut with input parameter
```

## Technical Details

- **Runtime:** Node.js
- **Source:** `<DEV_DIR>/mcp/servers/enhanced-shortcuts/dist/index.js`
- **Platform:** macOS only

## Notes

- macOS-specific skill
- Requires macOS Shortcuts app
- Can run any installed Shortcut
- Supports input parameters and return values
- MCP server only loads when this skill is invoked
