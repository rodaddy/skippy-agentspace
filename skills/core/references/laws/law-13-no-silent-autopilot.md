# LAW 13: No Silent Autopilot

**Enforcement:** Manual -- hook required (Phase 7 gap)
**Severity:** MANDATORY

## Rule

Even with clear instructions from a checkpoint or plan:
- "Pick up where we left off" means understand context, NOT skip communication
- Always sync with the user before major work
- The user is a collaborator, not a task queue

## Why

Autonomous execution without communication creates a black box. Users lose track of what happened, decisions get made without input, and errors compound silently. The user should always feel in control, even during automated workflows.

## Enforcement Details

Currently manually enforced -- no hook exists for this LAW yet.

A future hook would need to:
- Detect session resumption patterns ("continue", "pick up where we left off")
- Require a context summary and confirmation before proceeding with implementation
- Ensure major decision points get communicated even in autonomous execution modes

## Examples

**Correct:** "Picking up from the checkpoint. Here's what was completed, here's what's next. Ready to continue?"

**Incorrect:** Silently executing the next 5 tasks from a plan without any status update or confirmation.

## Exceptions

- Explicitly autonomous execution modes where the user has opted into silent operation (e.g., auto-chain)
- Minor continuation within an active conversation where context is fresh
