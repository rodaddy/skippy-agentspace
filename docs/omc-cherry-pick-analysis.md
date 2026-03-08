# OMC Cherry-Pick Analysis for skippy-agentspace

Analyzed: oh-my-claudecode v4.7.3 (oh-my-claude-sisyphus npm package)
Date: 2026-03-07
Status: Analysis only -- no cherry-picks taken yet

## Context

Phase 8 cherry-picked 5 ideas from PAUL into reference docs under `skills/skippy-dev/references/`. It was supposed to do the same for OMC, but `upstreams/omc/upstream.json` has `cherry_picks: []`. This analysis identifies what OMC offers and what's worth taking.

### What We Already Took (via cross-package synthesis)

The phase 6-8 reference docs already incorporated OMC patterns, though they're cited as synthesis sources rather than formal cherry-picks:

| Reference Doc | OMC Source | What Was Taken |
|---------------|-----------|----------------|
| `model-routing.md` | ultrawork agent tiers | LOW/MEDIUM/HIGH complexity classification heuristic |
| `verification-loops.md` | UltraQA cycling | Bounded iteration (max 5), same-failure detection (3x = exit), severity-rated review |
| `structured-deliberation.md` | ralplan + deep-interview | PDOC framework (Principles, Drivers, Options, Commitment), perspective roles, bounded iteration, deliberate mode for high-risk |
| `skill-extraction.md` | learner skill | Quality gates (non-Googleable, context-specific, actionable, hard-won), principles-over-snippets methodology |
| `context-brackets.md` | (PAUL primary, OMC context monitoring is related) | Context awareness pattern |

These are NOT redundant with the cherry-picks below -- the existing references extracted the decision heuristics. The cherry-picks below target ideas that haven't been extracted yet.

---

## What OMC Offers (Categorized)

### Category 1: Execution Modes

| Capability | Description | Infrastructure Required |
|-----------|-------------|------------------------|
| **Ralph** | PRD-driven persistence loop with story tracking, iteration limits, architect verification | State management (JSON files), agent spawning |
| **Autopilot** | 5-phase autonomous pipeline (expansion, planning, execution, QA, validation) | Multi-agent runtime, state management |
| **Ultrawork** | Parallel agent execution engine with model tier routing | Agent spawning with model parameter |
| **UltraQA** | Test-diagnose-fix cycling with bounded iterations | Agent spawning, build/test infrastructure |
| **Team** | N coordinated agents on shared task list, staged pipeline (plan-prd-exec-verify-fix) | Claude Code native teams API, tmux for CLI workers |

### Category 2: Planning and Requirements

| Capability | Description | Infrastructure Required |
|-----------|-------------|------------------------|
| **Ralplan** | Planner + Architect + Critic consensus loop with RALPLAN-DR structured output (Principles, Drivers, Options, ADR) | Multi-agent sequential delegation |
| **Deep Interview** | Socratic questioning with mathematical ambiguity scoring across weighted clarity dimensions; challenge agent modes (Contrarian, Simplifier, Ontologist) | State management, scoring model |
| **Plan skill** | Unified planning with auto-detect interview/direct/consensus/review modes | Agent delegation |
| **Pre-execution gate** | Intercepts vague execution requests, redirects to planning; detects concrete signals (file paths, function names, issue numbers) to auto-pass | Keyword analysis |

### Category 3: Quality and Review

| Capability | Description | Infrastructure Required |
|-----------|-------------|------------------------|
| **Code Review** | Severity-rated review (CRITICAL/HIGH/MEDIUM/LOW) with OWASP, code quality, performance checklists | Agent delegation |
| **Security Review** | OWASP Top 10 scan, secrets detection, input validation, dependency audit (npm audit) | Agent delegation, npm |
| **TDD Mode** | Red-Green-Refactor enforcement -- no production code without failing test first | Behavioral constraint only |
| **Build Fix** | Minimal-diff build error resolution (fix only, no refactoring) | Build/typecheck tooling |

### Category 4: Knowledge and Memory

| Capability | Description | Infrastructure Required |
|-----------|-------------|------------------------|
| **Learner** | Extract reusable skills from conversations with quality gates | File system (.omc/skills/) |
| **Note/Notepad** | 3-tier notes: Priority Context (always loaded, 500 char), Working Memory (auto-pruned 7d), Manual (permanent) | File system (.omc/notepad.md), MCP tools |
| **Project Memory** | Cross-session project knowledge (tech stack, build commands, conventions) | File system (.omc/project-memory.json), MCP tools |
| **Pre-compact checkpoint** | Saves active mode states, TODO summary, wisdom before context compaction | Hook system, state files |

