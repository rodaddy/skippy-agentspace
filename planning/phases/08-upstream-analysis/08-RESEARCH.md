# Phase 8: Upstream Analysis - Research

**Researched:** 2026-03-07
**Domain:** Upstream tracking, cross-package pattern analysis, best-of-breed synthesis, AI-driven update command
**Confidence:** HIGH

## Summary

Phase 8 adds OMC as a third tracked upstream, performs a systematic cross-package pattern analysis across GSD/PAUL/OMC, creates best-of-breed reference docs that synthesize the strongest implementations of shared patterns, and replaces the hardcoded shell-script-based `/skippy:update` with a generic AI-driven markdown command that iterates `upstreams/*/upstream.json`.

The codebase is well-prepared for this phase. Phase 5 established the directory-per-upstream pattern (`upstreams/<name>/upstream.json`) with a documented schema in CONVENTIONS.md. The existing PAUL reference docs in `skills/skippy/references/` provide a clear format template to evolve. The current `skippy-update.sh` shell script and `.versions` file need to be replaced, and the `update.md` command needs to be rewritten as AI-driven instructions.

The OMC codebase (v4.7.3, SHA `96a5d372`) contains 37 skills across 6 categories. After systematic scanning, I've identified the cross-package patterns and cherry-pick candidates that the implementation phase will need to analyze and document.

