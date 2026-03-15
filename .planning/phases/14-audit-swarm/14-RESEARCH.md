# Phase 14: Audit Swarm - Research

**Researched:** 2026-03-08
**Domain:** Multi-agent orchestration, code review automation, sandboxed execution
**Confidence:** HIGH

## Summary

Phase 14 formalizes the multi-agent audit loop proven during the v1.1 milestone (7 rounds, 20+ agents, 17 findings) into a repeatable `/skippy:review` command. The core mechanism is Claude Code's subagent system -- markdown files with YAML frontmatter that define specialized agents, each spawned via the Task/Agent tool with their own fresh context window, tool restrictions, and system prompts.

The command itself follows the established skippy command pattern (YAML frontmatter + `<objective>` + `<execution_context>` + `<process>` sections in a `.md` file). The orchestration logic lives entirely in the command's markdown instructions -- no shell scripts needed for agent spawning. The command instructs the main Claude instance to act as orchestrator, spawning 4 specialist subagents sequentially (security, code quality, architecture, consistency), aggregating findings into a shared board, then spawning fix agents and an evaluator.

**Critical constraint:** Subagents cannot spawn other subagents (Claude Code limitation). This means the orchestrator (main conversation) must handle all agent spawning -- no hierarchical delegation. The fix/eval cycle must also be orchestrated from the main conversation, not delegated to a meta-agent.

**Primary recommendation:** Implement `/skippy:review` as a command markdown file that orchestrates 4 reviewer subagent definitions (stored under `skills/skippy/agents/`) plus fix and eval agent definitions. The command instructions guide the main conversation through: scope detection, reviewer spawning, findings aggregation, fix agent spawning, and eval cycling. All subagent definitions include `permissionMode: bypassPermissions` and `isolation: worktree` where destructive operations are possible, plus HOME override instructions in system prompts.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SWARM-01 | `/skippy:review` spawns 4 specialist review agents (security, code quality, architecture, consistency) | Claude Code subagent system supports defining agents as markdown files in `skills/skippy/agents/`. The command markdown instructs the orchestrator to spawn each via the Agent tool. Each agent gets its own context window, tool restrictions, and focused system prompt. |
| SWARM-02 | Shared findings board aggregates results with cross-references | A markdown file at a known path (e.g., `.reports/skippy-review/findings.md`) serves as the aggregation point. Each reviewer appends findings. The orchestrator synthesizes after all reviewers complete. Proven pattern from v1.1 audit (`/tmp/skippy-audit-board.md`). |
| SWARM-03 | Fix agents address actionable findings with atomic commits | Fix agents are subagents spawned by the orchestrator after findings are prioritized. Each fix agent receives specific findings and makes atomic commits. Model routing: sonnet for standard fixes, opus for complex ones. |
| SWARM-04 | Re-evaluation loop verifies fixes and finds regressions | An evaluator subagent runs after fix agents complete. Uses the verification-loops.md cycling protocol (max 3 iterations, same-failure detection). If regressions found, spawns targeted fix agents. |
| SWARM-05 | All swarm testing runs in sandboxed HOME with backup-restore | Every agent system prompt includes `export HOME=$(mktemp -d)` before any operation that touches `~/.claude/`. The `isolation: worktree` frontmatter field gives destructive agents their own git worktree. Command instructions include backup step before execution. |
</phase_requirements>

## Standard Stack

### Core

| Component | Type | Purpose | Why Standard |
|-----------|------|---------|--------------|
| Claude Code subagents | Built-in | Agent spawning and isolation | Native Claude Code feature -- markdown files with YAML frontmatter define agents with tool restrictions, model selection, and system prompts |
| Agent tool (formerly Task) | Built-in | Spawning subagents from orchestrator | The only way to programmatically spawn subagents from within a conversation |
| Markdown command files | Convention | Command definition | Established skippy pattern -- YAML frontmatter + objective + process sections |
| Shared findings board | Pattern | Cross-agent communication | Proven in v1.1 audit -- markdown file at known path, each agent appends findings |

### Supporting

