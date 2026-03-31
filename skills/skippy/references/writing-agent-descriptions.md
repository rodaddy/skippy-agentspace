# Writing Agent Descriptions

The `description` field in a custom agent definition is the single most important field. It controls when the main agent delegates to your agent. Get it wrong and the agent either fires on everything or never fires at all.

## The Pattern

A good description has four parts:

1. **Starts with a verb** -- what the agent does (Reviews, Analyzes, Implements, Investigates)
2. **Names the technology or domain** -- scope it to a specific area
3. **Lists specific capabilities** -- what exactly it checks/does (3-5 items)
4. **Sets a boundary** -- when to use it, implying when NOT to

```
{verb} {domain} for {scope}. {capabilities list}. Use when {trigger condition}.
```

## Good vs Bad -- Real Examples

These are from our 11 agent definitions in `skills/skippy/agents/`.

### Architecture Reviewer (good)

> Strategic architecture advisor. Analyzes code, diagnoses bugs, provides actionable architectural guidance with file:line evidence. Read-only. Used by /skippy:review and /drive (architect verification).

**Why it works:** Names role (architecture advisor), lists what it does (analyze, diagnose, provide guidance), specifies output format (file:line evidence), declares constraint (read-only), names trigger commands.

### Executor (good)

> Focused task executor. Implements code changes precisely as specified with minimal diff and fresh verification. General-purpose implementation agent.

**Why it works:** "Focused" and "precisely as specified" set expectations -- this agent follows instructions, it doesn't make decisions. "Minimal diff" signals discipline. "General-purpose" tells the main agent this is the default for implementation work.

### Security Reviewer (good)

> Security vulnerability detection specialist. OWASP Top 10 analysis, secrets detection, dependency audits, shell injection scanning. Read-only. Prioritizes by severity x exploitability x blast radius.

**Why it works:** Names the framework (OWASP Top 10), lists 4 specific capabilities, declares read-only, explains prioritization logic. The main agent knows exactly when to delegate security work here.

### What a Bad Description Looks Like

> Reviews code.

**Why it fails:** Matches everything. The main agent can't distinguish between architecture review, security review, code quality review, or consistency review. All four of our review agents would match this description equally.

> Handles deployment tasks.

**Why it fails:** No boundary. Does it deploy to staging? Production? Does it create the infrastructure or just push code? An agent with this description will get invoked for routine development tasks that mention "deploy" in passing.

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Too broad ("helps with code") | Matches everything, delegates wrong tasks | Name specific technology and capabilities |
| Too narrow ("fixes bug #423") | Never matches again | Generalize to the class of work |
| No verb ("code quality tool") | Unclear what it does | Start with action verb |
| No boundary | Gets invoked for tangentially related work | Add "Use when..." clause |
| Lists tools instead of capabilities | "Uses Read, Grep, Glob" tells you nothing about what for | Describe outcomes, not mechanisms |

## Testing Your Descriptions

After creating or editing an agent definition, mentally test against these scenarios:

1. **Should-match tasks** -- Give Claude Code 3 tasks this agent should handle. Does the description clearly cover them?
2. **Should-NOT-match tasks** -- Give Claude Code 3 tasks that are adjacent but wrong. Does the description exclude them?
3. **Ambiguous tasks** -- Give Claude Code a vague task. Does the description help the main agent decide, or does it create confusion?

If your agent gets invoked for the wrong tasks, tighten the description. If it never gets invoked, broaden it. Description tuning is iterative.

## Complexity vs Model

Our agents use `complexity: HIGH/MEDIUM/LOW` instead of hardcoding a `model:` field. This keeps descriptions portable -- the orchestrator maps complexity to models at spawn time.

| Complexity | Typical Use | Model Mapping |
|---|---|---|
| HIGH | Deep reasoning, adversarial review, security analysis | opus |
| MEDIUM | Standard implementation, code review, research | sonnet |
| LOW | Fast scanning, simple lookups | haiku |

The description should match the complexity. A HIGH-complexity agent with a vague one-liner description is wasting an expensive model on poorly-scoped work.

## Placement

| Location | Scope | Override |
|---|---|---|
| `.claude/agents/` (project) | This project only | Takes precedence over global |
| `~/.claude/agents/` (global) | All projects | Overridden by project-specific |
| `skills/*/agents/` (skill) | Loaded by skill orchestrators | Referenced explicitly in skill prompts |

Project-specific agents override global ones when names conflict. Our skill agents live in `skills/skippy/agents/` and are referenced explicitly by `/skippy:review` and `/skippy:plan`.
