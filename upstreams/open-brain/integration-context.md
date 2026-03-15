# Open Brain Integration Context

**Source:** open-brain `.planning/phases/06-pai-integration/06-CONTEXT.md`
**Status:** Ready for planning in skippy-agentspace
**Ability:** #11 "Remember" -- semantic memory + cross-session continuity + decision logging

## What Open Brain Provides

6 MCP tools via `mcp2cli open-brain <tool>`:

| Tool | Purpose |
|------|---------|
| `search_brain` | Cross-table semantic vector search (thoughts, decisions, sessions, relationships) |
| `log_thought` | Save free-form notes/learnings with embedding |
| `log_decision` | Record decisions with rationale and alternatives |
| `session_save` | Write session summary with structured fields |
| `session_load` | Retrieve latest session context for a project |
| `find_person` | Relationship lookup with warmth score |

**Server:** LXC 208 (10.71.20.15:3100), PostgreSQL + pgvector on 10.71.20.49, LiteLLM embeddings (gemini-embedding-001, 768 dims)
**Auth:** Bearer token via `OPEN_BRAIN_AGENT_TOKEN` env var

## Integration Work (Consumer-Side)

### Skills to Wire

| Skill | Location | Current State | Target State |
|-------|----------|---------------|--------------|
| `/brain` | `~/.config/pai/Skills/brain/` | Already calls mcp2cli open-brain | Working -- migrate into skippy-agentspace |
| `/capture-session` | `~/.config/pai/Skills/capture-session/` | Already calls mcp2cli open-brain | Working -- migrate into skippy-agentspace |
| `/session-wrap` | `skills/session-wrap/` (this repo) | Markdown-only, no Open Brain | Add Open Brain push after markdown write |
| `/session-start` | `~/.config/pai/Skills/session-start/` | Reads .reports/ markdown only | Add Open Brain session_load query |

### Hooks to Wire

| Hook | Current State | Target State |
|------|---------------|--------------|
| `open-brain-session-load.ts` | Fires on SessionStart, queries Open Brain | Enhance -- richer output, coordinate with load-core-context |
| `open-brain-session-save.ts` | Fires on PreCompact, saves to Open Brain | Enhance -- richer capture (files, commands, decisions) |
| `open-brain-session-capture.ts` | Fires on SessionEnd, captures git state | New -- just committed to open-brain repo |
| `inject-brain-context.ts` | Queries /Exports/pai/ markdown | Replace with Open Brain search |
| `query-knowledge.ts` | PostgreSQL tag/full-text search | Replace with Open Brain search |

### Old Stores to Deprecate

| Store | Location | Action |
|-------|----------|--------|
| JSON KB files | `~/.config/pai-private/knowledge/*.json` | Archive (stale, last extracted 2026-02-01) |
| Markdown exports | `/Volumes/ThunderBolt/Exports/pai/` | Deprecate (no longer needed) |
| PostgreSQL KB (CT 200) | `10.71.20.49 knowledge table` | Replace with Open Brain |

### What Stays Unchanged

- `load-core-context.ts` hook -- MANDATORY, injects PAI LAWs (never touch)
- Claude Code project memory (MEMORY.md) -- orthogonal, per-project
- `~/.config/pai-private/memory/` -- personal context, low-frequency
- `.reports/` session files -- keep for human-readable audit trail
- `capture-all-events.ts` -- observability JSONL, complementary

## Graceful Degradation Requirement

All skills and hooks MUST detect Open Brain availability at runtime. If the server is down:
- Skills fall back to previous behavior (markdown reads, etc.)
- Hooks silently skip Open Brain calls (never block session lifecycle)
- Log a warning but don't error

## Sequencing Recommendation

1. **Migrate skills:** Move `/brain` and `/capture-session` from `~/.config/pai/Skills/` into `skills/` in this repo
2. **Wire session-wrap:** Add Open Brain push as Step 4.5 (after write, before commit)
3. **Wire session-start:** Add Open Brain session_load query alongside .reports/ reads
4. **Replace old hooks:** Swap inject-brain-context.ts and query-knowledge.ts for Open Brain equivalents
5. **Deprecate old stores:** Archive JSON KB, remove markdown export references
6. **Verify:** End-to-end test of capture -> search -> retrieval cycle
