# Phase 5: Foundation - Research

**Researched:** 2026-03-07
**Domain:** File conventions, JSON registry design, .gitignore patterns
**Confidence:** HIGH

## Summary

Phase 5 establishes two architectural conventions that every subsequent phase (6-10) builds on: (1) a documented public/private content boundary, and (2) an extensible upstream tracking registry. Both are purely structural -- no new dependencies, no complex code, just directories, JSON files, documentation, and .gitignore updates.

The public/private decision is already locked: private content lives externally at `~/.config/pai-private/`, NOT in-repo. The repo itself is entirely public-safe. This is the existing PAI pattern and the phase merely documents and enforces it. The upstream registry replaces the current shell-sourceable `.versions` file with a directory-per-upstream pattern under `upstreams/`, each containing an `upstream.json` with structured metadata. The current `.versions` data is effectively empty (`gsd_hash=none`, `paul_hash=none`, `last_check=never`), making migration trivial -- it's a fresh start.

**Primary recommendation:** Create the `upstreams/` directory structure with two initial upstreams (gsd, paul), write a conventions document covering public/private boundaries, update `.gitignore`, and remove the old `.versions` file. No scripts need modification in this phase -- Phase 8 handles the `skippy-update.sh` rewrite.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Private content lives externally at `~/.config/pai-private/` -- NOT in-repo gitignored. The repo itself is entirely public-safe (committable). No `private/` directory inside the repo.
- Document which content types are public (skills, references, commands, tools) vs private (API keys, personal preferences, memory files).
- .gitignore updated to reflect this convention but the heavy lifting is architectural -- private content simply never enters the repo.
- JSON format for upstream registry -- aligns with AI-agent-driven operations and matches `marketplace.json` precedent.
- File name: `upstream.json` (not `upstream.conf` -- JSON content should have JSON extension).
- Each upstream directory under `upstreams/` contains its own `upstream.json` with: repo URL, branch, last-checked SHA, and any upstream-specific metadata.
- Adding a new upstream = creating a new directory under `upstreams/` with the standard `upstream.json` -- no code changes required.
- Shell scripts ONLY for prerequisite validation (bun, jq, git, bash 4+). All actual install, config, and update operations live in markdown instruction files designed to be executed by AI agents.
- `.versions` currently contains effectively empty data. Fresh start with new format. No formal migration needed. `.versions` file removed after `upstreams/gsd/upstream.json` and `upstreams/paul/upstream.json` are created.
- `upstreams/` at repo root. Two initial directories: `upstreams/gsd/` and `upstreams/paul/`.
- Phase 8 will add `upstreams/omc/` -- the structure must accommodate this without changes.
- Each upstream directory is self-contained: `upstream.json` plus any upstream-specific files.

### Claude's Discretion
- Exact fields in `upstream.json` beyond the required (repo, branch, sha) -- planner determines what metadata is useful.
- How the public/private convention is documented (standalone doc vs section in CLAUDE.md vs both).
- Whether to create a `CONVENTIONS.md` or similar architectural reference doc.

### Deferred Ideas (OUT OF SCOPE)
- OMC as third upstream (Phase 8 -- `upstreams/omc/`)
- Rewriting `skippy-update.sh` to use generic upstream checker (Phase 8 -- UPST-04)
- Replacing `tools/install.sh` with agent-driven INSTALL.md (Phase 9-10)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FOUN-01 | Public/private content boundary is defined and documented | Convention doc defining public (skills, references, commands, tools, scripts) vs private (API keys, credentials, personal preferences, memory files). Private content lives at `~/.config/pai-private/`, never enters repo. .gitignore additions as safety net. |
| FOUN-02 | Extensible upstream registry replaces hardcoded GSD+PAUL tracking | `upstreams/` directory with `upstreams/gsd/upstream.json` and `upstreams/paul/upstream.json`. JSON format with repo, branch, sha, and metadata fields. |
| FOUN-03 | Adding a new upstream is creating a directory, not changing code | Drop-in pattern: create `upstreams/<name>/upstream.json` with the standard schema. No script or code changes. Phase 8 validates this by adding `upstreams/omc/`. |
| FOUN-04 | Existing `.versions` data migrated to new upstream format | Current `.versions` has `gsd_hash=none`, `paul_hash=none`, `last_check=never` -- effectively empty. Fresh start: create `upstream.json` files with these initial values, then remove `.versions`. |
</phase_requirements>

