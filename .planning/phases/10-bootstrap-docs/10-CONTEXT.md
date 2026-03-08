# Phase 10: Bootstrap & Docs - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

A user on a fresh machine can clone this repo and reach a working PAI setup by following documented steps, with automated verification confirming everything is wired correctly. Covers: README.md, SETUP.md, INSTALL.md, UPGRADE.md, prereqs.sh, and a verification/health-check script.

</domain>

<decisions>
## Implementation Decisions

### Documentation Audience & Tone
- Primary audience: future-you on a new machine, then technical friends, then FOSS community adopters
- Cross-platform: macOS primary (Homebrew), Linux covered (apt, dnf, pacman), WSL2 explicitly supported
- Straight technical tone -- no personality, no fluff. Like Arch Wiki.
- No assumed knowledge beyond "you have a Mac with Homebrew" (or equivalent package manager on Linux)

### README.md Structure
- Overview + quick start pattern: what this is (2 paragraphs), quick start (5 commands), then links to SETUP/INSTALL/UPGRADE for detail
- Standard open-source README pattern
- Not a monolith -- detail lives in dedicated docs

### SETUP.md
- Step-by-step first-time setup: clone -> prereqs -> install core -> install skills -> verify
- Numbered steps, no assumed knowledge
- Cross-platform install commands (brew/apt/dnf/pacman variants)

### INSTALL.md
- Adding individual skills or components to an existing setup
- Covers both plugin install and manual install.sh paths

### UPGRADE.md
- Documents BOTH manual steps (git pull + reinstall) AND AI-assisted path (/skippy:upgrade)
- Manual path required because repo may be used with Gemini, Codex, or other AI tools -- not Claude-only
- /skippy:upgrade is an AI command (markdown-based, consistent with Phase 8 pattern)
- Smart merge of user customizations: detect modifications, understand what changed, integrate in-line rather than overwrite

### Verification Script (tools/verify.sh)
- Reusable health check, not one-time post-install -- run anytime like `brew doctor`
- Full diagnostic scope: structural (symlinks, files) + functional (install.sh responds, index-sync.sh passes) + config (settings.json hook paths, command accessibility)
- Grouped output by category (Prerequisites, Skills, Hooks, Commands) with section headers
- Three severity levels: PASS/WARN/FAIL
- Suggests fixes for each failure with commands to copy-paste
- Re-run capability: fix issues, run again to confirm resolution
- Exit code: 0 for all pass or warn-only, 1 for any fail

### prereqs.sh
- Interactive install prompts: for each missing tool, ask "Install X? [y/N]" and run if approved
- Auto-detect OS: macOS (brew), Debian/Ubuntu (apt), Fedora (dnf), Arch (pacman)
- Always interactive -- no CI/non-interactive mode
- Checks: bun, jq, bash 4+, git -- reports versions for installed tools

### Claude's Discretion
- Doc ordering and cross-linking between README/SETUP/INSTALL/UPGRADE
- Exact verification check list beyond the categories specified
- Whether prereqs.sh and verify.sh share common output formatting code
- SETUP.md step granularity (how many steps total)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tools/install.sh` (246 lines): Battle-tested selective installer with --core, --all, positional args, status table. SETUP.md references this directly.
- `tools/uninstall.sh` (163 lines): Selective uninstaller. INSTALL.md/UPGRADE.md reference for clean reinstall path.
- `tools/index-sync.sh` (206 lines): INDEX.md regeneration. verify.sh can call `--check` mode.
- `tools/validate-hooks.sh` (317 lines): Hook validation infrastructure from Phase 7. verify.sh can reuse check logic.
- `CLAUDE.md`: Has full project overview, architecture, skill inventory. README.md can extract/simplify from this.
- `CONVENTIONS.md`: Public/private boundary documentation. Referenced by SETUP.md.
- `.claude-plugin/marketplace.json`: Plugin install path documented in INSTALL.md.

### Established Patterns
- Multi-backend JSON detection: bun > python3 > jq (Phase 7) -- prereqs.sh checks these
- Dual install targets: ~/.claude/skills/ (modern) vs ~/.claude/commands/ (legacy) -- SETUP.md covers both
- AI command pattern: markdown with <objective>, <process> structure (Phase 8) -- /skippy:upgrade follows this

### Integration Points
- prereqs.sh -> SETUP.md step 1 (run prereqs before install)
- install.sh -> SETUP.md step 2-3 (install core, then skills)
- verify.sh -> SETUP.md final step (confirm everything works)
- /skippy:upgrade -> UPGRADE.md (AI-assisted upgrade path)
- INDEX.md -> README.md quick reference (link to skill catalog)

</code_context>

<specifics>
## Specific Ideas

- verify.sh should feel like `brew doctor` -- run anytime, get a health report, see what needs fixing
- Cross-platform support driven by a real use case: a Windows friend running Claude Code in WSL2
- UPGRADE.md must work for non-Claude AI tools (Gemini, Codex) -- manual path is not optional

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 10-bootstrap-docs*
*Context gathered: 2026-03-08*
