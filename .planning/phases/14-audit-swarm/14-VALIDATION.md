---
phase: 14
slug: audit-swarm
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 14 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (Phase 12 bats-core not yet available) |
| **Config file** | none |
| **Quick run command** | `test -f skills/skippy-dev/commands/review.md && echo PASS` |
| **Full suite command** | Invoke `/skippy:review` against test scope, verify all 5 success criteria |
| **Estimated runtime** | ~60 seconds (agent spawning) |

---

## Sampling Rate

- **After every task commit:** Verify created files match expected structure
- **After every plan wave:** Manual review of agent definitions and command file
- **Before `/gsd:verify-work`:** Full `/skippy:review` invocation on test scope
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | SWARM-02 | smoke | `test -f skills/skippy-dev/references/audit-swarm.md` | n/a W0 | pending |
| 14-01-02 | 01 | 1 | SWARM-01 | smoke | `test -f skills/skippy-dev/commands/review.md` | n/a W0 | pending |
| 14-01-03 | 01 | 1 | SWARM-05 | review | `grep -l 'HOME.*BATS_TEST_TMPDIR\|HOME.*mktemp' skills/skippy-dev/agents/*.md` | n/a W0 | pending |
| 14-02-01 | 02 | 2 | SWARM-01 | manual | Invoke `/skippy:review`, verify 4 agent spawns | n/a | pending |
| 14-02-02 | 02 | 2 | SWARM-03 | manual | Check git log for atomic fix commits | n/a | pending |
| 14-02-03 | 02 | 2 | SWARM-04 | manual | Check findings board evaluation section | n/a | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `skills/skippy-dev/agents/` directory created
- [ ] `skills/skippy-dev/references/audit-swarm.md` reference doc
- [ ] `skills/skippy-dev/commands/review.md` command definition

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 4 specialist agents spawn correctly | SWARM-01 | Requires Claude Code runtime | Run `/skippy:review`, count Agent tool calls |
| Findings board cross-references | SWARM-02 | Content quality check | Review generated findings.md for cross-refs |
| Fix agents don't touch real HOME | SWARM-05 | Safety-critical, runtime check | Verify agent definitions, check no real files modified |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
