---
name: skippy:reconcile
description: Compare planned vs actual work for a completed phase -- tasks, acceptance criteria, file changes, state drift
---
<objective>
Run plan-vs-actual reconciliation on the most recent completed phase (or a user-specified phase number).

Produces a reconciliation report showing DONE/MODIFIED/SKIPPED/ADDED tasks, AC pass/fail status, unplanned file changes, and state consistency. Always saves the report to `.planning/phases/<NN>-*/RECONCILIATION.md`.
</objective>

<execution_context>
@../SKILL.md
@../references/reconciliation.md
@../references/state-consistency.md
@../references/plan-structure.md
</execution_context>

<process>

## Step 1: Identify Phase to Reconcile

If the user specifies a phase number (e.g., "reconcile phase 2"), use that number directly.

Otherwise, find the most recently completed phase:

1. Read `.planning/ROADMAP.md`
2. Find the last phase row marked with `[x]` (completed)
3. Extract the phase number and directory name
4. Verify against `.planning/STATE.md` frontmatter (`progress.completed_phases` count should match)

If no completed phase is found, report that there is nothing to reconcile yet.

## Step 2: Discover All Plans in the Phase

Phases can have multiple plans. Do NOT assume a single PLAN.md.

1. Glob for all plans in the phase directory: `.planning/phases/<NN>-*/<NN>-*-PLAN.md`
   - Example pattern for phase 2: `.planning/phases/02-*/*-PLAN.md`
2. For each PLAN.md found, identify the matching SUMMARY.md (same prefix, e.g., `02-01-PLAN.md` pairs with `02-01-SUMMARY.md`)
3. If a PLAN.md has no matching SUMMARY.md, flag it as an incomplete/skipped plan

## Step 3: Extract Tasks from Each Plan

Plans define tasks as markdown headings with structured fields (see `references/plan-structure.md` for the full spec):

```markdown
## Task 1: Description here
- files: `path/to/file.ts`, `path/to/other.ts`
- action: What the task does...
- verify: `verification command`
- done: Observable completion criteria
```

For each PLAN.md:
- Use `bun run tools/lib/skippy-state.ts extract-tasks <plan-file>` for reliable structured parsing
- Or manually extract `## Task N:` headings with their `- files:`, `- action:`, `- verify:`, `- done:` fields
- Note the task name, files, and done criteria for each task
- Also extract the `files_modified` list from YAML frontmatter (use `bun run tools/lib/skippy-state.ts parse-frontmatter <plan-file>`) -- these are the files the plan expected to change

## Step 4: Compare Plan vs Actual (Per Plan)

For each PLAN.md / SUMMARY.md pair:

**Task comparison:**
- Read the SUMMARY.md `## Task Commits` or `## Accomplishments` section
- For each planned task, classify as:
  - **DONE** -- completed as planned, done criteria met
  - **MODIFIED** -- completed but approach changed (note why from SUMMARY deviations section)
  - **SKIPPED** -- not done (note why)
  - **ADDED** -- work done that was not a planned task (found in SUMMARY but not in PLAN)

**Acceptance criteria:**
- Check PLAN.md `must_haves.truths` (if present) against actual file state
- For each truth/criterion, mark PASS, FAIL, or UNTESTED with evidence

**Deviations:**
- Read the SUMMARY.md `## Deviations from Plan` section -- this is the primary source of drift evidence
- Check `## Issues Encountered` for problems that may have caused modifications

## Step 5: Check for Unplanned File Changes

Use git history to detect file changes not anticipated by the plan:

1. From each SUMMARY.md, find the commit hashes listed in `## Task Commits`
2. Compare the PLAN.md `files_modified` frontmatter list against the SUMMARY.md `key-files` frontmatter (both `created` and `modified` lists)
3. Any file in the SUMMARY that is NOT in the PLAN's `files_modified` is an unplanned change -- flag it
4. Any file in the PLAN's `files_modified` that was NOT touched (not in SUMMARY `key-files`) is a missed file -- flag it

## Step 6: Check State Consistency

Follow the checks defined in `references/state-consistency.md`:

1. **Current phase agreement:** STATE.md `current_phase` matches ROADMAP.md's first incomplete phase
2. **Phase status agreement:** Completed phases have both PLAN.md and SUMMARY.md files
3. **Progress counts:** STATE.md `progress.completed_plans` matches the actual count of SUMMARY.md files on disk
4. **Git state:** Working directory clean? On the correct branch?

## Step 7: Generate Report

Use the report template from `references/reconciliation.md`:

- **Header:** Phase number, title, date, plan/completion commit hashes
- **Task Results table:** One row per task across ALL plans (not just the first plan)
  - Include which plan each task belongs to (e.g., "Plan 02-01, Task 1")
- **Acceptance Criteria table:** PASS/FAIL/UNTESTED for each criterion
- **Deviations section:** Unplanned changes and scope drift
- **State Consistency section:** Results of Step 6 checks
- **Verdict:** CLEAN, MINOR_DRIFT, MAJOR_DRIFT, or BLOCKED

## Step 8: Save Report

Always save the reconciliation report to:

```
.planning/phases/<NN>-<name>/RECONCILIATION.md
```

This creates a persistent record. Also display the full report to the user in the terminal output.

If a RECONCILIATION.md already exists for this phase, overwrite it (reconciliation can be re-run).

</process>