## Standard Stack

### Core

This phase has zero library or tool dependencies. Everything is plain files.

| Component | Format | Purpose | Why Standard |
|-----------|--------|---------|--------------|
| upstream.json | JSON | Per-upstream tracking metadata | User decision: matches marketplace.json precedent, AI-agent-friendly |
| CONVENTIONS.md | Markdown | Public/private boundary documentation | Standard docs pattern for this repo |
| .gitignore | gitignore | Safety net for private content patterns | Git standard |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| jq | any | Validate upstream.json during testing | Only for validation -- not a runtime dependency in this phase |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSON (upstream.json) | Bash key=value (upstream.conf) | Original STACK.md recommendation. User overrode: JSON aligns with marketplace.json and is AI-agent parseable. Correct decision. |
| In-repo `core/private/` gitignored | External `~/.config/pai-private/` | User overrode: external location means private content never touches the repo at all. Stronger guarantee than gitignore. |
| YAML/TOML | JSON | No parser needed beyond jq. JSON is the repo's existing metadata format. |

## Architecture Patterns

### Recommended Project Structure (after Phase 5)

```
skippy-agentspace/
  upstreams/
    gsd/
      upstream.json         # GSD tracking metadata
    paul/
      upstream.json         # PAUL tracking metadata
  skills/
    skippy/
      SKILL.md
      .versions             # REMOVED (replaced by upstreams/)
      commands/
      references/
      scripts/
  tools/
  .claude-plugin/
  CLAUDE.md
  CONVENTIONS.md            # NEW: public/private boundary + upstream conventions
  INDEX.md
  .gitignore                # UPDATED: private content safety patterns
```

### Pattern 1: Directory-as-Registry Entry

**What:** Each upstream is a self-contained directory under `upstreams/`. The directory name IS the upstream identifier. The directory contains an `upstream.json` with a fixed schema plus any upstream-specific files (cherry-pick notes, analysis docs).

**When to use:** Any time a new framework, tool, or upstream source needs tracking.

**Example:**

```json
{
  "name": "gsd",
  "description": "Get Shit Done -- phased execution framework for Claude Code",
  "repo": "https://github.com/gsd-build/get-shit-done.git",
  "branch": "main",
  "last_checked_sha": "none",
  "last_check": "never",
  "cherry_picks": [],
  "notes": "Base infrastructure -- we augment, never modify"
}
```

**Schema field rationale:**

| Field | Required | Type | Purpose |
|-------|----------|------|---------|
| `name` | yes | string | Human-readable identifier, matches directory name |
| `description` | yes | string | One-line summary of what this upstream provides |
| `repo` | yes | string (URL) | Git clone URL |
| `branch` | yes | string | Branch to track (usually "main") |
| `last_checked_sha` | yes | string | SHA of the last commit we checked, or "none" for never-checked |
| `last_check` | yes | string | ISO 8601 date or "never" |
| `cherry_picks` | no | string[] | List of ideas/features extracted from this upstream |
| `notes` | no | string | Freeform context about the relationship |

**Why these fields:**
- `name`, `repo`, `branch`, `last_checked_sha`, `last_check` -- direct mapping from the `.versions` data model, just structured
- `description` -- critical for AI agents that iterate upstreams to understand what they're looking at
- `cherry_picks` -- provenance tracking; when Phase 8 adds cherry-pick analysis, this field records what was taken
- `notes` -- captures the relationship (parasitic, cherry-pick-only, etc.)

### Pattern 2: Convention Documentation

**What:** A standalone `CONVENTIONS.md` at repo root documents the public/private split and the upstream registry pattern. This serves as the canonical reference for all subsequent phases.

