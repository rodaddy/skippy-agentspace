---
phase: 15
slug: hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 15 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (bats-core from Phase 12 not yet available) |
| **Config file** | none |
| **Quick run command** | `grep -r '<your-' skills/deploy-service/` (zero matches = pass) |
| **Full suite command** | `bash tools/bump-version.sh --dry-run --patch` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** `grep -r '<your-' skills/deploy-service/` returns 0 matches
- **After every plan wave:** `bash tools/bump-version.sh --dry-run --patch` succeeds
- **Before `/gsd:verify-work`:** All grep verifications pass, dry-run succeeds
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | HARD-03 | smoke | `test -f skills/deploy-service/config.env.example` | n/a W0 | pending |
| 15-01-02 | 01 | 1 | HARD-03 | smoke | `git check-ignore skills/deploy-service/config.env` | n/a | pending |
| 15-01-03 | 01 | 1 | HARD-01 | smoke | `grep -r '<your-' skills/deploy-service/` returns 0 | n/a | pending |
| 15-02-01 | 02 | 2 | HARD-02 | smoke | `bash tools/bump-version.sh --dry-run --patch` | n/a W0 | pending |
| 15-02-02 | 02 | 2 | HARD-02 | smoke | `grep -r '0.1.0' .claude-plugin/ skills/*/SKILL.md` after bump | n/a | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `skills/deploy-service/config.env.example` -- config template with all variables documented
- [ ] `tools/bump-version.sh` -- version management script

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| config.env validation errors | HARD-01 | Requires missing-var scenario | Source config.env with missing vars, verify `:?` errors |
| bump-version tag creation | HARD-02 | Optional feature, git state dependent | Run with `--tag`, check `git tag -l` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
