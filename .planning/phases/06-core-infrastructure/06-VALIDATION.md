---
phase: 6
slug: core-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell-based validation (markdown-only project -- no test framework) |
| **Config file** | none |
| **Quick run command** | `test -f skills/core/SKILL.md && echo PASS` |
| **Full suite command** | `bash tools/validate-core.sh` (created in Wave 0 or first plan) |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Quick file existence checks
- **After every plan wave:** Full validation (file existence + line counts + content spot-checks)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | CORE-01 | smoke | `ls skills/core/references/personas/{skippy,bob,clarisa,april}.md` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | CORE-01 | unit | `grep -q "## Personality" skills/core/references/personas/skippy.md` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 1 | CORE-02 | smoke | `ls skills/core/references/laws/law-*.md \| wc -l` (expect 15) | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 1 | CORE-03 | smoke | `ls skills/core/references/rules/*.md` | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 1 | CORE-04 | smoke | `test -f skills/core/references/templates/claude-md.template` | ❌ W0 | ⬜ pending |
| 06-03-02 | 03 | 1 | CORE-04 | smoke | `test -f skills/core/references/templates/user.md.template` | ❌ W0 | ⬜ pending |
| 06-04-01 | 04 | 1 | CORE-06 | unit | `test $(wc -l < skills/core/SKILL.md) -lt 150` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `skills/core/` directory structure created
- [ ] `tools/validate-core.sh` -- validates core/ structure (file existence, line counts, required sections)

*No test framework needed -- shell file checks are sufficient for a markdown-only skill.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Persona prompt quality | CORE-01 | Content quality is subjective | Read each persona file, confirm personality/style/behavioral rules are distinctive and complete |
| CLAUDE.md template usability | CORE-04 | Template ergonomics require human judgment | Copy template, fill placeholders, confirm it works as a project CLAUDE.md |

---

## Deferred Requirement

| Req ID | Status | Reason |
|--------|--------|--------|
| CORE-05 | DEFERRED | Command packaging deferred during discuss-phase. Needs todo system research first. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
