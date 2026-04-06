---
name: brain
description: Query, write, and manage your Open Brain knowledge base with automatic namespace resolution. USE WHEN logging thoughts, decisions, searching brain, session saves, or any OB interaction. All OB calls MUST go through this skill for proper namespace tagging.
metadata:
  version: 0.3.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: utility
triggers:
  - /brain
  - search brain
  - what do I know about
  - how did I handle
  - find in kb
  - log thought
  - log decision
  - save to brain
  - push to ob
  - remember this
  - my brain
  - personal brain
  - collab brain
---

# Brain - Open Brain with Namespace Awareness

All Open Brain interactions MUST go through this skill. Direct `mcp2cli open-brain` calls without namespace resolution will be blocked by hooks.

## Namespace Resolution (CRITICAL)

Before ANY write to OB, resolve the namespace using these rules in order:

### 1. Explicit Intent Override (highest priority)

If the user says any of these, override all other rules:

| User Says | Namespace | Example |
|-----------|-----------|---------|
| "my brain", "my ob", "personal", "private" | `<caller_identity>` | "save this to my brain" -> `rico` |
| "collab", "shared", "team", "king" | `collab` | "push this to collab" -> `collab` |

### 2. Host + Directory Detection (default)

Determine namespace from hostname and working directory:

```
HOSTNAME = $(hostname)

if HOSTNAME starts with "cc-":
  # LXC box -- default collab
  if user explicitly says "personal/private/my":
    namespace = <caller_identity>
  else:
    namespace = "collab"

elif HOSTNAME ends with ".local":
  # Personal machine (Mini-M4-Pro.local, rodaddy-air-2.local)
  if cwd matches */king* OR */King*:
    namespace = "collab"
  else:
    namespace = <caller_identity>

else:
  # Unknown host -- default to caller identity
  namespace = <caller_identity>
```

### 3. Caller Identity

`<caller_identity>` = the authenticated user's ID. This comes from the auth token, NOT hardcoded:
- Rico's sessions -> `rico`
- Kevin's sessions -> `kevin`
- Geetesh's sessions -> `geetesh`
- Skippy OC -> `skippy`
- Other agents -> their `clientId`

## Usage

### Resolve Namespace First

Before any OB call, determine the namespace:

```bash
# Step 1: Get hostname
HOSTNAME=$(hostname)

# Step 2: Get cwd basename for directory matching
CWD=$(basename "$PWD")

# Step 3: Apply rules (see Namespace Resolution above)
# Result: NAMESPACE variable set
```

### Search

```bash
# Search respects visibility -- users see own namespace + collab + shared
mcp2cli open-brain search_brain --params '{"query": "<user query>", "limit": 10}'

# Federated search (OB + qmd files)
mcp2cli open-brain search_all --params '{"query": "<user query>"}'

# Search within specific namespace
mcp2cli open-brain search_brain --params '{"query": "<query>", "namespace": "rico"}'
```

### Log Thought

```bash
# ALWAYS include namespace
mcp2cli open-brain log_thought --params '{"content": "<content>", "tags": ["tag1", "tag2"], "namespace": "<resolved_namespace>"}'
```

### Log Decision

```bash
mcp2cli open-brain log_decision --params '{"title": "<title>", "rationale": "<why>", "alternatives": ["<alt1>"], "tags": ["tag1"], "namespace": "<resolved_namespace>"}'
```

### Session Save

```bash
mcp2cli open-brain session_save --params '{"project": "<project>", "summary": "<summary>", "namespace": "<resolved_namespace>"}'
```

### Set Cognitive Tier

```bash
# Set an entry's tier: hot (front-of-mind, +0.3 boost), warm (default), cold (deprioritized, -0.2)
mcp2cli open-brain set_tier --params '{"table": "thoughts", "id": "<uuid>", "tier": "hot"}'
# Valid tables: thoughts, decisions, relationships, projects, sessions
```

### Tier-Filtered Search

```bash
# Search only hot (front-of-mind) entries
mcp2cli open-brain search_brain --params '{"query": "<query>", "tier": "hot"}'

# Federated search filtered to warm+ entries
mcp2cli open-brain search_all --params '{"query": "<query>", "tier": "warm"}'

# Recent entries by tier
mcp2cli open-brain list_recent --params '{"tier": "hot", "limit": 10}'
```

### Find Person

```bash
mcp2cli open-brain find_person --params '{"query": "<name or description>"}'
```

### Upsert Person

```bash
mcp2cli open-brain upsert_person --params '{"person_name": "<name>", "context": "<relationship>", "namespace": "<resolved_namespace>"}'
```

## Auto-Tagging Guidelines

When logging thoughts/decisions, include contextual tags:

| Context | Auto-Tags |
|---------|-----------|
| In a king repo | `["king", "<repo-name>"]` |
| Infrastructure work | `["infra", "<service-name>"]` |
| Personal/career | `["personal"]` |
| Financial | `["personal", "finance"]` |
| Session wrap | `["session", "<project>"]` |

Tags are additive -- merge with any user-provided tags.

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

| Tool | Use For | Namespace Required | Tier Param |
|------|---------|-------------------|------------|
| `search_brain` | Semantic search across all tables | Optional (filter) | Optional |
| `search_all` | Federated OB + qmd search | Optional (filter) | Optional |
| `find_person` | Lookup people by name or context | No | No |
| `log_thought` | Save a new thought/learning/note | **Yes** | No |
| `log_decision` | Record a decision with rationale | **Yes** | No |
| `session_save` | Save session summary | **Yes** | No |
| `session_load` | Load previous session context | No | No |
| `list_recent` | Browse recent entries | Optional (filter) | Optional |
| `update_entry` | Modify existing entry | No (inherits) | No |
| `rate_entry` | Rate entry usefulness | No | No |
| `archive_entry` | Soft-delete entry | No | No |
| `upsert_person` | Create/update contact | **Yes** | No |
| `set_tier` | Set cognitive tier (hot/warm/cold) | No | N/A (is the tier tool) |

## Reference Docs

- [Namespace Guide](references/namespace-guide.md) -- full mapping table and edge cases
- [Agent Usage](references/agent-usage.md) -- how OC agents should use this skill
