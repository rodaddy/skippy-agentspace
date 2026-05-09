---
name: desktop
description: Desktop Commander MCP - control desktop applications and windows
---

# Desktop Commander Skill

**Auto-loads:** Desktop Commander MCP server for desktop control

## Triggers

- "desktop"
- "window management"
- "control desktop"
- "app control"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/desktop-commander.json`

This skill enables the Desktop Commander MCP server which provides:
- Window management
- Application launching and control
- Desktop automation
- UI interaction
- Multi-monitor support

## Available Tools

Once loaded, you'll have access to:
- `mcp__desktop-commander__*` - All Desktop Commander MCP tools

## Usage Examples

**Window management:**
```
User: Move the current window to the left half of the screen
→ Uses Desktop Commander to reposition window
```

**Launch applications:**
```
User: Open Visual Studio Code
→ Launches VS Code via Desktop Commander
```

**Multi-monitor:**
```
User: Move this window to the external monitor
→ Repositions window across displays
```

## Technical Details

- **Package:** @wonderwhy-er/desktop-commander@latest
- **Runtime:** npx (always uses latest version)
- **Protocol:** stdio

## Notes

- Cross-platform desktop control
- Always pulls latest version via npx
- MCP server only loads when this skill is invoked
- Useful for window arrangement and desktop organization