| Component | Type | Purpose | When to Use |
|-----------|------|---------|-------------|
| `isolation: worktree` | Subagent field | Git worktree isolation for destructive agents | When a reviewer or fix agent might modify files that conflict with other agents |
| `permissionMode` | Subagent field | Control permission prompts | `bypassPermissions` for automated swarm agents; `plan` for read-only reviewers |
| `tools` allowlist | Subagent field | Restrict agent capabilities | Reviewers get read-only tools; fix agents get Read + Edit + Bash + Write |
| `model` routing | Subagent field | Cost-efficient model selection | `sonnet` for reviewers and standard fixes; `opus` for architecture review and complex fixes |
| `skills` preloading | Subagent field | Inject domain knowledge | Load relevant reference docs into each agent's context at startup |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Subagent `.md` files | `--agents` CLI JSON flag | CLI flag is session-only, not persistent or version-controlled |
| Sequential reviewer spawning | Parallel background subagents | Parallel is faster but risks context bloat when results return; sequential is safer for findings aggregation |
| Agent Teams | Subagents | Agent Teams are experimental and designed for cross-session coordination; subagents are simpler and sufficient for within-session orchestration |
| Worktree isolation | HOME override only | Worktree prevents git conflicts between agents; HOME override only prevents `~/.claude/` damage |

## Architecture Patterns

### Recommended Project Structure

```
skills/skippy/
  commands/
    review.md                  # The /skippy:review command definition
  agents/
    security-reviewer.md       # Security specialist subagent
    code-quality-reviewer.md   # Code quality specialist subagent
    architecture-reviewer.md   # Architecture specialist subagent
    consistency-reviewer.md    # Consistency specialist subagent
    fix-agent.md               # Fix agent for actionable findings
    eval-agent.md              # Evaluator agent for regression detection
  references/
    audit-swarm.md             # Reference doc: swarm orchestration protocol
    ...existing references...
```

### Pattern 1: Command-as-Orchestrator

**What:** The `/skippy:review` command markdown instructs the main conversation to act as a lightweight orchestrator that spawns subagents, collects results, and coordinates the fix/eval cycle.

**When to use:** Always -- this is the only pattern. Claude Code subagents cannot spawn other subagents, so orchestration must happen at the main conversation level.

**Structure:**

```markdown
---
name: skippy:review
description: Multi-agent code review swarm -- spawns specialist reviewers, aggregates findings, applies fixes, verifies
---
<objective>
Run a multi-agent review cycle on the current project or a specified scope.
</objective>

<execution_context>
@../SKILL.md
@../references/audit-swarm.md
@../references/verification-loops.md
@../references/model-routing.md
</execution_context>

<process>
## Step 1: Determine Scope
[detect what to review -- phase, milestone, or ad-hoc file list]

## Step 2: Spawn Reviewers
[spawn each reviewer subagent sequentially, passing scope]

## Step 3: Aggregate Findings
[collect results into shared findings board with severity ratings]

## Step 4: Prioritize and Fix
[spawn fix agents for CRITICAL and HIGH findings]

## Step 5: Evaluate
[spawn eval agent, cycle if regressions found, max 3 iterations]

## Step 6: Report
[generate final audit report]
</process>
```

### Pattern 2: Subagent Definition Pattern

**What:** Each specialist agent is a markdown file with YAML frontmatter defining its name, description, tools, model, and system prompt.

**When to use:** For every agent in the swarm.

**Example (security reviewer):**

```markdown
---
name: security-reviewer
description: Security audit specialist. Scans for vulnerabilities, injection risks, secret exposure, and unsafe patterns.
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: plan
skills:
  - skippy
---

You are a security reviewer for the skippy-agentspace project.
A portable Claude Code skill repo using shell scripts and markdown.

## Your Mission

Scan the specified scope for security issues. Focus on:
1. Secret/credential exposure (API keys, tokens, passwords in code or config)
2. Shell injection vectors (eval, unquoted variables, user input in commands)
3. Path traversal (user-supplied paths without validation)
4. Unsafe file operations (unguarded rm, chmod 777, world-writable)
5. .gitignore gaps (security patterns missing)

## Sandboxing Rule (CRITICAL)

Before running ANY command that touches ~/.claude/ or $HOME:
```bash
export HOME=$(mktemp -d)
```
NEVER operate against the real HOME directory.

## Output Format

Write findings to the findings board file path provided in your task prompt.
Use this format for each finding:

```markdown
### [SEVERITY] Finding Title
- **File:** path/to/file.ext:line
- **Type:** injection | exposure | traversal | unsafe-op | config-gap
- **Evidence:** [code snippet or command output]
- **Fix:** [specific remediation]
- **Cross-ref:** [related findings from other reviewers, if visible]
```

Severity levels: CRITICAL, HIGH, MEDIUM, LOW
```

