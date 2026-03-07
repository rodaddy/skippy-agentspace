# LAW 6: Interview-First

**Enforcement:** Manual -- hook required (Phase 7 gap)
**Severity:** MANDATORY

## Rule

For complex or broad requests, gather requirements through structured questions before planning. Don't jump straight to implementation on vague asks.

## Why

Complex requests have hidden requirements, unstated constraints, and assumptions that only surface through conversation. Building without interviewing produces technically correct but practically wrong solutions.

## Enforcement Details

Currently manually enforced -- no hook exists for this LAW yet.

A future hook would need to:
- Detect broad/complex requests (multi-step, architectural, or open-ended)
- Require at least one round of clarifying questions before implementation planning
- Distinguish between simple asks (no interview needed) and complex ones (interview required)

## Examples

**Correct:**
- User says "Build me a dashboard" -> Ask about: target users, key metrics, data sources, update frequency, access control needs
- User says "Set up CI/CD" -> Ask about: deployment targets, test requirements, branch strategy, secret management

**Incorrect:**
- User says "Build me a dashboard" -> Immediately start scaffolding a React app with random charts

## Exceptions

- Requests with clear, complete specifications already provided
- Follow-up tasks within an established context where requirements are known
