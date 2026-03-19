# Subagent Model Selection Guidance

**Source:** superpowers (obra/superpowers) -- subagent-driven-development/SKILL.md
**Cherry-picked:** 2026-03-17

## Concept

Use the least powerful model that can handle each agent role. This conserves cost and increases speed without sacrificing quality where it matters.

## Three-Tier Model Selection

| Tier | When to Use | PAI Mapping |
|------|------------|-------------|
| **Cheap/fast** | Mechanical tasks: isolated functions, clear specs, 1-2 files, well-defined input/output | Sonnet |
| **Standard** | Integration tasks: multi-file coordination, pattern matching, moderate judgment | Sonnet (complex) or Opus |
| **Most capable** | Architecture, design, review, debugging, broad codebase understanding | Opus |

## Complexity Signals

| Signal | Tier |
|--------|------|
| Touches 1-2 files with a complete spec | Cheap |
| Clear input/output, no ambiguity | Cheap |
| Touches multiple files with integration concerns | Standard |
| Requires understanding existing patterns | Standard |
| Requires design judgment | Most capable |
| Broad codebase understanding needed | Most capable |
| Debugging with unclear root cause | Most capable |
| Review/adversarial analysis | Most capable |

## PAI-Specific Rules

1. **Never Haiku** -- user banned Haiku on 2026-02-19. Minimum is Sonnet.
2. **Default to Sonnet** for implementation agents with clear specs
3. **Use Opus** for review, planning, architecture, and debugging agents
4. **Agent type determines tier, not task size** -- a large but mechanical task (e.g., "rename X across 20 files") still uses Sonnet

## Application to SAS Agent Dispatch

When `/skippy:execute` dispatches implementation agents:
- Read the task description
- Check complexity signals
- Select model accordingly
- Document the selection in the dispatch log

```markdown
## Model Selection for Wave 1

| Task | Complexity | Model | Rationale |
|------|-----------|-------|-----------|
| Add validation to input handler | 1 file, clear spec | Sonnet | Mechanical |
| Integrate auth with 3 services | Multi-file, patterns | Opus | Integration judgment |
| Write migration script | 1 file, clear spec | Sonnet | Mechanical |
```

## Cross-Model Review (Gemini via LiteLLM)

Claude Code's Agent tool only supports Claude models. For Gemini, call LiteLLM directly via `scripts/cross-model-review.sh`.

| Model | Role | When to Use |
|-------|------|-------------|
| **gemini-3.1-pro** | Adversarial reviewer, research second opinion | Code review, QA, research diversity. Different blind spots than Claude. |
| **gemini-3-flash** | Cheap bulk ops | Summarization, text processing, mechanical tasks where Sonnet is overkill. |

**Why cross-model matters:** Claude reviewing Claude catches logic/syntax issues but misses things Claude is systematically wrong about. Gemini has different training data, different reasoning patterns, different failure modes. Using both model families for review gives broader coverage.

**Default antagonist: `gemini-3.1-pro`** -- use for all adversarial review passes. Do NOT use gemini-3-pro (3.1 is strictly better).

## Escalation

If a cheaper model fails a task (BLOCKED status), escalate to a more capable model. Never retry the same model without changes. The failure signal means the task needs more reasoning capability.
