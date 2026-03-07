# LAW 10: qmd First

**Enforcement:** Manual -- hook required (Phase 7 gap)
**Severity:** MANDATORY

## Rule

ALWAYS query qmd MCP before using Read, Glob, or Grep on codebase files.

## Why

qmd has thousands of files indexed with semantic vectors. An index search costs ~150 tokens vs 500-3,000+ tokens per file read. Using qmd first saves context window and finds relevant files faster than manual searching.

## Search Order

1. `qmd search "query"` -- BM25 keyword search (fast, handles 80% of searches)
2. `qmd vsearch "query"` -- semantic vector search (conceptual matches)
3. `qmd query "query"` -- hybrid search with reranking (best quality, slower)
4. `qmd get <file>` / `qmd multi_get` -- retrieve specific documents
5. THEN Read/Glob/Grep if qmd didn't return enough

## Enforcement Details

Currently manually enforced -- no hook exists for this LAW yet.

A future hook would need to:
- Detect Read/Glob/Grep tool calls on codebase files
- Check if qmd was queried first in the conversation
- Allow bypass for exact known paths and files outside indexed collections

## Examples

**Correct:** `qmd search "authentication middleware"` -> find relevant files -> Read specific files
**Incorrect:** `Grep("auth", path="src/")` without checking qmd first

## Exceptions

- Exact known file paths (no search needed)
- Files outside qmd-indexed collections
- Git commands and non-codebase operations
