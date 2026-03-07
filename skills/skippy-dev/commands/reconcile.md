---
name: skippy:reconcile
description: Compare planned vs actual work for a GSD phase -- tasks, acceptance criteria, file changes, state drift
---
<objective>
Run plan-vs-actual reconciliation on the most recent completed phase (or a specified project path).

Produces a reconciliation report showing DONE/MODIFIED/SKIPPED/ADDED tasks, AC pass/fail status, unplanned file changes, and state consistency.
</objective>

<execution_context>
@/Users/rico/.config/pai/Skills/skippy-dev/SKILL.md
@/Users/rico/.config/pai/Skills/skippy-dev/references/reconciliation.md
@/Users/rico/.config/pai/Skills/skippy-dev/references/state-consistency.md
</execution_context>

<process>
Follow the `/skippy:reconcile` workflow in the SKILL.md.

1. Identify the project's `.planning/` directory (use cwd or user-specified path)
2. Find the most recently completed phase
3. Read PLAN.md and SUMMARY.md for that phase
4. Compare planned tasks vs actual results using the reconciliation template
5. Check state consistency across STATE.md, ROADMAP.md, PROJECT.md
6. Output the reconciliation report
7. Optionally save to `.planning/phases/<N>/RECONCILIATION.md`
</process>
