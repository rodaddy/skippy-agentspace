---
name: skippy:plan
description: Research, plan, and verify a phase with adversarial review
argument-hint: "[phase] [--skip-research] [--skip-verify]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Agent
  - WebFetch
  - WebSearch
---
<objective>
Create executable phase plans (PLAN.md files) for a roadmap phase.

**Flow:** Research (optional) -> Plan -> Adversarial Review -> Done

Orchestrator stays lean: validate phase, optionally research, spawn planner agent, verify plan quality, iterate until pass or max 3 iterations.
</objective>

<context>
Phase number: $ARGUMENTS (auto-detects next unplanned phase if omitted)

**Flags:**
- `--skip-research` -- Skip research, go straight to planning
- `--skip-verify` -- Skip adversarial review loop

**Reference docs (load as needed, not all at once):**
- Plan format: `references/plan-structure.md`
- Scope protection: `references/plan-boundaries.md`
- State tracking: `references/state-tracking.md`
- Execution patterns: `references/phased-execution.md`
</context>

<process>
1. **Locate project** -- Find `.planning/` in current directory or parents. Read STATE.md and ROADMAP.md.

2. **Resolve phase** -- If phase number provided, use it. Otherwise find next unplanned phase from ROADMAP.md.

3. **Validate** -- Confirm phase exists in ROADMAP.md, check for existing PLAN.md files, warn if re-planning.

4. **Check for context** -- If `.planning/phases/{phase}/CONTEXT.md` exists, read it for locked decisions and gray area resolutions.

5. **Research** (unless --skip-research) -- Spawn a research agent to investigate the phase's domain. Agent reads ROADMAP.md phase description + any CONTEXT.md, searches for patterns/pitfalls, writes RESEARCH.md to the phase directory.

6. **Plan** -- Spawn a planner agent with these instructions:
   - Read: ROADMAP.md (phase goals + success criteria), RESEARCH.md (if exists), CONTEXT.md (if exists), PROJECT.md (constraints)
   - Read: `references/plan-structure.md` for format spec
   - Read: `references/plan-boundaries.md` for scope protection
   - Write PLAN.md files to `.planning/phases/{phase}/`
   - Each plan: task breakdown with files, action, verify fields
   - Include DO NOT CHANGE and SCOPE LIMITS sections

7. **Verify** (unless --skip-verify) -- Spawn a reviewer agent to check the plan:
   - Does every success criterion from ROADMAP.md have a task that delivers it?
   - Are scope boundaries explicit?
   - Are file ownership conflicts between plans resolved?
   - If issues found: report to orchestrator, planner revises, re-verify (max 3 iterations)

8. **Update state** -- Update STATE.md with new phase status. Report plan count and next step.

9. **Route** -- Suggest: "Run `/skippy:execute {phase}` to execute" or flag blockers.
</process>
