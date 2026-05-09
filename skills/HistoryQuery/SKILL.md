---
name: history-query
description: Search and query PAI's Universal Output Capture System (UOCS). AUTO-LOADS at session start. Find past work, sessions, decisions, learnings, and tool usage from automatically captured history. USE WHEN user asks to search history, find past work, show sessions, query tool usage, or retrieve captured data.
---

# History Query Skill

Query PAI's automatically captured history data.

## When to Use This Skill

Activate when user requests:
- "Search my PAI history for X"
- "Find when we worked on X"
- "Show me sessions from last week"
- "What tools did I use yesterday?"
- "When did we decide to use X?"
- "Show me all learnings about X"
- "What bugs did we fix this month?"
- "Find research on X topic"

## What PAI Captures Automatically

PAI's hooks automatically capture everything to `~/.config/pai/history/`:

### Directory Structure

```
~/.config/pai/history/
├── sessions/YYYY-MM/          # Session summaries (SessionEnd hook)
├── learnings/YYYY-MM/         # Problem-solving narratives (Stop hook)
├── research/YYYY-MM/          # Investigation reports (Research agents)
├── decisions/YYYY-MM/         # Architectural decisions (Architect agent)
├── execution/
│   ├── features/YYYY-MM/      # Feature implementations
│   ├── bugs/YYYY-MM/          # Bug fixes
│   └── refactors/YYYY-MM/     # Code improvements
└── raw-outputs/YYYY-MM/       # JSONL logs (PostToolUse hook)
```

## Query Workflows

**All workflows use deterministic tools in `tools/` directory - these run automatically when triggered.**

### Workflow 1: Search All History

**User says:** "Search my history for authentication work"

**Execute:**
```bash
bun ~/.config/pai/Skills/HistoryQuery/tools/search-history.ts "authentication" --type all --limit 20
```

**What it does:**
- Searches all markdown files in history/ directories
- Searches JSONL event logs
- Groups results by type (sessions, learnings, decisions, etc.)
- Shows timestamps and match counts
- Formats output with file paths for easy reading

**Options:**
- `--type sessions|learnings|decisions|research|execution|all` - Filter by category
- `--limit N` - Limit results (default: 20)

### Workflow 2: Show Recent Sessions

**User says:** "Show me sessions from last week"

**Execute:**
```bash
bun ~/.config/pai/Skills/HistoryQuery/tools/show-sessions.ts --days 7 --limit 10
```

**What it does:**
- Finds all sessions from last N days
- Parses session files for tools used and files modified
- Sorts chronologically (newest first)
- Shows session name, timestamp, tools, file count

**Options:**
- `--days N` - Number of days to look back (default: 7)
- `--limit N` - Limit results (default: 10)

### Workflow 3: Query Tool Usage

**User says:** "What tools did I use most yesterday?"

**Execute:**
```bash
bun ~/.config/pai/Skills/HistoryQuery/tools/analyze-tools.ts --date 2025-12-29
# OR for last N days:
bun ~/.config/pai/Skills/HistoryQuery/tools/analyze-tools.ts --days 7
```

**What it does:**
- Parses JSONL event logs for tool usage
- Counts and ranks tools by usage
- Shows percentage breakdown with visual bars
- Lists all event types captured
- Shows trends over time

**Options:**
- `--date YYYY-MM-DD` - Analyze specific date
- `--days N` - Analyze last N days (default: 7)

### Workflow 4: Find Decisions

**User says:** "When did we decide to use Nano Banana Pro?"

**Execute:**
```bash
bun ~/.config/pai/Skills/HistoryQuery/tools/search-history.ts "Nano Banana Pro" --type decisions
```

**Note:** Also searches learnings and sessions automatically if no decisions found.

### Workflow 5: Timeline Query

**User says:** "Show timeline of work on X project"

**Execute:**
```bash
bun ~/.config/pai/Skills/HistoryQuery/tools/search-history.ts "project-name" --type all --limit 50
```

**Results are already sorted chronologically** - newest first.

## Quick Reference

**Three deterministic tools handle all queries:**

| Task | Tool | Example |
|------|------|---------|
| Search anything | `search-history.ts` | `"authentication" --type all` |
| View sessions | `show-sessions.ts` | `--days 7 --limit 10` |
| Analyze tool usage | `analyze-tools.ts` | `--date 2025-12-29` |

**All tools located at:** `~/.config/pai/Skills/HistoryQuery/tools/`

## Response Format

When presenting search results:

```markdown
## 🔍 History Search Results

**Query:** [user's search term]
**Found:** X results across Y files

### Sessions (N found)
- YYYY-MM-DD HH:MM - [Brief summary] (sessions/YYYY-MM/filename.md)

### Learnings (N found)
- YYYY-MM-DD HH:MM - [Brief summary] (learnings/YYYY-MM/filename.md)

### Decisions (N found)
- YYYY-MM-DD HH:MM - [Brief summary] (decisions/YYYY-MM/filename.md)

### Tool Usage (if queried)
- Tool Name: X uses
- Tool Name: Y uses

Would you like me to read any of these files for details?
```

## Advanced Queries

### Multi-term search
```bash
grep -r "term1" ~/.config/pai/history/ --include="*.md" | grep "term2"
```

### Date range search (files modified between dates)
```bash
find ~/.config/pai/history -name "*.md" -newermt "2025-12-01" ! -newermt "2025-12-31"
```

### Tool usage trends over time
```bash
for file in ~/.config/pai/history/raw-outputs/2025-12/*.jsonl; do
  echo "$(basename $file):"
  cat "$file" | jq -r '.tool' | sort | uniq -c | sort -rn | head -3
done
```

## Key Principles

1. **Read files on demand** - Show summaries first, read full content only if user asks
2. **Chronological by default** - Always sort results by timestamp
3. **Context matters** - Include surrounding context (which directory, what type)
4. **Respect privacy** - Don't expose sensitive data from JSONL logs
5. **Efficient queries** - Use grep/find/jq for speed, don't load everything into memory

## Integration with Other Skills

- **CORE** - Loads at session start, can reference history
- **Research** - Can check previous research before spawning agents
- **Art** - Can find previous art generation decisions
- **Fabric** - Can search for previous pattern usage

## Limitations

- History only exists AFTER hooks have captured data
- JSONL parsing requires `jq` installed
- Date filtering relies on filename timestamps
- Very large histories may require pagination

## Future Enhancements

- Advanced filtering (by agent type, tool type, duration)
- Visualization of usage patterns
- Export to different formats
- Automatic tagging and categorization
- Similarity search (find related work)
