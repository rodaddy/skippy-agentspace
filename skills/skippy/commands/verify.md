---
name: skippy:verify
description: Validate built features through conversational UAT with auto-fix loops
argument-hint: "[phase number]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---
<objective>
Validate built features through conversational testing. One test at a time, diagnose failures, auto-generate fix plans.

When issues are found: diagnose root cause, create fix PLAN.md, ready for `/skippy:execute`.
</objective>

<context>
Phase: $ARGUMENTS (optional -- auto-detects most recent completed phase if omitted)

**Reference docs:**
- Verification patterns: `references/verification-loops.md`
- State tracking: `references/state-tracking.md`
</context>

<process>
1. **Resolve phase** -- If phase provided, use it. Otherwise find most recently executed phase from STATE.md.

2. **Load success criteria** -- Read ROADMAP.md for the phase's success criteria. Read PLAN.md files for task-level verify fields. Build a test checklist.

3. **Present tests one at a time** -- For each success criterion:
   a. State what's being tested and how
   b. Run the verification (bash command, file check, or manual observation)
   c. Record PASS or FAIL with evidence

4. **On failure -- diagnose:**
   a. Spawn a diagnostic agent to investigate the failure
   b. Agent reads: relevant source files, PLAN.md, SUMMARY.md, error output
   c. Agent produces: root cause analysis, affected files, proposed fix

5. **Auto-fix loop** (max 3 cycles per failure):
   a. If diagnosis is clear: create a fix PLAN.md in the phase directory
   b. Execute the fix (spawn agent or apply directly if trivial)
   c. Re-run the failing test
   d. If still failing after 3 cycles: log as unresolved, move to next test

6. **Write UAT report** -- Save `{phase}-UAT.md` to the phase directory:
   - Date, total tests, pass/fail counts
   - Full test table with evidence
   - Unresolved issues with diagnosis

7. **Update state** -- Update STATE.md with verification results.

8. **Route:**
   - All pass: "Phase {N} verified. Run `/skippy:reconcile` for plan-vs-actual comparison."
   - Failures with fixes applied: "Re-run `/skippy:verify {N}` to confirm fixes."
   - Unresolved: "Manual intervention needed for {N} issues. See UAT report."
</process>
