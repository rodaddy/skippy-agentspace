# Anti-Rationalization Patterns

**Source:** superpowers (obra/superpowers) -- test-driven-development/SKILL.md, brainstorming/SKILL.md
**Cherry-picked:** 2026-03-17

## Concept

LLMs (and humans) rationalize skipping discipline. Effective skills preempt these rationalizations by listing them explicitly with rebuttals. This makes the excuse visible before the agent can act on it unconsciously.

## Pattern: Rationalization Table

Present common excuses alongside their rebuttals in a table format. The agent sees its own likely excuse before it forms, short-circuiting the rationalization.

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to need X" | Simple things break. The step takes 30 seconds. |
| "I'll do X after" | After-the-fact X proves nothing. |
| "Already manually verified" | Ad-hoc != systematic. No record, can't re-run. |
| "Just this once" | Every skip is "just this once." |
| "This is different because..." | It's not. Follow the process. |
```

## Pattern: Red Flags List

Enumerate thoughts/behaviors that signal the agent is about to violate a rule. Frame them as "if you notice yourself thinking this, STOP."

```markdown
## Red Flags -- STOP and Correct Course

- About to write code before getting approval
- Thinking "this is too simple to need the full process"
- Planning to "add tests later"
- Rationalizing "just this once"
- Saying "This is different because..."
- Skipping a step because "the user seems impatient"

**All of these mean: STOP. Follow the process.**
```

## PAI Application

Apply to LAW 4 (Critical Thinking) and LAW 5 (Explain Before Doing). These are the LAWs most frequently violated because the agent rationalizes skipping them.

### LAW 4 -- Common Rationalizations to Preempt

| Excuse | Reality |
|--------|---------|
| "The user's approach is fine" | Maybe, but you haven't checked. Challenge first. |
| "Pushing back will slow things down" | Not pushing back leads to rework. Slower overall. |
| "It's a small change, no need to analyze" | Small changes with unexamined assumptions cause the most bugs. |
| "The user knows what they want" | They know the goal. You should challenge the approach. |
| "I already raised a concern earlier" | Raise it again if it's still relevant. |

### LAW 5 -- Common Rationalizations to Preempt

| Excuse | Reality |
|--------|---------|
| "It's obvious what I'm about to do" | Obvious to you. State it anyway. |
| "The user already described the approach" | Confirm your understanding matches theirs. |
| "It's a quick fix, no need to explain" | Quick fixes have the highest hidden-assumption rate. |
| "I'll explain after" | After is too late. The point is alignment before action. |
| "The user seems to want speed" | Speed without alignment = rework. Slower overall. |
