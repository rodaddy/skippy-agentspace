# Marketplace Re-Audit -- 2026-04-06

Re-audit of all 5 tracked upstream sources, triggered by 24 days of upstream activity since the original audit (2026-03-13).

## Summary

| Source | Version at Original Audit | Current Version | Releases Since | New Commands | Patterns Extracted |
|--------|--------------------------|-----------------|----------------|--------------|-------------------|
| GSD | ~v1.22 | v1.34.2 | 13 | 11 (4 useful) | Gates taxonomy, review depth, stall detection, audit-to-fix |
| OMC | v4.7.3 | v4.10.2 | 10 | 11 (4 useful) | Sealed eval, 3-point injection, worktree-per-issue, anti-slop |
| gstack | ~v0.9 | v0.15.13 | 15+ | 11 (4 useful) | Adaptive review gating, DX boomerang, health trending, content security |
| PAUL | v1.0 | v1.2 | 2 | 23 (3 useful) | Diagnostic failure routing, evidence-before-claims, coherence check |
| superpowers | v5.0.5 | v5.0.7 | 2 | 0 (minor) | Agent-facing guardrails (deferred) |

## Ability Taxonomy Assessment

**11 abilities remain stable.** No new abilities needed. All patterns extracted enrich existing abilities:

| Ability | Patterns Added | Sources |
|---------|---------------|---------|
| Verify (#4) | Gates taxonomy, sealed eval, stall detection, audit-to-fix, DX boomerang, diagnostic failure routing, evidence-before-claims | GSD, OMC, gstack, PAUL |
| Review (#8) | Adaptive review gating, anti-slop mode, review depth tiers | gstack, OMC, GSD |
| Plan (#2) | Coherence check | PAUL |
| Interview (#7) | 3-point injection pipeline | OMC |
| Persist (#5) | Worktree-per-issue | OMC |
| Remember (#11) | Health trending | gstack |

## Open Brain Integration Update

OB updated from v1.1 to current (16 commits). Key additions:
- Cognitive tiering system (hot/warm/cold) with RRF boosts
- New tool: set_tier
- Tier parameter added to search_brain, search_all, list_recent
- Brain skill updated to v0.3.0 to reflect changes

## New Ecosystem Sources Evaluated

| Source | Stars | Verdict | Reason |
|--------|-------|---------|--------|
| OthmanAdi/planning-with-files | 18.1K | Not tracked | Manus-style planning, may evaluate later |
| VoltAgent/awesome-agent-skills | 14.4K | Not tracked | Aggregator, useful as future consume source |
| trailofbits/skills | 4.3K | Not tracked | Security research, niche but high quality |
| muratcankoylan/Agent-Skills-for-Context-Engineering | ~14.8K | Cherry-pick only | 3 reference patterns extracted, not tracked as upstream |
| JuliusBrussee/caveman | 3.9K | Not tracked | Token reduction, may evaluate later |

## OMC URL Correction

The OMC upstream URL was corrected in CLAUDE.md from `anthropics/oh-my-claudecode` to `Yeachan-Heo/oh-my-claudecode`. The upstream.json already had the correct URL.

## Reference Docs Created/Updated

### New Reference Docs
- `gates-taxonomy.md` -- 4 canonical gate types (GSD)
- `sealed-eval.md` -- Tamper-proof benchmark pattern (OMC)
- `context-degradation.md` -- 5 failure modes (Context Engineering)

### Enriched Reference Docs
- `verification-loops.md` -- +5 patterns (diagnostic routing, evidence-before-claims, stall detection, audit-to-fix, DX boomerang)
- `audit-swarm.md` -- +3 patterns (adaptive gating, anti-slop mode, review depth tiers)
- `plan-structure.md` -- +1 pattern (coherence check)
- `ambiguity-scoring.md` -- +1 pattern (3-point injection)

## Methodology

- 5 parallel scout agents gathered commits, releases, and README changes
- 5 parallel deep-audit agents classified new commands and extracted patterns
- Pattern classification: ESSENTIAL (novel, extract), USEFUL (enriches existing), CEREMONY (source-specific, skip), CUT (duplicate)
- All pattern extractions written as reference docs in skills/skippy/references/
