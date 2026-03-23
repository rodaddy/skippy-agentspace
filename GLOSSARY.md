# Glossary

Project-specific terminology for skippy-agentspace. All agents and contributors use these definitions.

## Domain Terms

| Term | Definition | NOT This |
|------|-----------|----------|
| **Ability** | A deduplicated, cross-source capability that emerges from coalescing overlapping patterns across multiple upstream sources. | A raw command or skill -- abilities are the distilled output of the coalesce step. |
| **Absorbed From** | The upstream marketplace or plugin a skill was adapted from, recorded in SKILL.md frontmatter as `absorbed_from`. | Direct copy -- absorbed skills are rewritten for portability and standalone use. |
| **Antagonist** | A reviewer agent whose explicit job is to break an implementation -- find edge cases, security gaps, and integration failures. | A quality reviewer -- the antagonist attacks; the quality reviewer checks correctness. |
| **Audit Cycle** | The Pattern 4 orchestration pattern: spawn specialist reviewers, aggregate findings to a shared board, fix, and re-evaluate (max 3 iterations). | A one-shot code review -- audit cycles loop until clean. |
| **Audit Swarm** | The multi-agent review process where specialist agents (security, quality, architecture, consistency) run in parallel and write findings to a shared board. | A single-agent review -- swarms are parallel, multi-perspective, and aggregated. |
| **Cherry-Pick** | A specific pattern or idea extracted from an upstream and adopted into this project, tracked in `upstreams/*/upstream.json`. | A git cherry-pick -- this is a conceptual adoption, not necessarily a commit operation. |
| **Checkpoint** | A structured STATE.md snapshot taken before a phase ends, a session closes, or context compaction occurs, used to resume work without conversation history. | A git commit -- checkpoints are planning artifacts, not version control. |
| **Coalesce** | The pipeline step that merges all consumed patterns from multiple sources into deduplicated abilities, resolving overlaps. | A merge -- coalesce discards duplicates and synthesizes; it does not concatenate. |
| **Command** | A slash command (`/skill:action`) defined in a skill's `commands/` directory that users or agents invoke directly. | A shell script or bash function -- commands are Claude Code slash commands, not executables. |
| **Compaction Resilience** | The practice of checkpointing state before Claude Code's context window compacts, so the next context window can resume cleanly. | Crash recovery -- compaction is a normal, scheduled event, not an error. |
| **Consume** | The pipeline step that audits a marketplace or plugin, classifies its commands, and extracts reusable patterns for coalescing. | Install -- consuming does not add anything to the user's environment; it audits and extracts. |
| **Context Brackets** | The pattern of self-monitoring context window usage and triggering a checkpoint before hitting compaction thresholds. | A code comment or documentation block. |
| **Cross-Package Analysis** | A review of patterns across all tracked upstreams to identify shared abstractions and redundancies -- stored in `docs/cross-package-analysis.md`. | Per-upstream analysis -- cross-package analysis compares across sources, not within one. |
| **Drive** | The `/drive` persistence loop skill: works through PRD stories until ALL acceptance criteria pass and an architect verifies the result. | Autopilot -- drive is story-driven with explicit verification; autopilot is idea-to-code autonomous. |
| **Eval** | The pipeline step that runs Karpathy-style binary assertion loops per ability and auto-fixes failures. | Manual testing -- evals are automated, assertion-based, and repeatable. |
| **Findings Board** | The shared markdown file at `.reports/skippy-review/findings-{timestamp}.md` where all audit swarm agents write their severity-rated findings. | Individual agent output -- the board is the single aggregated source of truth for a review cycle. |
| **Hook** | A TypeScript script registered in Claude Code's `settings.json` that intercepts tool calls to enforce a LAW before execution. | A git hook -- these are Claude Code pre-tool-use hooks, not version control hooks. |
| **LAW** | One of 15 mandatory, non-negotiable rules governing agent behavior, each enforced by a corresponding hook. | A guideline, best practice, or suggestion -- LAWs have no exceptions. |
| **Marketplace** | A Claude Code plugin repository that ships multiple skills installable via `/plugin install`. | A package registry (npm, PyPI) -- marketplaces ship Claude Code skills, not language packages. |
| **Model Routing** | The practice of matching agent complexity (HIGH/MEDIUM/LOW) to the appropriate model tier (opus/sonnet/haiku) based on task complexity. | Load balancing -- model routing is a deliberate cost/quality tradeoff, not traffic distribution. |
| **Open Brain** | The external Second Brain knowledge base (MCP server) providing semantic vector search across decisions, learnings, and session history. | The `brain` skill -- Open Brain is the backend; `/brain` is the skill that queries it. |
| **Parallel File Ownership** | The constraint that no two concurrently running agents modify the same file -- enforced via explicit scope boundaries in agent prompts. | Lock files or mutexes -- file ownership is a planning constraint, not a runtime mechanism. |
| **PAI** | Personal AI Infrastructure -- the multi-persona AI system that skippy-agentspace packages as portable installable skills. | The repo itself -- PAI is the broader private infrastructure; this repo is its portable public subset. |
| **Persona** | A named communication style (Skippy, Bob, Clarisa, April) that shapes an agent's judgment, tone, and priorities for a given task phase. | A user account or role -- personas are prompt fragments injected to change thinking style. |
| **Phase Handoff** | The Pattern 5 orchestration pattern for transferring state between execution phases, sessions, or compaction events via structured artifacts. | Session notes or conversation summaries -- handoffs use parseable STATE.md files, not prose. |
| **Phased Execution** | The GSD-derived pattern of organizing work into numbered phases with wave-based parallelism within each phase. | Sequential task lists -- phased execution allows parallel agent dispatch within a phase. |
| **Plan Boundaries** | Explicit "DO NOT CHANGE" scope declarations written into a PLAN.md to prevent agents from touching out-of-scope work. | Acceptance criteria -- boundaries define what is excluded; criteria define what must pass. |
| **Portability Tier** | A classification (Fully portable / Degraded without infra / Requires setup) indicating a skill's runtime dependencies and fallback behavior. | A quality rating -- portability tiers describe infrastructure requirements, not skill quality. |
| **PRD** | Product Requirements Document -- the machine-readable `.prd/prd.json` file containing stories, acceptance criteria, and shell verify commands. | A spec document or README -- a PRD in this project has executable verify commands and drives autonomous execution. |
| **Pre-Execution Gate** | The pattern of intercepting vague requests before any code is written to force planning, clarification, and scope definition. | Input validation -- the gate is a workflow checkpoint, not a data check. |
| **Pre-Flight** | Baseline checks (tests, typecheck, build) run before any story work begins to document the starting state and catch known issues early. | CI/CD checks -- pre-flight is a one-time baseline capture, not a continuous pipeline. |
| **Quality Reviewer** | A reviewer agent that checks correctness against acceptance criteria, error handling, test coverage, and code patterns -- distinct from the antagonist. | The antagonist -- the quality reviewer validates; the antagonist attacks. |
| **qmd** | The semantic vector search MCP server (local SQLite + vec0) that indexes all project files for federated knowledge + codebase search. | A generic search tool -- qmd is the specific MCP server used in this project, queried via `mcp2cli`. |
| **Reconcile** | The `/skippy:reconcile` command: compare what was planned (PLAN.md) vs what was actually done (SUMMARY.md) and report deviations. | A git diff -- reconcile compares planning artifacts, not code changes. |
| **Reference Doc** | A standalone markdown file in `skills/*/references/` containing a workflow pattern or rule that agents load on demand. | Documentation -- reference docs are prompt fragments injected into agent context, not user-facing docs. |
| **Skill** | A self-contained directory under `skills/` with a SKILL.md, optional commands, references, and scripts that provide a named capability. | A plugin or package -- skills have no runtime dependencies on each other and require no build step. |
| **Skill Chain** | The Pattern 3 orchestration pattern of invoking skills sequentially where the output of one feeds the next. | A workflow engine -- skill chains are templates the human (or orchestrating agent) follows, not automated pipelines. |
| **Skill Extraction** | The process of promoting a recurring correction or pattern into a formal reference doc, then into a full skill. | Refactoring -- extraction elevates a pattern into reusable, installable form. |
| **Skill Stack** | The Pattern 2 orchestration pattern of loading multiple reference docs simultaneously for deep work in a single domain. | Dependency injection -- stacking is additive context loading, not code dependency resolution. |
| **STATE.md** | The authoritative current-phase progress file updated at every phase transition, used as the single source of truth for project status. | A changelog or log file -- STATE.md is always current, never append-only historical. |
| **Story** | A unit of work in a PRD with an id, title, acceptance criteria, and shell verify commands; the atom of PRD-driven execution. | A GitHub issue or ticket -- stories in this project must have executable verify commands to be valid. |
| **Upstream** | A tracked external marketplace or plugin (GSD, OMC, PAUL) whose patterns were consumed during the audit, tracked in `upstreams/*/upstream.json`. | A git remote or dependency -- upstreams are monitored for cherry-picks, not synced automatically. |
| **Verify Command** | A shell command in a PRD story whose exit code (0 = pass) and stdout patterns determine whether an acceptance criterion is met. | A test -- verify commands are the contractual proof that a story is done, not developer-owned test cases. |