### Pattern 3: Findings Board Protocol

**What:** A structured markdown file at a known path that serves as the communication channel between agents.

**When to use:** Every review cycle creates a fresh findings board.

**Location:** `.reports/skippy-review/findings-{timestamp}.md`

**Structure:**

```markdown
# Audit Findings Board

**Scope:** [what was reviewed]
**Started:** [timestamp]
**Status:** [in-progress | findings-complete | fixes-applied | verified]

## Security Review
[appended by security-reviewer agent]

## Code Quality Review
[appended by code-quality-reviewer agent]

## Architecture Review
[appended by architecture-reviewer agent]

## Consistency Review
[appended by consistency-reviewer agent]

## Synthesis
[written by orchestrator after all reviews complete]

### Priority Actions
| # | Severity | Finding | Reviewer | Fix Status |
|---|----------|---------|----------|------------|

## Fix Log
[appended by fix agents -- commit hashes and what was fixed]

## Evaluation
[appended by eval agent -- regression check results]
```

### Pattern 4: Sandbox Protocol

**What:** Every agent that might touch `~/.claude/` or run destructive commands operates in a sandboxed environment.

**When to use:** All agents in the swarm, but especially fix agents and any agent with Bash tool access.

**Implementation layers:**

1. **HOME override in system prompt:** Every agent's system prompt includes the instruction to `export HOME=$(mktemp -d)` before any HOME-referencing operation
2. **Worktree isolation (optional):** Agents with `isolation: worktree` get their own git worktree -- changes are isolated until merged
3. **Tool restrictions:** Reviewers get read-only tools (`Read, Grep, Glob, Bash`); fix agents get write tools but with scope constraints in their prompts
4. **Pre-flight backup instruction:** The command's Step 1 includes running backup if `tools/backup-restore.sh` exists (note: this script doesn't currently exist and may need creation or deferral)

### Anti-Patterns to Avoid

- **Nested agent spawning:** Subagents cannot spawn other subagents. Never design a reviewer that tries to delegate sub-tasks to its own agents. All spawning must happen from the main conversation.
- **Parallel reviewer spawning with large returns:** Spawning all 4 reviewers in parallel returns all findings to the main context simultaneously, which can overflow context. Spawn sequentially or use background mode with small summaries.
- **Shared mutable state without coordination:** Multiple fix agents writing to the same files simultaneously causes conflicts. Fix agents should operate on non-overlapping file sets, or run sequentially.
- **Trusting agent HOME isolation:** System prompt instructions are best-effort -- an agent might forget. The `isolation: worktree` field provides a stronger guarantee for git-level isolation.
- **Unbounded fix/eval cycling:** Always cap iterations (max 3 for fix/eval, max 5 for a complete audit cycle). Same-failure detection from verification-loops.md applies.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Agent spawning | Custom shell script to launch Claude instances | Claude Code Agent tool (subagent system) | Built-in, handles context isolation, tool restrictions, model routing |
| Agent definition format | Custom YAML/JSON schema | Standard subagent markdown with YAML frontmatter | Official Claude Code format, loaded at session start, version-controllable |
| Cross-agent communication | Custom IPC, sockets, or temp file protocols | Shared markdown findings board at known path | Simple, debuggable, proven in v1.1 (20+ agents used /tmp/skippy-audit-board.md) |
| Fix verification cycling | Custom retry logic | verification-loops.md protocol | Already defined: max iterations, same-failure detection, severity-rated exit |
| Model selection per agent | Custom routing logic | `model` field in subagent frontmatter | Built into Claude Code -- `sonnet`, `opus`, `haiku`, or `inherit` |
| Git isolation | Manual branch management per agent | `isolation: worktree` subagent field | Claude Code handles worktree creation and cleanup automatically |

