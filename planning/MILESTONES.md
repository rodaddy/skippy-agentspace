# Milestones

## v1.2 Standalone Skippy (Shipped: 2026-03-08)

**Phases completed:** 6 phases (11-16), 14 plans
**Stats:** 74 commits, 309 files changed, 41K insertions, 3K shell LOC, 10K markdown LOC

**Key accomplishments:**
- Shared shell library (`tools/lib/common.sh`) with 8 `skippy_`-namespaced functions, DRY extraction across all 6 tool scripts
- bats-core test suite (37 tests across 6 `.bats` files) with vendored submodules and sandboxed HOME isolation
- GSD pattern absorption into 4 standalone reference docs (phased-execution, state-tracking, plan-structure, checkpoints) -- zero runtime GSD dependency
- Multi-agent audit swarm (`/skippy:review`) with 6 specialist subagent definitions and 3-layer sandbox protocol
- deploy-service hardening (`config.env` mechanism replacing 9 placeholders) + version bump automation (`bump-version.sh` across 26 locations)
- CONTRIBUTING.md, standalone identity framing across all docs, and CI workflow for GitHub Actions

---

## v1.1 Portable PAI (Shipped: 2026-03-08)

**Phases completed:** 6 phases (5-10), 16 plans

**Key accomplishments:**
- 12 skills across 4 categories (core, workflow, utility, domain)
- 15 reference docs (5 PAUL enhancements + 5 OMC cherry-picks + 5 conventions)
- 3 upstream tracking configs (GSD, PAUL, OMC)
- Bootstrap tools (prereqs.sh, verify.sh, install.sh, uninstall.sh, index-sync.sh)
- 36 automated tests (hook validation + index sync)

---

## v1.0 Initial Release (Shipped: 2026-03-07)

**Phases completed:** 4 phases, 9 plans

**Key accomplishments:**
- Origin documentation and architectural decisions
- 5 PAUL enhancement reference docs
- 3 utility commands (reconcile, update, cleanup)
- Install/uninstall tooling with symlink management
- INDEX.md auto-generation via index-sync.sh

---