**When to use:** Any time a developer or AI agent needs to understand "where does this content go?" or "how do I add an upstream?"

**Recommended sections:**

1. **Content Classification** -- table of what's public vs private with examples
2. **Private Content Location** -- `~/.config/pai-private/` with directory structure
3. **Upstream Registry** -- how `upstreams/` works, schema reference, adding a new upstream
4. **Installation Philosophy** -- shell scripts for prereqs only, markdown instructions for AI agents

### Anti-Patterns to Avoid

- **In-repo private directory:** Do NOT create `private/`, `core/private/`, or any gitignored directory for sensitive content. The locked decision is: private content lives at `~/.config/pai-private/`. Period.
- **Over-engineering the JSON schema:** Start with the fields above. Don't add version ranges, dependency graphs, or complex metadata. Phase 8 can extend if needed.
- **Modifying skippy-update.sh:** This phase creates the data structure. Phase 8 rewrites the script to consume it. Don't touch the script now.
- **Creating a JSON Schema file:** Premature. The schema is simple enough to document in CONVENTIONS.md. A formal `.schema.json` adds maintenance overhead without value at 2-3 upstreams.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON validation | Custom bash JSON parser | `jq` for validation checks | Bash can't reliably parse JSON. jq is the standard. |
| Private content detection | git hooks scanning for patterns | External directory convention | Architectural prevention > detection. Private content at `~/.config/pai-private/` never enters the repo. |
| Upstream discovery | Script that scans for upstream.json files | `ls upstreams/` or `for dir in upstreams/*/` | The directory structure IS the registry. No discovery code needed. |

**Key insight:** This phase is almost entirely documentation and file creation. The power is in the convention, not in code. The `upstreams/*/upstream.json` pattern is self-describing -- `ls upstreams/` is the registry query.

## Common Pitfalls

### Pitfall 1: Roadmap/CONTEXT.md Format Discrepancy

**What goes wrong:** The ROADMAP.md success criteria #2 says `upstream.conf` (bash key=value format). The CONTEXT.md locks the decision as `upstream.json` (JSON format). If the planner follows the roadmap literally, they'll create the wrong format.

**Why it happens:** ROADMAP.md was written before the context discussion that changed the format from conf to JSON.

**How to avoid:** Follow CONTEXT.md decisions (JSON/upstream.json). The roadmap text is aspirational; the CONTEXT.md decisions are authoritative. Optionally update the roadmap after this phase.

**Warning signs:** Any plan that creates `upstream.conf` instead of `upstream.json`.

### Pitfall 2: Forgetting to Remove .versions

**What goes wrong:** Creating the new `upstreams/` structure but leaving `.versions` in place. `skippy-update.sh` continues reading `.versions` (which is fine -- Phase 8 handles the script rewrite), but having two tracking systems creates confusion about which is authoritative.

**Why it happens:** Fear of breaking the existing `skippy-update.sh` command.

**How to avoid:** The CONTEXT.md explicitly says: "`.versions` file removed after `upstreams/gsd/upstream.json` and `upstreams/paul/upstream.json` are created." The script will still run -- it initializes `.versions` if missing (line 17-21 of `skippy-update.sh`). It will just reset to `none/none/never`, which is the same as the current state.

**Warning signs:** Both `.versions` and `upstreams/*/upstream.json` existing after phase completion.

### Pitfall 3: Scope Creep into Script Modifications

**What goes wrong:** Modifying `skippy-update.sh` to read the new `upstream.json` format. This is Phase 8's job (UPST-04).

**Why it happens:** Natural instinct to make the new data format actually consumed by something.

**How to avoid:** Phase 5 establishes the structure. Phase 8 rewrites the consumer. The CONTEXT.md deferred list explicitly calls this out.

**Warning signs:** Any plan task that modifies files in `skills/skippy/scripts/`.

### Pitfall 4: Overly Complex .gitignore Additions

**What goes wrong:** Adding elaborate gitignore patterns for private content that doesn't exist in the repo and never will.