**Key insight:** The entire audit swarm is orchestrated through markdown files -- command definitions and agent definitions. No shell scripts are needed for the agent orchestration layer itself. Shell scripts only appear if you need pre-flight backup or post-audit report formatting, which are optional.

## Common Pitfalls

### Pitfall 1: The 71-Skill Nuke (HOME Isolation Failure)

**What goes wrong:** An agent runs a destructive command (like `uninstall.sh --all`) against the real `~/.claude/` directory, deleting user skills.
**Why it happens:** The v1.1 red team agent ran `uninstall.sh --all` against real HOME because the system prompt's sandbox instruction was ignored or forgotten.
**How to avoid:** Multi-layer defense: (1) system prompt instruction for HOME override, (2) `permissionMode: plan` for reviewers (read-only), (3) `isolation: worktree` for agents that modify files, (4) `tools` allowlist excluding Write/Edit for pure reviewers.
**Warning signs:** Any agent with Bash tool access that doesn't have explicit sandbox instructions. Any agent definition missing `permissionMode` or `tools` restrictions.

### Pitfall 2: Context Overflow from Parallel Returns

**What goes wrong:** Spawning all 4 reviewers as background subagents returns their full findings to the main conversation context simultaneously, consuming most of the orchestrator's context budget.
**Why it happens:** Each reviewer might return 2,000-5,000 tokens of findings. 4 reviewers = 8,000-20,000 tokens suddenly added to the main context.
**How to avoid:** Spawn reviewers sequentially, or instruct them to write findings to the board file and return only a summary count (e.g., "Found 3 CRITICAL, 5 HIGH, 2 MEDIUM issues. See findings board.").
**Warning signs:** Orchestrator hitting DEEP context bracket after reviewer returns. Findings being truncated.

### Pitfall 3: Subagent Cannot Spawn Subagent

**What goes wrong:** Designing a "review coordinator" subagent that tries to spawn individual reviewers. The coordinator can't spawn anything.
**Why it happens:** Claude Code prevents nested agent spawning to avoid infinite delegation chains.
**How to avoid:** The main conversation IS the orchestrator. The command instructions guide the main conversation through the spawning sequence. No intermediate coordinator agent.
**Warning signs:** Command design that has a "coordinator" agent between the user and the reviewers.

### Pitfall 4: Fix Agents Conflicting on Same Files

**What goes wrong:** Two fix agents both try to modify the same file, creating conflicting edits or merge conflicts.
**Why it happens:** Multiple findings may reference the same file. If fix agents run in parallel without file-level coordination, they collide.
**How to avoid:** The orchestrator groups findings by file before spawning fix agents. Each fix agent gets a non-overlapping set of files. Or run fix agents sequentially.
**Warning signs:** Multiple CRITICAL/HIGH findings pointing to the same file across different reviewers.

### Pitfall 5: Findings Board Write Conflicts

**What goes wrong:** If reviewers run in parallel and both try to write/append to the same findings board file, content may be lost.
**Why it happens:** Multiple subagents writing to the same file without coordination.
**How to avoid:** Either (1) run reviewers sequentially so each appends to the board in turn, or (2) give each reviewer its own output file and have the orchestrator merge them into the board.
**Warning signs:** Missing sections in the findings board. Truncated reviewer output.

### Pitfall 6: Stale Agent Definitions

**What goes wrong:** Subagent `.md` files under `skills/skippy/agents/` are not loaded until session start. Creating them mid-session requires `/agents` reload or session restart.
**Why it happens:** Claude Code loads subagent definitions at session start, not dynamically.
**How to avoid:** Agent definitions must exist before the session where `/skippy:review` is invoked. After initial creation (this phase), they're always available. If the command creates agents dynamically, it must use the `--agents` CLI flag pattern instead.
**Warning signs:** "Agent not found" errors when the command tries to delegate to a reviewer.

## Code Examples

### Subagent Definition (Verified Pattern from Official Docs)

