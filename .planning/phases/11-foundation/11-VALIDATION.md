---
phase: 11
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 11 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bats-core (planned Phase 12, not yet installed) |
| **Config file** | none -- Phase 12 will create |
| **Quick run command** | `bash tools/verify.sh` |
| **Full suite command** | `bash tools/verify.sh && for f in tools/*.sh; do bash "$f" --help 2>/dev/null; done` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/verify.sh`
- **After every plan wave:** Run each of the 6 scripts individually to confirm no regressions
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | FOUND-01 | smoke | `bash tools/verify.sh` | Yes | ⬜ pending |
| 11-01-02 | 01 | 1 | FOUND-01 | smoke | `source tools/lib/common.sh && skippy_pass "test"` | No -- created by task | ⬜ pending |
| 11-01-03 | 01 | 1 | FOUND-01 | smoke | `bash tools/install.sh --help 2>/dev/null` | Yes | ⬜ pending |
| 11-02-01 | 02 | 1 | FOUND-02 | manual | `git archive HEAD \| tar t \| grep -c .planning` | No -- created by task | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Manual verification sufficient for this phase; automated tests come in Phase 12
- [ ] `tests/` directory does not exist yet (Phase 12 scope)
- [ ] bats-core not installed (Phase 12 will handle)

*Existing `tools/verify.sh` covers smoke testing for this phase.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| .gitattributes excludes dev paths from archive | FOUND-02 | git archive behavior requires manual check | `git archive HEAD \| tar t \| grep -c .planning` should return 0 |
| Skill scripts don't source common.sh | FOUND-01 | Negative assertion | `grep -r "common.sh" skills/` should return no matches |
| Fallback stubs work when common.sh removed | FOUND-01 | Destructive test | Rename common.sh, run verify.sh, confirm output still works |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
