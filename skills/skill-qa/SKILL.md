---
name: skill-qa
description: >-
  Test harness for PAI skills and hooks. Validates hooks fire correctly,
  skills trigger for the right requests, and enforcement actually works.
  Feeds gaps into autoresearch for iterative improvement. USE WHEN
  test hooks, validate skills, skill quality, hook enforcement,
  QA the enforcement layer, or skill-qa.
triggers:
  - /skill-qa
  - test hooks
  - validate skills
  - check enforcement
  - are hooks working
  - skill quality audit
user-invocable: true
---

# Skill QA -- Hook & Skill Test Harness

Tests whether PAI's enforcement layer actually works: do hooks catch violations? Do skills trigger when they should? Are skills good enough that manual work isn't tempting?

Feeds gap reports into `/autoresearch` for iterative improvement.

## Workflow

### Phase A: Inventory Scan

1. Read `~/.claude/settings.json` to inventory all hooks (matcher, source file, type)
2. Read all `~/.config/pai/Skills/*/SKILL.md` frontmatter for skill triggers
3. Load previous gap report from `.skill-qa/gaps.json` if it exists (for delta tracking)
4. Present summary: hook count, skill count, known gaps from last run

### Phase B: Test Execution

Run test scenarios from **references/test-scenarios.md** against the real hooks and skill system. Three test categories:

#### B1: Hook Enforcement Tests

For each hook test scenario:
1. Construct the JSON stdin payload the hook expects (`toolName`, `toolInput`, `recentMessages`)
2. Pipe it to the hook script: `echo '<json>' | bun run <hook_path>`
3. Check exit code: 0 = allow, 1 = warn/feedback, 2 = block
4. Compare to expected result
5. Record: PASS (expected behavior) or FAIL (unexpected)

```bash
# Example: test pre-ancient-bash-blocker with a violation
echo '{"toolName":"Write","toolInput":{"file_path":"/tmp/test.sh","content":"#!/bin/bash\necho hello"}}' | bun run ~/.claude/hooks/law-enforcement/pre-ancient-bash-blocker.ts
# Expected: exit 2 (block)
```

#### B2: Skill Trigger Tests

For each skill trigger scenario:
1. Simulate a user request string
2. Match against all skill `description` + `triggers` fields
3. Check: does the RIGHT skill match? Does it match FIRST?
4. Check: do WRONG skills NOT match?
5. Record: PASS or FAIL with which skill(s) matched

#### B3: Skill Quality Tests

For each skill quality scenario:
1. Read the SKILL.md content
2. Evaluate against binary quality criteria (via agent-judge):
   - Does the skill have clear, actionable steps?
   - Does it cover the common use case without reading references?
   - Is it current (no stale references to moved/renamed things)?
   - Would an agent prefer using this skill over doing it manually?
3. Record: PASS or FAIL per criterion

### Phase C: Gap Classification

For each FAIL, classify the gap:

| Gap Type | Meaning | Fix Target |
|----------|---------|------------|
| `trigger-miss` | Skill exists but description doesn't match the request | Skill trigger description |
| `trigger-false-positive` | Skill triggered for unrelated request | Skill trigger description |
| `hook-miss` | Hook should have caught violation but didn't | Hook source code |
| `hook-false-positive` | Hook blocked a legitimate operation | Hook source code |
| `hook-broken` | Hook has code bugs (wrong input format, etc.) | Hook source code |
| `quality-gap` | Skill exists and triggers but content is poor/outdated | Skill content |
| `overlap` | Multiple hooks/skills fire for same scenario, conflicting | Consolidation needed |
| `bypass` | Subagent or pattern bypasses enforcement entirely | Hook logic |

### Phase D: Report + Feed

1. Write gap report to `.skill-qa/gaps.json`:
   ```json
   {
     "timestamp": "ISO 8601",
     "baseline": "path to baseline tarball",
     "summary": { "total_tests": 0, "passed": 0, "failed": 0 },
     "gaps": [
       {
         "type": "trigger-miss",
         "skill": "vaultwarden",
         "scenario": "I need the API key for Discord",
         "expected": "vaultwarden skill triggers",
         "actual": "no skill matched",
         "severity": "high"
       }
     ],
     "hook_results": { "hook_name": { "pass": 0, "fail": 0 } },
     "known_broken": ["pre-lsp-first.ts -- wrong input format"]
   }
   ```

2. Write human-readable report to `.skill-qa/report.md`

3. If autoresearch integration requested, convert gaps to eval criteria:
   - Each gap type maps to a binary eval criterion
   - Gaps become the test battery for autoresearch optimization
   - Write criteria to `.skill-qa/autoresearch-criteria.json`

### Phase E: Delta Comparison

If a previous gap report exists:
1. Compare current gaps to previous gaps
2. Report: gaps fixed, gaps introduced, gaps unchanged
3. Track improvement trend over time in `.skill-qa/history.jsonl`

## Autoresearch Integration

When paired with `/autoresearch`:

1. Run `/skill-qa` to produce gap report
2. Gap report becomes autoresearch eval criteria:
   - `trigger-miss` gaps -> "Does skill X trigger for request Y?" (command test)
   - `hook-miss` gaps -> "Does hook X block input Y?" (command test)
   - `quality-gap` gaps -> "Is skill X better than manual?" (agent-judge)
3. Autoresearch optimizes skill triggers/content
4. Re-run `/skill-qa` to measure improvement
5. Repeat until gaps are resolved or plateaued

## Output

```
SKILL QA REPORT -- 2026-04-08
================================
Tests: 87 total | 72 passed | 15 failed

HOOK ENFORCEMENT:
  pre-ancient-bash-blocker:    8/8  PASS
  pre-skill-enforcer:          6/8  FAIL (2 false negatives)
  pre-lsp-first:               0/4  FAIL (hook broken -- wrong input format)
  ...

SKILL TRIGGERS:
  vaultwarden:                 5/6  FAIL (missed: "Discord API key")
  deploy-service:              4/4  PASS
  session-wrap:                3/4  FAIL (missed: "let's wrap up")
  ...

SKILL QUALITY:
  n8n:                         4/4  PASS
  homeassistant:               2/4  FAIL (stale references, unclear steps)
  ...

GAPS BY TYPE:
  trigger-miss:       5
  hook-miss:          3
  hook-broken:        1
  quality-gap:        4
  bypass:             2

Gap report: .skill-qa/gaps.json
Full report: .skill-qa/report.md
```

## Known Issues to Test (from Hook Survey)

These are confirmed gaps to include in the test battery:

1. **pre-lsp-first.ts** -- reads `tool`/`params`/`toolHistory` but CC sends `toolName`/`toolInput`/`recentMessages`. Likely never fires.
2. **pre-backup-verify.ts** -- warns but never blocks (exits 0 with feedback)
3. **security-validator.ts curl path** -- ask tier exits 0, doesn't gate
4. **pre-skill-enforcer.ts vs enforce-skill-usage.ts** -- two overlapping enforcers with different logic
5. **pre-qmd-first.ts** -- Grep patterns >40 chars bypass LAW 10
6. **pre-implementation.ts** -- LAW 5 check trivially satisfied by generic text
7. **Subagent bypass** -- almost all hooks pass subagents through unchecked

## References

- **references/test-scenarios.md** -- Full test battery with expected results
- **references/hook-inventory.md** -- Current hook documentation and known states
- **references/gap-classification.md** -- How to classify and prioritize gaps
