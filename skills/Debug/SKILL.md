---
name: Debug
description: Structured debugging workflows and problem analysis. USE WHEN debug issue, troubleshoot problem, fix bug, investigate error, analyze failure, trace problem, or need systematic debugging approach for code issues and system failures.
---

# Debug - Systematic Problem Solving

Structured debugging workflows for investigating and resolving code issues efficiently.

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **InvestigateError** | "debug this", "investigate error", "why is this failing" | `Workflows/InvestigateError.md` |
| **TraceExecution** | "trace execution", "step through", "execution flow" | `Workflows/TraceExecution.md` |
| **AnalyzeFailure** | "analyze failure", "what went wrong", "root cause" | `Workflows/AnalyzeFailure.md` |
| **CompareWorking** | "compare working version", "what changed" | `Workflows/CompareWorking.md` |

## Examples

**Example 1: Investigate error**
```
User: "Debug this TypeError in my API"
→ Invokes InvestigateError workflow
→ Analyzes error message and stack trace
→ Identifies likely causes
→ Suggests fixes with explanations
```

**Example 2: Trace execution**
```
User: "Why isn't this function being called?"
→ Invokes TraceExecution workflow
→ Traces code path and execution flow
→ Identifies where flow breaks
→ Explains the issue
```

**Example 3: Root cause analysis**
```
User: "My build fails intermittently"
→ Invokes AnalyzeFailure workflow
→ Gathers failure patterns
→ Identifies environmental factors
→ Provides systematic solution
```

---

## Debugging Methodology

**1. Reproduce**
- Consistent reproduction steps
- Minimal test case
- Environment details

**2. Isolate**
- Narrow down scope
- Identify components involved
- Remove variables

**3. Analyze**
- Error messages
- Stack traces
- Logs
- State at failure

**4. Hypothesize**
- Likely causes
- Test theories
- Eliminate possibilities

**5. Fix**
- Implement solution
- Verify fix
- Prevent regression

**6. Document**
- What failed
- Why it failed
- How it was fixed
- Prevention strategy