**Primary recommendation:** Work in four clear deliverable groups -- (1) OMC upstream registration, (2) cross-package analysis document, (3) best-of-breed reference docs, (4) generic AI-driven update command -- with the analysis document driving the reference doc selection.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Full systematic scan of all 30+ OMC skills/features -- categorize each as: cherry-pick, reject with reason, or defer
- Document rejection reasons (same approach as PAUL rejection table)
- Map overlaps: for each OMC feature, note if GSD/PAI already covers it and whether OMC's version is better
- Cross-package analysis is a living document at project root level (e.g., docs/ or .planning/)
- Living document with 'last reviewed' timestamp -- /skippy:update flags for re-review when OMC adds new features
- Detailed comparison for each shared pattern: side-by-side implementation comparison, strengths/weaknesses, explicit recommendation
- Best-of-breed docs use evolved format from existing PAUL reference docs: add structured sections like 'Source Upstreams', 'Why This Version', 'Integration Points'
- Credit sources inline (e.g., "Context management: GSD's approach with OMC's notepad persistence")
- Count determined by analysis -- create a doc for every pattern worth synthesizing, quality over quantity (minimum 3 per requirement)
- Location: skills/skippy/references/ alongside existing PAUL reference docs
- /skippy:update becomes an AI-driven command (markdown instructions that Claude executes interactively) instead of a shell script
- The command iterates upstreams/*/upstream.json, fetches each repo, compares SHAs, reports changes conversationally, and can suggest cherry-picks
- Updates upstream.json files in-place (writes new last_checked_sha and last_check after each run)
- .versions file removed immediately -- clean break, upstream.json is sole source of truth
- skippy-update.sh either removed or replaced with the AI-driven command.md

### Claude's Discretion
- Exact organization of the cross-package analysis document
- Which specific patterns qualify as "best-of-breed" vs too niche
- Technical implementation of the AI-driven update command
- How to handle OMC features that are PAI-specific (personas, homekit, etc.) in the analysis

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UPST-01 | OMC added as third upstream source in registry | upstream.json schema documented in CONVENTIONS.md, OMC repo URL and SHA identified, directory-per-upstream pattern from Phase 5 |
| UPST-02 | Cross-package analysis identifies patterns common across GSD, PAUL, and OMC | Full OMC skill inventory (37 skills) scanned, overlap patterns identified, GSD/PAUL equivalents mapped |
| UPST-03 | Best-of-breed skippy versions created for common patterns | Existing reference doc format analyzed, evolved format designed with source attribution sections |
| UPST-04 | /skippy:update uses generic upstream checker instead of hardcoded repos | Current shell script analyzed, AI-driven command pattern documented, upstream.json iteration approach designed |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown | N/A | All deliverables are markdown files | Project constraint: no build step, shell + markdown only |
| upstream.json | Schema v1 | Upstream tracking metadata | Established in Phase 5, documented in CONVENTIONS.md |
| Git CLI | 2.5+ | Fetch upstream repos, compare SHAs | Already used by skippy-update.sh |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jq | Any | Parse upstream.json in shell validation | Only if verification scripts need JSON parsing |
| bun | Any | Project's Node.js runtime | If any validation tooling needs JS |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AI-driven command (chosen) | Enhanced shell script | Shell can't suggest cherry-picks or have conversational output -- AI command aligns with Phase 5 installation philosophy |
| Living doc at project root (chosen) | Per-skill analysis files | Root-level gives holistic view, easier to cross-reference, matches decision |

## Architecture Patterns

### Recommended Project Structure
```
upstreams/
  gsd/upstream.json           # Existing
  paul/upstream.json          # Existing
  omc/upstream.json           # NEW: Phase 8
docs/
  cross-package-analysis.md   # NEW: Living analysis document
skills/skippy/
  commands/
    update.md                 # REWRITTEN: AI-driven generic command
  references/
    context-brackets.md       # Existing (PAUL)
    reconciliation.md         # Existing (PAUL)
    task-anatomy.md           # Existing (PAUL)
    plan-boundaries.md        # Existing (PAUL)
    state-consistency.md      # Existing (PAUL)
    gsd-dependency-map.md     # Existing (GSD)
    model-routing.md          # NEW: Best-of-breed (OMC+GSD)
    verification-loops.md     # NEW: Best-of-breed (OMC+PAUL+GSD)
    session-persistence.md    # NEW: Best-of-breed (OMC+GSD)
    [additional as analysis dictates]
  scripts/
    skippy-update.sh          # REMOVED (replaced by AI command)
  .versions                   # REMOVED (upstream.json is source of truth)
  SKILL.md                    # UPDATED: reflect new references + command
```

### Pattern 1: Directory-Per-Upstream (Existing)
**What:** Each upstream is a directory under `upstreams/` with an `upstream.json` file
**When to use:** Adding any new upstream source
**Example:**
```json
// upstreams/omc/upstream.json
{
  "name": "omc",
  "description": "Oh My ClaudeCode -- multi-agent orchestration with skills, hooks, and execution modes",
  "repo": "https://github.com/Yeachan-Heo/oh-my-claudecode.git",
  "branch": "main",
  "last_checked_sha": "96a5d3725586b18492fb4b8019ec37ba6ffd7b14",
  "last_check": "2026-03-07",
  "cherry_picks": [],
  "notes": "Cherry-pick ideas only -- no runtime dependency on OMC's Node.js infrastructure"
}
```

### Pattern 2: Evolved Best-of-Breed Reference Doc Format
**What:** Enhanced reference doc format with source attribution and synthesis metadata
**When to use:** Creating new reference docs that synthesize patterns from multiple upstreams
**Example:**
```markdown
# [Pattern Name] -- Best-of-Breed Synthesis

Synthesized from [upstream1] and [upstream2]. [One-line description].

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | [how GSD does it] | [what's good] | [what's missing] |
| OMC | [how OMC does it] | [what's good] | [what's missing] |
| PAUL | [how PAUL does it] | [what's good] | [what's missing] |

## Why This Version

[Explain which parts came from where and why this synthesis is better than any single source]

## The Pattern

[Actual content -- actionable guidance]

## Integration Points

[How this fits into the skippy workflow, which GSD phases it applies to]

## When to Apply

[Conditions where this pattern is relevant]

---
*Sources: [upstream1] [file], [upstream2] [file]*
*Last reviewed: YYYY-MM-DD*
```

### Pattern 3: AI-Driven Command (Markdown Instructions)
**What:** Commands written as markdown that Claude executes interactively, replacing shell scripts
**When to use:** Operations that benefit from conversational output, contextual suggestions, or adaptive behavior
**Example:**
```markdown
---
name: skippy:update
description: Check all tracked upstreams for changes and suggest cherry-picks
---
<objective>
Check all registered upstreams for new commits and report changes conversationally.
</objective>

<process>
1. Read all upstream.json files from upstreams/*/upstream.json
2. For each upstream:
   a. Clone/fetch the repo to a cache directory
   b. Compare HEAD SHA against last_checked_sha
   c. If changed, report: commits since last check, changed files, areas of interest
   d. Update upstream.json with new SHA and date
