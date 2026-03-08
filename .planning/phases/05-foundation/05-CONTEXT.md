# Phase 5: Foundation - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the architectural conventions that all subsequent phases (6-10) build on: a documented public/private content boundary with .gitignore enforcement, and an extensible upstream registry that replaces the hardcoded GSD+PAUL tracking in `.versions`.

</domain>

<decisions>
## Implementation Decisions

### Public/private boundary
- Private content lives externally at `~/.config/pai-private/` -- the existing PAI pattern. NOT in-repo gitignored.
- The repo itself is entirely public-safe (committable). No `private/` directory inside the repo.
- Document which content types are public (skills, references, commands, tools) vs private (API keys, personal preferences, memory files).
- .gitignore updated to reflect this convention but the heavy lifting is architectural -- private content simply never enters the repo.

### Upstream registry format
- JSON format -- aligns with AI-agent-driven operations and matches `marketplace.json` precedent.
- File name: `upstream.json` (not `upstream.conf` -- JSON content should have JSON extension).
- Each upstream directory under `upstreams/` contains its own `upstream.json` with: repo URL, branch, last-checked SHA, and any upstream-specific metadata.
- Adding a new upstream = creating a new directory under `upstreams/` with the standard `upstream.json` -- no code changes required.

### Installation philosophy (CRITICAL -- affects all subsequent phases)
- Shell scripts ONLY for prerequisite validation (bun, jq, git, bash 4+).
- All actual install, config, and update operations live in markdown instruction files (INSTALL.md, UPDATE.md, CONFIG.md) designed to be executed by AI agents (Claude, Gemini, Codex).
- This is a departure from v1.0's `tools/install.sh` approach. Phase 9+ will reflect this shift.
- Existing shell scripts in `tools/` remain for v1.0 compatibility but the v1.1 direction is agent-driven.

### Migration strategy
- `.versions` currently contains `gsd_hash=none`, `paul_hash=none`, `last_check=never` -- effectively empty.
- Fresh start with the new `upstreams/` format. No formal migration needed.
- `.versions` file removed after `upstreams/gsd/upstream.json` and `upstreams/paul/upstream.json` are created.

### Directory conventions
- `upstreams/` at repo root (per success criteria: `ls upstreams/` shows one directory per upstream).
- Two initial directories: `upstreams/gsd/` and `upstreams/paul/`.
- Phase 8 will add `upstreams/omc/` -- the structure must accommodate this without changes.
- Each upstream directory is self-contained: `upstream.json` plus any upstream-specific files.

### Claude's Discretion
- Exact fields in `upstream.json` beyond the required (repo, branch, sha) -- planner determines what metadata is useful.
- How the public/private convention is documented (standalone doc vs section in CLAUDE.md vs both).
- Whether to create a `CONVENTIONS.md` or similar architectural reference doc.

</decisions>

<specifics>
## Specific Ideas

- The upstream registry should feel like a plugin system -- drop a directory in, it just works.
- `skippy-update.sh` currently reads `.versions` directly. Phase 8 will rewrite it to iterate `upstreams/*/upstream.json`, but Phase 5 just establishes the structure.
- Don't over-engineer the JSON schema -- start minimal, extend later.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/skippy-dev/.versions`: Current upstream tracking (shell-sourceable, to be replaced)
- `skills/skippy-dev/scripts/skippy-update.sh`: Reads `.versions`, will need updating in Phase 8
- `.claude-plugin/marketplace.json`: JSON precedent for structured metadata in this repo

### Established Patterns
- Shell scripts in `tools/` for installation -- v1.0 pattern, shifting to agent-driven in v1.1
- Flat file structure at repo root (CLAUDE.md, INDEX.md)
- Skills as self-contained directories under `skills/`

### Integration Points
- `skippy-update.sh` reads `.versions` -- Phase 8 will update to read `upstreams/*/upstream.json`
- `tools/install.sh` currently handles symlink creation -- v1.1 moves this to markdown instructions
- `.gitignore` needs updates for the public/private convention

</code_context>

<deferred>
## Deferred Ideas

- OMC as third upstream (Phase 8 -- `upstreams/omc/`)
- Rewriting `skippy-update.sh` to use generic upstream checker (Phase 8 -- UPST-04)
- Replacing `tools/install.sh` with agent-driven INSTALL.md (Phase 9-10)

</deferred>

---

*Phase: 05-foundation*
*Context gathered: 2026-03-07*
