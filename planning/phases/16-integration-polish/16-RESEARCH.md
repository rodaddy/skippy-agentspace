# Phase 16: Integration & Polish - Research

**Researched:** 2026-03-08
**Domain:** Documentation consistency, verification, standalone identity framing
**Confidence:** HIGH

## Summary

Phase 16 is a documentation and verification polish pass -- no new features, no new code logic. All v1.2 features (Phases 11-15) are complete. The work is: (1) create CONTRIBUTING.md (FOUND-03), (2) update CLAUDE.md and README.md to reflect standalone identity, (3) fix verify.sh to check for the `review` command, (4) regenerate INDEX.md, and (5) run the full verification suite.

The codebase is in good shape. `tools/verify.sh` currently passes with 24 pass, 1 warning, 0 failures. `bats tests/` passes all 37 tests. The main gaps are stale documentation that still references pre-absorption framing ("used as-is", "0 (dependency)", "15 reference docs" when there are now 18, "GSD dependency map" still listed as a reference doc).

**Primary recommendation:** This phase is pure documentation work. Three plans max: (1) CONTRIBUTING.md creation, (2) CLAUDE.md + README.md standalone identity update, (3) verify.sh fix + final verification pass.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FOUND-03 | `CONTRIBUTING.md` documents how to add skills, run tests, and submit changes | Skill structure patterns documented in CONVENTIONS.md, SKILL.md convention in skills/skippy/SKILL.md, test runner is `bats tests/` and `tools/integration-test.sh`, branching convention is feat/fix/wip/ branches (hook-enforced) |
</phase_requirements>

## Current State Audit

### Files That Need Changes

| File | Issue | Required Change |
|------|-------|-----------------|
| `CONTRIBUTING.md` | Does not exist | Create with skill addition, testing, and submission guidance |
| `CLAUDE.md` line 3 | "Cherry-picks the best workflow ideas from GSD and PAUL" | Update to standalone framing -- skippy IS the framework |
| `CLAUDE.md` line 14 | "Not a fork. All upstreams ride unchanged" | Update -- upstreams are now historical sources, not active dependencies |
| `CLAUDE.md` line 118 | "No GSD dependency" constraint | Already says "Standalone execution" -- verify and strengthen |
| `README.md` line 7 | "15 reference docs" | Update to 18 (3 added in Phase 13, 1 in Phase 14, 2 deleted) |
| `README.md` line 51 | "Cherry-Picked Reference Docs (15)" | Update to 18 |
| `README.md` lines 55-63 | Reference doc grouping misses Phase 13/14 additions | Add phased-execution, state-tracking, checkpoints, audit-swarm to listing |
| `README.md` line 62 | Lists "GSD dependency map" (deleted in Phase 13) | Remove, replace with current docs |
| `README.md` line 70 | "Phased execution framework (used as-is) \| 0 (dependency)" | Change to "Historical source of phased execution patterns \| 9" (or count actual cherry-picks) |
| `README.md` lines 107-109 | Testing only shows `integration-test.sh` | Add `bats tests/` instructions |
| `tools/verify.sh` line 209 | Checks `reconcile update cleanup migrate upgrade` | Add `review` to the command check list |
| `INDEX.md` | Already has `/skippy:review` | Regenerate via `tools/index-sync.sh --generate` to confirm consistency |

### Files That Are Fine

| File | Status | Evidence |
|------|--------|---------|
| `INDEX.md` | Already lists `/skippy:review` | `verify.sh` reports "INDEX.md is consistent with skills/" |
| `skills/skippy/SKILL.md` | Already has 18 enhancement rows including audit-swarm | Verified in Phase 14 |
| `skills/skippy/commands/review.md` | Exists | `ls` confirmed 6 commands including review.md |
| `skills/` directory | Zero GSD dependency language | Phase 13 verification confirmed |
| `tools/lib/common.sh` | Functioning | verify.sh sources it successfully |
| All bats tests | 37/37 pass | Confirmed via `bats tests/` run |

## Architecture Patterns

### CONTRIBUTING.md Structure

Based on project conventions (CONVENTIONS.md, SKILL.md pattern, existing docs):

```
CONTRIBUTING.md
  ## Adding a Skill
    - Directory structure (skills/<name>/)
    - SKILL.md frontmatter requirements (name, description, metadata.version/author/source/category)
    - Slim SKILL.md convention (<150 lines, deep refs in references/)
    - Integration checklist (marketplace.json, INDEX.md via index-sync.sh)
  ## Running Tests
    - bats tests/ (unit tests, 37 cases, sandboxed HOME)
    - tools/integration-test.sh (full suite, 36 tests, clones upstreams)
    - tools/integration-test.sh --quick (skip upstream clones)
    - tools/verify.sh (health check)
  ## Submitting Changes
    - Branch naming: feat/, fix/, wip/ (hook-enforced, never commit to main)
    - PR workflow
    - Shell conventions (#!/usr/bin/env bash, shellcheck, set -euo pipefail)
  ## Conventions
    - Reference to CONVENTIONS.md for full details
    - skippy_ namespace for shared functions
    - validate_skill_name() for user input
    - No cross-skill imports (portability constraint)
```

