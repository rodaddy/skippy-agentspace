# HARD-GATE Pattern

**Source:** superpowers (obra/superpowers) -- brainstorming/SKILL.md
**Cherry-picked:** 2026-03-17

## Concept

A `<HARD-GATE>` is an explicit marker in a skill definition that tells the agent it CANNOT proceed past this point without user approval. Unlike prose instructions ("get approval before..."), the tag format is unambiguous and harder for the agent to rationalize away.

## Syntax

```markdown
<HARD-GATE>
Do NOT [specific prohibited actions] until [specific condition is met].
This applies to [scope -- every case, not just complex ones].
</HARD-GATE>
```

## Why It Works

1. **Visual distinctiveness** -- the XML-like tag stands out from surrounding prose, making it harder to skim past
2. **Explicit prohibition** -- states what is NOT allowed, not just what should happen
3. **Scope enforcement** -- explicitly closes the "this case is simple enough to skip" loophole
4. **Parseable** -- agents can be trained to treat these as hard constraints, not suggestions

## Examples for PAI Skills

### In brainstorming/planning skills:
```markdown
<HARD-GATE>
Do NOT write code, spawn implementation agents, or take any implementation
action until you have explained your approach and the user has approved it.
This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>
```

### In review skills:
```markdown
<HARD-GATE>
Do NOT start code quality review until spec compliance review has passed.
Spec compliance must be explicitly approved before quality review begins.
</HARD-GATE>
```

### In deployment skills:
```markdown
<HARD-GATE>
Do NOT push to remote or create a PR until all tests pass and the user
has reviewed the diff. No exceptions for "obvious" changes.
</HARD-GATE>
```

## PAI Application

Add `<HARD-GATE>` tags to skills where LAW 5 (Explain Before Doing) and LAW 13 (No Silent Autopilot) are most frequently violated:

- `/skippy:execute` -- gate before spawning implementation agents
- `/skippy:plan` -- gate before finalizing plan without user review
- `/deploy-service` -- gate before creating infrastructure
- Any skill that transitions from planning to implementation
