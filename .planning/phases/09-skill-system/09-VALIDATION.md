---
phase: 9
slug: skill-system
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 9 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + manual verification |
| **Config file** | none -- shell scripts are the test harness |
| **Quick run command** | `bash tools/install.sh --help && bash tools/index-sync.sh --check` |
| **Full suite command** | `bash tools/install.sh --all && bash tools/index-sync.sh --check && bash tools/install.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/index-sync.sh --check && wc -l skills/*/SKILL.md | awk '$1 > 150'`
- **After every plan wave:** Full install/uninstall cycle + index check
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | SKIL-01 | smoke | `bash tools/install.sh --core && ls -la ~/.claude/skills/core` | Wave 0 | pending |
| 09-01-02 | 01 | 1 | SKIL-01 | smoke | `bash tools/install.sh skippy-dev && ls -la ~/.claude/skills/skippy-dev` | Wave 0 | pending |
| 09-01-03 | 01 | 1 | SKIL-01 | smoke | `bash tools/install.sh` (visual check for status table) | Wave 0 | pending |
| 09-02-01 | 02 | 1 | SKIL-02 | manual-only | Run /skippy:migrate in Claude session, verify output | Manual | pending |
| 09-03-01 | 03 | 2 | SKIL-03 | unit | `wc -l skills/*/SKILL.md \| awk '$1 > 150'` (should return empty) | Wave 0 | pending |
| 09-03-02 | 03 | 2 | SKIL-03 | unit | `for d in skills/*/; do [[ -f "$d/SKILL.md" ]] \|\| echo "MISSING: $d"; done` | Wave 0 | pending |
| 09-04-01 | 04 | 2 | SKIL-04 | smoke | `bash tools/index-sync.sh --check` | Exists | pending |
| 09-04-02 | 04 | 2 | SKIL-04 | smoke | `bash tools/index-sync.sh --generate && grep '\[installed\]' INDEX.md` | Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Extend index-sync.sh with category detection and install badge logic
- [ ] Add `category:` field to existing core and skippy-dev SKILL.md frontmatter
- [ ] No formal test harness -- validation is shell commands checking expected state

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| /skippy:migrate produces portable skill | SKIL-02 | AI command requires Claude runtime | Run in Claude Code session, verify output structure matches standard layout |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
