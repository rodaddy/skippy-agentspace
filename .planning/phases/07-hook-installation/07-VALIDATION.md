---
phase: 7
slug: hook-installation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 7 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell-based validation script (no test framework in project) |
| **Config file** | none -- Wave 0 creates validation script |
| **Quick run command** | `bash tools/validate-hooks.sh` |
| **Full suite command** | `bash tools/validate-hooks.sh --full` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/validate-hooks.sh`
- **After every plan wave:** Run `bash tools/validate-hooks.sh --full`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | HOOK-01 | smoke | `jq '.hooks \| length' skills/core/hooks/manifest.json` (expect 15) | Wave 0 | pending |
| 07-01-02 | 01 | 1 | HOOK-01 | smoke | Verify each manifest entry has event, matcher, command, description | Wave 0 | pending |
| 07-02-01 | 02 | 1 | HOOK-02 | integration | Install on test settings.json, verify GSD hooks preserved | Wave 0 | pending |
| 07-02-02 | 02 | 1 | HOOK-03 | integration | Uninstall, verify GSD hooks intact, PAI hooks gone | Wave 0 | pending |
| 07-02-03 | 02 | 1 | HOOK-04 | integration | Install twice, diff settings.json (expect identical) | Wave 0 | pending |
| 07-02-04 | 02 | 1 | HOOK-05 | smoke | Check backup file exists after install | Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `tools/validate-hooks.sh` -- verification script for all HOOK requirements
- [ ] Test fixture: sample settings.json with GSD/OMC hooks for integration testing

*Validation script tests manifest completeness, install/uninstall safety, idempotency, and backup creation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hook actually fires in Claude Code | All | Requires live Claude Code session | Install hooks, trigger a LAW violation, verify hook blocks/warns |
| Persona-aware context injection | HOOK-01 | Requires active persona state | Switch persona, trigger hook, check persona name in output |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
