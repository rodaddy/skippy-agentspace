# Progress Log Template

Write this to `.prd/progress.md` during PRD creation and update it throughout execution.

```markdown
# PRD Progress: <project name>

## Status
- Created: <date>
- Tier: <quick|standard|full>
- Stories: N total, N passed, N failed, N pending
- Cycle: <current> / <max>

## Gaps (identified during creation)
- <gap 1>
- <gap 2>

## Critic Findings
### Gap Hunter
- <finding and resolution>

### Verification Auditor
- <finding and resolution>

## Disagreements (findings rejected with reasoning)
- <finding>: <why rejected>

## Execution Log
- <date> US-001: passed (cycle 1)
- <date> US-002: failed, retry 1 (cycle 2)
- <date> US-002: passed (cycle 3)

## Amendments
- <date>: <what changed and why>

## Out of Scope
- <explicitly excluded work>
```
