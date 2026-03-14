---
name: skippy:cleanup
description: Clean up ephemeral files (debug logs, telemetry, session history) with quarantine or nuke mode
---
<objective>
Manage ephemeral file bloat from debug logs, telemetry, and session history.

Two modes: `--quarantine` (default, moves to quarantine directory) or `--nuke` (permanent delete).
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>
Ask the user which mode unless they specified:
- `--quarantine` (default): Moves files to a configurable quarantine directory for later review
- `--nuke`: Deletes permanently

Then run:

```bash
${CLAUDE_SKILL_DIR}/scripts/skippy-cleanup.sh [--quarantine|--nuke]
```

Report the space freed and what was cleaned.
</process>
