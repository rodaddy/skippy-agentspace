---
name: skippy:review
description: Multi-agent audit swarm -- spawns specialist reviewers, aggregates findings, applies fixes, verifies
---
<objective>
Run a multi-agent code review cycle on the current project or a specified scope. Spawns 4 specialist reviewers sequentially, aggregates findings into a shared board, applies fixes for critical issues, and verifies no regressions.

This command does NOT require GSD or any external framework. The main conversation acts as orchestrator -- all agent spawns happen here. Subagents CANNOT spawn other subagents (Claude Code limitation).
</objective>

<execution_context>
@../SKILL.md
@../references/audit-swarm.md
@../references/verification-loops.md
@../references/model-routing.md
</execution_context>

<process>

## Step 1: Determine Scope and Prepare

If the user specifies a scope (e.g., "review phase 13", "review tools/"), use that.

Otherwise, auto-detect:
1. Read `.planning/STATE.md` for the current phase
2. If a phase is in progress, scope to that phase's modified files
3. If no phase context, default to full repo scan

Accept `--scope <path>` for targeted review of specific directories or files.

Create the findings board:
1. Create `.reports/skippy-review/` directory if it doesn't exist
2. Generate timestamp: `TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)`
3. Create findings board at `.reports/skippy-review/findings-${TIMESTAMP}.md` with the template:

```markdown
# Audit Findings Board

**Scope:** [what was reviewed]
**Started:** [timestamp]
**Status:** in-progress

## Security Review
[pending -- will be populated by security-reviewer agent]

## Code Quality Review
[pending -- will be populated by code-quality-reviewer agent]

## Architecture Review
[pending -- will be populated by architecture-reviewer agent]

## Consistency Review
[pending -- will be populated by consistency-reviewer agent]

## Synthesis

### Priority Actions
| # | Severity | Finding | Reviewer | Fix Status |
|---|----------|---------|----------|------------|

## Fix Log
[pending -- will be populated by fix agents]

## Evaluation
[pending -- will be populated by eval agent]
```

## Step 2: Spawn Reviewer Agents (Sequential)

Spawn each of the 4 reviewers one at a time using the Agent tool. Sequential spawning is intentional -- it prevents context overflow from large simultaneous returns and avoids findings board write conflicts.

For each reviewer in order:
1. **security-reviewer** -- scans for vulnerabilities, injection, secret exposure
2. **code-quality-reviewer** -- reviews DRY, error handling, dead code, complexity
3. **architecture-reviewer** -- checks portability, conventions, dependencies, SoC (uses opus model)
4. **consistency-reviewer** -- verifies cross-file alignment (SKILL.md, INDEX.md, state files)

For each reviewer, read its agent definition file (`skills/skippy/agents/{agent-name}.md`) and extract YAML frontmatter fields to pass as Agent tool parameters:
- `model` → Agent tool `model` parameter (e.g., "opus" for architecture-reviewer)
- `permissionMode` → Agent tool `mode` parameter (e.g., "plan" for reviewers)
- `isolation` → Agent tool `isolation` parameter (e.g., "worktree" for fix-agent)

Spawn the Agent tool with:
- **Prompt:** Include the scope to review, the findings board file path, and the instruction: "Read `skills/skippy/agents/{agent-name}.md` for your full instructions. Write your findings to the `## {Section Name} Review` section of the findings board at {path}. Return a summary count only (e.g., 'Found 2 CRITICAL, 3 HIGH, 1 MEDIUM issues')."
- **mode:** `plan` (from agent frontmatter -- ensures reviewers are read-only)
- Wait for completion before spawning the next reviewer
- Record the summary count returned by each reviewer

All agents include HOME sandbox instructions in their definition files. Reviewers use `permissionMode: plan` (read-only) -- they cannot modify project files.

## Step 3: Synthesize Findings

After all 4 reviewers complete:

1. Read the full findings board file
2. Cross-reference findings between reviewers:
   - Same file flagged by multiple reviewers (e.g., security injection + code quality validation gap)
   - Same root cause identified from different angles
