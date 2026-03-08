# Plan Structure -- PLAN.md Format Specification

PLAN.md format specification -- frontmatter, task blocks, verification criteria, deviation rules, and summary format. Defines the canonical structure for phased execution plans.

## Frontmatter Fields

Every PLAN.md starts with YAML frontmatter between `---` delimiters:

| Field | Required | Purpose | Example |
|-------|----------|---------|---------|
| `phase` | Yes | Phase slug | `13-gsd-pattern-absorption` |
| `plan` | Yes | Plan number within phase | `01` |
| `type` | Yes | Plan type | `execute`, `research`, `tdd` |
| `wave` | Yes | Parallel execution group | `1` (default) |
| `depends_on` | No | Plans that must complete first | `[01]` |
| `files_modified` | Yes | Files this plan will touch | List of paths |
| `autonomous` | Yes | Can execute without checkpoints | `true` / `false` |
| `requirements` | No | Requirement IDs addressed | `[AUTH-01, AUTH-02]` |
| `must_haves` | No | Goal-backward verification spec | See Must-Haves section |

Missing `wave` defaults to 1. Missing `depends_on` means no dependencies.

## Task Format

Skippy uses markdown headers with YAML-style fields for task definitions. Every task needs four fields -- if you can't specify all four, the task is too vague and needs to be broken down further.

```markdown
## Task N: [Action-oriented name]
- files: `path/to/file.ext`
- action: [Specific implementation instructions]
- verify: `[command that returns 0 on success]`
- done: [Observable completion criteria]
```

### Field Requirements

| Field | What It Answers | Must Be |
|-------|----------------|---------|
| **files** | What changes? | Specific paths, not directories |
| **action** | What to do? | Concrete steps, not goals |
| **verify** | How to test? | A command or check that returns pass/fail |
| **done** | How to know it's complete? | An observable state, not a feeling |

### Good vs Bad Tasks

**Bad -- too vague:**
```markdown
## Task 1: Add authentication
- files: `src/`
- action: Implement auth
- verify: Test it
- done: Auth works
```

**Good -- all four fields are specific:**
```markdown
## Task 1: Create JWT validation middleware
- files: `src/middleware/auth.ts`, `src/routes/index.ts`
- action: Create middleware that validates Bearer tokens using jose,
  attach decoded user to request object
- verify: `bun test tests/middleware/auth.test.ts` -- 4 tests pass
- done: Protected routes return 401 without valid token, 200 with valid token
```

### Task Types

| Type | Behavior | Example |
|------|----------|---------|
| `auto` | Execute autonomously | Implementation tasks |
| `checkpoint:human-verify` | Pause for user verification | UI review, functional testing |
| `checkpoint:decision` | Pause for user decision | Technology selection |
| `checkpoint:human-action` | Pause for unavoidable manual step | Email verification, 2FA |

See checkpoints.md for checkpoint protocol details.

## Deviation Rules

During execution, unplanned work will be discovered. Apply these rules automatically and document all deviations in the summary.

| Priority | Rule | Trigger | Action | Permission |
|----------|------|---------|--------|------------|
| 1 | **Architectural** | New DB table, schema change, new service, switching libs, breaking API | STOP -- present decision to user | Ask |
| 2 | **Bug** | Broken behavior, errors, wrong logic, type errors, security vulnerabilities | Fix inline, test, verify | Auto |
| 3 | **Missing Critical** | No error handling, no validation, no auth on protected routes, missing indexes | Add it, test, verify | Auto |
| 4 | **Blocking** | Missing dependency, wrong types, broken imports, missing config | Fix blocker, verify unblocked | Auto |

**Decision heuristic:** Does the issue affect correctness, security, or ability to complete the task?
- YES -- Rules 2-4 (auto-fix)
- MAYBE -- Rule 1 (ask)
- Unsure -- Rule 1 (ask)

**Edge cases:** Missing validation = Rule 3 (security). Null crash = Rule 2 (bug). New table = Rule 1 (architectural). New column = Rule 2 or 3 (context-dependent).

**Scope boundary:** Only auto-fix issues directly caused by the current task's changes. Pre-existing warnings or linting errors in unrelated files are out of scope -- log them as deferred items, do not fix them.

## Task Commit Protocol

After each task completes (verification passed, done criteria met), commit immediately.

1. **Stage individually** -- never `git add .` or `git add -A`
2. **Commit format:** `{type}({phase}-{plan}): {description}`
3. **Record hash** for the summary

| Commit Type | When |
|-------------|------|
| `feat` | New functionality |
| `fix` | Bug fix |
| `test` | Test-only changes (TDD RED) |
| `refactor` | No behavior change (TDD REFACTOR) |
| `chore` | Config, dependencies |
| `docs` | Documentation |

## Summary Format

After all tasks complete, create `{phase}-{plan}-SUMMARY.md` with:

**Frontmatter:** `phase`, `plan`, `subsystem`, `tags`, dependency graph (`requires`/`provides`/`affects`), `tech-stack` (added/patterns), `key-files` (created/modified), `key-decisions`, `requirements-completed`, `duration`, `completed`.

**Body sections:** Performance (duration, timestamps, counts), Accomplishments, Task Commits (hash per task), Files Created/Modified, Decisions Made, Deviations from Plan, Issues Encountered, Next Phase Readiness.

**One-liner must be substantive:**
- Good: "JWT auth with refresh rotation using jose library"
- Bad: "Authentication implemented"

## Must-Haves (Goal-Backward Verification)

The `must_haves` frontmatter block defines verifiable success criteria:

| Field | Purpose | Example |
|-------|---------|---------|
| `truths` | Assertions that must be true after execution | `"phased-execution.md covers wave parallelism"` |
| `artifacts` | Files that must exist with constraints | `path`, `provides`, `min_lines`, `contains` |
| `key_links` | Cross-references that must exist between artifacts | `from`, `to`, `via`, `pattern` |

Verifiers check `must_haves` against the actual codebase after execution. Failed checks trigger gap-closure plans.

## Integration Points

- **Reconciliation:** See reconciliation.md for plan-vs-actual comparison after execution
- **Scope protection:** See plan-boundaries.md for DO NOT CHANGE and SCOPE LIMITS sections
- **Verification:** See verification-loops.md for cycling protocol on failures
- **Checkpoints:** See checkpoints.md for checkpoint types and deviation Rule 1

## When to Apply

- Writing any PLAN.md for phased execution
- Reviewing plans for completeness (every task has 4 fields)
- Spawning planner agents (instruct them to follow this format)
- NOT for ad-hoc task lists or research notes -- this is for execution plans

---
*Source: Adapted from GSD execute-plan.md and summary.md template. Task format adapted from PAUL task-anatomy.*
*Last reviewed: 2026-03-08*
