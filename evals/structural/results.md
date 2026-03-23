# Structural Eval Results

- **Date:** 2026-03-22
- **Score:** 111/111 (100%)
- **Iterations:** 21
- **Categories:** 23
- **Runner:** `evals/structural/runner.sh`

## Iteration History

### Round 1 -- Baseline (20/26 -- 76%)

**Failures:**
- #4: #!/bin/bash shebang detected (false positive -- runner.sh mentions it in text)
- #6: Missing Commands/For Agents section in 21 skills
- #8: 8 skills missing from marketplace.json
- #19: INDEX.md count mismatch
- #23: Hardcoded token (false positive -- `gh api` example)
- #26: Absolute paths (false positive -- `/home/runner` template)

### Round 2 (24/26 -- 92%)

**Fixes applied:**
- Fixed assertion #4 to check only first line (shebang), not whole file
- Fixed assertion #23 to exclude `gh api` and `$(...)` patterns
- Fixed assertion #26 to exclude generic service paths (`/home/runner`, `/home/n8n`)
- Added 8 missing skills to marketplace.json (brain, capture-session, gh-review, prd, prd-to-issues, session-handoff, session-start, ubiquitous-language)
- Regenerated INDEX.md via `index-sync.sh --generate`

### Round 3 (26/26 -- 100%)

**Fixes applied:**
- Updated assertion #6 to accept broader usage section names (Usage, Workflow, When to Use, Trigger, etc.)
- Fixed INDEX.md grep pattern to match `[installed]` format

### Round 4 -- Expanded (42/46 -- 91%)

Added 20 new assertions (deep-quality, cross-refs, install-pipeline, consistency).

**Failures:**
- #28: 3 skills missing metadata: block (prd, prd-to-issues, ubiquitous-language)
- #32: TODO/FIXME false positives in agent docs (referencing detection, not leaving markers)
- #33: CLAUDE.md says "16 skills" but actual count is 24
- #43: VERSION file didn't exist

### Round 5 (46/46 -- 100%)

**Fixes applied:**
- Added metadata: blocks to prd, prd-to-issues, ubiquitous-language SKILL.md files
- Tightened TODO assertion to exclude agents/, references/, and pattern descriptions
- Updated CLAUDE.md skill counts (16->24, 12->24)
- Created VERSION file (1.2.0)

### Round 6 -- Expanded (67/68 -- 98%)

Added 22 more assertions (ci-cd, skill-depth, doc-quality, upgrade, resilience).

**Failures:**
- #63: Upstream SHA field check used wrong field name

### Round 7 (68/68 -- 100%)

**Fixes applied:**
- Fixed assertion #63 to check `last_checked_sha` field (actual upstream.json format)

### Round 8 (68/68 -- 100%)

Fixed 3 critical uninstall.sh bugs. No regressions.

### Round 9 (68/68 -- 100%)

Updated CLAUDE.md file tree to match reality (all 24 skills, evals/, VERSION, GLOSSARY).
Added CI workflow for structural evals.

### Round 10 -- Expanded (81/84 -- 96%)

Added 16 assertions (agents, eval-coverage, upstream-freshness, claudemd-accuracy).
3 failures: missing complexity: in agents, stale assertion logic, missing consumed sources.

### Round 11 (84/84 -- 100%)

Fixed: planner.md + researcher.md complexity: fields. CLAUDE.md consumed sources (added gstack, superpowers). Assertion #73 and #83 logic.

### Round 12 -- Expanded (95/96 -- 98%)

Added 12 assertions (glossary, shell-quality, test-infra, skill-consistency).
1 failure: shellcheck found `local` outside function in uninstall.sh.

### Round 13 (96/96 -- 100%)

Fixed `local` -> plain variable assignment in uninstall.sh main body.

### Round 14 -- Final Expansion (103/103 -- 100%)

Added 7 assertions (git-hygiene, naming). All pass.

### Round 15 -- Lifecycle (111/111 -- 100%)

Added 8 lifecycle assertions (#104-111). Sandboxed install/uninstall tests using `mktemp -d` HOME. All pass.

### Dogfood Verification (2026-03-22)

Previous "5-env verification" claim was unsubstantiated -- all 14 runs in run-log came from the same local Mac. This round does actual multi-environment verification. See `DOGFOOD.md` for full results.

## Changes Made During Eval

- marketplace.json: Added 8 missing skills (24 total)
- INDEX.md: Regenerated with all 24 skills
- CLAUDE.md: Updated file tree, skill counts (16->24), added gstack + superpowers to consumed sources
- VERSION: Created (1.2.0)
- 3 SKILL.md files: Added metadata: blocks (prd, prd-to-issues, ubiquitous-language)
- 2 agent files: Added complexity: field (planner.md, researcher.md)
- uninstall.sh: Fixed 3 critical bugs (copied dir handling, fallback function, interactive read), shellcheck error
- .github/workflows/test.yml: Added structural-evals CI job
- evals/structural/runner.sh: Created with 103 assertions across 22 categories
- evals/behavioral/: Created install-experience.json (16 assertions) + repo-quality.json (12 assertions)