3. Deduplicate findings that describe the same issue from different perspectives
4. Add cross-ref notes to duplicate findings (e.g., "See also: Security Review finding #2")

## Step 4: Prioritize

Build the Priority Actions table in the Synthesis section:

1. Sort by severity: CRITICAL first, then HIGH, then MEDIUM, then LOW
2. Group by file for efficient fix planning (multiple findings on one file = one fix agent)
3. Count totals by severity and report to user:
   ```
   Findings: N total (C critical, H high, M medium, L low)
   ```

Only CRITICAL and HIGH findings trigger fix agent spawning. MEDIUM and LOW are documented but not auto-fixed.

## Step 5: Fix (CRITICAL and HIGH only)

For each CRITICAL or HIGH finding (or group of findings on the same file):

1. Spawn the fix-agent using the Agent tool with a prompt containing:
   - The specific finding(s) to fix (copy from findings board)
   - The file path(s) to modify
   - Instruction: "Read `skills/skippy/agents/fix-agent.md` for your full instructions. Apply the fix. Make one atomic commit per finding with message prefixed `fix(review):`. Report the commit hash and what was changed."
2. Wait for completion
3. Record commit hash and fix description in the Fix Log section of the findings board

If no CRITICAL or HIGH findings exist, skip this step and report "No critical fixes needed."

## Step 6: Evaluate

Spawn the eval-agent with a prompt containing:
- The findings board path (to see what was fixed)
- The list of commit hashes from Step 5
- Instruction: "Read `skills/skippy/agents/eval-agent.md` for your full instructions. Verify each fix was applied correctly. Check that fixes didn't introduce regressions. Write results to the `## Evaluation` section of the findings board. Return PASS or FAIL with details."

If eval returns FAIL:
1. Check if the failure matches a previous failure signature (same-failure detection from verification-loops.md)
2. If same failure 3 times: stop cycling, report the persistent issue
3. If new failure and cycle count < 3: spawn a targeted fix-agent for the regression, then re-evaluate
4. If cycle count >= 3: stop cycling, report remaining issues

If no fixes were applied (Step 5 was skipped), skip evaluation too.

## Step 7: Finalize Findings Board

Update the findings board:
1. Set status to "verified" (or "partial -- N issues remain" if some fixes failed)
2. Add final statistics section:
   ```markdown
   ## Final Statistics
   - **Total findings:** N (C critical, H high, M medium, L low)
   - **Fixes applied:** F across X commits
   - **Regressions found:** R
   - **Regressions resolved:** RR
   - **Eval cycles:** N
   - **Duration:** Xm Ys
   ```
3. Update all finding statuses: OPEN -> FIXED or WONTFIX (with reason)

## Step 8: Report

Display a summary to the user:

```
## Audit Complete

**Scope:** {what was reviewed}
**Findings:** {N} total ({C} critical, {H} high, {M} medium, {L} low)
**Fixed:** {F} findings across {X} commits
**Regressions:** {R} found, {RR} resolved
**Status:** {CLEAN | PARTIAL | NEEDS_ATTENTION}

Full report: .reports/skippy-review/findings-{timestamp}.md
```

Status meanings:
- **CLEAN** -- All CRITICAL/HIGH findings fixed and verified, no regressions
- **PARTIAL** -- Some CRITICAL/HIGH findings remain after max fix cycles
- **NEEDS_ATTENTION** -- Unfixed CRITICAL findings exist -- list them explicitly

If NEEDS_ATTENTION, list the remaining unfixed CRITICAL/HIGH items so the user knows what to address manually.

## Important Notes

- Sequential spawning is intentional (see audit-swarm.md for rationale)
- The orchestrator (this conversation) manages all agent spawning -- subagents cannot spawn other subagents
- All agents include HOME sandbox instructions -- never operate against real `~/.claude/`
- Fix agents operate in worktree isolation when available
- The max eval cycle count is 3 -- if a fix keeps failing after 3 attempts, stop and report

</process>
