# Update Formats Reference

Templates for each type of todo update action.

## Progress Update (item stays in place)

Append to the file (multiple updates accumulate -- don't replace previous ones):

```markdown
## Progress Update (<date>)

- <What was done>
- <Current blockers or next steps>
- <Revised scope if changed>
```

## Completion

Append structured notes BEFORE moving the file:

```markdown
## Completion Notes (<date>)

### What we did
<Numbered list of actual steps taken, in order>

### What worked
<Bullet points -- approaches, tools, patterns that succeeded>

### What didn't work / was misleading
<Bullet points -- things that looked right but weren't, false positives, wasted effort>

### Gotchas for future reference
<Numbered list -- specific, actionable lessons learned. Include commands, paths, config values.>

### Final state
<Brief description of end result -- what's running, what changed, where things live>
```

## Deferral

```markdown
## Deferred (<date>)

### Reason
<Why it's being deferred>

### Progress so far
<What was done, if anything>

### Resume notes
<What to pick up on when revisiting -- include context that would be lost>
```

## Drop

```markdown
## Dropped (<date>)

### Reason
<Why -- no longer relevant, solved differently, superseded by X, etc.>
```

## Quality Guidelines

- **Completion notes are mandatory.** Even if the task seems trivial, document what happened.
- **Capture misleading tests.** If a test passed but the real thing failed, explain why. These are the most valuable gotchas.
- **Be specific.** "Check permissions" is useless. "Verify process GID with `/proc/<pid>/status`, not `id <user>` -- systemd `Group=` overrides passwd" is useful.
