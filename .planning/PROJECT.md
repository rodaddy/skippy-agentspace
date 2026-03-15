# skippy-agentspace

## What This Is

A skill curation engine for Claude Code. Users pull in any number of Claude Code marketplaces/plugins. Skippy audits each one, extracts the valuable patterns, coalesces them across sources into deduplicated abilities, and verifies every ability with Karpathy-style binary assertion eval loops. The output is a clean, personalized skill set -- quality-gated and self-improving.

## Core Value

**Consume -> Coalesce -> Eval -> Iterate -> Ship**

1. **Consume** -- audit any marketplace/plugin, classify every command as ESSENTIAL/USEFUL/CEREMONY/CUT, extract core patterns
2. **Coalesce** -- merge patterns across all consumed sources, deduplicate overlapping capabilities, produce minimal ability set
3. **Eval** -- run binary assertion loops (`evals/evals.json`) against each ability, score pass/fail
4. **Iterate** -- failed assertions trigger ONE targeted fix per iteration, re-eval, loop until perfect or max iterations
5. **Ship** -- verified abilities install into the user's Claude Code setup; when abilities improve, push updates back to repo

No other skill framework does steps 3-5. They all stop at "here's the skill, trust us." Skippy says "here's the skill, here's the assertions proving it works, and here's the score."

## How It Works For Any User

1. Install skippy-agentspace
2. `skippy:consume <marketplace-url>` -- audits the source, extracts patterns
3. `skippy:consume <another-marketplace>` -- repeat for N sources
4. `skippy:coalesce` -- merges all consumed patterns into abilities
5. `skippy:eval` -- runs assertion loops, auto-fixes failures
6. Result: personalized, quality-verified ability set

The 11 default abilities (Bootstrap, Plan, Execute, Verify, Persist, Loop, Interview, Review, Debug, Cleanup, Remember) are what falls out when the inputs are GSD+OMC+PAUL+Open Brain. Different sources produce different abilities.

## Lessons From First Manual Run (2026-03-13)

The v2.0 pipeline was first run manually this session. These failures become features:

| What Went Wrong | Pipeline Feature It Becomes |
|----------------|---------------------------|
| Install nearly regressed 11 PAI skills with older repo snapshots (`cp -R` created nested dirs) | **Pre-consume diff** -- before absorbing, compare source vs installed versions. Never overwrite newer with older. |
| Backup only covered `~/.claude/`, missed `~/.config/pai/` | **Full-scope backup** -- consume step snapshots ALL affected directories before any modification |
| 75 individual symlinks maintained by hand when 1 directory symlink works | **Architecture audit** -- consume step should detect and flag structural inefficiencies like symlink sprawl |
| No conflict detection between sources | **Cross-source overlap detection** -- coalesce step must identify when two sources provide the same capability and pick the better one, not install both |
| Security hooks blocked destructive operations (rm), had to use mv | **Non-destructive operations only** -- pipeline uses mv-to-tmp, never rm. Hooks are allies, not obstacles |
| Eval prompts discovered by accident on Desktop | **Eval-first discovery** -- consume step should scan for existing evals/assertions in both source AND target, merge them |
| Audit agents worked great but results weren't captured | **Audit persistence** -- every consume produces a structured audit doc in `.planning/audits/` automatically |
| Manual classification (ESSENTIAL/USEFUL/CEREMONY/CUT) was time-consuming | **Classification heuristics** -- pattern-match common ceremony indicators (help commands, setup wizards, self-referential tooling, deprecated wrappers) for pre-classification |

## Milestones

### v2.0 Curation Engine (next)

The consume -> coalesce -> eval -> iterate pipeline. Turns skippy-agentspace from "12 portable skills" into a skill curation framework for any Claude Code user.

**What ships:**
- `skippy:consume <source>` -- audit a marketplace/plugin, extract patterns, classify, persist results
- `skippy:coalesce` -- merge all consumed patterns into abilities, deduplicate, cut overlap
- `skippy:eval` -- Karpathy-style binary assertion loop per ability, auto-fix, iterate to perfect
- `skippy:status` -- show consumed sources, abilities, scores, overlap
- Pre-consume diff (never regress installed skills)
- Full-scope backup before any modification
- Cross-source overlap detection and resolution
- Audit persistence (`.planning/audits/`)
- 11 default abilities from GSD+OMC+PAUL+Open Brain pre-consumed

**Architecture:**
- Each consumed source gets an entry in `upstreams/` with audit results
- Each ability is a skill dir with SKILL.md + commands/ + references/ + evals/
- `evals/evals.json` defines binary assertions per ability
- `evals/results.md` tracks scores and iteration history
- The 18 existing reference docs become the knowledge base for pattern classification

### v1.2 Standalone Skippy (shipped 2026-03-08)

Skippy IS the framework -- no external dependencies on GSD, PAUL, or OMC at runtime. 6 phases, 14 plans, 22 requirements -- all satisfied.

**What shipped:**
- Shared shell library (`tools/lib/common.sh`) with DRY extraction across all tool scripts
- bats-core test suite (37 tests) with vendored submodules and sandboxed HOME isolation
- GSD pattern absorption into 4 standalone reference docs -- zero runtime GSD dependency
- Multi-agent audit swarm (`/skippy:review`) with 6 specialist subagent definitions
- deploy-service hardening (`config.env` mechanism) + version bump automation (`bump-version.sh`)
- CONTRIBUTING.md, `.gitattributes` export-ignore, CI workflow, standalone identity framing

### v1.1 Portable PAI (shipped 2026-03-08)

12 skills across 4 categories, 15 reference docs, 3 upstream tracking configs, bootstrap tools.

### v1.0 Initial Release (shipped 2026-03-07)