**Why it happens:** The convention says "private content never enters the repo" but developers feel compelled to add safety-net patterns anyway.

**How to avoid:** Add minimal, sensible patterns as a safety net (e.g., `*.secret`, `.env.local`, common credential file names). Don't try to enumerate every possible private file. The architectural decision (external directory) is the primary protection.

**Warning signs:** More than 10 lines added to .gitignore for "private content patterns."

## Code Examples

### upstream.json for GSD

```json
{
  "name": "gsd",
  "description": "Get Shit Done -- phased execution framework for Claude Code",
  "repo": "https://github.com/gsd-build/get-shit-done.git",
  "branch": "main",
  "last_checked_sha": "none",
  "last_check": "never",
  "cherry_picks": [],
  "notes": "Base infrastructure -- we augment, never modify"
}
```

### upstream.json for PAUL

```json
{
  "name": "paul",
  "description": "Plan-Apply-Unify Loop -- structured planning framework",
  "repo": "https://github.com/ChristopherKahler/paul.git",
  "branch": "main",
  "last_checked_sha": "none",
  "last_check": "never",
  "cherry_picks": [
    "context-brackets",
    "mandatory-reconciliation",
    "task-anatomy",
    "plan-boundaries",
    "state-consistency"
  ],
  "notes": "5 ideas cherry-picked as reference docs in skills/skippy/references/"
}
```

### Existing .versions Content (being replaced)

```bash
# Current content of skills/skippy/.versions
gsd_hash=none
paul_hash=none
last_check=never
```

### Minimal .gitignore Additions

```gitignore
# Private content safety net
# Primary protection: private content lives at ~/.config/pai-private/
# These patterns are a secondary defense against accidental inclusion
*.secret
*.credentials
*.private
credentials/
secrets/
```

### CONVENTIONS.md Structure (skeleton)

