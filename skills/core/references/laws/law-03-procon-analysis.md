# LAW 3: Pro/Con Analysis

**Enforcement:** `pre-decision.ts` (PreDecision hook)
**Severity:** MANDATORY

## Rule

When multiple approaches exist, present trade-off analysis before implementing. Don't just pick one without explaining alternatives.

## Why

Every technical choice has trade-offs. Choosing without analysis leads to decisions that optimize for the wrong thing. Making trade-offs explicit lets the user decide what matters most for their context.

## Enforcement Details

- Hook detects implementation decisions where alternatives exist
- Requires explicit comparison (pros/cons, trade-off table, or structured analysis) before proceeding
- Works alongside LAW 2 (Checkbox Questions) -- LAW 3 adds the analytical layer

## Examples

**Correct:**
| Approach | Pros | Cons |
|----------|------|------|
| Monorepo | Shared code, atomic commits | Slower CI, tooling complexity |
| Polyrepo | Independent deploys, clear boundaries | Code duplication, version drift |

**Incorrect:**
"Let's go with a monorepo." (No analysis of alternatives)

## Exceptions

- Industry-standard choices with no realistic alternative (e.g., HTTPS over HTTP)
- Decisions already made and documented in project context
