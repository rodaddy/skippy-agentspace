# PRD Workflows

Execution, closing, review, and amendment workflows for the PRD skill.

## Creation Workflow

### Phase 0: Clarification Gate

**Always ask 2-4 targeted questions** before drafting stories. Even detailed task descriptions have unstated assumptions. Questions should cover:

1. **Scope boundaries** -- what's explicitly OUT of scope?
2. **Error handling** -- what should happen when things fail? (skip, abort, retry?)
3. **Existing state** -- is there existing code/tests to protect? What's the baseline?
4. **Success definition** -- what does "done" look like beyond "it works"? (perf targets, data volume, edge cases?)

Skip questions ONLY if the user provides a fully-specified PRD with all acceptance criteria already written. In practice, always ask.

### Phase 1: Discover

1. Detect project stack (language, test runner, type checker)
2. Run pre-flight commands (tests, type check, build)
3. Document known issues from pre-flight results
4. Read relevant codebase structure
5. Determine complexity tier (Quick / Standard / Full)

### Phase 2: Draft

1. Parse the task into discrete work units
2. Write stories following all rules (see `story-rules.md`)
3. Write verify commands with `expect_pattern` AND `expect_not_pattern`
4. Include mandatory stories: regression + e2e + idempotency (if applicable)
5. Add setup (first) and cleanup (last) stories
6. Set explicit dependencies
7. Verify no circular dependencies in the `depends_on` graph

### Phase 3: Self-Check (Mandatory)

- [ ] Every story has at least 1 verify command with `expect_pattern`
- [ ] No story has more than 7 acceptance criteria
- [ ] No story title contains "and"
- [ ] Regression story exists
- [ ] E2E story exists with real-world test
- [ ] Setup/cleanup stories exist (if applicable)
- [ ] All dependencies explicit, no circular deps
- [ ] Pre-flight ran, known_issues documented
- [ ] Stack metadata correct (test_runner, type_checker, working_directory)
- [ ] Complexity tier set correctly
- [ ] Cycle limits set (default 5/story, 20 total)
- [ ] Each acceptance criterion maps to at least one verify command
- [ ] Verify commands are deterministic (no external network, no side effects)

### Phase 4: Antagonistic Review

**Quick tier:** Skip.
**Standard tier:** Spawn 2 critics (Gap Hunter + Verification Auditor).
**Full tier:** Spawn 4 critics.

Pass the full `.prd/prd.json` content to each critic agent. Each critic reads the JSON and attacks it.

```
1. Gap Hunter (critic agent, model: "sonnet-nocache")
   "Find every gap, missing edge case, unstated assumption,
    and implicit dependency. Number each finding."

2. Verification Auditor (architect agent, model: "sonnet-nocache")
   "For each verify command: is it executable? Could it pass
    while the criterion is unmet (false positive)? Does
    expect_not_pattern catch hidden failures?"

3. Scope Splitter (lightweight architect agent, model: "haiku-nocache")  [Full tier only]
   "Flag compound stories, redundancies, over-scoping."

4. Regression Analyst (code-reviewer agent, model: "sonnet-nocache")  [Full tier only]
   "What existing functionality could break? Is the e2e story
    realistic? What's the blast radius?"
```

### Phase 5: Incorporate and Finalize

1. Fix critic findings. Document disagreements in progress.md
2. Write `.prd/prd.json` and `.prd/progress.md`
3. Create `.prd/evidence/` directory

## Next Steps (Output After PRD Creation)

After Phase 5 completes and `.prd/prd.json` is written, ALWAYS present this to the user:

```
## What's Next?

Your PRD is ready at .prd/prd.json (N stories, tier: <tier>).

Pick an execution path:
- `/prd-to-issues` -- create tracked GitHub issues (team visibility, HITL/AFK classification)
- `/drive` -- execute locally in a persistence loop (solo blitz, guaranteed completion)
- `/prd --execute` -- run stories inline (same session, no separate orchestration)
```

Do NOT auto-pick a path. The user decides based on context (team vs solo, visibility needs, session length).

## Execution Workflow (`/prd --execute`)

This is the core loop. An agent picks up the PRD and works through stories autonomously.

### Story Selection

1. Read `.prd/prd.json`
2. Find next story: `status == "pending"` AND all `depends_on` are `passed`
3. Pick lowest priority number (priority 1 = first)
4. If no stories available and some are `blocked`, report and stop

### Pipelined Review Protocol (Standard + Full tiers)

During `--execute`, the orchestrator runs a team-based pipeline where reviewers wait for coders to finish before reading any files. This eliminates false positives from reading mid-edit.

