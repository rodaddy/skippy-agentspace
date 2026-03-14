# Skill Extraction -- Best-of-Breed Synthesis

Capture reusable knowledge from debugging sessions with quality gates that filter noise from signal. Synthesized from OMC's learner methodology.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| OMC (learner) | Skill extraction from conversations with quality gates: non-Googleable, context-specific, actionable, hard-won; principles over code snippets; tiered storage (user vs project level) | Rigorous filtering prevents knowledge bloat, focuses on decision heuristics over copy-paste solutions | Requires OMC runtime and file paths (.omc/skills/), assumes structured skill format with YAML frontmatter |
| PAI | `/correct` command -- add corrections to CLAUDE.md Gotchas sections when mistakes recur | Integrated into project docs, version-controlled, loaded automatically | Flat list, no quality gate, corrections accumulate without structure, no graduation path to reusable skills |

## Why This Version

OMC's learner has the right METHODOLOGY -- quality gates that prevent knowledge hoarding, and the insight that principles beat code snippets. PAI's correction system has the right MECHANISM -- git-tracked, loaded automatically, embedded in project context. This synthesis applies OMC's quality filters and principle-first thinking to PAI's existing correction workflow, and adds a graduation path from correction to skill.

## The Pattern

### The Quality Gate (Apply Before Saving Anything)

Every candidate piece of knowledge must pass ALL FOUR gates:

| Gate | Question | Fail = Don't Save |
|------|----------|-------------------|
| **Non-Googleable** | Could someone find this in 5 minutes of searching? | Standard patterns, library usage, common error fixes |
| **Context-Specific** | Does this reference actual files, errors, or patterns from THIS codebase? | Generic programming advice, universal best practices |
| **Actionable** | Does it tell you exactly WHAT to do and WHERE? | Vague guidance like "handle edge cases" or "add error handling" |
| **Hard-Won** | Did discovering this take significant debugging effort? | Trivial fixes, obvious solutions, things that worked on first try |

If a candidate fails ANY gate, don't save it. The cost of a bloated knowledge base (context pollution, false matches) exceeds the cost of re-discovering a simple solution.

### What to Capture: Principles, Not Snippets

The difference between noise and signal:

- **Noise (don't save):** "When you see ConnectionResetError, add this try/except block"
- **Signal (save this):** "In async network code, any I/O operation can fail independently due to client/server lifecycle mismatches. Wrap each I/O operation separately because failure between operations is the common case."

A good skill changes how you APPROACH problems, not just what code you produce. Capture the DECISION HEURISTIC -- the thinking that led to the solution -- not the solution itself.

### Recognition Triggers

Save knowledge ONLY after:
- Solving a bug that required deep investigation (not obvious from the error message)
- Discovering a non-obvious workaround specific to this codebase
- Finding a hidden gotcha that wastes time when forgotten
- Uncovering undocumented behavior that affects the project

### The Graduation Path

Knowledge matures through three stages:

```
1. CORRECTION (immediate)
   When: Just hit the issue, know the fix
   Where: CLAUDE.md Gotchas section via /correct
   Format: One-liner with file path and fix

2. PATTERN (after 2-3 occurrences)
   When: Same class of issue keeps appearing
   Where: Project reference doc or skill reference
   Format: Principle + recognition pattern + approach

3. SKILL (proven reusable)
   When: Pattern applies across projects, not just this one
   Where: Portable skill in skills/ directory
   Format: Full skill with insight, recognition, approach, examples
```

Most knowledge stays at stage 1. That's correct -- only genuinely reusable patterns should graduate.

### Anti-Patterns (Do NOT Extract)

- Generic programming patterns (use documentation)
- Refactoring techniques (universally known)
- Library usage examples (use library docs)
- Type definitions or boilerplate
- Anything a developer could find in 5 minutes of searching

## Integration Points

- **PAI `/correct` command:** Stage 1 entry point. Corrections are the raw material for skill extraction.
- **Project CLAUDE.md:** Where corrections land initially. Periodic review identifies patterns worth graduating.
- **Skills directory:** Stage 3 destination for proven, portable knowledge.
- **Session wrap:** Natural checkpoint to evaluate whether the session produced any extractable knowledge.

## When to Apply

- After solving a non-trivial debugging session
- During session wrap when reviewing what was accomplished
- When the same type of correction appears for the third time (graduation trigger)
- During periodic CLAUDE.md review to identify accumulated patterns
- NOT proactively during normal development -- extraction is reactive to discoveries

---
*Sources: OMC `skills/learner/SKILL.md` (quality gates, principle-first methodology), PAI `/correct` command (correction workflow)*
*Last reviewed: 2026-03-07*