Source: [Claude Code Subagent Docs](https://code.claude.com/docs/en/sub-agents)

```markdown
---
name: security-reviewer
description: Security audit specialist for skippy-agentspace. Use when running /skippy:review.
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: plan
---

You are a security reviewer. [system prompt content]
```

**Frontmatter fields used by this phase:**

| Field | Value | Why |
|-------|-------|-----|
| `name` | `security-reviewer` | Unique identifier, lowercase-hyphens |
| `description` | Detailed role description | Claude uses this for auto-delegation |
| `tools` | `Read, Grep, Glob, Bash` | Read-only plus bash for grep/find operations |
| `model` | `sonnet` | Good balance of capability and cost for review |
| `permissionMode` | `plan` | Read-only mode prevents accidental writes |
| `skills` | `skippy` | Preloads skippy SKILL.md context |

### Command Definition (Established Project Pattern)

Source: Existing `skills/skippy/commands/reconcile.md`

```markdown
---
name: skippy:review
description: Multi-agent audit swarm -- spawns specialist reviewers, aggregates findings, applies fixes
---
<objective>
Run a multi-agent code review cycle on the current project.
</objective>

<execution_context>
@../SKILL.md
@../references/audit-swarm.md
@../references/verification-loops.md
</execution_context>

<process>
## Step 1: Determine Scope and Prepare
...
## Step 2: Spawn Reviewer Agents
...
</process>
```

### Findings Board Entry Format

Source: v1.1 audit process (proven pattern from `/tmp/skippy-audit-board.md`)

```markdown
### [CRITICAL] Shell injection in validate_skill_name

- **File:** tools/lib/common.sh:45
- **Type:** injection
- **Reviewer:** security-reviewer
- **Evidence:**
  ```bash
  # User input passed directly to eval
  eval "check_$skill_name"
  ```
- **Fix:** Use direct command execution or arrays instead of eval
- **Cross-ref:** See code-quality-reviewer finding #3 (same function)
- **Status:** OPEN | FIXED (commit abc1234) | WONTFIX (reason)
```

### Orchestrator Flow (Command Process Logic)

```
1. SCOPE     -- Detect review target (phase dir, file list, or full repo)
2. PREPARE   -- Create findings board file, record start time
3. REVIEW    -- For each reviewer type:
                 a. Spawn subagent with scope + board path in prompt
                 b. Wait for completion
                 c. Read returned summary
4. SYNTHESIZE -- Read full findings board, cross-reference, deduplicate
5. PRIORITIZE -- Sort by severity, group by file for fix planning
6. FIX       -- For each CRITICAL/HIGH finding:
                 a. Spawn fix agent with finding details + file path
                 b. Wait for atomic commit
                 c. Record commit hash on findings board
7. EVALUATE  -- Spawn eval agent to check for regressions
                 Loop max 3 times if regressions found
8. REPORT    -- Write final audit report with statistics
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Task tool for subagents | Agent tool (Task renamed) | Claude Code v2.1.63 | `Task(...)` still works as alias but `Agent(...)` is canonical |
| No agent isolation | `isolation: worktree` field | 2026 | Agents can get their own git worktree automatically |
| Manual agent spawning only | Background subagents with Ctrl+B | 2026 | Agents can run concurrently; permission pre-approval |
| No persistent memory | `memory: user\|project\|local` | 2026 | Agents can build knowledge across sessions via MEMORY.md |
| Agent Teams (experimental) | Still experimental | Opus 4.6 release | Cross-session coordination; more complex than needed for within-session swarm |

**Important for this phase:**
- The `isolation: worktree` field is the correct way to handle git-level isolation for fix agents, not manual worktree management
- `permissionMode: plan` is the correct way to make reviewers read-only, not just tool restrictions
- Skills preloading (`skills:` field) injects reference docs into subagent context at startup -- no need for agents to discover and read them

## Open Questions

1. **Agent file location -- `.claude/agents/` vs `skills/skippy/agents/`**
   - What we know: Claude Code loads agents from `.claude/agents/` (project) or `~/.claude/agents/` (user). Plugin agents come from the plugin's `agents/` directory.
   - What's unclear: Whether agents under `skills/skippy/agents/` are automatically discovered via the plugin system, or whether they need to be in `.claude/agents/` or installed there via symlink.
   - Recommendation: Store agent definitions in `skills/skippy/agents/` as source of truth for version control. The install process should symlink them to `.claude/agents/` (or the plugin system should handle this via `marketplace.json`). Verify by checking if the plugin `agents/` directory pattern applies here. If not, create `.claude/agents/` symlinks during `install.sh`.

2. **backup-restore.sh existence**
   - What we know: MEMORY.md mentions `bash tools/backup-restore.sh backup` as a testing protocol, but the file does not exist in the current repo.
   - What's unclear: Whether it was removed, never created, or lives elsewhere.
   - Recommendation: Either create a minimal backup-restore.sh in this phase (since SWARM-05 requires sandboxed execution with backup), or defer to Phase 12 (testing) and rely on HOME override + worktree isolation for sandboxing.

3. **Sequential vs parallel reviewer execution**
   - What we know: Sequential is safer for context management and findings board writes. Parallel is faster but risks context overflow.
   - What's unclear: Whether background subagents that write to files (not returning large results) are safe to run in parallel.
   - Recommendation: Start with sequential execution in v1. Add a `--parallel` flag as a v2 enhancement (SWRM requirements in v2 scope).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual verification (no bats-core tests yet -- Phase 12) |
| Config file | None -- Phase 12 creates test infrastructure |
| Quick run command | `/skippy:review --scope .` (run review on current project) |
| Full suite command | Manual: verify all 5 success criteria from ROADMAP.md |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SWARM-01 | Command spawns 4 specialist agents | manual | Invoke `/skippy:review`, verify 4 agent invocations in transcript | N/A -- command-based |
| SWARM-02 | Shared findings board aggregates results | manual | Check `.reports/skippy-review/findings-*.md` exists with 4 sections | N/A -- file check |
| SWARM-03 | Fix agents make atomic commits | manual | Check `git log` for fix commits after review cycle | N/A -- git check |
| SWARM-04 | Eval agent verifies fixes, detects regressions | manual | Check findings board `## Evaluation` section populated | N/A -- file check |
| SWARM-05 | All agents use sandboxed HOME | manual | Verify agent definitions include HOME override + permissionMode/isolation | N/A -- file review |

### Sampling Rate

- **Per task commit:** Manual verification of created files
- **Per wave merge:** Run `/skippy:review` against a test scope and verify all 5 success criteria
- **Phase gate:** All success criteria TRUE before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] Agent definitions directory (`skills/skippy/agents/`) does not exist yet
- [ ] `.reports/` directory convention not yet established
- [ ] `audit-swarm.md` reference doc does not exist yet
- [ ] Agent installation path (symlinks to `.claude/agents/` or plugin discovery) needs verification
- [ ] `backup-restore.sh` does not exist (may need creation or deferral)

