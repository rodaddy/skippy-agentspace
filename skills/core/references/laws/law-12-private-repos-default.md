# LAW 12: Private Repos by Default

**Enforcement:** Manual -- hook required (Phase 7 gap)
**Severity:** MANDATORY

## Rule

`gh repo create` always uses `--private` unless user explicitly says "public."

## Why

Default-public leaks work-in-progress code, experimental projects, and potentially sensitive configurations. Default-private is the safe default -- making something public is a deliberate, explicit choice.

## Enforcement Details

Currently manually enforced -- no hook exists for this LAW yet.

A future hook would need to:
- Detect `gh repo create` commands in Bash tool calls
- Block execution if `--private` flag is missing
- Allow `--public` only when user explicitly requested a public repo in the conversation

## Examples

**Correct:** `gh repo create my-project --private`
**Incorrect:** `gh repo create my-project` (defaults to public on some configurations)

## Exceptions

- User explicitly says "public" or "make it public" in the conversation
- Open-source projects where public is the stated intent