### Category 5: Developer Tools

| Capability | Description | Infrastructure Required |
|-----------|-------------|------------------------|
| **HUD** | Real-time statusline showing active modes, context %, agent count, todos, PRD story | Claude Code statusLine config, Node.js script |
| **Preemptive Compaction** | Monitors context usage, warns at configurable thresholds (70% warning, 85% critical) | PostToolUse hook, token estimation |
| **Task Decomposer** | Splits tasks into parallelizable components with non-overlapping file ownership and dependency ordering | TypeScript runtime |
| **Deep Init** | Generates hierarchical AGENTS.md documentation across codebase directories | Agent delegation, file system |
| **Project Session Manager** | Git worktree + tmux session management for isolated dev environments | git, tmux, gh CLI |

### Category 6: Agent Catalog

32 specialized agent prompts across 5 lanes: Build/Analysis, Review, Domain Specialist, Product, and Coordination.

### Category 7: Domain-Specific (Niche)

| Capability | Description | Worth Taking? |
|-----------|-------------|---------------|
| **Writer Memory** | Creative writing memory system (characters, relationships, scenes, themes) with Korean-first vocabulary | No -- domain-specific to fiction writing |
| **CCG** | Tri-model advisor (Claude + Codex + Gemini synthesis) | No -- requires external CLIs |
| **Rate Limit Wait** | Auto-resume daemon for rate-limited sessions | No -- tmux-specific infrastructure |

---

## What's Worth Taking (Recommended Cherry-Picks)

### Cherry-Pick 1: Pre-Execution Gate Pattern

**Source:** `skills/ralplan/SKILL.md` (Pre-Execution Gate section)
**Reference doc name:** `references/pre-execution-gate.md`
**Priority:** HIGH

**What it is:** A decision heuristic that intercepts vague execution requests and redirects them to planning. It detects concrete signals (file paths, function names, issue numbers, camelCase/PascalCase symbols, numbered steps, error references, code blocks) to auto-pass, and redirects underspecified prompts to planning first.

**Why take it:** We already have structured deliberation (PDOC) but no gate that PREVENTS execution from starting without adequate specification. GSD's plan-check runs after planning -- this pattern runs BEFORE execution, catching the "ralph fix things" problem. It's a behavioral discipline, not infrastructure.

**What we already have that's related:** Plan boundaries (what NOT to touch) and task anatomy (4 required fields). The gate complements these -- it's the upstream filter that ensures they get applied.

**Adaptation needed:** Replace OMC's keyword detection with a general decision guide. The concrete signal list (file paths, symbols, steps, etc.) is directly portable. The escape hatch (`force:` prefix) is a nice touch.

### Cherry-Pick 2: Ambiguity Scoring for Requirements

**Source:** `skills/deep-interview/SKILL.md`
**Reference doc name:** `references/ambiguity-scoring.md`
**Priority:** MEDIUM

**What it is:** A mathematical framework for measuring requirements clarity across weighted dimensions (Goal Clarity 40%, Constraint Clarity 30%, Success Criteria 30% for greenfield; adjusted for brownfield with 15% Context Clarity). Questions target the weakest dimension. Challenge agent modes (Contrarian at round 4, Simplifier at round 6, Ontologist at round 8) shift perspective to break plateaus.

**Why take it:** The PDOC framework (structured-deliberation.md) handles plan quality but not requirements quality. You can have a well-structured plan for the wrong thing. The ambiguity scoring provides a quantitative signal for "do we know WHAT to build?" vs PDOC's "is our plan for HOW to build it sound?"

**What we already have that's related:** Structured deliberation covers the planning review loop. This is upstream of that -- it answers "are requirements clear enough to start planning?"

**Adaptation needed:** Extract the scoring formula, dimension weights, and challenge agent modes as a decision heuristic. Don't need the full 20-round interview infrastructure -- the insight is the weighted clarity dimensions and the challenge mode rotation pattern. Can be applied as a mental checklist before entering GSD plan-phase.

### Cherry-Pick 3: Pre-Compact State Preservation

**Source:** `src/hooks/pre-compact/index.ts`
**Reference doc name:** `references/compaction-resilience.md`
**Priority:** MEDIUM

**What it is:** Before context compaction, create a checkpoint that saves: active mode states (what phase, what iteration, what prompt), TODO counts, accumulated wisdom from notepad/learnings, and background job status. The checkpoint is formatted as a structured summary injected into the post-compaction context.