3. For upstreams with cherry_picks, highlight changes in cherry-picked areas
4. Suggest potential new cherry-picks based on changed files
5. Flag if cross-package-analysis.md needs re-review
</process>
```

### Anti-Patterns to Avoid
- **Hardcoded upstream URLs in scripts:** The whole point of UPST-04 is generic iteration over `upstreams/*/upstream.json`. Never reference specific repos in the command logic.
- **Importing OMC's Node.js runtime:** This project is shell + markdown only. Cherry-pick IDEAS, not code. The out-of-scope table explicitly says "OMC runtime dependency" is excluded.
- **Copying OMC skill files verbatim:** Best-of-breed docs SYNTHESIZE the strongest version. They're not copies -- they're distilled principles adapted for our workflow.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Upstream version tracking | Custom tracking files | `upstreams/*/upstream.json` schema | Already established in Phase 5, documented in CONVENTIONS.md |
| Upstream diff reporting | Custom diff tools | Git CLI (`git log`, `git diff --name-only`) | Standard git operations, already proven in current skippy-update.sh |
| Cross-package analysis format | Invented structure | PAUL rejection table pattern + enhanced comparison tables | Project already has the PAUL rejection pattern in CLAUDE.md |

## Common Pitfalls

### Pitfall 1: Superficial OMC Skill Scanning
**What goes wrong:** Scanning skill names/descriptions only and missing the actual implementation patterns worth cherry-picking.
**Why it happens:** 37 skills is a lot. Temptation to categorize by name rather than reading the SKILL.md files.
**How to avoid:** Read every SKILL.md file. The value is in the WORKFLOW and PATTERN, not the name. OMC's `learner` skill, for example, isn't about a "learning" feature -- it's about a principled skill-extraction methodology.
**Warning signs:** Analysis doc only has 1-2 line descriptions for each skill.

### Pitfall 2: Conflating Cherry-Pick with Runtime Dependency
**What goes wrong:** Trying to make OMC features "work" in skippy rather than extracting the underlying principle.
**Why it happens:** OMC skills reference MCP tools (`state_write`, `notepad_write`), Task delegation, etc. that don't exist in our context.
**How to avoid:** Extract the PRINCIPLE and DECISION-MAKING HEURISTIC, not the implementation. OMC's `note` skill uses MCP tools -- our version would describe the CONCEPT of tiered persistence (priority/working/manual) as a pattern.
**Warning signs:** Reference docs mention OMC-specific tools or file paths like `.omc/`.

### Pitfall 3: .versions File Left as Zombie
**What goes wrong:** Removing .versions from the script but forgetting to actually delete the file, or forgetting to update all references.
**Why it happens:** .versions is referenced in skippy-update.sh, SKILL.md, and possibly CLAUDE.md's "What's Built" section.
**How to avoid:** Search for all references: `grep -r ".versions" . --include="*.md" --include="*.sh"`. Remove the file AND all references.
**Warning signs:** Any remaining mention of `.versions` in repo after phase completion.

### Pitfall 4: AI Command That's Actually a Shell Script in Disguise
**What goes wrong:** Writing the new update.md as step-by-step bash commands that Claude runs mechanically, missing the point of AI-driven.
**Why it happens:** The old shell script is the mental model.
**How to avoid:** The AI command should describe INTENT and let Claude adapt. "Check each upstream for changes and report conversationally" not "run git fetch origin --quiet && git rev-parse HEAD".
**Warning signs:** The command.md is >50% code blocks.

### Pitfall 5: Cross-Package Analysis Without Actionable Recommendations
**What goes wrong:** Analysis document becomes a feature comparison matrix without clear "use X's approach" recommendations.
**Why it happens:** Being comprehensive without being opinionated.
**How to avoid:** Every shared pattern must end with an explicit recommendation: "Use OMC's approach because..." or "Synthesize: GSD's structure + OMC's persistence."
**Warning signs:** Analysis entries without a "Recommendation" row.

## OMC Skill Inventory -- Complete Scan

This is the systematic scan the CONTEXT.md mandates. All 37 OMC skills categorized.

### Execution Mode Skills (5)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| autopilot | Full autonomous idea-to-code pipeline (5 phases) | **Reject** | GSD phases handle this | Multi-agent orchestration requiring OMC runtime. GSD's phased approach is our foundation. |
| ralph | PRD-driven persistence loop with architect verification | **Reject** | GSD executor + verifier | Requires OMC state management, MCP tools. GSD already has verification. |
| ultrawork | Parallel execution engine with model routing | **Cherry-pick pattern** | GSD parallelization is basic | The MODEL ROUTING concept (Haiku/Sonnet/Opus tiers by task complexity) is valuable as a reference doc. |
| team | N coordinated agents on shared task list | **Reject** | GSD parallel execution | Heavy runtime dependency. Tmux pane management not portable. |
| ultraqa | QA cycling: test-verify-fix-repeat until goal met | **Cherry-pick pattern** | GSD verify-work is single-pass | The CYCLING concept (max 5 iterations, same-error detection, early exit) is useful. |

### Planning Skills (5)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| omc-plan | Strategic planning with interview workflow | **Reject** | GSD discuss-phase + plan-phase | Overlaps heavily with GSD's existing planning flow. |
| ralplan | Planner+Architect+Critic consensus planning with RALPLAN-DR | **Cherry-pick pattern** | GSD plan-check (partial) | The STRUCTURED DELIBERATION concept (Principles, Decision Drivers, Viable Options, ADR output) is worth synthesizing. Our plan-check is simpler. |
| deep-interview | Socratic interview with mathematical ambiguity gating | **Cherry-pick pattern** | GSD discuss-phase (basic) | The AMBIGUITY SCORING concept and challenge agent modes (Contrarian, Simplifier, Ontologist) are novel. GSD discuss-phase is freeform. |
| analyze | Deep analysis delegation | **Reject** | Standard agent delegation | Just a thin wrapper around debugger agent. No novel pattern. |
| ralph-init | Initialize PRD for ralph | **Reject** | N/A | Specific to ralph runtime. |

### Code Quality Skills (4)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| code-review | Multi-category severity-rated code review | **Cherry-pick pattern** | PAI verification (partial) | The SEVERITY RATING system (CRITICAL/HIGH/MEDIUM/LOW) and STRUCTURED CHECKLIST are worth a reference doc. |
| security-review | Security vulnerability detection | **Reject** | Covered by code-review checklist | Subset of code-review. Not distinct enough for separate doc. |
| tdd | Test-driven development enforcement | **Reject** | Standard TDD | Red-green-refactor is well-documented everywhere. Not project-specific. |
| build-fix | Fix build/TypeScript errors | **Reject** | Standard debugging | Just delegates to build-fixer agent. No novel pattern. |

### Exploration Skills (3)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| deepinit | Generate hierarchical AGENTS.md | **Reject** | Not applicable | OMC-specific documentation format. |
| sciomc | Parallel scientist orchestration for research | **Cherry-pick pattern** | GSD research-phase (partial) | The STRUCTURED RESEARCH PROTOCOL (decompose into stages, parallel execution, cross-validation, synthesis) is strong. Overlaps with our research-phase but more rigorous. |
| external-context | Parallel web search with facet decomposition | **Reject** | Standard web search | Just spawns document-specialist agents. |

### Utility Skills (11)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| learner | Extract reusable skill from conversation | **Cherry-pick pattern** | PAI correction system (partial) | The SKILL EXTRACTION METHODOLOGY (non-Googleable, context-specific, actionable, hard-won quality gates) is excellent. Better than our ad-hoc corrections. |
| note | Tiered persistence (priority/working/manual) | **Cherry-pick pattern** | PAI session-wrap (partial) | The TIERED PERSISTENCE concept (Priority Context always loaded, Working Memory timestamped + pruned, Manual never pruned) is worth a reference doc. |
| cancel | Cancel active modes | **Reject** | N/A | OMC-specific runtime control. |
| hud | Configure HUD display | **Reject** | N/A | OMC-specific UI feature. |
| omc-doctor | Diagnose installation issues | **Reject** | N/A | OMC-specific troubleshooting. |
| omc-setup | Setup wizard | **Reject** | N/A | OMC-specific setup. |
| omc-help | Usage guide | **Reject** | N/A | OMC-specific help. |
| mcp-setup | Configure MCP servers | **Reject** | N/A | OMC-specific MCP configuration. |
| skill | Manage local skills | **Reject** | N/A | OMC-specific skill management. |
| trace | Agent flow timeline | **Reject** | N/A | OMC-specific observability. |
| learn-about-omc | Usage pattern analysis | **Reject** | N/A | OMC-specific analytics. |

### Domain Skills (4)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| project-session-manager | Git worktree + tmux isolation | **Reject** | PAI cw aliases (worktrees) | PAI already has `cw`, `cwa`, `cwb`, `cwc` aliases. PSM adds tmux -- too heavy, not portable. |
| writer-memory | Creative writing memory system | **Reject** | N/A | Korean fiction domain. Not applicable. |
| release | Automated release workflow | **Reject** | N/A | OMC-specific release process. |
| ccg | Claude-Codex-Gemini tri-model orchestration | **Reject** | N/A | Requires Codex + Gemini CLIs. Not portable. |

### Cross-Platform / Integration Skills (5)
| Skill | Description | Cherry-Pick? | GSD/PAI Overlap | Notes |
|-------|-------------|-------------|-----------------|-------|
| ask-codex | Delegate to Codex CLI | **Reject** | N/A | Requires Codex CLI. Not portable. |
| ask-gemini | Delegate to Gemini CLI | **Reject** | N/A | Requires Gemini CLI. Not portable. |
| configure-notifications | Telegram/Discord/Slack integration | **Reject** | N/A | External service dependency. |
| configure-openclaw | Deprecated | **Reject** | N/A | Deprecated by OMC itself. |
| omc-teams | Spawn CLI workers in tmux panes | **Reject** | N/A | Tmux pane management. Not portable. |

### Cherry-Pick Summary

| Pattern | Source Skills | Priority | Reference Doc Name |
|---------|-------------|----------|-------------------|
| Model Routing (agent tier selection) | ultrawork, ralph, sciomc | HIGH | `model-routing.md` |
| Verification Loops (cycling until pass) | ultraqa, ralph, autopilot | HIGH | `verification-loops.md` |
| Session Persistence (tiered note/state survival) | note, ralph, writer-memory | HIGH | `session-persistence.md` |
| Structured Deliberation (multi-agent consensus) | ralplan, deep-interview | MEDIUM | `structured-deliberation.md` |
| Skill Extraction (learning from sessions) | learner | MEDIUM | `skill-extraction.md` |
| Structured Research (parallel investigation) | sciomc | MEDIUM | `structured-research.md` |
| Code Review Protocol (severity-rated checklist) | code-review, security-review | LOW | Consider merging into existing verification reference |

## Cross-Package Pattern Analysis -- Pre-Research

Patterns that appear in 2+ upstreams (GSD, PAUL, OMC):

### Pattern: Task Verification
| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `gsd:verify-work` -- single-pass verification agent | Structured, tied to phase lifecycle | Single pass, no cycling |
| PAUL | Verification protocol in verification-protocol.md | Explicit pass/fail criteria | No automation, manual process |
| OMC | UltraQA -- cycling verification (test-diagnose-fix-repeat, max 5) + Ralph architect verification | Automated cycling, early pattern detection | Heavy runtime dependency |
| **Recommendation** | Synthesize: PAUL's explicit criteria + OMC's cycling concept + GSD's phase-tied execution | | |

### Pattern: Context / State Management
| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `.planning/STATE.md` + structured artifacts for context transfer | Persistent across sessions, git-tracked | No tiered urgency, no auto-pruning |
| PAUL | Context management guidelines | Lightweight | No persistence mechanism |
| OMC | `.omc/notepad.md` (Priority/Working/Manual tiers) + `project-memory.json` + state files | Tiered persistence, auto-pruning, session resilience | Requires MCP tools, OMC-specific |
| **Recommendation** | Synthesize: GSD's git-tracked state + OMC's tiered persistence concept (adapted for our context brackets) | | |

### Pattern: Planning Quality Gates
| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `plan-check` -- checker agent reviews plans | Automated, catches issues before execution | Single reviewer, no structured criteria |
| PAUL | Plan format with explicit fields, scope protection | Structured requirements | No multi-agent review |
| OMC | Ralplan -- Planner+Architect+Critic consensus (max 5 iterations) + RALPLAN-DR structured deliberation | Multi-perspective, bounded iteration, ADR output | Heavy, overkill for small tasks |
| **Recommendation** | Synthesize: PAUL's structured fields (already in task-anatomy.md) + OMC's multi-perspective review concept (adapted as guidance for plan-check) | | |

### Pattern: Model / Agent Routing
| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | Basic model_profile in config.json (quality/speed/cost) | Simple | No per-task routing |
| OMC | Agent tiers (Haiku=LOW, Sonnet=MEDIUM, Opus=HIGH) with explicit complexity matching | Granular, cost-efficient, documented decision guide | Assumes multi-agent runtime |
| **Recommendation** | Use OMC's tier concept as a reference doc -- applicable when spawning explore/executor agents in GSD | | |

### Pattern: Structured Research
| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | `gsd:research-phase` -- single researcher agent | Structured output (RESEARCH.md), confidence levels | Single agent, no parallel investigation |
| OMC | SciOMC -- decompose into stages, parallel scientist agents, cross-validation, synthesis | Parallel, rigorous verification, session persistence | Heavy runtime |
| **Recommendation** | Existing GSD research is adequate. Document OMC's decomposition concept as a reference for complex research tasks. | | |

## Code Examples

### OMC upstream.json Entry
```json
{
  "name": "omc",
  "description": "Oh My ClaudeCode -- multi-agent orchestration with skills, hooks, and execution modes",
  "repo": "https://github.com/Yeachan-Heo/oh-my-claudecode.git",
  "branch": "main",
  "last_checked_sha": "96a5d3725586b18492fb4b8019ec37ba6ffd7b14",
  "last_check": "2026-03-07",
  "cherry_picks": [],
  "notes": "Cherry-pick ideas only -- no runtime dependency on OMC's Node.js infrastructure"
}
```

### AI-Driven Update Command Structure
```markdown
---
name: skippy:update
description: Check all tracked upstreams for changes and suggest cherry-picks
---
<objective>
Iterate all registered upstreams, check for new commits, report changes
conversationally, update tracking data, and suggest potential cherry-picks.
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>
## Step 1: Discover Upstreams

