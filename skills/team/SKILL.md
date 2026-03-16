---
name: team
description: Spawn N coordinated agents working on a shared task list using Claude Code native team tools. Decompose, distribute, and verify.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
  absorbed_from: oh-my-claudecode/team
---

# team -- Coordinated Agent Execution

Spawn N agents working on a shared task list. Decomposes a high-level task, distributes sub-tasks to agents, coordinates via messaging, and verifies results.

## Requirements

- Claude Code with native team APIs (`TeamCreate`, `SendMessage`, `TaskCreate`)
- These are built-in Claude Code tools -- no MCP or external setup needed
- **Without team APIs:** Fall back to spawning independent agents via the `Agent` tool (loses inter-agent messaging but parallel execution still works)

## Usage

```
/team N "task description"
/team "task description"
```

- **N** -- Number of agents (1-10). Optional; defaults to auto-sizing based on task decomposition.
- **task** -- High-level task to decompose and distribute

## When to Use

- Task decomposes into N independent sub-tasks
- User says "team", "swarm", "parallelize", or wants multi-agent coordination
- Work benefits from concurrent execution with coordination

## When NOT to Use

- Simple parallel dispatch without coordination -- just spawn agents directly
- Sequential task with no parallelism -- delegate to a single agent
- Guaranteed completion with verification -- use `/drive`
- Full lifecycle -- use `/autopilot`

## Workflow

### Step 1: Decompose

Analyze the task and break it into independent sub-tasks. Each sub-task must have:
- Clear scope (which files/components)
- Non-overlapping file ownership (no two agents touch the same file)
- Testable acceptance criteria

### Step 2: Spawn Team

Use Claude Code's native `TeamCreate` to create the team. Each agent gets:
- A specific sub-task assignment
- File ownership boundaries
- The shared context needed

Route agents by complexity:
| Sub-task Type | Complexity |
|--------------|------------|
| Simple changes (config, types) | LOW |
| Standard implementation | MEDIUM |
| Complex refactoring, debugging | HIGH |

### Step 3: Coordinate

Use `SendMessage` for inter-agent coordination:
- Share discoveries that affect other agents
- Resolve conflicts if file ownership overlaps
- Sync on shared interfaces (types, APIs)

### Step 4: Verify

When all agents complete:
1. Build/typecheck the combined result
2. Run test suite
3. Check for integration issues between agent outputs
4. Fix any conflicts

## Parallel File Ownership

**Critical**: No two agents should modify the same file. If overlap is unavoidable:
1. One agent owns the file
2. Other agents send changes via `SendMessage`
3. Owner agent applies all changes

See `skills/skippy/references/parallel-file-ownership.md` for the full protocol.

## Escalation

- If agents deadlock on coordination, escalate to user
- If sub-tasks have unclear dependencies, ask before decomposing
- If N > 10, push back -- coordination overhead exceeds parallelism benefit