**Why take it:** We already have context brackets (self-monitoring context usage) and session persistence (transferring state across sessions). But we don't have a pattern for what to PRESERVE when compaction happens mid-task. This fills the gap between "awareness of context pressure" (context-brackets) and "session-to-session transfer" (session-persistence). It's the intra-session state preservation pattern.

**What we already have that's related:** Context brackets tell you WHEN you're running low. Session persistence tells you HOW to save state at session boundaries. This tells you WHAT to save when compaction happens during a session.

**Adaptation needed:** Extract as a behavioral pattern, not a hook implementation. The key insight is the checkpoint structure: what was I doing (mode/phase), what's remaining (TODO counts), what did I learn (wisdom). GSD's `.planning/STATE.md` already has some of this -- the reference doc should show how to write a compact checkpoint that survives compaction.

### Cherry-Pick 4: Task Decomposition with File Ownership

**Source:** `src/features/task-decomposer/index.ts`
**Reference doc name:** `references/task-decomposition.md`
**Priority:** LOW-MEDIUM

**What it is:** Analyzes a task description to identify parallelizable components, assigns non-overlapping file ownership patterns to each component, detects shared files requiring orchestration (package.json, tsconfig.json, etc.), and calculates execution order respecting dependencies. Includes strategies per task type (fullstack, refactoring, bug-fix, feature).

**Why take it:** Our model routing reference already covers WHEN to parallelize (complexity classification) but not HOW to split work safely. The file ownership pattern prevents the classic parallel execution bug where two agents edit the same file simultaneously. The shared file detection is particularly useful.

**What we already have that's related:** Model routing (which tier for which task), verification loops (how to validate results). Missing: how to split work into non-conflicting units.

**Adaptation needed:** Extract the decision heuristic: (1) classify task type, (2) identify natural component boundaries, (3) assign file ownership patterns, (4) flag shared files, (5) order by dependencies. The TypeScript implementation is OMC-specific, but the pattern catalog (fullstack splits into frontend/backend/database/shared, refactoring splits by module, etc.) is directly portable as a reference.

---

## What to Skip (With Rationale)

### Skip: Execution Mode Implementations (Ralph, Autopilot, Ultrawork, Team)

**Why:** These are OMC's runtime features, not transferable patterns. We already extracted the useful heuristics:
- Ralph's persistence loop idea -> verification-loops.md (cycling with bounds)
- Ultrawork's tier routing -> model-routing.md (complexity classification)
- Ralph's architect verification -> verification-loops.md (severity-rated review)
- Team's staged pipeline -> not needed (GSD has its own phased execution)

The actual implementations require OMC's agent spawning infrastructure (Task calls with model parameters, state management via MCP tools). Taking them would mean reimplementing OMC, which defeats the portable skill repo approach.

### Skip: Full Agent Catalog (32 Agents)

