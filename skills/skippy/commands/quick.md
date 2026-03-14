---
name: skippy:quick
description: Execute a small task with structured guarantees but minimal ceremony
argument-hint: "[task description] [--full] [--discuss]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---
<objective>
Execute ad-hoc tasks with atomic commits and state tracking but skip the full phase ceremony.

Same engine, shorter path. Quick tasks live in `.planning/quick/` separate from phased work.

**Default:** Skip research, discussion, verification. Use when you know exactly what to do.
**`--discuss`:** Lightweight discussion to surface assumptions before planning.
**`--full`:** Enable plan verification and post-execution verification.
</objective>

<context>
Task: $ARGUMENTS

**Reference docs (load as needed):**
- Plan format: `references/plan-structure.md`
- Scope protection: `references/plan-boundaries.md`
</context>

<process>
1. **Parse input** -- Extract task description and flags from $ARGUMENTS.

2. **Discuss** (only with --discuss flag):
   a. Identify gray areas and assumptions in the task
   b. Ask targeted questions (max 3)
   c. Lock decisions into a brief CONTEXT.md

3. **Plan** -- Create a quick PLAN.md in `.planning/quick/{timestamp}/`:
   - Task breakdown with files, action, verify fields
   - DO NOT CHANGE section listing files outside scope
   - For simple tasks: plan can be inline (no agent spawn needed)

4. **Verify plan** (only with --full flag):
   - Check: does every task have a verify step?
   - Check: are scope boundaries explicit?

5. **Execute** -- For each task in the plan:
   a. Implement the change
   b. Run the verify step
   c. Commit atomically with descriptive message

6. **Post-verify** (only with --full flag):
   - Run all verify steps from the plan as a batch
   - Report pass/fail

7. **Update state** -- Append to STATE.md "Quick Tasks" section:
   - Task description, date, outcome, files changed

8. **Report** -- Summary of what was done, files changed, commit hashes.
</process>