## Technical Terms

| Term | Definition | NOT This |
|------|-----------|----------|
| **Absorbed From** | The `absorbed_from` SKILL.md frontmatter field recording the upstream source a skill was adapted from. | A dependency declaration -- it is attribution metadata, not a runtime link. |
| **`bats-core`** | The Bash Automated Testing System used for unit tests in `tests/` -- tests run in a sandboxed HOME directory. | bats the animal -- it is a shell testing framework. |
| **Cache Poisoning** | The failure mode where a reviewer agent reads stale cached LLM responses from a previous agent's turn, producing incorrect findings. | A security attack -- in this project it refers to LLM semantic cache cross-contamination between agents. |
| **`common.sh`** | The shared shell library at `tools/lib/common.sh` providing `skippy_*` helper functions for all `tools/` scripts. | A utility available to skill scripts -- skill scripts are standalone and do NOT source `common.sh`. |
| **Complexity Tier** | The HIGH/MEDIUM/LOW classification of an agent task that determines which model to use (opus/sonnet/haiku). | A priority level -- complexity tiers drive model selection, not scheduling order. |
| **Evidence** | The per-story JSON file in `.prd/evidence/US-NNN.json` capturing command output, exit codes, and git commit at verification time. | Narrative proof or assertions -- evidence is command output captured by a separate verifier agent. |
| **`index-sync.sh`** | The tool that auto-generates `INDEX.md` from `skills/*/SKILL.md` frontmatter -- run `--generate` to rebuild. | A database index -- it generates the skill catalog markdown file. |
| **`marketplace.json`** | The plugin manifest at `.claude-plugin/marketplace.json` that lists all skills available for `/plugin install`. | A package.json -- it is a Claude Code plugin registry file, not a Node.js manifest. |
| **`nocache` alias** | A LiteLLM model alias (e.g., `sonnet-nocache`) that bypasses semantic caching -- mandatory for reviewer and antagonist agents to prevent cross-agent cache poisoning. | A cache-busting HTTP header -- it is a LiteLLM routing alias. |
| **PDOC** | Plan, Discussion, Options, Conclusion -- the structured deliberation framework for architecture decisions. | A file format or tool -- PDOC is a 4-part reasoning template. |
| **`skippy_` prefix** | The namespace convention for all shared functions in `common.sh` (`skippy_pass`, `skippy_fail`, etc.) and `_SKIPPY_` for private variables. | A global namespace for all project code -- only `tools/lib/common.sh` functions use this prefix. |
| **`upstream.json`** | The tracking file per upstream in `upstreams/<name>/upstream.json` recording last-checked SHA, cherry-picks, and metadata. | A lock file -- it is a manual tracking record updated by `/skippy:update`. |
| **Wave** | A batch of independent agent tasks within a phase that can be dispatched in parallel -- agents in the same wave have non-overlapping file ownership. | A deployment wave -- in this project, waves are parallel execution batches within a phase. |

