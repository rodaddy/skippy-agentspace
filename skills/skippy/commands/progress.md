---
name: skippy:progress
description: Check project progress, show context, route to next action
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---
<objective>
Provide situational awareness: where are we, what's done, what's next. Then route to the right action.
</objective>

<process>
1. **Load state** -- Read `.planning/STATE.md` and `.planning/ROADMAP.md`.

2. **Summarize position:**
   - Current milestone and phase
   - Completion percentage (phases done / total)
   - Last activity (from STATE.md)
   - Any blockers or concerns

3. **Show what's next** -- Identify the next actionable phase or task:
   - Unplanned phase? -> "Run `/skippy:plan {N}`"
   - Planned but unexecuted? -> "Run `/skippy:execute {N}`"
   - Executed but unverified? -> "Run `/skippy:verify {N}`"
   - All phases complete? -> "Milestone complete. Run `/skippy:reconcile` for final review."
   - Quick tasks pending? -> List them

4. **Show recent context** -- Last 3 decisions from STATE.md, any pending todos.

5. **Route** -- Present the single most logical next action. Don't list all options -- pick one and explain why.
</process>
