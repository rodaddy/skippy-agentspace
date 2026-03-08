# Phase 8: Upstream Analysis - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Add OMC as third tracked upstream source alongside GSD and PAUL, perform systematic cross-package pattern analysis across all three upstreams, create best-of-breed reference docs synthesizing the strongest implementations, and make `/skippy:update` a generic AI-driven command that works against any registered upstream.

</domain>

<decisions>
## Implementation Decisions

### Cross-Package Pattern Analysis
- Detailed comparison for each shared pattern: side-by-side implementation comparison, strengths/weaknesses, explicit recommendation
- Cast a wide net across all OMC skills/features -- systematic scan, not just pre-identified candidates
- For patterns in 2+ upstreams: synthesize the best from all sources unless one is a clear winner, then use that
- Analysis doc lives at project root level (e.g., docs/ or .planning/) -- a project artifact, not a skill deliverable
- Living document with 'last reviewed' timestamp -- /skippy:update flags for re-review when OMC adds new features

### Best-of-Breed Reference Docs
- Evolved format from existing PAUL reference docs: add structured sections like 'Source Upstreams', 'Why This Version', 'Integration Points'
- Credit sources inline (e.g., "Context management: GSD's approach with OMC's notepad persistence") -- traceability for future updates
- Count determined by analysis -- create a doc for every pattern worth synthesizing, quality over quantity (minimum 3 per requirement)
- Location: skills/skippy-dev/references/ alongside existing PAUL reference docs

### Generic Upstream Checker
- /skippy:update becomes an AI-driven command (markdown instructions that Claude executes interactively) instead of a shell script
- The command iterates upstreams/*/upstream.json, fetches each repo, compares SHAs, reports changes conversationally, and can suggest cherry-picks
- Updates upstream.json files in-place (writes new last_checked_sha and last_check after each run)
- .versions file removed immediately -- clean break, upstream.json is sole source of truth
- skippy-update.sh either removed or replaced with the AI-driven command.md

### OMC Cherry-Pick Scope
- Full systematic scan of all 30+ OMC skills/features -- categorize each as: cherry-pick, reject with reason, or defer
- Document rejection reasons (same approach as PAUL rejection table) -- future-proofs against re-evaluation
- Map overlaps: for each OMC feature, note if GSD/PAI already covers it and whether OMC's version is better
- Analysis is a living document that /skippy:update can flag when OMC adds new features

### Claude's Discretion
- Exact organization of the cross-package analysis document
- Which specific patterns qualify as "best-of-breed" vs too niche
- Technical implementation of the AI-driven update command
- How to handle OMC features that are PAI-specific (personas, homekit, etc.) in the analysis

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `upstreams/gsd/upstream.json` and `upstreams/paul/upstream.json`: established schema template for OMC entry
- `skills/skippy-dev/references/`: 5 existing PAUL reference docs as format examples
- `skills/skippy-dev/commands/update.md`: existing command definition to evolve
- `skills/skippy-dev/scripts/skippy-update.sh`: fetch_repo() and report_changes() functions as logic reference

### Established Patterns
- Directory-per-upstream pattern (Phase 5): `upstreams/<name>/upstream.json`
- upstream.json schema: name, description, repo, branch, last_checked_sha, last_check, cherry_picks, notes
- Reference docs: ~2-5KB markdown, actionable guidance, in skills/skippy-dev/references/
- Commands: markdown files in skills/skippy-dev/commands/ that Claude executes

### Integration Points
- `/skippy:update` command entry point: skills/skippy-dev/commands/update.md
- Upstream registry: upstreams/ directory (gsd, paul, will add omc)
- SKILL.md: skills/skippy-dev/SKILL.md references commands and references
- OMC source: cached at ~/.claude/plugins/cache/omc/oh-my-claudecode/ and repo at https://github.com/Yeachan-Heo/oh-my-claudecode.git

</code_context>

<specifics>
## Specific Ideas

- OMC repo: https://github.com/Yeachan-Heo/oh-my-claudecode.git (also cached locally at ~/.claude/plugins/cache/omc/)
- Research identified initial candidates: ralplan, learner, deepsearch, persistent notepad -- but full scan should discover more
- The shift from shell script to AI-driven command aligns with Phase 5's decision that "all actual install/config/update operations live in markdown instruction files designed for AI agents"

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 08-upstream-analysis*
*Context gathered: 2026-03-07*
