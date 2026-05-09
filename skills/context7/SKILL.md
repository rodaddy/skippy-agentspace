---
name: context7
description: Context7 MCP - semantic context management with Upstash vector store
---

# Context7 Skill

**Auto-loads:** Context7 MCP server for semantic context management

## Triggers

- "context7"
- "semantic search"
- "context management"
- "upstash"
- "vector store"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/context7.json`

This skill enables the Context7 MCP server which provides:
- Semantic context storage
- Vector similarity search
- Context retrieval
- Embeddings management
- Long-term context memory

## Available Tools

Once loaded, you'll have access to:
- `mcp__context7__*` - All Context7 MCP tools

## Usage Examples

**Store context:**
```
User: Save this conversation context for later
→ Stores semantic embeddings in Upstash
```

**Retrieve context:**
```
User: Find similar conversations about API design
→ Vector similarity search in context store
```

**Manage context:**
```
User: Clear old context from last month
→ Manages stored context entries
```

## Technical Details

- **Package:** @upstash/context7-mcp
- **Runtime:** npx
- **Backend:** Upstash Vector Store
- **Timeout:** 60 seconds
- **Transport:** stdio

## Notes

- Requires Upstash account and API credentials
- Provides semantic search across stored contexts
- Complements built-in memory MCP
- Use for long-term, searchable context storage
- MCP server only loads when this skill is invoked
