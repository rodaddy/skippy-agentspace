# Open Brain Integration Context

**Source:** open-brain `.planning/phases/06-pai-integration/06-CONTEXT.md`
**Status:** COMPLETE -- all skills wired, hooks cleaned, old stores handled (2026-03-15)
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

**Server:** LXC 208 (10.71.20.15:3100), PostgreSQL + pgvector on 10.71.20.49, LiteLLM embeddings via 10.71.20.33:4000 (gemini-embedding-001, 768 dims)
**Auth:** Bearer token via `OPEN_BRAIN_AGENT_TOKEN` env var

## Integration Work (Consumer-Side)

### Skills to Wire

| Skill | Location | Current State | Target State |
|-------|----------|---------------|--------------|
| `/brain` | `skills/brain/` | Migrated with graceful degradation (local JSON fallback) | **DONE** |
| `/capture-session` | `skills/capture-session/` | Rewritten as OB-native (removed legacy Mattermost script) | **DONE** |
| `/session-wrap` | `skills/session-wrap/` | Step 3.5 added for OB session_save | **DONE** |
| `/session-start` | `skills/session-start/` | 8th source added (OB session_load in scout prompt) | **DONE** |

### Hooks to Wire

| Hook | Current State | Target State |
|------|---------------|--------------|
| `open-brain-session-load.ts` | Fires on SessionStart, queries Open Brain | Working -- **DONE** (OB session) |
| `open-brain-session-save.ts` | Fires on PreCompact, saves to Open Brain | Working -- **DONE** (OB session) |
| `open-brain-session-capture.ts` | Fires on SessionEnd, captures git state | Working -- **DONE** (OB session) |
| `inject-brain-context.ts` | Was inactive, read stale markdown exports | **REMOVED** (moved to /tmp, 2026-03-15) |
| `query-knowledge.ts` | Was inactive, queried old PostgreSQL KB | **REMOVED** (moved to /tmp, 2026-03-15) |

### Old Stores to Deprecate

| Store | Location | Action |
|-------|----------|--------|
| JSON KB files | `~/.config/pai-private/knowledge/*.json` | **KEPT** -- brain skill local fallback reads these |
| Markdown exports | `/Volumes/ThunderBolt/Exports/pai/` | **ARCHIVED** to `~/Archive/pai-exports-20260131` (2026-03-15) |
| PostgreSQL KB (CT 200) | `10.71.20.49 knowledge table` | Superseded by Open Brain (same server, new schema) |

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

## Sequencing (COMPLETED 2026-03-15)

1. ~~Migrate skills~~ -- brain, capture-session, session-start migrated (PR #18)
2. ~~Wire session-wrap~~ -- Step 3.5 added for session_save (PR #18)
3. ~~Wire session-start~~ -- 8th scout source added (PR #18)
4. ~~Replace old hooks~~ -- inject-brain-context.ts + query-knowledge.ts removed (inactive, replaced by OB session hooks)
5. ~~Deprecate old stores~~ -- exports archived, JSON KB kept for fallback
6. **Verify:** End-to-end test of capture -> search -> retrieval cycle -- PENDING
