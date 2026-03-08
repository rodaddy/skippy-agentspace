---
name: correct
description: Add a correction to the appropriate doc when Claude repeatedly makes the same mistake. Quick way to capture recurring rules.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
  category: workflow
---

# /correct - Add Correction Rule

Add a correction to the appropriate doc's Gotchas section.

## Usage

```
/correct Don't suggest npm, always use bun
/correct Stop nesting SQL in SSH command strings
/correct Remember to check branch before committing
```

## Workflow

1. **Parse the correction** from user input
2. **Classify by topic** and route to the matching doc file:

| Topic | Doc File |
|-------|----------|
| Shell, TypeScript, Python, quoting, LSP | Code conventions doc |
| Git, secrets, branches, credentials | Git and secrets doc |
| Infrastructure, containers, networking, deploy | Infrastructure doc |
| Agents, parallelism, orchestration | Agent orchestration doc |
| Sessions, checkpoints, output, persistence | Session management doc |

3. **Override if specified:**
   - "for this project" -- Project (`./CLAUDE.md`, create Corrections section if needed)
   - "globally" or "everywhere" -- Global (`~/.claude/CLAUDE.md`)
4. **Read the target doc file**
5. **Append to the Gotchas section** (or create one if missing)
6. **Confirm** what was added and where

## Format

Corrections are added as bullet points in the doc's Gotchas section:
```markdown
- **[Short label]** -- [description of what to do/not do]
```

## Examples

**Input:** `/correct stop nesting SQL in SSH strings`
**Routed to:** Code conventions doc (Shell Gotchas section)
```markdown
- **Complex quoting over SSH** -- don't nest SQL/Python/JSON in SSH command strings. Pipe via stdin instead.
```

**Input:** `/correct always run ggshield before first push`
**Routed to:** Git and secrets doc (Gotchas section)
```markdown
- **Pre-push scan** -- run `ggshield secret scan repo .` before first push of any repo.
```

## Implementation

When invoked:

1. Take the user's input as the correction description
2. Classify the topic (shell/code/git/infra/agents/sessions)
3. If ambiguous, ask the user which doc it belongs in
4. Read the target doc file
5. Find the appropriate Gotchas section (or last section)
6. Append the formatted correction
7. Confirm: "Added to [target file]"

> **PAI enhancements available:** In PAI installations, corrections route to specific Deep Doc files at ~/.claude/docs/.
