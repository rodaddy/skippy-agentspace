---
phase: 13
slug: gsd-pattern-absorption
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 13 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification + grep validation |
| **Config file** | None -- Phase 12 (bats-core) is pending |
| **Quick run command** | `grep -r "requires GSD\|gsd-tools\|get-shit-done" skills/ --include="*.md" -l` |
| **Full suite command** | `grep -rn "GSD" skills/ --include="*.md" \| grep -v "Source:\|Adapted from\|Sources:"` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick grep for GSD dependency language
- **After every plan wave:** Run full grep scan across all skills/
- **Before `/gsd:verify-work`:** All 7 validation commands pass
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | ABSORB-01 | smoke | `test -f skills/skippy/references/phased-execution.md && wc -l < skills/skippy/references/phased-execution.md` | Wave 0 | pending |
| 13-01-02 | 01 | 1 | ABSORB-02 | smoke | `test -f skills/skippy/references/state-tracking.md && wc -l < skills/skippy/references/state-tracking.md` | Wave 0 | pending |
| 13-01-03 | 01 | 1 | ABSORB-03 | smoke | `test -f skills/skippy/references/plan-structure.md && grep -q "## Task" skills/skippy/references/plan-structure.md` | Wave 0 | pending |
| 13-01-04 | 01 | 1 | ABSORB-04 | smoke | `test -f skills/skippy/references/checkpoints.md && grep -q "human-verify" skills/skippy/references/checkpoints.md` | Wave 0 | pending |
| 13-02-01 | 02 | 2 | ABSORB-05 | grep | `! grep -q "gsd-executor\|gsd:verify-work" skills/skippy/references/verification-loops.md` | Existing | pending |
| 13-02-02 | 02 | 2 | ABSORB-06 | grep | `! grep -rn "requires GSD\|gsd-tools\|gsd-executor\|gsd-verifier\|gsd-planner" skills/ --include="*.md"` | N/A | pending |
| 13-02-03 | 02 | 2 | ABSORB-07 | smoke | `grep -q "## Task" skills/skippy/commands/reconcile.md && ! grep -q "<task" skills/skippy/commands/reconcile.md` | Existing | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Reference doc stubs for phased-execution.md, state-tracking.md, plan-structure.md, checkpoints.md
- [ ] No test framework -- validation is grep-based for this phase (Phase 12 adds bats-core)

*Existing infrastructure (grep) covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reference doc content quality | ABSORB-01 through ABSORB-04 | Semantic content can't be grep-validated | Read each doc, verify protocol is actionable and self-contained |
| reconcile parsing correctness | ABSORB-07 | No bats tests yet | Run `/skippy:reconcile` against a sample .planning/ with new format |
| skippy-state.ts functionality | ABSORB-07 | No unit tests yet | Manual verification of parser output against sample PLAN.md |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