#### Team Setup
At the start of execution, create a team. Reviewer agents are spawned **fresh per wave** (not persistent) to avoid cache poisoning:

1. **Quality Reviewer** (`code-reviewer`, `model: "sonnet-nocache"`) -- fresh instance per wave
   - Checks code quality, correctness vs acceptance criteria, test coverage
   - Reports severity-rated findings

2. **Antagonist** (`security-reviewer`, `model: "sonnet-nocache"`) -- fresh instance per wave
   - Tries to break the implementation
   - Finds edge cases, security issues, integration gaps
   - Checks cross-story wiring

3. **Build Watcher** (`build-fixer-low`, `model: "haiku"`) -- spawned per-wave
   - Runs tsc + tests after each story completes
   - Spawns build-fixer on failure

**Cache isolation (mandatory):** Use `-nocache` model aliases (`sonnet-nocache`, `haiku-nocache`) for all reviewer/antagonist agents. These bypass LiteLLM's semantic cache via `custom_callbacks.py`, preventing cross-agent cache poisoning. Spawn fresh instances per wave rather than persistent agents to avoid context accumulation.

Model enforcement is mandatory -- always pass `model` explicitly to prevent inheriting Opus from the parent context.

#### Handoff Protocol
After each wave of coders completes:

1. Orchestrator collects: files changed, acceptance criteria, story context for all stories in the wave
2. Spawns fresh Quality Reviewer + fresh Antagonist as foreground Task agents, with handoff context baked into the spawn prompt (not sent as a follow-up message)
3. Spawns Build Watcher (haiku) to run tsc + tests in background
4. Reviewers read the COMPLETED files and return findings
5. Orchestrator triages findings:
   - CRITICAL: Block story, report to user, pause execution
   - HIGH: Block story, attempt auto-fix or report to user
   - MEDIUM: Log to progress.md, continue
   - LOW: Log only
6. Reviewer agents terminate after responding (they are single-use per wave)

#### Story Lifecycle Gate
A story can only transition to `passed` when ALL of:
- Coder reports completion
- Build Watcher confirms tsc + tests pass
- Quality Reviewer responds (no CRITICAL/HIGH)
- Antagonist responds (no CRITICAL/HIGH)

#### Integration Check
Between waves, include cross-story integration review in the reviewer spawn prompt:
- Are exports from story A imported by story B (or vice versa)?
- Do API contracts match between producer/consumer?
- Any shared state (DB tables, caches, config) that needs coordination?
- Any function that SHOULD be called from other modules but isn't wired?

#### Handoff Context Template (included in reviewer spawn prompt)
```
REVIEW HANDOFF -- Wave N: [story list]

All files are COMPLETE and safe to read.

Stories in this wave:

Story US-NNN: <title>
Files changed:
- src/path/to/file.ts (NEW|MODIFIED, N lines)
Acceptance criteria:
1. <criterion 1>
2. <criterion 2>

[repeat for each story in wave]

INTEGRATION CHECK (if wave > 1):
Previously completed stories: [list]
Check cross-story wiring between this wave and previous waves.

Read each file completely.
Report findings as: SEVERITY | file:line | description
```

#### Reviewer Agent Prompt Templates

Quality Reviewer spawn prompt (fresh per wave -- do NOT reuse across waves):
```
You are a code quality reviewer for this wave of PRD execution.
You will review ONE wave of completed stories, then your job is done.

The files listed below are COMPLETE and safe to read.

CODE INTELLIGENCE (MANDATORY): Use LSP tools (goToDefinition, findReferences, hover, documentSymbol) and search_all (mcp2cli open-brain search_all -- federates OB knowledge + qmd files) BEFORE falling back to Read/Glob/Grep. LSP gives type-aware precision. search_all gives semantic search across knowledge + codebase. Raw reads are last resort.

Instructions:
1. Read EVERY file listed in the handoff completely
2. Compare the implementation against the acceptance criteria provided
3. Check: correctness, error handling, test coverage, patterns, naming
4. Report findings as: SEVERITY | file:line | description
5. Reply with ALL findings

Severity guide:
- CRITICAL: Will cause data loss, security breach, or crash in production
- HIGH: Violates acceptance criteria, missing error handling, broken logic
- MEDIUM: Code quality issue, missing edge case, weak test
- LOW: Style, naming, minor improvement
```

