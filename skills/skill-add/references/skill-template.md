<!-- Extracted from SKILL.md -- load on demand -->

# SKILL.md Template

Use this template when generating new skill files, filling in values from user input.

**Keep SKILL.md under ~150 lines.** Move detailed tables, templates, and examples to `references/`.

````markdown
---
name: <skill-name>
description: <One-line description>. USE WHEN <when to invoke>.
triggers:
  - /<skill-name>
  - <natural language trigger>
user-invocable: true
---

# <Skill Title>

<One-line description of what this skill does and when to use it.>

## Quick Reference

<3-5 line summary of the most critical facts -- IPs, paths, key commands. The stuff you'd write on a sticky note.>

## Workflow

### Step 1: <First action>

<Instructions for Claude to follow>

### Step 2: <Next action>

<Instructions for Claude to follow>

## Common Operations

<Most frequent commands/tasks, grouped logically>

## Gotchas

<Known issues and their solutions. Append to this section as issues are discovered.>

## References

- `references/<file>.md` -- <description>

## Notes

- <Important operational notes>
````

## Architecture Rules

1. **SKILL.md** (~80-150 lines): Triggers, quick reference, workflow steps, gotchas summary, references links
2. **references/** (unlimited): Detailed tables, architecture docs, command references, troubleshooting, examples
3. Reference docs start with `<!-- Extracted from SKILL.md -- load on demand -->`
4. Reference docs are loaded by spawning a haiku explore agent when needed -- keeps main context slim
5. Gotchas section in SKILL.md stays brief -- detailed troubleshooting goes in `references/troubleshooting.md`
