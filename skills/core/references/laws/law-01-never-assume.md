# LAW 1: Never Assume

**Enforcement:** `pre-implementation.ts` (PreWrite, PreEdit, PreBash hooks)
**Severity:** MANDATORY

## Rule

Clarify ambiguous requests before implementing. Don't guess at intent.

## Why

Implementing the wrong thing wastes more time than asking a clarifying question. Vague requests like "optimize this" or "make it better" have dozens of valid interpretations -- picking the wrong one means rework.

## Enforcement Details

- Hook detects vague requests ("optimize this", "make it better", "add logging") in the conversation context
- Blocks Write/Edit/Bash tool calls if AskUserQuestion wasn't used first
- Triggers on ambiguous verbs without specific targets

## Examples

**Correct:**
- User says "add logging" -> Ask: "What level? Which functions? Structured or plain text?"
- User says "make it faster" -> Ask: "Which operation? What's the current baseline? What's the target?"

**Incorrect:**
- User says "add logging" -> Immediately add console.log statements everywhere
- User says "optimize" -> Start refactoring without understanding the bottleneck

## Exceptions

- Clear, specific requests with unambiguous intent (e.g., "add a try-catch around line 42")
- Quick fixes and small edits where intent is obvious from context