Read all upstream.json files:
- List directories under upstreams/ in the skippy-agentspace repo root
- For each directory, read upstream.json
- Build a list of {name, repo, branch, last_checked_sha, cherry_picks}

## Step 2: Check Each Upstream

For each upstream:
1. Determine cache directory: ~/.cache/skippy-upstream/<name>
2. If cached repo exists, fetch; otherwise clone
3. Get current HEAD SHA
4. Compare against last_checked_sha from upstream.json

## Step 3: Report Changes

For each upstream with changes:
- Show commit count and date range
- List changed files (grouped by area if many)
- If upstream has cherry_picks, highlight changes in those areas
- Suggest potential new cherry-picks based on changed file patterns

For upstreams with no changes:
- Brief "no changes since <date>" line

## Step 4: Update Tracking

For each checked upstream, update its upstream.json:
- Set last_checked_sha to current HEAD
- Set last_check to today's date (ISO 8601)

## Step 5: Cross-Package Analysis Flag

Check if docs/cross-package-analysis.md exists.
If yes, note its 'last reviewed' date.
If any upstream has significant changes (>10 commits or changes in
cherry-picked areas), suggest re-reviewing the analysis document.

Present all findings conversationally. No auto-merge -- human decides.
</process>
```

### Cross-Package Analysis Document Structure
```markdown
# Cross-Package Pattern Analysis