Origin documentation, 5 PAUL enhancement reference docs, 3 utility commands, install/uninstall tooling.

## Requirements

### Validated

<!-- Shipped in v1.0 and confirmed working. -->

- ✓ Origin documentation -- full story of why this exists -- v1.0
- ✓ 5 PAUL enhancement reference docs with real, actionable content -- v1.0
- ✓ `/skippy:reconcile` command works against a real `.planning/` project -- v1.0
- ✓ `/skippy:update` script clones both repos, tracks versions, reports diffs -- v1.0
- ✓ `/skippy:cleanup` script quarantines or nukes ephemeral files -- v1.0
- ✓ Install/uninstall tooling correctly symlinks skills -- v1.0
- ✓ Index sync validates INDEX.md matches actual skills -- v1.0
- ✓ Cold session context for new sessions -- v1.0
- ✓ CLAUDE.md includes origin story and architectural decisions -- v1.0
- ✓ All scripts pass basic functional testing -- v1.0
- ✓ OMC analysis and cherry-pick (third upstream alongside GSD and PAUL) -- v1.1
- ✓ Extensible upstream system -- add new packages/marketplaces to cherry-pick from -- v1.1
- ✓ Core infrastructure package (personas, LAWs, hooks, commands) -- v1.1
- ✓ All PAI skills restructured to slim SKILL.md + deep references pattern -- v1.1
- ✓ Add-on skill system (opt-in installation per skill) -- v1.1
- ✓ New machine bootstrap (clone + install = working PAI) -- v1.1

### Active

<!-- All milestones through v1.2 shipped. -->

All v1.2 requirements satisfied. See `REQUIREMENTS.md` for full traceability and `.planning/milestones/` for archived snapshots.

### Out of Scope

- Forking GSD or PAUL -- historical source attribution only
- Auto-merging upstream changes -- `/skippy:update` reports, human decides
- BDD Given/When/Then ceremony for acceptance criteria -- too much overhead for solo dev
- PAUL's "no subagents for execution" philosophy -- parallel execution is correct at scale
- Publishing to npm or any package registry -- private repo, manual install

## Context

### Origin Story

On 2026-03-06, we watched a YouTube video (MppKHh_MfFc) comparing GSD vs the PAUL framework. After running `fabric extract_wisdom` on it, we cloned PAUL's repo (ChristopherKahler/paul) and did a deep code review.

**What PAUL does well (stolen):**
1. **Context Brackets** -- FRESH/MODERATE/DEEP/CRITICAL behavior adaptation based on context window usage
2. **Mandatory Reconciliation (UNIFY)** -- plan-vs-actual comparison after every phase
3. **Task Anatomy** -- 4 required fields per task: files, action, verify, done
4. **Plan Boundaries** -- explicit DO NOT CHANGE and SCOPE LIMITS in every plan
5. **State Consistency** -- cross-file alignment verification at phase transitions

**What PAUL gets wrong (rejected):**
- No subagents for execution -- works for tiny projects, dies at scale
- "Plans are prompts" -- clever framing for "write specific plans," not novel
- BDD for every acceptance criterion -- ceremony for ceremony's sake on solo projects
- The "70% context loss" claim about GSD subagents -- GSD writes structured artifacts for context transfer

### Architectural Decision

Three approaches were considered:

| Approach | Pros | Cons |
|----------|------|------|
| **PAI Skill + Hooks** (chosen) | No forks, modular, zero upstream maintenance | Derived from GSD patterns |
| Full Skippy Framework | Full control, unified commands | Massive maintenance, diverges from both upstreams |
| Just Patch GSD | 30 minutes of work | No update mechanism, per-project, coupled to GSD internals |

We chose the portable skill repo approach: standalone execution with source attribution to GSD and PAUL, plus utility commands for reconciliation, upstream monitoring, and cleanup.

### Relationship to PAI

- **Source:** This repo (`skippy-agentspace/`) is the development copy
- **Installed copy:** `~/.config/pai/Skills/skippy/` (symlinked via `tools/install.sh`)
- **Commands registered:** `~/.claude/commands/skippy/` (symlinks to `skills/skippy/commands/`)
- **Agent access:** Listed in `~/.config/pai/Skills/AGENT-INDEX.md` under "Development Workflow"

### Backup

Pre-change backup created at `~/Desktop/claude_setup/backup-2026-03-06-skippy/` with restore script. Ephemeral files (2.5G of debug/telemetry/history) quarantined to `/Volumes/ThunderBolt/_tmp/claude-cleanup-2026-03-06/`.

## Constraints

- **Portability**: Every skill must work with vanilla Claude Code (`~/.claude/commands/`). PAI enhancements are optional.
- **Self-contained**: Each skill declares its own triggers, references, and commands. No cross-skill imports.
- **Slim core**: SKILL.md is the entry point (~150 lines max). Detail lives in `references/`.
- **Standalone execution**: Skippy defines its own execution protocol via reference docs. GSD credited as source, not required as dependency.
- **Stack**: Shell scripts (`#!/usr/bin/env bash`) for tools, markdown for rules/references. Bun/TypeScript for structured data operations (YAML parsing, state management).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Portable skill repo over fork | Zero maintenance, modular, upgradeable | -- Pending |
| Reference docs over hooks | Hooks can't detect context usage; rules are self-enforced | -- Pending |
| Shell scripts for tooling | No build step, no dependencies, portable | -- Pending |
| Quarantine before delete for cleanup | Safer -- verify nothing breaks before nuking | -- Pending |
| Separate agentspace repo | Skills should be portable, not buried in PAI config | -- Pending |

---
*Last updated: 2026-03-08 after v1.2 milestone complete*