**Why:** The agent prompts are OMC-specific (they reference OMC's delegation API, skill system, and state management). GSD uses different agent roles (explore, executor, checker). What we already took from the agent catalog is the MODEL ROUTING idea -- match agent complexity to model tier. The specific prompts aren't portable.

### Skip: HUD Statusline

**Why:** Requires Node.js runtime, Claude Code's statusLine API, and OMC's state file format. The concept (live observability) is good, but it's infrastructure, not a transferable pattern. Our context brackets reference already provides awareness of context state, which is the key insight.

### Skip: Keyword Detection / Magic Keywords

**Why:** This is OMC's UX sugar for triggering execution modes. We don't need it -- GSD uses explicit slash commands and phase-based execution. The keyword detection is actually problematic in our setup (we had to remove the hook to prevent false triggers -- see MEMORY.md).

### Skip: Note/Notepad/Project Memory MCP Tools

**Why:** These are OMC's runtime services that we already use directly via the OMC plugin. There's nothing to cherry-pick -- we use the tools as-is. The PATTERN of tiered notes (priority/working/manual) could be a reference doc, but it's simple enough to not warrant one.

### Skip: Deep Init (AGENTS.md Generation)

**Why:** OMC-specific documentation format. We use CLAUDE.md, INDEX.md, and PROJECT.md. The hierarchical documentation idea is fine but doesn't add value over our existing doc structure.

### Skip: Writer Memory

**Why:** Domain-specific to Korean fiction writing workflows. Entirely outside our scope.

### Skip: Project Session Manager / Teleport

**Why:** We already have worktree support via Claude Code's native `EnterWorktree` tool and our `cw`/`cwa`/`cwb`/`cwc` aliases. PSM adds tmux orchestration which is OMC-specific infrastructure.

### Skip: TDD Mode

**Why:** While test-first is a good practice, the OMC skill is just behavioral enforcement text ("delete code written before tests"). It doesn't add a pattern beyond what "write failing test first" already says. Not worth a reference doc.

### Skip: Build Fix Skill

**Why:** "Fix build errors with minimal changes" is obvious practice. The OMC skill just delegates to a build-fixer agent at Sonnet tier. No novel heuristic to extract.

### Skip: Code Review / Security Review Skills

**Why:** The severity rating pattern (CRITICAL/HIGH/MEDIUM/LOW) was already taken into verification-loops.md. The OWASP checklists and review categories are standard security knowledge, not OMC-specific insights. Not worth a reference doc -- if needed, just reference OWASP directly.

### Skip: CCG (Tri-Model Advisor)

**Why:** Requires Codex CLI and Gemini CLI installations. Multi-model synthesis is interesting conceptually but requires infrastructure we don't have or need.

### Skip: Rate Limit Wait

**Why:** tmux-specific daemon. Not portable.

### Skip: Preemptive Compaction Hook (as code)

**Why:** The hook implementation requires OMC's PostToolUse event system. However, the CONCEPT of token estimation and warning thresholds is worth taking -- it's captured in cherry-pick 3 (compaction resilience) as a behavioral pattern rather than a hook.

---

## Summary

| # | Cherry-Pick | Reference Doc | Priority | Status |
|---|-------------|---------------|----------|--------|
| 1 | Pre-execution gate | `references/pre-execution-gate.md` | HIGH | Proposed |
| 2 | Ambiguity scoring | `references/ambiguity-scoring.md` | MEDIUM | Proposed |
| 3 | Compaction resilience | `references/compaction-resilience.md` | MEDIUM | Proposed |
| 4 | Task decomposition | `references/task-decomposition.md` | LOW-MEDIUM | Proposed |

### Comparison with PAUL Cherry-Picks

| Upstream | Cherry-Picks Taken | Pattern |
|----------|-------------------|---------|
| PAUL | 5 (context brackets, reconciliation, task anatomy, plan boundaries, state consistency) | Behavioral disciplines for planning rigor |
| OMC (proposed) | 4 (pre-execution gate, ambiguity scoring, compaction resilience, task decomposition) | Decision heuristics for execution readiness and parallel safety |

PAUL's cherry-picks focus on **planning discipline** -- making plans better. OMC's cherry-picks focus on **execution readiness** -- ensuring you're ready to execute and resilient during execution. They're complementary layers.

### Implementation Order

1. **Pre-execution gate** (HIGH) -- immediate value, prevents wasted execution cycles on vague tasks
2. **Ambiguity scoring** (MEDIUM) -- provides quantitative requirements quality gate upstream of PDOC
3. **Compaction resilience** (MEDIUM) -- fills gap between context-brackets and session-persistence
4. **Task decomposition** (LOW-MEDIUM) -- useful for parallel execution safety, less urgent

### Update to upstream.json

When cherry-picks are implemented, update `upstreams/omc/upstream.json`:

```json
{
  "cherry_picks": [
    {
      "id": "pre-execution-gate",
      "source": "skills/ralplan/SKILL.md",
      "target": "skills/skippy-dev/references/pre-execution-gate.md",
      "description": "Vague prompt interception with concrete signal detection",
      "date": "<date>"
    },
    {
      "id": "ambiguity-scoring",
      "source": "skills/deep-interview/SKILL.md",
      "target": "skills/skippy-dev/references/ambiguity-scoring.md",
      "description": "Weighted clarity dimensions with challenge agent modes",
      "date": "<date>"
    },
    {
      "id": "compaction-resilience",
      "source": "src/hooks/pre-compact/index.ts",
      "target": "skills/skippy-dev/references/compaction-resilience.md",
      "description": "Checkpoint structure for mid-session compaction survival",
      "date": "<date>"
    },
    {
      "id": "task-decomposition",
      "source": "src/features/task-decomposer/index.ts",
      "target": "skills/skippy-dev/references/task-decomposition.md",
      "description": "File ownership patterns for parallel execution safety",
      "date": "<date>"
    }
  ]
}
```

---

*Analysis based on OMC v4.7.3 source at `~/.claude/plugins/cache/omc/oh-my-claudecode/4.7.3/`*