Antagonist spawn prompt (fresh per wave -- do NOT reuse across waves):
```
You are an antagonist reviewer for this wave of PRD execution.
Your job is to BREAK things and find what the coder missed.
You will review ONE wave of completed stories, then your job is done.

The files listed below are COMPLETE and safe to read.

CODE INTELLIGENCE (MANDATORY): Use LSP tools (goToDefinition, findReferences, hover, documentSymbol, incomingCalls, outgoingCalls) and search_all (mcp2cli open-brain search_all -- federates OB knowledge + qmd files) BEFORE falling back to Read/Glob/Grep. LSP gives type-aware precision. search_all gives semantic search across knowledge + codebase. Raw reads are last resort.

Instructions:
1. Read EVERY file listed in the handoff completely
2. Try to break the implementation:
   - What inputs would cause crashes or wrong results?
   - What edge cases are unhandled?
   - What security issues exist (injection, PII leaks, auth bypass)?
   - What cross-module wiring is missing?
   - What happens when dependencies fail?
3. Report findings as: SEVERITY | file:line | description
4. Reply with ALL findings
```

#### Quick Tier Exception
Quick tier (1-3 stories) skips persistent reviewers. Post-hoc review only.

### Story Execution Cycle

```
1. Set story status to "in_progress"
2. Increment limits.current_cycle
3. Check cycle limit: if current_cycle > max_total_cycles, STOP
4. Implement the story (write code, make changes)
5. Set story status to "awaiting_verify"
6. Run this story's verify commands (or delegate to verifier agent)
7. Run regression check: re-run verify commands for ALL previously-passed stories
8. Evaluate results:
   a. ALL commands pass AND no regressions -> status = "passed"
   b. Story passes BUT causes regression -> status = "failed", fix regression first
   c. Story fails -> increment retries. If retries < max -> status = "pending" (retry)
   d. Story fails AND retries >= max -> status = "failed", STOP and report
9. Write evidence to .prd/evidence/US-NNN.json
10. Pick next story (back to step 1)
```

### Cycle Limits (Anti-Loop Protection)

| Limit | Default | What Happens |
|-------|---------|-------------|
| `max_retries_per_story` | 5 | Story fails permanently, execution stops |
| `max_total_cycles` | 20 | Entire PRD execution stops, report status |

When a limit is hit, the agent MUST:
1. Write current state to `.prd/prd.json`
2. Write a summary to `.prd/progress.md` explaining what worked and what didn't
3. Stop execution -- do NOT continue or reset counters

### Regression Protection

After marking a story `passed`, re-verify ALL previously-passed stories. If any regress:
1. Mark the CURRENT story as `failed` with reason "caused regression in US-XXX"
2. The regressed story stays `passed` (the code was fine before this change)
3. The current story must be fixed to not break previous work

### Failure Recovery

- **Soft failure** (independent story fails): mark failed, skip to next independent story
- **Hard failure** (dependency chain broken): mark dependents as `blocked`
- **Flaky failure**: if `retry_on_fail: true` on the verify command, retry up to 3 times with 2s delay

## Closing Workflow (`/prd --close`)

Run by a DIFFERENT agent than the executor (or at minimum, a fresh agent instance).

1. Reject if any story has status `pending` or `in_progress` -- close requires all stories attempted
2. For EACH story in priority order:
   a. Run every verify command
   b. Capture exit code + stdout (first 2000 chars) + stderr (first 500 chars)
   c. Write to `.prd/evidence/US-NNN.json` with git commit hash and timestamp
   d. ALL commands pass + patterns match + not-patterns clean -> `passed`
   e. ANY command fails -> `failed` with specific command identified
3. For manual checks: prompt user for confirmation (or mark `blocked` in autonomous mode)
4. If any story is `failed`, STOP -- do not mark PRD complete
5. Set `completed_at` only when ALL stories are `passed`
6. Write summary to `.prd/progress.md`

## Review Workflow (`/prd --review`)

1. Read `.prd/prd.json`
2. Re-run ALL verify commands for ALL stories
3. Compare current results vs stored evidence in `.prd/evidence/`
4. Flag drift: was passing, now failing
5. Flag stories with no evidence files
6. Write review report to `.prd/review-report.md`

## Amendment Workflow (`/prd --amend`)

### Story not yet started (pending)
Edit in place. No evidence to invalidate.

### Story in progress
Set back to `pending`. Agent restarts with new requirements.

### Story already passed
Create NEW story `US-NNN-v2` with `depends_on` the original. Original stays `passed` but gets `"superseded_by": "US-NNN-v2"`. New story covers only the delta.

### PRD needs major pivot
Close current PRD with note "superseded". Create new `.prd/prd.json` (archive old to `.prd/archive/`).

Record all amendments in `amendment_history`:
```json
{
  "amended_at": "2026-02-21T14:32:00-08:00",
  "story_id": "US-003",
  "change": "added error handling criteria",
  "reason": "discovered edge case during US-005"
}
```
