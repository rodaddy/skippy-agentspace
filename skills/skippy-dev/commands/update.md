---
name: skippy:update
description: Check GSD and PAUL repos for upstream changes worth absorbing
---
<objective>
Run the upstream update checker to see if GSD or PAUL have new commits since our last check.

Reports changed files and recent commits -- human decides what to absorb.
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>
Run the update script:

```bash
${CLAUDE_SKILL_DIR}/scripts/skippy-update.sh
```

Review the output. If changes are detected, read the relevant files from `/tmp/skippy-upstream/` to evaluate whether they're worth absorbing into skippy-dev references.

No auto-merge -- present findings and let the user decide.
</process>
