---
phase: 1
slug: spec-compliance
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-03-07
---

# Phase 1 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (bash + grep) |
| **Config file** | none -- shell commands only |
| **Quick run command** | `grep -rn '/Users/\|/Volumes/' skills/` |
| **Full suite command** | See Per-Task Verification Map below |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `grep -rn '/Users/\|/Volumes/' skills/` -- zero matches expected
- **After every plan wave:** Run all 4 validation commands from map below
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | SPEC-01 | smoke | `grep -rn '/Users/\|/Volumes/' skills/ \| grep -v '.planning/'` | N/A -- inline | ⬜ pending |
| 01-01-02 | 01 | 1 | SPEC-02 | smoke | `head -20 skills/skippy-dev/SKILL.md \| grep -c 'triggers:'` (expect 0) | N/A -- inline | ⬜ pending |
| 01-01-03 | 01 | 1 | SPEC-03 | smoke | `test -d skills/skippy-dev/scripts/ && ! test -d skills/skippy-dev/bin/ && ! grep -rn 'bin/skippy' skills/` | N/A -- inline | ⬜ pending |
| 01-01-04 | 01 | 1 | STRU-01 | smoke | `wc -l skills/skippy-dev/SKILL.md` (expect < 150) + `ls skills/skippy-dev/references/*.md \| wc -l` (expect 5) + `test -f INDEX.md` | N/A -- inline | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. All validation is inline shell commands -- no test framework or fixtures needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `@../` traversal works in command .md files | SPEC-01 | Requires Claude Code runtime to verify path resolution | Add a test `@` reference and invoke the command |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
