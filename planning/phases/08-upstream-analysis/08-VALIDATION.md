---
phase: 08
slug: upstream-analysis
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual validation (shell + markdown project, no test framework) |
| **Config file** | None |
| **Quick run command** | `ls upstreams/*/upstream.json && cat upstreams/omc/upstream.json \| jq .` |
| **Full suite command** | Manual checklist verification |
| **Estimated runtime** | ~5 seconds (smoke tests only) |

---

## Sampling Rate

- **After every task commit:** Manual review of changed files
- **After every plan wave:** Full checklist verification
- **Before `/gsd:verify-work`:** All smoke tests pass + manual review of analysis quality
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | UPST-01 | smoke | `cat upstreams/omc/upstream.json \| jq .` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | UPST-04 | smoke | `test ! -f skills/skippy/.versions` | ✅ | ⬜ pending |
| 08-01-03 | 01 | 1 | UPST-04 | smoke | `test ! -f skills/skippy/scripts/skippy-update.sh` | ✅ | ⬜ pending |
| 08-02-01 | 02 | 2 | UPST-02 | smoke | `test -f docs/cross-package-analysis.md` | ❌ W0 | ⬜ pending |
| 08-02-02 | 02 | 2 | UPST-02 | manual | Review document for pattern comparison tables | ❌ W0 | ⬜ pending |
| 08-02-03 | 02 | 2 | UPST-03 | smoke | `ls skills/skippy/references/*.md \| wc -l` (count > 10) | ❌ W0 | ⬜ pending |
| 08-02-04 | 02 | 2 | UPST-03 | manual | Read each new doc for Source Upstreams / Why This Version sections | ❌ W0 | ⬜ pending |
| 08-xx-01 | TBD | TBD | UPST-01 | manual | Run /skippy:update, verify OMC appears | ❌ W0 | ⬜ pending |
| 08-xx-02 | TBD | TBD | UPST-04 | manual | Read update.md, verify no hardcoded URLs | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None -- this is a markdown/documentation-heavy phase. No test infrastructure needed beyond file existence checks and JSON validation via jq.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cross-package analysis covers 2+ upstreams per pattern | UPST-02 | Quality judgment -- must verify comparison depth | Read doc, verify each pattern has entries from 2+ upstreams |
| Reference docs have evolved format | UPST-03 | Content quality -- sections exist but quality matters | Check Source Upstreams, Why This Version, Integration Points sections |
| /skippy:update reports OMC status | UPST-01 | Interactive command | Run update, verify OMC line in output |
| /skippy:update uses generic iteration | UPST-04 | Logic review | Read update.md, confirm no hardcoded repo URLs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
