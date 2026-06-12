---
phase: 16
slug: integration-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 16 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bats-core (vendored submodule at tests/bats/) |
| **Config file** | None (bats uses convention-based test discovery) |
| **Quick run command** | `./tests/bats/bin/bats tests/` |
| **Full suite command** | `./tests/bats/bin/bats tests/ && bash tools/integration-test.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/verify.sh && ./tests/bats/bin/bats tests/verify.bats`
- **After every plan wave:** Run `./tests/bats/bin/bats tests/ && bash tools/integration-test.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | FOUND-03 | smoke | `test -f CONTRIBUTING.md && grep -q "Adding a Skill" CONTRIBUTING.md && grep -q "Running Tests" CONTRIBUTING.md && grep -q "Submitting Changes" CONTRIBUTING.md` | N/A | ⬜ pending |
| 16-01-02 | 01 | 1 | SC-1 | smoke | `grep -q "SKILL.md" CONTRIBUTING.md` | N/A | ⬜ pending |
| 16-02-01 | 02 | 1 | SC-2 | smoke | `grep -q "Skippy IS the framework\|standalone" CLAUDE.md && ! grep -q "No GSD modification" CLAUDE.md` | N/A | ⬜ pending |
| 16-03-01 | 03 | 2 | SC-3 | integration | `bash tools/verify.sh` | Existing | ⬜ pending |
| 16-03-02 | 03 | 2 | SC-4 | integration | `bash tools/index-sync.sh --check` | Existing | ⬜ pending |
| 16-03-03 | 03 | 2 | SC-5 | smoke | `grep -q "bats tests/" README.md` | N/A | ⬜ pending |
| 16-03-04 | 03 | 2 | SC-6 | unit | `grep -q "review" tools/verify.sh` | Existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed for this documentation phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CONTRIBUTING.md prose quality | FOUND-03 | Content quality can't be automated | Read CONTRIBUTING.md, verify sections are clear and actionable |
| README.md standalone framing | SC-5 | Tone/framing is subjective | Read README.md, verify "Skippy IS the framework" positioning |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
