# Story Writing Rules

Rules for writing PRD stories. Every story in a PRD must follow these rules -- no exceptions.

## Rule 1: Every Story Has Verify Commands (Non-Negotiable)

The verify commands ARE the definition of done. If you can't write a command that proves the story works, the story is too vague.

`expect_pattern` is REQUIRED (not optional). `expect_not_pattern` is recommended for catching hidden failures.

| BAD | GOOD |
|-----|------|
| `"criteria": ["It works"]` | `"command": "curl -sf localhost:3000/health \| jq -e '.status == \"ok\"'"` |
| `"criteria": ["Tests pass"]` | `"command": "uv run pytest tests/test_auth.py -x -q"`, `"expect_pattern": "\\d+ passed"`, `"expect_not_pattern": "failed\|error"` |
| `"criteria": ["File exists"]` | `"command": "test -f .reports/output.md && wc -l < .reports/output.md"`, `"expect_pattern": "^[1-9]"` |

## Rule 2: Acceptance Criteria Limits

- Feature stories: max 7 criteria
- All stories: max 7 criteria, no exceptions. If you need more, split the story.
- If you need more, split the story

Each criterion MUST map to at least one verify command. Verify command count should approximate criteria count.

## Rule 3: No Compound Titles

If the title contains "and", split the story.

## Rule 4: Setup and Teardown Are Explicit Stories

Test environments, sandbox creation, cleanup -- all tracked as stories with verify commands.

## Rule 5: Three Mandatory Story Types

Every PRD MUST include these (skip only in Quick tier if genuinely N/A):

**a) Regression story** -- existing tests + type check still pass:
```json
{
  "title": "Verify no regressions in existing functionality",
  "verify": {
    "commands": [
      { "name": "existing tests pass", "command": "<test_runner> -x -q", "expect_pattern": "passed", "expect_not_pattern": "failed|error" },
      { "name": "type check clean", "command": "<type_checker>", "expect_pattern": "Success|no issues" }
    ]
  }
}
```
If `type_checker` is null, omit the type check command. If no tests exist yet, verify the runner exits 0 with `expect_not_pattern: "error"`.

**b) E2E story** -- real-world end-to-end test that proves the feature actually works in practice, not just in unit tests:
```json
{
  "title": "End-to-end validation with real data",
  "verify": {
    "commands": [
      { "name": "e2e test passes", "command": "<actual usage command with real or realistic data>", "expect_pattern": "<expected real output>" }
    ]
  }
}
```

**c) Idempotency story** (when applicable) -- re-running is safe:
```json
{
  "title": "Re-run produces no changes (idempotent)",
  "verify": {
    "commands": [
      { "name": "second run is clean", "command": "<same command again>", "expect_pattern": "<already done|no changes|skipped>" }
    ]
  }
}
```

## Rule 6: Dependencies Are Explicit

`"depends_on": ["US-001"]`. Agents MUST NOT start stories whose dependencies aren't `passed`. No circular dependencies allowed.

## Rule 7: Verify Commands Must Be Deterministic

- No network calls to external services (mock or use local)
- No timing-dependent checks
- No side effects (verify = read-only observation)
- All commands run from `stack.working_directory`
- If a command needs a running service, a setup story MUST start it

## Rule 8: Manual Checks Are The Exception

- Max 1 manual check per story
- Automated verify commands MUST outnumber manual checks
- During `--close`, manual checks prompt the user for confirmation
- In autonomous mode, manual checks cause the story to be `blocked`

## Rule 9: Integration Stories Are Explicit

When stories produce modules that MUST be wired together (e.g., a scoring function
that handlers must call), create an explicit integration story:

```json
{
  "id": "US-008",
  "title": "Wire scoring into payment and status handlers",
  "description": "As a system, I want score recalculation triggered by state changes so that work queue priorities stay current.",
  "depends_on": ["US-006", "US-004"],
  "acceptance_criteria": [
    "recalculateScore called after payment creation",
    "recalculateScore called after status update",
    "recalculateScore called after communication log entry"
  ],
  "verify": {
    "commands": [
      { "name": "wiring exists", "command": "grep -r 'recalculateScore' src/server/handlers/", "expect_pattern": "payments|accounts|communication" }
    ]
  }
}
```

This prevents the "parallel build gap" where each agent builds their piece
correctly but nobody wires the cross-cutting concerns.
