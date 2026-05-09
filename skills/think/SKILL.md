---
name: think
description: Sequential Thinking MCP - advanced step-by-step reasoning and problem solving
---

# Sequential Thinking Skill

**Auto-loads:** Sequential Thinking MCP server for complex reasoning

## Triggers

- "think deeply"
- "sequential thinking"
- "step by step"
- "complex problem"
- "reason through"

## MCP Configuration

**Config location:** `~/.config/pai-private/mcp-configs/sequential-thinking.json`

This skill enables the Sequential Thinking MCP server which provides:
- Step-by-step reasoning chains
- Complex problem decomposition
- Logical inference tracking
- Thought process visualization
- Multi-step analysis

## Available Tools

Once loaded, you'll have access to:
- `mcp__sequential-thinking__*` - All Sequential Thinking MCP tools

## Usage Examples

**Complex analysis:**
```
User: Think through the architectural implications of switching from REST to GraphQL
→ Uses sequential thinking to break down problem systematically
```

**Multi-step reasoning:**
```
User: Reason through why this algorithm is O(n²)
→ Step-by-step complexity analysis
```

**Problem decomposition:**
```
User: Break down how to implement distributed caching
→ Systematic decomposition with reasoning steps
```

## Technical Details

- **Package:** @modelcontextprotocol/server-sequential-thinking
- **Runtime:** npx
- **Timeout:** 60 seconds
- **Transport:** stdio

## Notes

- Use for complex, multi-step reasoning tasks
- Complements normal thinking mode with structured steps
- Visualizes reasoning chains
- Useful for debugging logic and architectural decisions
- MCP server only loads when this skill is invoked