## Sources

### Primary (HIGH confidence)

- [Claude Code Subagent Documentation](https://code.claude.com/docs/en/sub-agents) -- Complete subagent system documentation including YAML frontmatter fields, tool restrictions, permission modes, isolation, hooks, memory, and best practices. Fetched and verified 2026-03-08.
- Existing project files -- All 5 existing commands in `skills/skippy/commands/` examined for pattern consistency. All 13 reference docs examined for integration points.
- Project MEMORY.md -- v1.1 audit process details (7 rounds, 20+ agents, 17 findings, 71-skill nuke incident, sandboxing protocol).

### Secondary (MEDIUM confidence)

- [Claude Code Task Tool vs Subagents](https://www.ibuildwith.ai/blog/task-tool-vs-subagents-how-agents-work-in-claude-code/) -- Confirmed Task tool renamed to Agent tool in v2.1.63
- [Claude Code Multi-Agent Guide](https://claudefa.st/blog/guide/agents/agent-teams) -- Agent Teams as experimental feature, subagent limitations (no nesting)
- [Claude Code Subagent Best Practices](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/) -- Practical patterns for subagent design

### Tertiary (LOW confidence)

- [Claude Code Swarm Orchestration Gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea) -- Community swarm pattern; not verified against official docs
- Agent Teams experimental status -- described in multiple sources but no official stability commitment

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Claude Code subagent system is well-documented with official docs verified
- Architecture: HIGH -- Command pattern established by 5 existing commands; subagent definition format confirmed from official docs
- Pitfalls: HIGH -- Most pitfalls derived from actual v1.1 audit incidents (71-skill nuke, context overflow) with documented mitigations
- Agent file location: MEDIUM -- Plugin agent discovery path needs verification; may require install.sh changes

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable -- Claude Code subagent system is established)
