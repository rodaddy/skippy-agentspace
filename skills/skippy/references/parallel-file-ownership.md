# Parallel File Ownership -- Safe Concurrent Execution

Adapted from OMC's task-decomposer. Assigns non-overlapping file ownership when splitting work across parallel agents. Prevents the classic parallel execution bug where two agents edit the same file simultaneously. Complements model routing (which tier for which task) -- this handles HOW to split work safely.

## When to Apply

- When spawning 2+ executor agents to work in parallel
- During GSD plan-phase when breaking work into parallelizable waves
- Before any concurrent execution where multiple agents touch the codebase
- When a single task naturally decomposes into independent components

## Ownership Rules

### Rule 1: One Owner Per File

Every file being modified is owned by exactly one agent. No exceptions, no "both agents can edit it carefully."

### Rule 2: Ownership by Directory

Prefer assigning ownership by directory subtree rather than individual files. Easier to reason about, fewer boundary disputes.

```
Agent A owns: src/auth/**
Agent B owns: src/api/**
Agent C owns: tests/**
```

### Rule 3: Shared Files Get a Single Owner

Files that multiple agents need (package.json, tsconfig, shared types) are assigned to ONE agent. Other agents document what they need changed and the owner applies it.

## Shared File Detection

These files are common conflict points. Flag them during task decomposition:

| File Pattern | Why It's Shared | Resolution |
|-------------|----------------|------------|
| `package.json` | Dependencies, scripts | One agent owns; others list deps needed |
| `tsconfig.json` / `jsconfig.json` | Compiler config | One agent owns; rarely needs parallel changes |
| `*.config.js/ts` (vite, eslint, etc.) | Build/lint config | One agent owns |
| `src/index.ts` / `src/main.ts` | App entry point, exports | One agent owns; others avoid touching |
| `src/types/*.ts` / `*.d.ts` | Shared type definitions | One agent owns types; others import |
| `.env` / `.env.example` | Environment variables | One agent owns; others document needed vars |
| `CLAUDE.md` / `README.md` | Project docs | Not modified during feature execution |
| `migrations/**` | Database schema | Sequential only -- never parallel |

## Task Decomposition by Type

### Fullstack Feature

```
Agent A (Frontend):  src/components/**, src/pages/**, src/hooks/**
Agent B (Backend):   src/api/**, src/services/**, src/middleware/**
Agent C (Data):      src/models/**, src/database/**, migrations/**
Shared owner (A):    src/types/**, package.json
```

### Refactoring

```
Split by module boundary:
Agent A: src/auth/**     (all auth-related files)
Agent B: src/billing/**  (all billing-related files)
Agent C: src/users/**    (all user-related files)
Shared owner (A): src/types/**, src/utils/** (shared utilities)
```

### Bug Fix (Multiple Independent Bugs)

```
Agent A: Bug #1 files (identified from error trace)
Agent B: Bug #2 files (identified from error trace)
Shared owner: Whoever finishes first handles shared files
```

### Test Writing

```
Agent A: tests/unit/**      (unit tests, mirrors src/ structure)
Agent B: tests/integration/** (integration tests)
Agent C: tests/e2e/**        (end-to-end tests)
Shared owner (A): test fixtures, test utilities
```

## Dependency-Ordered Execution

When tasks have dependencies, execute in batches:

```
Batch 1 (parallel): Tasks with no dependencies
    |
    v  (wait for all to complete)
Batch 2 (parallel): Tasks that depended on Batch 1
    |
    v  (wait for all to complete)
Batch 3 (parallel): Tasks that depended on Batch 2
```

### Identifying Dependencies

A task B depends on task A if:
- B imports a module that A is creating or modifying
- B tests functionality that A is implementing
- B extends a type or interface that A is defining
- B configures something that A installs (e.g., A adds a dep, B configures it)

## Conflict Detection Checklist

Before starting parallel execution, verify:

1. **No file overlap:** List all files each agent will touch. Any file in 2+ lists = conflict.
2. **No import overlap:** If Agent A creates `src/utils/auth.ts` and Agent B imports it, B depends on A.
3. **No shared state:** If both agents run tests, will they share a test database? A temp directory?
4. **No build conflicts:** Will both agents modify things that change the build output in conflicting ways?

If any check fails, either:
- Reassign the conflicting file to one owner
- Sequence the conflicting tasks (move one to a later batch)
- Merge the two tasks into one agent's scope

## Integration Prompt

When decomposing work for parallel agents:

```
Split the work so each agent owns a non-overlapping set of files. Assign ownership
by directory subtree when possible. Flag shared files (package.json, tsconfig,
shared types, entry points) and assign each to a single owner. If two agents need
the same file, either sequence them or merge the tasks. List file ownership
explicitly before spawning agents.
```
