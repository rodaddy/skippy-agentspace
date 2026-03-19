# Two-Stage Review Ordering

**Source:** superpowers (obra/superpowers) -- subagent-driven-development/SKILL.md
**Cherry-picked:** 2026-03-17

## Concept

Code review is split into two distinct, ordered stages:

1. **Spec compliance review** -- "Did you build what was asked?"
2. **Code quality review** -- "Did you build it well?"

The ordering is enforced: code quality review CANNOT start until spec compliance passes. This prevents wasting review cycles polishing code that doesn't meet the spec.

## Why Order Matters

| Order | What Happens |
|-------|-------------|
| Spec first, quality second | Catch "built the wrong thing" early. Only polish code that's correct. |
| Quality first, spec second | Waste cycles refactoring code that gets rewritten when spec gaps are found. |
| Combined | Reviewers conflate "it's well-written" with "it's correct." Clean code that does the wrong thing passes review. |

## The Pattern

```
Implementer completes task
    → Dispatch spec compliance reviewer
        → "Does the implementation match every requirement in the spec?"
        → "Is anything missing? Is anything extra (not requested)?"
    → IF spec issues found:
        → Implementer fixes
        → Re-dispatch spec reviewer
        → Repeat until approved
    → THEN dispatch code quality reviewer
        → "Is the code well-structured, tested, maintainable?"
        → "Any bugs, edge cases, performance issues?"
    → IF quality issues found:
        → Implementer fixes
        → Re-dispatch quality reviewer
        → Repeat until approved
    → Mark complete
```

## Spec Reviewer Focus

- Every requirement in the spec is implemented
- Nothing extra was added (YAGNI)
- Edge cases mentioned in the spec are handled
- The behavior matches what was described, not just the letter

## Code Quality Reviewer Focus

- Code structure and readability
- Test coverage and test quality
- Error handling and edge cases
- Performance considerations
- Consistency with codebase patterns

## PAI Application

Apply to `/skippy:review` swarm. Currently the review swarm runs multiple specialist agents (security, architecture, code quality) but doesn't enforce spec-compliance-first ordering.

Proposed change: add a spec compliance pass before the specialist swarm runs. If the implementation doesn't match the plan/requirements, no point running security or architecture review on code that will change.

```
Current:  implement → [security + arch + quality] in parallel → fix
Proposed: implement → spec compliance → fix if needed → [security + arch + quality] in parallel → fix
```
