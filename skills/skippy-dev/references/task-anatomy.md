# Task Anatomy -- 4 Required Fields

Adapted from PAUL's plan-format.md. Every task in a GSD plan should have these four fields. If you can't specify all four, the task is too vague -- break it down further.

## Required Fields

| Field | Purpose | Example |
|-------|---------|---------|
| **files** | Which files will be created/modified/deleted | `src/auth/login.ts`, `tests/auth.test.ts` |
| **action** | What specifically changes | "Add JWT validation middleware" |
| **verify** | How to confirm it worked | "Run `bun test tests/auth.test.ts`, expect 3 new tests pass" |
| **done** | Observable completion signal | "Login endpoint returns 401 for expired tokens" |

## Good vs Bad Tasks

### Bad (too vague)

```markdown
- [ ] Add authentication
- [ ] Fix the bug
- [ ] Improve performance
- [ ] Update the API
```

Why bad: No files specified, no verification, no done criteria. "Add authentication" could mean 50 different things.

### Good (all four fields)

```markdown
- [ ] Add JWT validation middleware
  - files: `src/middleware/auth.ts` (create), `src/routes/index.ts` (modify)
  - action: Create middleware that validates Bearer tokens using jsonwebtoken, attach decoded user to request
  - verify: `bun test tests/middleware/auth.test.ts` -- 4 tests (valid token, expired, malformed, missing)
  - done: Protected routes return 401 without valid token, 200 with valid token
```

### Good (small task, compact format)

```markdown
- [ ] Fix off-by-one in pagination
  - files: `src/utils/paginate.ts`
  - action: Change `offset = page * limit` to `offset = (page - 1) * limit`
  - verify: `bun test tests/utils/paginate.test.ts` passes
  - done: Page 1 returns first N items (not second N)
```

## When to Apply

- **GSD plan-phase:** Planner agents should use this format for all tasks in PLAN.md
- **Manual task creation:** When writing tasks in `.planning/todos/`
- **Agent prompts:** Tell gsd-planner to "follow task-anatomy format from skippy-dev"

## Exceptions

- Trivial tasks (rename a variable, fix a typo) don't need all four fields
- Research tasks replace `files` with `output` (what the research should produce)
- The goal is clarity, not ceremony -- if the task is obvious, keep it light

## Integration Prompt

When spawning a gsd-planner agent, add:

```
For each task in the plan, include: files (what changes), action (what to do),
verify (how to test), done (observable result). If you can't fill all four,
the task needs to be broken down further.
```
