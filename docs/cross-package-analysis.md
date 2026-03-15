# Cross-Package Pattern Analysis

**Last reviewed:** 2026-03-07
**Upstreams analyzed:**
- GSD: [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done.git)
- PAUL: [ChristopherKahler/paul](https://github.com/ChristopherKahler/paul.git)
- OMC: [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode.git) (SHA `96a5d372`, v4.7.3)

---

## Section 1: Shared Patterns

Patterns appearing in 2+ upstreams, with side-by-side comparison and explicit recommendation for each.

### 1. Task Verification

How each upstream ensures work is correct after execution.

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `gsd:verify-work` -- single-pass verification agent runs after each plan execution | Structured, tied to phase lifecycle, automatic | Single pass only -- if verification fails, human intervention needed |
| PAUL | Verification protocol with explicit pass/fail criteria per task | Clear success criteria defined upfront, testable | No automation -- relies on manual checking against criteria |
| OMC | UltraQA -- autonomous cycling (test-diagnose-fix-repeat, max 5 iterations) with architect diagnosis and same-failure detection | Automated cycling with early exit on repeated failures, multi-agent diagnosis (qa-tester + architect + executor) | Heavy runtime dependency on OMC's agent infrastructure |

**Recommendation:** Synthesize all three. Use PAUL's explicit criteria (already captured in `plan-structure.md`) to define what "pass" means, GSD's phase-tied execution as the trigger point, and OMC's cycling concept (bounded iterations, same-failure early exit) as the verification loop strategy. The key insight from OMC: verification should CYCLE rather than single-pass, with a hard cap (5 iterations) and duplicate-failure detection to avoid infinite loops.

**Reference doc:** `verification-loops.md` (Plan 02, HIGH priority)

---

### 2. Context / State Management

How each upstream persists and organizes state across sessions and context windows.

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `.planning/STATE.md` -- git-tracked markdown with position, decisions, blockers, metrics | Persistent across sessions, version-controlled, human-readable | Flat structure -- no urgency tiers, no auto-pruning, grows unbounded |
| PAUL | Context management guidelines with session awareness | Lightweight, explicit about what to preserve | No persistence mechanism -- guidelines only, no tooling |
| OMC | `.omc/notepad.md` with three tiers: Priority Context (always loaded, 500 char limit), Working Memory (timestamped, auto-pruned after 7 days), Manual (never pruned) | Tiered urgency, automatic pruning, compaction-resilient | Requires MCP tools (`state_write`, `notepad_write`), OMC-specific file paths |

**Recommendation:** Synthesize GSD's git-tracked state with OMC's tiered persistence concept. GSD's STATE.md is the right persistence mechanism (git-tracked, portable, no MCP dependency). OMC's contribution is the CONCEPT of tiered urgency: some context is always-load (like OMC's Priority Context), some is session-scoped and can be pruned (like Working Memory), and some is permanent reference (like Manual). This maps well to our existing context brackets (FRESH/MODERATE/DEEP/CRITICAL) -- adapt tier behavior based on context depth.

**Reference doc:** `session-persistence.md` (Plan 02, HIGH priority)

---

### 3. Planning Quality Gates

How each upstream ensures plan quality before execution begins.

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `plan-check` -- single checker agent reviews plans against criteria | Automated, catches issues before execution, integrated into workflow | Single reviewer perspective, no structured deliberation format |
| PAUL | Plan format with explicit fields (scope, boundaries, DO NOT CHANGE sections) | Structured requirements prevent scope creep, clear boundaries | No multi-agent review, no iteration on feedback |
| OMC | Ralplan -- Planner + Architect + Critic consensus (max 5 iterations) with RALPLAN-DR structured deliberation (Principles, Decision Drivers, Viable Options, ADR output) | Multi-perspective review, bounded iteration, structured output with ADR, deliberate mode for high-risk work | Heavy -- overkill for small tasks, requires OMC agent infrastructure |

**Recommendation:** Synthesize PAUL's structured fields (already in `plan-structure.md` and `plan-boundaries.md`) with OMC's multi-perspective deliberation concept. The key insight from OMC is not the 3-agent runtime (we don't need that) but the RALPLAN-DR structure: defining Principles, Decision Drivers, and Viable Options before committing to a plan. This can enhance GSD's plan-check by giving the checker agent a structured deliberation framework to evaluate against, rather than freeform review.

**Reference doc:** `structured-deliberation.md` (Plan 02, MEDIUM priority)

---

### 4. Model / Agent Routing

How each upstream selects the right model or agent tier for different task complexities.

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `model_profile` in config.json (quality/speed/cost) -- applies globally to the phase | Simple, one setting for the whole phase | No per-task routing -- complex and simple tasks get the same model |
| OMC | Agent tiers with explicit complexity matching: Haiku (LOW -- lookups, simple edits), Sonnet (MEDIUM -- standard implementation), Opus (HIGH -- complex analysis, refactoring) | Granular per-task routing, cost-efficient, documented decision guide in `agent-tiers.md` | Assumes multi-agent runtime with Task delegation |

**Recommendation:** Use OMC's tier concept as a reference doc. GSD already spawns explore/executor agents -- the missing piece is a decision guide for WHICH model to use WHEN. OMC's 3-tier system (Haiku/Sonnet/Opus mapped to LOW/MEDIUM/HIGH complexity) is practical and directly applicable when spawning GSD subagents. The reference doc should provide the complexity classification heuristic, not the runtime machinery.

**Reference doc:** `model-routing.md` (Plan 02, HIGH priority)

---

### 5. Structured Research

How each upstream approaches investigation and analysis tasks.

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `gsd:research-phase` -- single researcher agent produces RESEARCH.md with confidence levels and structured sections | Structured output format, confidence ratings, well-integrated with planning phases | Single agent, sequential investigation, no parallel exploration |
| OMC | SciOMC -- decompose research goal into 3-7 independent stages, parallel scientist agents per stage, cross-validation of findings, synthesis into comprehensive report | Parallel investigation, hypothesis-driven stages, cross-validation catches inconsistencies, model-routed per stage complexity | Heavy runtime, requires OMC's agent orchestration, may over-engineer simple research tasks |

**Recommendation:** GSD's existing research phase is adequate for most work. Document OMC's decomposition concept as a reference for complex research tasks where a single-agent pass would miss cross-cutting concerns. The key ideas worth capturing: (1) decompose into independent stages with explicit hypotheses, (2) route stages to appropriate model tiers, (3) cross-validate findings between stages before synthesis. This is a "reach for when needed" pattern, not a default workflow change.

**Reference doc:** `structured-research.md` (Plan 02, MEDIUM priority)

---

## Section 2: OMC Feature Inventory

Full categorization of all 37 OMC skills. Every skill is classified as Cherry-Picked (pattern extracted), Rejected (with reason), or Deferred (with re-evaluation criteria).

### Cherry-Picked (8 patterns)

Features where OMC introduces a concept worth extracting as a reference doc.

| Feature | What We Take | Reference Doc |
|---------|-------------|---------------|
| ultrawork | Model routing concept -- Haiku/Sonnet/Opus tiers mapped to LOW/MEDIUM/HIGH task complexity | `model-routing.md` |
| ultraqa | Verification cycling -- bounded iteration (max 5), same-failure detection, architect diagnosis between cycles | `verification-loops.md` |
| ralplan | Structured deliberation -- RALPLAN-DR format (Principles, Decision Drivers, Viable Options, ADR output) | `structured-deliberation.md` |
| deep-interview | Ambiguity scoring concept -- weighted clarity dimensions, mathematical gating before execution, challenge agent modes (Contrarian, Simplifier, Ontologist) | `structured-deliberation.md` (merged -- both address pre-execution clarity) |
| code-review | Severity rating system -- CRITICAL/HIGH/MEDIUM/LOW with structured checklist categories (Security, Quality, Performance, Practices, Maintainability) | Consider merging into `verification-loops.md` |
| sciomc | Structured research protocol -- decompose into stages, parallel execution, cross-validation, synthesis | `structured-research.md` |
| learner | Skill extraction methodology -- non-Googleable, context-specific, actionable quality gates; principles over code snippets | `skill-extraction.md` |
| note | Tiered persistence concept -- Priority Context (always loaded), Working Memory (timestamped, auto-pruned), Manual (never pruned) | `session-persistence.md` |

### Rejected (29 features)

Features rejected with documented rationale for each.

| Feature | Reason | GSD/PAI Equivalent |
|---------|--------|-------------------|
| autopilot | Full autonomous pipeline requiring OMC runtime (5 phases, multi-agent orchestration). Too heavy, not portable. | GSD phased execution is our foundation |
| ralph | PRD-driven persistence loop requiring OMC state management and MCP tools. | GSD executor + verifier covers this |
| team | N coordinated agents on shared task list via tmux pane management. Not portable. | GSD parallel execution |
| omc-plan | Strategic planning with interview workflow. Overlaps heavily with GSD's discuss-phase + plan-phase. | GSD discuss-phase + plan-phase |
| analyze | Thin wrapper around debugger agent delegation. No novel pattern. | Standard agent delegation |
| ralph-init | Initialize PRD for ralph runtime. Specific to ralph. | N/A (ralph-specific) |
| security-review | Security vulnerability detection. Subset of code-review checklist, not distinct enough for separate doc. | Covered by code-review patterns in verification-loops |
| tdd | Test-driven development enforcement. Red-green-refactor is universally documented. | Standard TDD (GSD has TDD execution flow) |
| build-fix | Fix build/TypeScript errors. Just delegates to build-fixer agent. No novel pattern. | Standard debugging |
| deepinit | Generate hierarchical AGENTS.md. OMC-specific documentation format. | Not applicable |
| external-context | Parallel web search with facet decomposition. Just spawns document-specialist agents. | Standard web search tools |
| project-session-manager | Git worktree + tmux isolation. PAI already has `cw`, `cwa`, `cwb`, `cwc` aliases for worktrees. PSM adds tmux -- too heavy. | PAI worktree aliases (`cw` family) |
| writer-memory | Creative writing memory system for Korean fiction. Domain-specific, not applicable. | N/A (domain-specific) |
| release | Automated release workflow. OMC-specific release process. | N/A (OMC-specific) |
| ccg | Claude-Codex-Gemini tri-model orchestration. Requires Codex + Gemini CLIs. Not portable. | N/A (multi-CLI dependency) |
| ask-codex | Delegate to Codex CLI. Requires Codex CLI installation. Not portable. | N/A (external CLI dependency) |
| ask-gemini | Delegate to Gemini CLI. Requires Gemini CLI installation. Not portable. | N/A (external CLI dependency) |
| configure-notifications | Telegram/Discord/Slack integration. External service dependency. | N/A (external service dependency) |
| configure-openclaw | Deprecated by OMC itself. | N/A (deprecated) |
| omc-teams | Spawn CLI workers in tmux panes. Not portable. | N/A (tmux dependency) |
| cancel | Cancel active OMC modes. OMC-specific runtime control. | N/A (OMC-specific) |
| hud | Configure HUD display. OMC-specific UI feature. | N/A (OMC-specific) |
| omc-doctor | Diagnose OMC installation issues. OMC-specific troubleshooting. | N/A (OMC-specific) |
| omc-setup | OMC setup wizard. OMC-specific setup. | N/A (OMC-specific) |
| omc-help | OMC usage guide. OMC-specific help. | N/A (OMC-specific) |
| mcp-setup | Configure MCP servers. OMC-specific MCP configuration. | N/A (OMC-specific) |
| skill | Manage local OMC skills. OMC-specific skill management runtime. | N/A (OMC-specific) |
| trace | Agent flow timeline and observability. OMC-specific debugging tool. | N/A (OMC-specific) |
| learn-about-omc | Usage pattern analysis and OMC analytics. OMC-specific telemetry. | N/A (OMC-specific) |

### Deferred (0 features)

No features are deferred. Every skill was either worth cherry-picking (as a pattern) or clearly rejectable. If OMC adds new skills in future versions, `/skippy:update` will flag them for evaluation.

| Feature | Why Deferred | Re-evaluate When |
|---------|-------------|-----------------|
| *(none)* | All 37 skills categorized | When `/skippy:update` detects new OMC skills |

---

## Section 3: Cherry-Pick Summary

Mapping of cherry-picked patterns to planned reference docs and implementation priority.

| Pattern | Source Skills | Priority | Reference Doc | Drives |
|---------|-------------|----------|---------------|--------|
| Model Routing | ultrawork, sciomc | **HIGH** | `model-routing.md` | Agent spawning decisions in GSD executor/explore |
| Verification Loops | ultraqa, code-review | **HIGH** | `verification-loops.md` | Post-task verification in GSD execution flow |
| Session Persistence | note | **HIGH** | `session-persistence.md` | Context management across GSD sessions |
| Structured Deliberation | ralplan, deep-interview | **MEDIUM** | `structured-deliberation.md` | Pre-execution planning quality in GSD plan-check |
| Skill Extraction | learner | **MEDIUM** | `skill-extraction.md` | Capturing reusable patterns from debugging sessions |
| Structured Research | sciomc | **MEDIUM** | `structured-research.md` | Complex research tasks in GSD research-phase |
| Code Review Protocol | code-review | **LOW** | Merge into `verification-loops.md` | Severity-rated review checklist |

**HIGH priority** patterns address gaps in the current workflow -- they should be created first in Plan 02.

**MEDIUM priority** patterns enhance existing capabilities -- create if the analysis confirms they're substantial enough for standalone docs.

**LOW priority** patterns are worth documenting but may merge into other docs rather than standing alone.

---

## Methodology

Each of the 37 OMC skills was evaluated by reading its SKILL.md file directly from the local cache at `~/.claude/plugins/cache/omc/oh-my-claudecode/4.7.3/skills/`. The evaluation criteria for each skill:

1. **Does it introduce a novel pattern?** -- If the skill is just a thin wrapper around agent delegation with no unique methodology, reject.
2. **Does GSD or PAI already cover this?** -- If yes, is OMC's version meaningfully better? If not, reject.
3. **Is it portable?** -- If it requires OMC runtime, MCP tools, tmux, or external CLIs, the implementation is rejected. But the underlying CONCEPT may still be cherry-picked.
4. **Is the pattern general or domain-specific?** -- Korean fiction memory systems, Codex/Gemini CLI wrappers, and OMC setup wizards are not applicable to our workflow.

The same methodology was applied to PAUL when the project started (see CLAUDE.md "What We Rejected from PAUL"). Documenting rejection reasons prevents re-evaluation churn when revisiting upstream changes.

## Notes

This is a living document. When `/skippy:update` detects significant upstream changes (>10 commits or changes in cherry-picked areas), it will suggest re-reviewing this analysis.

The cherry-pick approach is consistent across all three upstreams: extract the PRINCIPLE and DECISION-MAKING HEURISTIC, never the implementation. OMC skills reference MCP tools, Task delegation, and agent types that don't exist in our context. Our reference docs describe CONCEPTS adapted for GSD's execution model.

### Relationship to Plan 02

The Cherry-Pick Summary table (Section 3) directly drives Plan 02's deliverables. Each HIGH priority pattern becomes a reference doc in `skills/skippy/references/`. The reference docs follow an evolved format with Source Upstreams, Why This Version, and Integration Points sections -- building on the established format from the 5 existing PAUL reference docs.

### Relationship to Plan 03

The generic `/skippy:update` command (Plan 03) will iterate `upstreams/*/upstream.json` including the new OMC entry. When it detects changes in cherry-picked areas, it will reference this document to help assess whether the analysis needs updating.
