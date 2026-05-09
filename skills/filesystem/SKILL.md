---
name: filesystem
description: Filesystem MCP - extended file operations beyond built-in tools
---

# Filesystem Skill

**Auto-loads:** Filesystem MCP server for advanced file operations

## Triggers

- "filesystem"
- "file operations"
- "directory operations"
- "bulk file ops"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/filesystem.json`

This skill enables the Filesystem MCP server which provides:
- Advanced file operations
- Bulk file manipulation
- Directory tree operations
- File system queries
- Extended file metadata

## Available Tools

Once loaded, you'll have access to:
- `mcp__filesystem__*` - All Filesystem MCP tools

## Usage Examples

**Bulk operations:**
```
User: Rename all .txt files in this directory to add a timestamp
→ Uses Filesystem MCP for bulk rename
```

**Advanced queries:**
```
User: Find all files larger than 100MB in <DEV_DIR>
→ Queries filesystem with size filters
```

**Tree operations:**
```
User: Copy the entire directory structure but only .md files
→ Advanced copy with filtering
```

## Technical Details

- **Package:** @modelcontextprotocol/server-filesystem
- **Runtime:** npx
- **Scope:** <DEV_DIR>
- **Timeout:** 60 seconds
- **Transport:** stdio

## Notes

- Complements built-in Read/Write/Edit tools
- Use for operations beyond basic file I/O
- Scoped to Development directory for safety
- MCP server only loads when this skill is invoked
