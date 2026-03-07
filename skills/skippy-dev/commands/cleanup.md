---
name: skippy:cleanup
description: Clean up ephemeral files (debug logs, telemetry, session history) with quarantine or nuke mode
---
<objective>
Manage ephemeral file bloat from debug logs, telemetry, and session history.

Two modes: `--quarantine` (default, moves to ThunderBolt _tmp) or `--nuke` (permanent delete).
</objective>

<execution_context>
@/Users/rico/.config/pai/Skills/skippy-dev/SKILL.md
</execution_context>

<process>
Ask the user which mode unless they specified:
- `--quarantine` (default): Moves files to `/Volumes/ThunderBolt/_tmp/skippy-cleanup/` for later review
- `--nuke`: Deletes permanently

Then run:

```bash
~/.config/pai/Skills/skippy-dev/bin/skippy-cleanup.sh [--quarantine|--nuke]
```

Report the space freed and what was cleaned.
</process>