### Standalone Identity Framing

The key messaging shift for CLAUDE.md and README.md:

| Old Framing | New Framing |
|-------------|-------------|
| "Cherry-picks from GSD and PAUL" | "Standalone framework with patterns adapted from GSD, PAUL, and OMC" |
| "Not a fork. All upstreams ride unchanged" | "Standalone skill framework. Upstream repos are historical sources, not runtime dependencies" |
| "Phased execution framework (used as-is)" | "Historical source of phased execution patterns" |
| "0 (dependency)" | Count of patterns adapted (9 or similar) |
| "15 reference docs" | "18 reference docs" |
| "GSD dependency map" in reference list | Replace with "phased execution, state tracking, checkpoints, audit swarm" |
| "No GSD modification" constraint | "Standalone execution" (already done in PROJECT.md -- propagate to CLAUDE.md) |

### verify.sh Command Check Fix

The fix is a single line change -- add `review` to the command name loop on line 209:

```bash
# Current:
for cmd_name in reconcile update cleanup migrate upgrade; do

# Fixed:
for cmd_name in reconcile update cleanup migrate upgrade review; do
```

This brings the check from 5 to 6 commands, matching the actual command count.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| INDEX.md regeneration | Manual edits | `tools/index-sync.sh --generate` | Auto-generates from SKILL.md frontmatter |
| Reference doc count | Manual counting | `ls skills/skippy/references/ \| wc -l` | Source of truth is the directory |
| Verify.sh testing | Ad-hoc manual runs | `bats tests/verify.bats` | Existing tests cover verify.sh behavior |

## Common Pitfalls

### Pitfall 1: Stale Numbers in Multiple Locations
**What goes wrong:** Updating "15 reference docs" in one place but missing it in another.
**Why it happens:** README.md mentions the count in at least 2 places (line 7 and line 51).
**How to avoid:** grep for "15 reference" across all files before declaring done.
**Warning signs:** Numbers don't match `ls references/ | wc -l`.

### Pitfall 2: Over-Cleaning GSD References in .planning/
**What goes wrong:** Removing GSD references from .planning/ historical artifacts (plans, summaries, verifications) that are meant to be historical records.
**Why it happens:** Grepping for "GSD" and replacing everywhere.
**How to avoid:** Only update DISTRIBUTED content (CLAUDE.md, README.md, CONVENTIONS.md). Leave .planning/ history untouched -- it's export-ignored via .gitattributes anyway.
**Warning signs:** Editing files in `.planning/phases/*/` that are completed phase artifacts.

### Pitfall 3: Breaking verify.sh While Fixing It
**What goes wrong:** Adding `review` to the command check loop but introducing a syntax error.
**Why it happens:** verify.sh uses `set -euo pipefail` -- any error kills the script.
**How to avoid:** Run `bats tests/verify.bats` after the change. Also run `verify.sh` directly.
**Warning signs:** verify.sh exits with non-zero before reaching Summary.

### Pitfall 4: CONTRIBUTING.md Too Long or Too Detailed
**What goes wrong:** Creating a 200+ line CONTRIBUTING.md with excessive detail about internals.
**Why it happens:** Trying to document everything instead of referencing existing docs.
**How to avoid:** Keep it under 100 lines. Reference CONVENTIONS.md, SETUP.md, INSTALL.md for details. CONTRIBUTING.md is a routing document, not a comprehensive guide.
**Warning signs:** Duplicating content from CONVENTIONS.md or SETUP.md.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bats-core (vendored submodule at tests/bats/) |
| Config file | None (bats uses convention-based test discovery) |
| Quick run command | `./tests/bats/bin/bats tests/` |
| Full suite command | `./tests/bats/bin/bats tests/ && bash tools/integration-test.sh` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-03 | CONTRIBUTING.md exists with required sections | smoke | `test -f CONTRIBUTING.md && grep -q "Adding a Skill" CONTRIBUTING.md && grep -q "Running Tests" CONTRIBUTING.md && grep -q "Submitting Changes" CONTRIBUTING.md` | N/A (file check) |
| SC-1 | CONTRIBUTING.md has SKILL.md convention section | smoke | `grep -q "SKILL.md" CONTRIBUTING.md` | N/A |
| SC-2 | CLAUDE.md has standalone identity framing | smoke | `grep -q "Skippy IS the framework\|standalone" CLAUDE.md && ! grep -q "No GSD modification" CLAUDE.md` | N/A |
| SC-3 | verify.sh passes with zero failures | integration | `bash tools/verify.sh` | Existing |
| SC-4 | INDEX.md consistent after regeneration | integration | `bash tools/index-sync.sh --check` | Existing |
| SC-5 | README.md has bats test instructions | smoke | `grep -q "bats tests/" README.md` | N/A |
| SC-6 | verify.sh checks review command | unit | `grep -q "review" tools/verify.sh` | Existing |

