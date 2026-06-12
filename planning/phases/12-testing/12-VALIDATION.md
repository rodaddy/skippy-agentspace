---
phase: 12
slug: testing
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 12 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bats-core 1.x (via git submodule) |
| **Config file** | none -- bats uses convention (tests/*.bats) |
| **Quick run command** | `./tests/bats/bin/bats tests/common-lib.bats` |
| **Full suite command** | `./tests/bats/bin/bats tests/` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./tests/bats/bin/bats tests/`
- **After every plan wave:** Run `./tests/bats/bin/bats tests/`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | TEST-01 | infra | `ls tests/bats/bin/bats` | n/a W0 | pending |
| 12-01-02 | 01 | 1 | TEST-02 | infra | `grep BATS_TEST_TMPDIR tests/test_helper/common.bash` | n/a W0 | pending |
| 12-01-03 | 01 | 1 | TEST-01 | unit | `./tests/bats/bin/bats tests/common-lib.bats` | n/a W0 | pending |
| 12-02-01 | 02 | 2 | TEST-01 | unit | `./tests/bats/bin/bats tests/install.bats` | n/a W0 | pending |
| 12-02-02 | 02 | 2 | TEST-01 | unit | `./tests/bats/bin/bats tests/uninstall.bats` | n/a W0 | pending |
| 12-02-03 | 02 | 2 | TEST-01 | unit | `./tests/bats/bin/bats tests/verify.bats` | n/a W0 | pending |
| 12-02-04 | 02 | 2 | TEST-01 | unit | `./tests/bats/bin/bats tests/index-sync.bats` | n/a W0 | pending |
| 12-02-05 | 02 | 2 | TEST-01 | unit | `./tests/bats/bin/bats tests/validate-hooks.bats` | n/a W0 | pending |
| 12-03-01 | 03 | 3 | TEST-03 | integration | `./tests/bats/bin/bats tests/` | n/a | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `tests/bats/` -- bats-core git submodule
- [ ] `tests/test_helper/bats-support/` -- bats-support git submodule
- [ ] `tests/test_helper/bats-assert/` -- bats-assert git submodule
- [ ] `tests/test_helper/common.bash` -- shared setup (HOME override, fixture creation)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI workflow runs on push | TEST-03 | Requires GitHub Actions runner | Push branch, check Actions tab |
| prereqs.sh interactive prompts | TEST-01 | Interactive stdin needed | Run manually, verify prompts |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
