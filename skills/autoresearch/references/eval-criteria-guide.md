<!-- Extracted from SKILL.md -- load on demand -->

# Eval Criteria Guide

## Rules for Good Criteria

1. **Binary only** -- every criterion is yes or no. Never scales, Likert, or "out of 10"
2. **Specific** -- "Does the function have a docstring?" not "Is the code documented?"
3. **Observable** -- checkable by reading output, running a command, or inspecting results
4. **Independent** -- each tests a different dimension. No overlapping questions
5. **Not gameable** -- avoid criteria so specific the prompt can parrot the eval wording

## Eval Types

### `command` (Preferred)

A shell command where exit 0 = pass, non-zero = fail.

```
command: grep -q "alt=" output.html
command: npx eslint --quiet file.ts
command: bun test --bail
command: grep -c "^# " file.md | grep -q "^1$"
```

**Retry rule:** On failure, retry once. Pass on retry = pass but flag `"flaky": true`. Flaky on 3+ runs = report as unstable.

### `agent-judge` (When No Command Works)

Spawn a **separate sonnet agent** that receives ONLY:
- The raw output text
- The criterion text
- Nothing else -- no prompt, no context, no history

The agent returns: `{ "pass": true/false, "reason": "brief explanation" }`

**Eval isolation is critical.** The judging agent must not know what prompt produced the output. This prevents author-intent bias.

**Adversarial re-eval (every cycle):** Pick 2 passing outputs and re-evaluate with skeptical prompting: "Looking at ONLY this output with no other context -- would a hostile reviewer agree this passes [criterion]?" If any flip to fail, update scores.

## Example Criteria by Domain

### Skill Trigger Optimization
1. Does the skill trigger for the test request? -- command: match against trigger regex
2. Is the skill the FIRST match (not buried behind others)? -- agent-judge
3. Does the skill NOT trigger for unrelated requests? -- command: inverse match
4. Is the trigger description under 300 characters? -- command: wc -c

### Hook Enforcement
1. Does the hook exit non-zero for violation inputs? -- command: run hook with test stdin
2. Does the hook exit zero for legitimate inputs? -- command: run hook with clean stdin
3. Does the hook produce a clear error message? -- agent-judge
4. Does the hook complete in under 2 seconds? -- command: timeout 2 hook

### Code Quality
1. Does the function have error handling? -- agent-judge
2. Does it pass the linter? -- command: eslint/ruff
3. Are all parameters typed? -- command: tsc --noEmit
4. Is cyclomatic complexity under 10? -- command: complexity checker

### Documentation
1. Has a title under 60 chars? -- command: grep + wc
2. Has meta description 120-160 chars? -- command: grep + wc
3. Uses exactly one H1? -- command: grep -c
4. All images have descriptive alt text? -- agent-judge
5. Has 2+ internal links? -- agent-judge

## Item-Level Failure Tracking

Track failures per item+criterion in `state.json -> item_failures`:
- Key: `"item_path:criterion_name"`
- Value: failure count

If any pair fails 5+ times across runs, flag it:
"Item [path] has failed [criterion] in [N] runs -- likely an item-level issue, not a prompt problem."

Do NOT count flagged failures toward the prompt's score.

## Criteria Health Check (Run 10)

- **Too easy**: 100% pass rate since run 1 -- not discriminating. Suggest harder replacement.
- **Too hard**: never exceeded 20% -- may be unreasonable or need code changes. Suggest rewording.
- Do NOT pause the loop. Log flags and keep running.