```markdown
# Conventions

## Content Classification

| Type | Classification | Location | Examples |
|------|---------------|----------|----------|
| Skills | Public | `skills/` in repo | SKILL.md, commands/, references/ |
| References | Public | `skills/*/references/` | context-brackets.md, plan-boundaries.md |
| Commands | Public | `skills/*/commands/` | reconcile.md, update.md, cleanup.md |
| Tools/Scripts | Public | `tools/`, `skills/*/scripts/` | install.sh, skippy-update.sh |
| Plugin metadata | Public | `.claude-plugin/` | marketplace.json |
| API keys/tokens | Private | `~/.config/pai-private/` | Never in repo |
| Personal preferences | Private | `~/.config/pai-private/memory/` | MEMORY.md |
| Credential patterns | Private | `~/.config/pai-private/rules/` | Security protocols |
| MCP server configs | Private | Machine-specific | IP addresses, ports |

## Upstream Registry

[Schema documentation, how to add a new upstream]

## Installation Philosophy

[Shell scripts for prereqs only, markdown instructions for AI agents]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Shell key=value `.versions` | JSON `upstream.json` per upstream | Phase 5 (this phase) | AI-parseable, structured, extensible |
| Two hardcoded repos in `skippy-update.sh` | Directory-per-upstream registry | Phase 5 (this phase) | Adding upstream = creating directory, not editing code |
| Implicit public/private understanding | Documented convention in CONVENTIONS.md | Phase 5 (this phase) | All subsequent phases know where content goes |

**Deprecated/outdated:**
- `skills/skippy/.versions`: Replaced by `upstreams/*/upstream.json`. Remove after upstreams are created.

## Open Questions

1. **Cherry-picks field: list of strings or list of objects?**
   - What we know: PAUL's cherry-picks are currently documented in SKILL.md and references/. A simple string list names them. An object list could add dates, source files, etc.
   - What's unclear: Will Phase 8's cross-package analysis need richer metadata per cherry-pick?
   - Recommendation: Start with string list (simple). Phase 8 can extend to objects if needed. JSON is forward-compatible for this change.

2. **CONVENTIONS.md vs CLAUDE.md section**
   - What we know: CLAUDE.md is already 87 lines (compact). Adding conventions there keeps everything in one file but makes it longer.
   - What's unclear: Whether AI agents will load CONVENTIONS.md on their own, or if it needs to be referenced from CLAUDE.md.
   - Recommendation: Standalone CONVENTIONS.md with a one-line reference from CLAUDE.md ("See CONVENTIONS.md for content classification and upstream registry docs"). Keeps CLAUDE.md focused on cold-session orientation.

3. **last_check field: ISO 8601 or simple date?**
   - What we know: Current `.versions` uses `YYYY-MM-DD` format (from `date +%Y-%m-%d` in skippy-update.sh).
   - What's unclear: Whether Phase 8's generic checker will need timestamps or just dates.
   - Recommendation: Use ISO 8601 date string (`"2026-03-07"`) for consistency. Full datetime isn't needed -- we care about the day, not the minute.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bash + manual verification (no test framework -- this is a convention/docs phase) |
| Config file | none |
| Quick run command | `ls upstreams/*/upstream.json && jq . upstreams/*/upstream.json` |
| Full suite command | `jq . upstreams/gsd/upstream.json && jq . upstreams/paul/upstream.json && test ! -f skills/skippy/.versions && test -f CONVENTIONS.md && echo "PASS"` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUN-01 | Public/private boundary documented | manual | `test -f CONVENTIONS.md && grep -q "Content Classification" CONVENTIONS.md` | No -- Wave 0 |
| FOUN-02 | Upstream registry exists with gsd + paul | smoke | `ls upstreams/gsd/upstream.json upstreams/paul/upstream.json` | No -- Wave 0 |
| FOUN-03 | New upstream = new directory only | smoke | `mkdir -p upstreams/test-upstream && cp upstreams/gsd/upstream.json upstreams/test-upstream/ && ls upstreams/test-upstream/upstream.json && rm -rf upstreams/test-upstream` | No -- Wave 0 |
| FOUN-04 | .versions data migrated, .versions removed | smoke | `test ! -f skills/skippy/.versions && jq -e '.last_checked_sha' upstreams/gsd/upstream.json` | No -- Wave 0 |

### Sampling Rate

- **Per task commit:** `ls upstreams/*/upstream.json && jq . upstreams/*/upstream.json 2>/dev/null`
- **Per wave merge:** Full suite command (above)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `upstreams/gsd/upstream.json` -- covers FOUN-02, FOUN-04
- [ ] `upstreams/paul/upstream.json` -- covers FOUN-02, FOUN-04
- [ ] `CONVENTIONS.md` -- covers FOUN-01
- [ ] `.gitignore` updates -- covers FOUN-01
- [ ] Removal of `skills/skippy/.versions` -- covers FOUN-04

*(All gaps are the deliverables themselves -- this phase creates net-new files, not code that needs testing infrastructure.)*

## Sources

### Primary (HIGH confidence)

- `skills/skippy/.versions` -- direct inspection of current tracking file (3 lines, all "none/never")
- `skills/skippy/scripts/skippy-update.sh` -- direct inspection of script that reads .versions (122 lines)
- `.claude-plugin/marketplace.json` -- JSON format precedent in this repo
- `.planning/phases/05-foundation/05-CONTEXT.md` -- locked user decisions
- `.planning/research/STACK.md` -- original stack recommendations (overridden by CONTEXT.md for format choice)
- `.planning/research/SUMMARY.md` -- project research summary with architecture patterns

### Secondary (MEDIUM confidence)

- `.planning/research/FEATURES.md` -- public/private split analysis from project research phase

### Tertiary (LOW confidence)

None. This phase's domain is entirely within the existing codebase and locked decisions. No external research needed.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- zero dependencies, plain files only
- Architecture: HIGH -- locked decisions from CONTEXT.md, well-understood directory patterns
- Pitfalls: HIGH -- all pitfalls derived from direct inspection of existing code and explicit CONTEXT.md constraints

**Research date:** 2026-03-07
**Valid until:** indefinite (conventions don't expire; no external dependencies to version-drift)
