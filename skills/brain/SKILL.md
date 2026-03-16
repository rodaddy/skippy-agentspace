---
name: brain
description: Query your Second Brain knowledge base for decisions, learnings, patterns, and solutions. USE WHEN you need to find how something was done before, what decisions were made, or search for solutions to problems.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: utility
triggers:
  - /brain
  - search brain
  - what do I know about
  - how did I handle
  - find in kb
---

# Brain - Knowledge Base Query

Query your Open Brain knowledge base using semantic vector search across all knowledge types.

## Usage

```
/brain auth patterns
/brain how did I handle database connections
/brain what decisions about embeddings
```

## Implementation

When invoked, use mcp2cli to query Open Brain:

### Search (default)

```bash
mcp2cli open-brain search_brain --params '{"query": "<user query>", "limit": 10}'
```

Results include `source_type` (thought, decision, session, relationship, project), `content_preview`, `tags`, and `distance` (lower = more relevant).

### Find Person

If the user asks about a person:

```bash
mcp2cli open-brain find_person --params '{"query": "<name or description>"}'
```

### Log New Knowledge

If the user wants to save something:

```bash
# Save a thought/learning
mcp2cli open-brain log_thought --params '{"content": "<content>", "tags": ["tag1", "tag2"]}'

# Save a decision
mcp2cli open-brain log_decision --params '{"title": "<title>", "rationale": "<why>", "alternatives": ["<alt1>"], "tags": ["tag1"]}'
```

## Output Format

```
## Brain Search: "<query>"

### Decisions (N found)
- **Title** -- rationale summary
  Tags: tag1, tag2

### Thoughts/Learnings (N found)
- Content preview
  Tags: tag1, tag2

### Sessions (N found)
- **Project** (date) -- summary
```

## Graceful Degradation

If `mcp2cli open-brain` fails (server down, network issue):
1. Log a warning: "Open Brain unavailable, falling back to local search"
2. Run `scripts/search-kb.ts <query>` for local JSON-based search
3. Present results in the same output format

The local fallback searches `~/.config/pai-private/knowledge/` JSON files (decisions-v2.json, learnings-v2.json, patterns-v2.json).

## Tools Available

| Tool | Use For |
|------|---------|
| `search_brain` | Semantic search across all tables |
| `find_person` | Lookup people by name or context |
| `log_thought` | Save a new thought/learning/note |
| `log_decision` | Record a decision with rationale |
| `session_save` | Save session summary |
| `session_load` | Load previous session context |
