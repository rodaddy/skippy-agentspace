# Retrospective

## v1.2 Standalone Skippy (2026-03-08)

### What Was Built

6 phases, 14 plans, 22 requirements, 74 commits. 309 files changed, ~41K insertions.

- **Phase 11 -- Foundation:** Shared shell library (`tools/lib/common.sh`) with 8 `skippy_`-namespaced functions. DRY extraction across all 6 tool scripts with source-with-fallback pattern. `.gitattributes` with 14 export-ignore entries.
- **Phase 12 -- Testing:** bats-core test suite with 37 tests across 6 `.bats` files. Vendored test dependencies via git submodules. Sandboxed HOME isolation (`$BATS_TEST_TMPDIR`) so no test touches real `~/.claude/`. GitHub Actions CI workflow.
- **Phase 13 -- GSD Absorption:** 4 standalone reference docs (phased-execution, state-tracking, plan-structure, checkpoints) absorbing GSD's core execution patterns. `skippy-state.ts` parser for markdown+YAML task format. Zero "requires GSD" language in distributed content.
- **Phase 14 -- Audit Swarm:** `/skippy:review` command with 6 specialist subagent definitions (security, code-quality, architecture, consistency, fix, eval). 3-layer sandbox protocol (HOME override, worktree isolation, tool restrictions). Shared findings board protocol.
- **Phase 15 -- Hardening:** `config.env` mechanism replacing 9 hardcoded placeholders in deploy-service. `bump-version.sh` for atomic version updates across 26 locations in 13 files. Portable `_sed_inplace` helper for GNU/BSD compatibility.
- **Phase 16 -- Integration:** CONTRIBUTING.md as a routing doc. Standalone identity framing across CLAUDE.md and README.md. Final verification pass confirming all changes consistent.

### What Worked

**Wave-based parallelism in phase execution.** Phases 11, 13, and 14 had no dependencies on each other and could execute in parallel (Wave 1). Phases 12 and 15 depended on Phase 11 only (Wave 2). Phase 16 depended on all (Wave 3). This kept the critical path short.

**Multi-agent audit swarm pattern.** The v1.1 audit process (7 rounds, 23 agents, 17 findings) proved that multi-angle reviews catch what single-pass misses. Formalizing this as `/skippy:review` with defined agent roles, shared findings boards, and fix/eval cycles makes it repeatable.

**Sandboxed testing as default.** After the v1.1 incident where `uninstall.sh --all` deleted 71 PAI skills from real `~/.claude/`, every test and review agent in v1.2 uses sandboxed HOME. The bats test helper enforces `HOME=$BATS_TEST_TMPDIR` in `_common_setup`. This is now a non-negotiable pattern.

**Source-with-fallback pattern for common.sh.** Scripts source `common.sh` but define inline fallback stubs if it's missing. This means individual scripts still work when extracted from the repo -- portability preserved while DRY achieved.

**Slim plans, fast execution.** Plans averaged 2-4 minutes each. The plan structure (frontmatter + tasks with files/action/verify/done fields) kept scope tight. No plan exceeded its boundary.

### What Was Inefficient

**Nyquist validation never completed.** All 6 VALIDATION.md files remain `status: draft`. The validation infrastructure was written but the sign-off ceremony never executed. Same pattern as v1.1. The ceremony adds no value beyond what VERIFICATION.md already provides -- it should be deprecated or automated.

**Summary frontmatter `one_liner` field never populated.** The `summary-extract` CLI tool returned null for all 14 summaries because the `one_liner` field wasn't in the YAML. Accomplishment extraction required reading full summaries manually. Either enforce the field or remove it from the schema.

**STATE.md accumulated duplicate metrics sections.** The "By Phase" table and "Recent Trend" section overlap. Appending per-plan metrics after each completion without consolidation created redundancy.

**No automated tests for TypeScript tooling.** `skippy-state.ts` (the markdown+YAML parser) and `bump-version.sh` have no test coverage. Both are load-bearing for `/skippy:reconcile` and release workflows respectively.

### Key Lessons

1. **Absorption > dependency.** Converting GSD patterns from "install GSD and run its tools" to "read these reference docs and follow the protocol" eliminated a runtime dependency while preserving all the value. The patterns are the asset, not the code.

2. **Sandbox everything by default.** The 71-skill nuke incident was the best thing that happened to v1.1 -- it established the sandbox-first pattern that made v1.2 testing trustworthy. Defense-in-depth (HOME override + worktree + tool restrictions) is the correct layering.

3. **Plans as scope containers.** Small, focused plans (1-3 tasks, 1-8 files) with explicit success criteria and verification steps prevent scope creep. The plan boundary pattern from PAUL ("DO NOT CHANGE" lists) works.

4. **Process debt is real but low-priority.** Nyquist compliance, CORE-05 deferral marking, and missing test coverage are all real debt. None blocked shipping. Track it, fix it in v2, don't let it delay a milestone.

5. **Multi-agent review finds different bugs than single-agent review.** Security reviewers find injection vectors. Architecture reviewers find coupling. Consistency reviewers find naming drift. Quality reviewers find edge cases. No single reviewer catches all categories.

---

## v1.1 Portable PAI (2026-03-08)

See `.planning/v1.1-MILESTONE-AUDIT.md` for the formal audit report.

**What worked:** Slim SKILL.md + deep references pattern. Selective install/uninstall. OMC as third upstream proving the extensible upstream registry design.

**What was inefficient:** Hook development (Phase 7) took 16 minutes for 15 hooks -- the shared lib pattern helped but the volume was high. Skill migration (Phase 9) required 3 plans due to batch complexity.

**Key lesson:** The parasitic approach (ride upstream unchanged, inject ideas as reference docs) was the right architectural choice. Zero upstream maintenance burden across 3 tracked repos.

---

## v1.0 Initial Release (2026-03-07)

**What worked:** Fast execution -- 9 plans in one day. Clean scope: origin docs, 5 PAUL enhancements, 3 commands, install tooling.

**What was inefficient:** GSD dependency mapping (Phase 4) produced a document that was later deleted in v1.2 when the patterns were absorbed into standalone reference docs. The map was useful as a transition artifact but had no long-term value.

**Key lesson:** Start with the minimum viable skill repo. Packaging and distribution first, content second. Getting the install/uninstall flow right early paid dividends in every subsequent phase.
