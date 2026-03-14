# Marketplace Audit -- 2026-03-13

## Sources Audited

| Source | Commands/Modes | Essential | Useful | Ceremony | Cut |
|--------|---------------|-----------|--------|----------|-----|
| GSD (get-shit-done) | 32 | 7 | 10 | 12 | 3 |
| OMC (oh-my-claudecode 4.7.3) | 38 | 5 | 13 | 3 | 17 |
| Open Brain | 18 patterns | 3 | 5 | 5 | 5 |
| PAUL | 5 (already done) | 5 | 0 | 0 | 0 |
| **Total** | **93** | **20** | **28** | **20** | **25** |

## Coalesced Output: 11 Abilities

| # | Ability | Absorbs From | Core Pattern |
|---|---------|-------------|--------------|
| 1 | **Bootstrap** | GSD: new-project, new-milestone | Questioning protocol -> requirements -> roadmap |
| 2 | **Plan** | GSD: plan-phase, discuss-phase; OMC: plan, ralplan | Research -> gray areas -> adversarial review -> consensus |
| 3 | **Execute** | GSD: execute-phase, quick; OMC: ultrawork | Wave-based parallel dispatch with model routing |
| 4 | **Verify** | GSD: verify-work; OMC: ultraqa | Conversational UAT + automated fix loops |
| 5 | **Persist** | GSD: progress, pause/resume; OMC: note, project-memory | Session continuity + context survival across compaction |
| 6 | **Loop** | OMC: ralph | Iterate on acceptance criteria until all pass + architect verify |
| 7 | **Interview** | OMC: deep-interview | Ambiguity scoring -> targeted questioning -> threshold gate |
| 8 | **Review** | OMC: code-review, security-review; skippy: review swarm | Multi-perspective audit with severity ratings |
| 9 | **Debug** | GSD: debug | Structured hypothesis -> subagent investigation |
| 10 | **Cleanup** | GSD: cleanup; skippy: cleanup | Ephemeral file management |
| 11 | **Remember** | Open Brain: semantic store, hooks, decision logging | Cross-session/cross-project semantic memory + auto-capture hooks |

## GSD Detail (32 -> 6 clusters)

### Kept

| Command | Classification | Core Pattern |
|---------|---------------|-------------|
| new-project | ESSENTIAL | Project bootstrap with questioning protocol |
| new-milestone | ESSENTIAL | Brownfield continuation with history preservation |
| plan-phase | ESSENTIAL | Research -> plan -> plan-checker verify loop |
| execute-phase | ESSENTIAL | Wave-based parallel execution with dependency analysis |
| quick | ESSENTIAL | Lightweight plan+execute for ad-hoc tasks |
| verify-work | ESSENTIAL | Conversational UAT with auto-diagnosis |
| progress | ESSENTIAL | State-aware routing ("where am I, what's next") |
| debug | USEFUL | Scientific debugging with subagent isolation |
| discuss-phase | USEFUL | Gray area identification before planning |
| map-codebase | USEFUL | Parallel codebase analysis |

### Cut

add-phase, insert-phase, remove-phase, complete-milestone, cleanup (ceremony),
plan-milestone-gaps, add-tests, validate-phase (retroactive paperwork),
reapply-patches, set-profile, settings (GSD-specific config),
update, join-discord, help (meta/marketing),
add-todo, check-todos (already skippy skills),
audit-milestone (superseded by skippy:review)

## OMC Detail (38 -> 7 patterns)

### Kept

| Command/Mode | Classification | Core Pattern |
|---|---|---|
| ralph | ESSENTIAL | Persistence loop with PRD + architect verification |
| ultrawork | ESSENTIAL | Parallel agent execution with model routing |
| ralplan | ESSENTIAL | Planner -> Architect -> Critic consensus loop |
| plan (omc-plan) | ESSENTIAL | Strategic planning with ambiguity detection |
| cancel | ESSENTIAL | State cleanup with dependency-aware cascading |
| ultraqa | USEFUL | Automated fix loop: check -> diagnose -> fix -> repeat |
| deep-interview | USEFUL | Socratic Q&A with ambiguity scoring |
| code-review | USEFUL | Multi-category severity-rated review |
| security-review | USEFUL | OWASP Top 10 + secrets detection |
| build-fix | USEFUL | Minimal-diff build error resolution |
| note | USEFUL | Tiered persistence (priority/working/manual) |
| hud | USEFUL | Real-time session status visibility |
| learner | USEFUL | Extract reusable skills from conversation |

### Cut

autopilot (ceremony wrapper around ralph), ralph-init (duplicates ralph),
tdd (one-line instruction), deepinit (team feature), skill (file CRUD),
learn-about-omc, omc-help, omc-setup, omc-doctor, release (self-referential),
ccg, ask-codex, ask-gemini, omc-teams (external CLI deps),
sciomc (over-engineered research), external-context (thin wrapper),
project-session-manager (duplicates cw aliases), configure-notifications,
configure-openclaw (deprecated), writer-memory (Korean fiction),
mcp-setup (one-time), analyze (thin wrapper)

## Open Brain Detail (18 -> 1 ability + reference docs)

### Kept as "Remember" ability

- Semantic memory store with vector search
- Cross-domain search (multi-table CTE)
- Hook-driven session continuity (PreCompact auto-save)
- Decision logging with rationale + alternatives

### Kept as reference docs

- MCP hook integration pattern (two-step handshake)
- Content hash deduplication (SHA-256 ON CONFLICT)
- Graceful embedding degradation (NULL + backfill)

### Cut

Relationship/people tracking, role-based auth matrix, MCP transport management,
embedding backfill configs, structured JSON logging, ToolDeps DI pattern,
pre-computed test embeddings, fetch-secrets integration