### Sampling Rate

- **Per task commit:** `bash tools/verify.sh && ./tests/bats/bin/bats tests/verify.bats`
- **Per wave merge:** `./tests/bats/bin/bats tests/`
- **Phase gate:** Full suite green + verify.sh zero failures

### Wave 0 Gaps

None -- existing test infrastructure covers all phase requirements. No new test files needed for this documentation phase.

## Code Examples

### CONTRIBUTING.md Skeleton

```markdown
# Contributing to skippy-agentspace

## Adding a Skill

1. Create `skills/<name>/` directory
2. Create `SKILL.md` with required frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: <one-line description>
   metadata:
     version: 0.1.0
     author: <name>
     source: https://github.com/rodaddy/skippy-agentspace
     category: core|workflow|utility|domain
   ---
   ```
3. Keep SKILL.md under 150 lines -- detail goes in `references/` subdirectory
4. Register in `.claude-plugin/marketplace.json`
5. Run `bash tools/index-sync.sh --generate` to update INDEX.md

## Running Tests

```bash
# Unit tests (bats-core, sandboxed HOME)
./tests/bats/bin/bats tests/

# Health check
bash tools/verify.sh

# Full integration suite
bash tools/integration-test.sh
bash tools/integration-test.sh --quick   # skip upstream clones
```

## Submitting Changes

- Branch naming: `feat/`, `fix/`, `wip/` prefixes (hook-enforced)
- Never commit directly to main
- Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`
- Run tests before submitting

See [CONVENTIONS.md](CONVENTIONS.md) for coding conventions and content classification.
```

### verify.sh Command Fix

```bash
# Line 209 -- add review to the loop
for cmd_name in reconcile update cleanup migrate upgrade review; do
```

### README.md Upstream Table Fix

```markdown
| Upstream | What We Take | Patterns Adapted |
|----------|-------------|-----------------|
| [GSD](https://github.com/gsd-build/get-shit-done) | Historical source of phased execution patterns | 9 |
| [PAUL](https://github.com/ChristopherKahler/paul) | 5 planning discipline ideas | 5 |
| [OMC](https://github.com/anthropics/oh-my-claudecode) | 4 execution readiness patterns | 4 |
```

## State of the Art

| Old State (pre-Phase 16) | New State (post-Phase 16) | Impact |
|--------------------------|---------------------------|--------|
| README says "15 reference docs" | README says "18 reference docs" | Accurate count |
| README lists "GSD dependency map" reference | Lists phased-execution, state-tracking, checkpoints, audit-swarm | Reflects absorption |
| GSD shown as "dependency" in README upstream table | GSD shown as "historical source" | Standalone positioning |
| CLAUDE.md says "Cherry-picks from GSD and PAUL" | Says "Standalone framework with adapted patterns" | Identity shift |
| verify.sh checks 5 commands | verify.sh checks 6 commands (adds review) | Complete verification |
| No CONTRIBUTING.md | CONTRIBUTING.md with skill addition, testing, submission guidance | FOUND-03 satisfied |
| README testing shows only integration-test.sh | README testing shows both bats and integration-test.sh | Complete test docs |

## Open Questions

1. **GSD cherry-pick count for README upstream table**
   - What we know: Phase 13 absorbed 4 patterns (phased-execution, state-tracking, plan-structure, checkpoints) plus 5 existing reference docs reference GSD ideas
   - What's unclear: Exact count of GSD-sourced patterns to show in the table
   - Recommendation: Count reference docs with "Adapted from GSD" source footers. Use that number. If uncertain, use "9" (the count of non-GSD-specific reference docs that trace to GSD patterns)

2. **CLAUDE.md Project Status table update scope**
   - What we know: Phase status table in CLAUDE.md stops at Phase 11. Phases 12-16 are not listed.
   - What's unclear: Should we add all v1.2 phases to the table or keep it minimal?
   - Recommendation: Add Phases 12-16 to the status table for completeness since this is the v1.2 closing phase.

## Sources

### Primary (HIGH confidence)
- Direct file inspection of all affected files (CLAUDE.md, README.md, verify.sh, INDEX.md, SKILL.md)
- `tools/verify.sh` output (24 pass, 1 warning, 0 failures)
- `bats tests/` output (37/37 pass)
- `ls skills/skippy/references/` (18 files)
- Phase 13 VERIFICATION.md (confirmed GSD language cleanup in skills/)

### Secondary (MEDIUM confidence)
- Phase 13-15 plan summaries for understanding what changed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new libraries, pure documentation
- Architecture: HIGH - CONTRIBUTING.md structure follows established patterns (SETUP.md, INSTALL.md, UPGRADE.md)
- Pitfalls: HIGH - identified from direct codebase inspection and project history

**Research date:** 2026-03-08
**Valid until:** No expiry -- documentation/polish phase with no external dependencies