**Last reviewed:** YYYY-MM-DD
**Upstreams analyzed:** GSD (SHA), PAUL (SHA), OMC (SHA)

## Shared Patterns

### [Pattern Name]

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| GSD | ... | ... | ... |
| PAUL | ... | ... | ... |
| OMC | ... | ... | ... |

**Recommendation:** [explicit guidance]
**Reference doc:** [link to best-of-breed doc if created]

## OMC Feature Inventory

### Cherry-Picked
| Feature | What We Took | Reference Doc |
|---------|-------------|---------------|
| ... | ... | ... |

### Rejected
| Feature | Reason | GSD/PAI Equivalent |
|---------|--------|-------------------|
| ... | ... | ... |

### Deferred
| Feature | Why Deferred | Re-evaluate When |
|---------|-------------|-----------------|
| ... | ... | ... |
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.versions` file (key=value) | `upstreams/*/upstream.json` | Phase 5 (v1.1) | Extensible, no code changes to add upstreams |
| Hardcoded repo URLs in shell script | Generic iteration over upstream dirs | Phase 8 (this phase) | Adding new upstream = mkdir + json file |
| Shell script for update checking | AI-driven markdown command | Phase 8 (this phase) | Conversational output, cherry-pick suggestions |
| Single-source reference docs (PAUL only) | Multi-source best-of-breed synthesis | Phase 8 (this phase) | Stronger patterns from multiple perspectives |

**Deprecated/outdated after this phase:**
- `skills/skippy/.versions` -- replaced by upstream.json files
- `skills/skippy/scripts/skippy-update.sh` -- replaced by AI-driven command
- Hardcoded GSD/PAUL references in update command -- replaced by generic upstream iteration

## Open Questions

1. **Cross-package analysis location: `docs/` vs `.planning/`**
   - What we know: CONTEXT.md says "project root level (e.g., docs/ or .planning/)" -- Claude's discretion
   - Recommendation: Use `docs/cross-package-analysis.md` -- this is a project artifact, not a planning artifact. Planning artifacts are phase-scoped; this document spans all phases and persists indefinitely.

2. **How many best-of-breed docs to create?**
   - What we know: Minimum 3 per UPST-03. Analysis identified 6-7 candidate patterns.
   - Recommendation: Start with the 3 HIGH priority ones (model-routing, verification-loops, session-persistence). Add MEDIUM priority ones (structured-deliberation, skill-extraction) if analysis confirms they're substantial enough. Better to have 4-5 excellent docs than 7 thin ones.

3. **SKILL.md update scope**
   - What we know: Adding new reference docs requires updating SKILL.md's reference table.
   - Recommendation: Update the table to include new best-of-breed references, note their multi-source origin.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual validation (shell + markdown project, no test framework) |
| Config file | None |
| Quick run command | `ls upstreams/*/upstream.json && cat upstreams/omc/upstream.json \| jq .` |
| Full suite command | Manual checklist verification |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UPST-01 | OMC upstream.json exists and is valid JSON | smoke | `cat upstreams/omc/upstream.json \| jq .` | Wave 0 |
| UPST-01 | /skippy:update reports OMC status | manual | Run update command, verify OMC appears | Wave 0 |
| UPST-02 | Cross-package analysis document exists | smoke | `test -f docs/cross-package-analysis.md` | Wave 0 |
| UPST-02 | Analysis covers patterns in 2+ upstreams | manual | Review document for pattern comparison tables | Wave 0 |
| UPST-03 | At least 3 best-of-breed reference docs exist | smoke | `ls skills/skippy/references/*.md \| wc -l` (count > 10, was 6) | Wave 0 |
| UPST-03 | Reference docs have evolved format (Source Upstreams, Why This Version) | manual | Read each new doc for required sections | Wave 0 |
| UPST-04 | /skippy:update iterates upstreams/ generically | manual | Read update.md, verify no hardcoded URLs | Wave 0 |
| UPST-04 | .versions file is removed | smoke | `test ! -f skills/skippy/.versions` | Wave 0 |
| UPST-04 | skippy-update.sh is removed | smoke | `test ! -f skills/skippy/scripts/skippy-update.sh` | Wave 0 |

### Sampling Rate
- **Per task commit:** Manual review of changed files
- **Per wave merge:** Full checklist verification
- **Phase gate:** All smoke tests pass + manual review of analysis quality

### Wave 0 Gaps
None -- this is a markdown/documentation-heavy phase. No test infrastructure needed beyond file existence checks and JSON validation via jq.

## Sources

### Primary (HIGH confidence)
- OMC source code at `~/.claude/plugins/cache/omc/oh-my-claudecode/4.7.3/` -- all 37 SKILL.md files read directly
- OMC AGENTS.md (root + skills/) -- full skill catalog and agent catalog
- Existing upstream.json files at `upstreams/gsd/` and `upstreams/paul/`
- CONVENTIONS.md -- upstream.json schema documentation
- Existing reference docs at `skills/skippy/references/` -- 6 files, format established
- Current `skippy-update.sh` and `update.md` -- logic to replace

### Secondary (MEDIUM confidence)
- OMC repo metadata (SHA `96a5d372`, v4.7.3) -- current as of research date
- Cross-package pattern identification -- based on thorough reading of all three upstreams' source

### Tertiary (LOW confidence)
- None -- all findings based on direct source code reading

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new libraries, all patterns established in prior phases
- Architecture: HIGH -- extends existing directory-per-upstream pattern from Phase 5
- OMC inventory: HIGH -- read all 37 SKILL.md files directly from local cache
- Cross-package patterns: HIGH -- based on direct source comparison across all three upstreams
- Best-of-breed selection: MEDIUM -- pattern prioritization is judgment-based, may shift during implementation

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (OMC moves fast -- 1372 PRs merged, check for new skills)
