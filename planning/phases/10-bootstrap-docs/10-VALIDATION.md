---
phase: 10
slug: bootstrap-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + shellcheck |
| **Config file** | none |
| **Quick run command** | `bash tools/verify.sh` |
| **Full suite command** | `bash tools/verify.sh && shellcheck tools/*.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/verify.sh`
- **After every plan wave:** Run `bash tools/verify.sh && shellcheck tools/*.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | BOOT-01 | integration | `bash tools/prereqs.sh` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | BOOT-05 | integration | `bash tools/verify.sh` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | BOOT-02 | manual | review SETUP.md | ❌ W0 | ⬜ pending |
| 10-02-02 | 02 | 2 | BOOT-03 | manual | review INSTALL.md | ❌ W0 | ⬜ pending |
| 10-02-03 | 02 | 2 | BOOT-04 | manual | review UPGRADE.md | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/prereqs.sh` — prerequisite checker stub
- [ ] `tools/verify.sh` — verification script stub

*Existing infrastructure (install.sh, validate-hooks.sh, index-sync.sh) covers partial requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| SETUP.md completeness | BOOT-02 | Documentation quality requires human review | Follow steps on fresh machine |
| INSTALL.md accuracy | BOOT-03 | Selective install paths need human walkthrough | Try adding single skill |
| UPGRADE.md safety | BOOT-04 | Customization preservation needs human judgment | Upgrade with local changes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
