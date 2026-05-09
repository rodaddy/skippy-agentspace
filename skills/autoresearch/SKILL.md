---
name: autoresearch
description: >-
  Self-improving optimization using Karpathy's autoresearch pattern.
  Scans targets, defines binary eval criteria, runs autonomous
  generate-eval-score-mutate loop. USE WHEN optimize prompts,
  improve skills, run autoresearch, iterative improvement, or
  self-improvement loop.
triggers:
  - /autoresearch
  - optimize this prompt
  - run autoresearch
  - improve this skill
  - iterative optimization
  - self-improving loop
user-invocable: true
---

# Autoresearch -- Self-Improving Optimization Engine

Autonomous optimization using the Karpathy autoresearch pattern: generate variations, evaluate against binary criteria, keep winners, mutate from best, repeat.

## When to Use

- Optimizing prompt or skill definitions
- Improving code quality patterns across a repo
- Any target with measurable yes/no eval criteria
- Paired with `/skill-qa` for skill/hook improvement feedback loops

## Phase Overview

See **references/phases-detail.md** for full templates and examples.

### Phase 1: Discovery

Scan the optimization target to understand context.

- **For skills/hooks**: Read SKILL.md, hook source, settings.json
- **For repos**: Use qmd to understand codebase structure and patterns
- **For prompts**: Read the prompt file and understand its purpose

Present a brief summary: target name, stack/context, existing quality signals.

### Phase 2: Target Selection

If user already stated their goal, skip to Phase 3.

Otherwise: ask the user first (present blank template for Target/Scope/Context). If they say "suggest", scan against universal quality dimensions and propose 5-8 targets. Always include a "your own idea" option.

### Phase 3: Metric Definition

Generate 4-6 binary (yes/no) eval criteria. Two eval types:

- **`command`** -- shell command, exit 0 = pass. Prefer this when a reliable programmatic check exists.
- **`agent-judge`** -- spawn a **separate sonnet agent** that receives ONLY the raw output + criterion text. True eval isolation -- the judge never sees the prompt that produced the output.

Rules: binary only (never scales), specific (not vibes), observable, independent, not gameable. See **references/eval-criteria-guide.md** for examples.

Present criteria to user, wait for approval.

### Phase 4: Baseline + Setup

1. Choose batch size: 5-6 (complex), 7-8 (moderate), 9-10 (lightweight)
2. Create `.autoresearch/` directory with state files (see **references/state-format.md**)
3. Select 3-5 fixed validation items
4. Run initial prompt once to establish baseline score
5. Add `.autoresearch/` to `.gitignore`

### Phase 5: Autonomous Loop

**CRITICAL: Re-read ALL state from disk every cycle. Never rely on conversational memory.**

Each cycle:

1. **Load state** from `.autoresearch/state.json`, `prompt.txt`, last 5 entries of `results.jsonl`
2. **Sample items** -- validation set (fixed) + rotating sample (coverage-first)
3. **Generate outputs** from current prompt
4. **Evaluate** -- spawn isolated sonnet agent for agent-judge criteria, run commands for command criteria
5. **Score** -- per-criterion totals, validation score (primary), total score
6. **Compare** -- validation_score vs best. Keep if improved by confidence margin (2pts for 5-7 items, 1pt for 8-10). Discard and revert otherwise.
7. **Mutate** from `best_prompt.txt` using structured operators (see **references/mutation-operators.md**)
8. **Log** full entry to `results.jsonl` including prompt text, scores, mutation operator
9. **Plateau breaker** at 5 stale runs: full rewrite from scratch using only criteria + failure patterns
10. **Continue** -- do not stop, do not ask permission

### Stopping Conditions

- User says stop
- Perfect score for 3 consecutive runs
- 50 cycles with no improvement in last 20

Print final summary with starting score, final score, improvement %, most effective mutation operators ranked by KEEP rate.

## PAI Adaptations (vs Original)

| Original | PAI Version |
|----------|-------------|
| Self-judging eval | Separate sonnet agent (true isolation) |
| Manual file scanning | qmd for repo discovery |
| Single-threaded eval | Agent orchestration for parallel eval |
| Conversational state | File-based state + disk re-read every cycle |
| Generic mutations | 6 structured operators, logged and ranked |

## Operational Rules

1. Never ask to continue once loop starts -- you are autonomous
2. Re-read state from disk EVERY cycle -- files are truth, not memory
3. Binary evals only -- yes/no, never scales or "out of 10"
4. Evaluate in isolation -- separate agent, no prompt context
5. Mutate from best, never from a failed attempt
6. Use structured mutation operators -- rotate and log
7. Validation set is sacred -- same items every cycle
8. Be strict -- if not clearly passing, it fails
9. Do not modify source code -- optimize the prompt/skill only
10. Log everything -- every cycle gets a full JSONL entry

## State Files

| File | Purpose |
|------|---------|
| `.autoresearch/prompt.txt` | Current cycle's prompt being tested |
| `.autoresearch/best_prompt.txt` | Highest-scoring prompt (your final output) |
| `.autoresearch/state.json` | Loop state: scores, samples, plateau counter |
| `.autoresearch/results.jsonl` | Complete experiment log, one JSON line per cycle |

## References

- **references/phases-detail.md** -- Full phase workflows with templates and examples
- **references/mutation-operators.md** -- 6 structured mutation operators with usage guide
- **references/eval-criteria-guide.md** -- How to write good binary eval criteria
- **references/state-format.md** -- JSON schemas for state.json and results.jsonl
