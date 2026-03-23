# Marketplace Audit: gstack -- 2026-03-21

**Source:** [garrytan/gstack](https://github.com/garrytan/gstack) (v0.9.8.0, 742 commits)
**Author:** Garry Tan (YC President & CEO)
**Philosophy:** Ordered sprint pipeline. Think -> Plan -> Build -> Review -> Test -> Ship -> Monitor.

## Summary

| Metric | Value |
|--------|-------|
| Skills audited | 25 |
| NOVEL (no SAS equivalent) | 3 |
| PARTIAL (SAS covers base, gstack adds value) | 16 |
| DUPLICATE (already have this) | 6 |
| Extractable patterns | 8 |
| New abilities needed | 0 |
| Existing abilities enriched | 5 |

**Key finding:** gstack's value is in workflow discipline, not new capabilities. The 8 extractable patterns all strengthen existing SAS abilities -- no new abilities needed. This is enrichment, not expansion.

## Security Gate Results (External Trust)

| Verdict | Count | Notes |
|---------|-------|-------|
| SAFE | 14 | Clean -- no findings |
| CAUTION | 1 | gstack-upgrade (supply chain: git clone) |
| DANGEROUS | 10 | All from legitimate browser automation + curl |

Zero actual threats. All 10 "dangerous" hits are from headless Chromium patterns and curl-based health checks -- expected for a framework with a browser daemon.

## Classification Detail

### NOVEL (3) -- New Patterns, Not New Skills

| Skill | What It Does | Extract As |
|-------|-------------|------------|
| **codex** | Second opinion from different AI model + cross-model agreement analysis | Pattern for Review ability: "adversarial cross-model check" |
| **design-review** | Interactive 0-10 rating per design dimension with "what would make this a 10" | Pattern for Plan ability: "design dimension scoring" |
| **setup-browser-cookies** | Import auth cookies from real browser into headless session | Pattern for browser skill: "cookie bridge for authenticated testing" |

None of these warrant standalone skills. codex's pattern folds into Review. design-review folds into Plan. Cookie bridge folds into the browser skill.

### PARTIAL (16) -- Patterns Worth Extracting

| Skill | SAS Equivalent | Extractable Pattern |
|-------|---------------|---------------------|
| **benchmark** | (none) | Performance budget thresholds: TTFB/FCP/LCP extraction via `performance.getEntries`, 50% regression = alert |
| **canary** | deploy-service | Post-deploy monitoring loop: baseline capture, continuous checks, transient tolerance (2+ consecutive failures before alert) |
| **design-consultation** | (none) | Design system scaffolding: aesthetic direction enum, SAFE/RISK breakdown, HTML preview with font/color dogfooding |
| **document-release** | session-wrap | Diff-based doc sync: cross-ref `git diff` against README/ARCHITECTURE/CONTRIBUTING, auto-update factual items, flag narrative changes |
| **investigate** | Debug | 4-phase root cause discipline: investigate -> analyze -> hypothesize -> implement. Iron law: no fix without root cause confirmed |
| **land-and-deploy** | deploy-service | Post-merge orchestration: wait for CI, verify prod health, integrate canary checks. Distinct from provisioning |
| **office-hours** | (none) | Forcing questions: demand reality, status quo, desperate specificity, narrowest wedge, observation, future-fit |
| **plan-ceo-review** | skippy:plan | 4 scope modes: EXPAND / SELECTIVE-EXPAND / HOLD / REDUCE with interactive selection |
| **plan-design-review** | skippy:plan | Design dimension scoring applied to plan files (not live sites) |
| **plan-eng-review** | skippy:plan | Eng review checklist: architecture, data flow, edge cases, test coverage, performance |
| **qa** | (none) | Atomic QA loop: find bug -> fix -> commit atomic -> re-verify. 3 tiers (quick/standard/exhaustive). Health scores |
| **qa-only** | (none) | Report-only QA: structured report with health score + screenshots + repro steps, zero code changes |
| **retro** | (none) | Weekly retrospective: commit history analysis, per-person breakdown, trend tracking, praise + growth |
| **review** | skippy:review | SQL safety checks, LLM trust boundary checks, conditional side-effect detection |
| **setup-deploy** | deploy-service | Deploy config wizard: detect platform (Fly/Render/Vercel/etc), prod URL, health endpoints |
| **ship** | Git skill | Ship orchestration: detect base, run tests, review diff, bump VERSION, update CHANGELOG, push, create PR |

### DUPLICATE (6) -- Already Have These

| Skill | SAS Equivalent | Notes |
|-------|---------------|-------|
| browse | browser (MCP) | Both do headless Chromium. gstack's is a compiled daemon; SAS uses agent-browser MCP. Different implementation, same capability |
| careful | pre-exec-guard.ts | We just built this. gstack's pattern list is a subset of ours (23 vs their ~12) |
| freeze | (hook pattern) | Directory-scoped edit blocking. Trivial hook -- not worth importing |
| guard | careful + freeze | Composite of two duplicates |
| gstack-upgrade | skippy:upgrade | Self-upgrade machinery. Project-specific |
| unfreeze | (freeze cleanup) | State file deletion. 5 lines of logic |

## Coalesced Output: 8 Patterns -> 5 Existing Abilities

**Zero new abilities. Zero new skills. Patterns enrich what we already have.**

| Existing Ability | Patterns Absorbed | Source Skills |
|-----------------|-------------------|--------------|
| **Plan** | Forcing questions (pre-planning conversation), scope modes (expand/hold/reduce), design dimension scoring (0-10 with "what makes this a 10") | office-hours, plan-ceo-review, plan-design-review, design-review |
| **Debug** | 4-phase root cause discipline (investigate -> analyze -> hypothesize -> implement), iron law enforcement | investigate |
| **Verify** | Atomic QA-test-fix loop (find -> fix -> commit -> re-verify), post-deploy monitoring with transient tolerance, performance budget thresholds | qa, canary, benchmark |
| **Review** | Cross-model adversarial check, SQL safety patterns, LLM trust boundary checks, diff-based doc sync | codex, review, document-release |
| **Execute** | Ship orchestration (base detect -> test -> diff review -> version bump -> PR) | ship |

### What We DON'T Pull

| Category | Skills | Why Skip |
|----------|--------|----------|
| Browser infra | browse, setup-browser-cookies | We have agent-browser MCP. Cookie bridge is interesting but niche |
| Safety hooks | careful, freeze, guard, unfreeze | pre-exec-guard.ts already covers this with more patterns |
| Meta/self | gstack-upgrade | Project-specific |
| Design system | design-consultation | Too opinionated for SAS (assumes web frontend). Extract as reference doc if needed later |
| Retrospective | retro | Interesting but better as an Open Brain query than a skill |
| Report-only QA | qa-only | qa's pattern covers both modes (fix vs report) -- separate skill is unnecessary |
| Deploy wizard | setup-deploy | deploy-service handles PAI's infra. Platform detection for Fly/Vercel/etc not relevant |

## Implementation Notes

The 8 patterns are **reference docs**, not code. They'd land as:

```
skills/skippy/references/pattern-forcing-questions.md
skills/skippy/references/pattern-root-cause-discipline.md
skills/skippy/references/pattern-atomic-qa-loop.md
skills/skippy/references/pattern-post-deploy-monitoring.md
skills/skippy/references/pattern-scope-modes.md
skills/skippy/references/pattern-design-scoring.md
skills/skippy/references/pattern-cross-model-review.md
skills/skippy/references/pattern-diff-doc-sync.md
```

Each is a ~50-80 line markdown file that the relevant skill command reads when needed. Zero new TypeScript. Zero new slash commands. The existing `/skippy:plan`, `/skippy:review`, Debug skill, and Verify patterns just get richer context.

**Estimated total addition:** ~500 lines of reference docs across 8 files.

## Comparison to Previous Audits

| Source | Audited | Kept | Cut Rate | New Abilities |
|--------|---------|------|----------|---------------|
| GSD | 32 | 10 | 69% | 6 |
| OMC | 38 | 13 | 66% | 3 |
| PAUL | 5 | 5 | 0% | 2 |
| Open Brain | 18 | 6 | 67% | 1 |
| **gstack** | **25** | **8 patterns** | **68%** | **0** |

gstack confirms the pattern: ~2/3 of any framework is ceremony or overlap. The remaining 1/3 distills into patterns that enrich existing abilities. At this point (4th source consumed), we're seeing diminishing returns on new abilities -- which is exactly right. The taxonomy is stabilizing.
