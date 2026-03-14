# Plan Boundaries -- Scope Protection

Adapted from PAUL's scope management. Every plan should declare what it will NOT touch. Boundaries are hard constraints, not suggestions.

## Template

Add a `## Boundaries` section to every PLAN.md (see `plan-structure.md` for the full plan format):

```markdown
## Boundaries

### DO NOT CHANGE
- `src/database/migrations/` -- migration files are immutable once applied
- `package.json` dependencies -- no new deps without explicit approval
- `.env` files -- environment config is out of scope
- `CLAUDE.md` -- project rules don't change during feature work

### SCOPE LIMITS
- This phase covers authentication only -- authorization (roles/permissions) is Phase 3
- API changes are internal only -- no public API contract changes
- No database schema changes -- work with existing tables
- Frontend changes limited to `src/components/auth/` -- don't touch other components
```

## Rules

### DO NOT CHANGE
- Lists files, directories, or patterns that must not be modified
- Executor agents treat these as **hard errors** -- if a task would require changing a protected file, stop and flag it
- Common protected items:
  - Migration files (immutable after apply)
  - Lock files (only change via package manager)
  - CI/CD configs (separate concern)
  - Environment files (ops concern)
  - CLAUDE.md / project config (meta concern)

### SCOPE LIMITS
- Declares what is explicitly **out of scope** for this phase
- Prevents scope creep during execution
- If an executor discovers work that crosses a scope limit, it should:
  1. Note it as a future task / tech debt
  2. NOT implement it
  3. Report it in the phase summary

## When to Apply

- **Every PLAN.md** should have boundaries -- even if they're short
- **Especially important** when:
  - Multiple people/agents work on the same codebase
  - The phase touches shared infrastructure
  - There's a risk of scope creep (large features, refactors)
  - Files have implicit dependencies (changing one breaks another)

## Enforcement

Boundaries are self-enforced by agents reading the plan. No hooks required. The reconciliation step (`/skippy:reconcile`) will catch boundary violations by comparing planned files vs actually changed files.

## Integration Prompt

When spawning a planner agent, add:

```
Include a ## Boundaries section in the plan with DO NOT CHANGE (protected files)
and SCOPE LIMITS (what's explicitly out of scope for this phase).
```

When spawning an executor agent, add:

```
Before modifying any file, check the plan's ## Boundaries section. If the file
is listed under DO NOT CHANGE, stop and report the conflict. If the work crosses
a SCOPE LIMIT, note it as future work and skip it.
```

---
*Source: Adapted from PAUL scope management*
*Last reviewed: 2026-03-08*