## Abbreviations

| Abbrev | Expansion |
|--------|-----------|
| **AFK** | Away From Keyboard -- classification for PRD stories that can execute autonomously without user interaction. |
| **DDD** | Domain-Driven Design -- the origin of the "ubiquitous language" pattern that the `/ubiquitous-language` skill is based on. |
| **GSD** | Get Shit Done -- the upstream Claude Code skill framework at `gsd-build/get-shit-done`. |
| **HITL** | Human In The Loop -- classification for PRD stories requiring user interaction or manual checks. |
| **LAW** | Mandatory AI behavior rule (not an acronym) -- 15 total, all hook-enforced. |
| **OMC** | Oh My Claude Code -- the upstream Claude Code plugin framework at `anthropics/oh-my-claudecode`. |
| **PAI** | Personal AI Infrastructure -- Rico's multi-persona AI system that this repo packages as portable skills. |
| **PAUL** | Planning and Ubiquitous Language -- the upstream framework at `ChristopherKahler/paul`, source of 5 planning discipline patterns. |
| **PDOC** | Plan, Discussion, Options, Conclusion -- structured deliberation framework for architecture decisions. |
| **PRD** | Product Requirements Document -- machine-readable story tracker with executable verify commands. |
| **qmd** | Query My Docs -- the local semantic vector search MCP server. |
| **SHA** | Git commit hash -- used in `upstream.json` to track last-checked upstream state. |
| **US** | User Story -- prefix for story IDs in PRDs (e.g., `US-001`). |
