# Pre-Execution Gate -- Vague Prompt Interception

Adapted from OMC's ralplan skill. Intercepts underspecified execution requests and redirects them to planning before work begins. The gate runs BEFORE execution -- complementing plan boundaries (what NOT to touch) and task anatomy (how to structure tasks) by ensuring neither is bypassed.

## When to Apply

- Before any execution request that didn't come from a structured plan
- When a user or orchestrator says "fix this", "build that", "make it work" without specifics
- As a self-check before spawning executor agents
- NOT needed when executing tasks from a PLAN.md (those already passed through planning)

## The Gate

Every execution request is either **concrete** (pass through) or **vague** (redirect to planning).

### Concrete Signal Detection

A request is concrete if it contains **2+ signals** from this list:

| Signal Type | Examples | Weight |
|-------------|----------|--------|
| **File paths** | `src/auth/login.ts`, `tests/*.test.ts` | Strong |
| **Function/symbol names** | `validateToken()`, `UserService`, `AUTH_HEADER` | Strong |
| **Issue/PR numbers** | `#142`, `PR #38`, `GH-205` | Strong |
| **Error references** | Stack traces, error messages, line numbers | Strong |
| **Code blocks** | Inline code or fenced blocks with actual code | Strong |
| **Numbered steps** | "1. Add middleware, 2. Update routes, 3. Run tests" | Moderate |
| **Specific values** | "change timeout from 30s to 60s", "rename X to Y" | Moderate |
| **camelCase/PascalCase** | Identifiers that reference real code symbols | Moderate |

### Decision Logic

```
IF request has 2+ strong signals OR 1 strong + 2 moderate:
  -> PASS: Execute directly
ELSE IF request has 1 strong signal:
  -> CLARIFY: "I see [signal]. Can you specify [what's missing]?"
ELSE:
  -> REDIRECT: "This needs planning first. Let me create a plan."
```

## Vague Request Examples

| Request | Verdict | Why |
|---------|---------|-----|
| "Fix authentication" | REDIRECT | No files, no symbols, no error reference |
| "The login is broken" | REDIRECT | Symptom without specifics |
| "Improve performance" | REDIRECT | No target, no metric, no files |
| "Update the API" | REDIRECT | Which endpoints? What changes? |
| "Refactor the codebase" | REDIRECT | Entire codebase is not a task |

## Concrete Request Examples

| Request | Verdict | Why |
|---------|---------|-----|
| "Fix the off-by-one in `paginate.ts` line 42" | PASS | File + line number |
| "Add JWT validation to `src/middleware/auth.ts`" | PASS | File + specific action |
| "Fix #142 -- login returns 500 on expired tokens" | PASS | Issue number + error + context |
| "1. Add rate limiter to /api/upload, 2. Set limit to 10/min, 3. Add test" | PASS | Numbered steps + specific values |

## Escape Hatch

Prefix with `force:` to bypass the gate when you know what you're doing but the request pattern doesn't carry enough signals. Example: "force: just make it green" -- skips the gate, you own the consequences.

## Integration with GSD

The gate sits upstream of everything:

```
User request -> PRE-EXECUTION GATE -> Plan phase -> Task anatomy -> Boundaries -> Execute
                    ^                                                               |
                    |__ Catches requests that would skip planning entirely __________|
```

When redirecting to planning:
1. Acknowledge the user's intent
2. Identify what's missing (files? scope? success criteria?)
3. Ask targeted questions or propose a plan-phase entry
4. Don't just refuse -- help them get to concrete

## Integration Prompt

When processing execution requests outside a structured plan:

```
Before executing, check if the request is concrete enough. Look for file paths,
function names, issue numbers, error references, or numbered steps. If fewer than
2 concrete signals are present, redirect to planning first. Don't execute vague
requests -- help the user specify what they actually need.
```
