---
phase: 5
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + manual verification (convention/docs phase -- no test framework) |
| **Config file** | none |
| **Quick run command** | `ls upstreams/*/upstream.json && jq . upstreams/*/upstream.json` |
| **Full suite command** | `jq . upstreams/gsd/upstream.json && jq . upstreams/paul/upstream.json && test ! -f skills/skippy/.versions && test -f CONVENTIONS.md && echo "PASS"` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `ls upstreams/*/upstream.json && jq . upstreams/*/upstream.json 2>/dev/null`
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | FOUN-01 | manual | `test -f CONVENTIONS.md && grep -q "Content Classification" CONVENTIONS.md` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | FOUN-01 | smoke | `grep -q "upstreams/" .gitignore` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | FOUN-02 | smoke | `ls upstreams/gsd/upstream.json upstreams/paul/upstream.json` | ❌ W0 | ⬜ pending |
| 05-02-02 | 02 | 1 | FOUN-03 | smoke | `mkdir -p upstreams/test && cp upstreams/gsd/upstream.json upstreams/test/ && ls upstreams/test/upstream.json && rm -rf upstreams/test` | ❌ W0 | ⬜ pending |
| 05-02-03 | 02 | 1 | FOUN-04 | smoke | `test ! -f skills/skippy/.versions && jq -e '.last_checked_sha' upstreams/gsd/upstream.json` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `upstreams/gsd/upstream.json` -- covers FOUN-02, FOUN-04
- [ ] `upstreams/paul/upstream.json` -- covers FOUN-02, FOUN-04
- [ ] `CONVENTIONS.md` -- covers FOUN-01
- [ ] `.gitignore` updates -- covers FOUN-01
- [ ] Removal of `skills/skippy/.versions` -- covers FOUN-04

*All gaps are the deliverables themselves -- this phase creates net-new files, not code that needs testing infrastructure.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CONVENTIONS.md content quality | FOUN-01 | Document clarity is subjective | Read CONVENTIONS.md, confirm public/private boundary is unambiguous |
| New upstream extensibility | FOUN-03 | Requires human judgment on ergonomics | Follow documented steps to add a hypothetical third upstream |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
