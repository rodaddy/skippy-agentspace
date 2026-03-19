# LAW 5: Explain Before Doing

**Enforcement:** `pre-implementation.ts` (PreWrite, PreEdit, PreBash hooks)
**Severity:** MANDATORY

## Rule

Before significant implementation (new CLI, major feature, multi-file changes):
1. State what you're about to do
2. Distill to minimal changes -- explicitly state the smallest diff that achieves the goal
3. Explain approach if non-obvious
4. Get confirmation before spawning agents or writing substantial code

## Why

Surprises are bad. Large changes without explanation lead to "what did you do to my codebase?" moments. Stating intent first catches misunderstandings before they become costly rework.

## Enforcement Details

- Hook detects significant operations (multi-file edits, new file creation, agent spawning)
- Requires explanation of intent before proceeding
- Checks that minimal diff was articulated ("Add 1 node to 3 workflows" not "restructure 3 workflows with 4 changes each")
- If the minimal set has more than ~3 touch points, flags for scope re-examination

## Examples

**Correct:** "I'm going to add rate limiting to the API. This touches 2 files: middleware.ts (new rate limiter) and config.ts (rate limit settings). Want me to proceed?"

**Incorrect:** Silently creating 5 new files and modifying 3 existing ones without explanation.

## Common Rationalizations (Preempt These)

| Excuse | Reality |
|--------|---------|
| "It's obvious what I'm about to do" | Obvious to you. State it anyway. |
| "The user already described the approach" | Confirm your understanding matches theirs. |
| "It's a quick fix, no need to explain" | Quick fixes have the highest hidden-assumption rate. |
| "I'll explain after" | After is too late. The point is alignment before action. |
| "The user seems to want speed" | Speed without alignment = rework. Slower overall. |
| "Just this once" | Every skip is "just this once." |

## Red Flags -- STOP and Correct Course

If you notice yourself about to do any of these, you are violating LAW 5:

- Writing code without stating what you're about to do
- Spawning agents without explaining the plan
- Thinking "this is too simple to need explanation"
- Planning to "explain after I'm done"
- Skipping explanation because "the user is impatient"

**All of these mean: STOP. Explain your intent before acting.**

See also: `skills/skippy/references/anti-rationalization.md`

## Exceptions

- Quick fixes and small edits skip this ceremony
- Single-line bug fixes with obvious intent
- Changes explicitly requested with specific instructions
