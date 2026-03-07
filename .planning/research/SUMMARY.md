# Research Summary: skippy-agentspace

**Domain:** Portable Claude Code skill marketplace
**Researched:** 2026-03-06
**Overall confidence:** HIGH

## Executive Summary

The Claude Code skill ecosystem in 2026 is mature and well-standardized. The Agent Skills open standard -- originally developed by Anthropic and now adopted by 30+ AI coding tools including Codex, Gemini CLI, Cursor, VS Code Copilot, Goose, and Roo Code -- provides a single `SKILL.md` format that works across the industry. Claude Code extends this standard with a native plugin system for distribution: any git repository can serve as a plugin marketplace via `.claude-plugin/plugin.json`, enabling one-command install via `/plugin marketplace add owner/repo`.

skippy-agentspace is already 80-90% aligned with this ecosystem. The skill anatomy (SKILL.md entrypoint, references/ for on-demand docs, bin/ for scripts, commands/ for slash commands) matches the standard patterns. The parasitic enhancement approach -- augmenting GSD with PAUL's best ideas without forking either -- is architecturally sound. The main gaps are mechanical: hardcoded absolute paths that break portability, a non-standard `triggers:` frontmatter field, `bin/` instead of spec-standard `scripts/`, and missing plugin packaging metadata.

The path forward is clear and low-risk. The existing skill structure needs spec alignment (rename, frontmatter cleanup, path portability), then plugin packaging (two JSON files), then validation of the three commands against real workflows. No new technology is needed. No build tooling. No runtime dependencies. The stack is markdown, YAML frontmatter, and bash scripts -- exactly what the project already uses.

The research also uncovered several non-obvious pitfalls: Claude Code's skill description budget (~16k chars, ~42 skills at average description length) can silently exclude skills; command naming collisions with reserved names can crash ALL command loading (confirmed bug #13586); `skippy-update.sh` uses `/tmp` for upstream clones (volatile on macOS) and `source` for parsing `.versions` (unsafe). These are fixable but must be addressed in Phase 1.

## Key Findings

**Stack:** Agent Skills open standard (SKILL.md + YAML frontmatter) + Claude Code plugin system (.claude-plugin/plugin.json + marketplace.json) + bash scripts. No build step, no runtime dependencies. The `commands/` subdirectory pattern is legacy -- skills system replaces it with SKILL.md as the command entrypoint.

**Architecture:** Progressive disclosure (metadata -> instructions -> resources) is already implemented correctly. Three discovery mechanisms exist (skills > commands > plugins), and the migration path from commands/ to skills/ is well-defined. Plugin system copies files to cache, so everything must be self-contained with portable paths.

**Critical pitfalls (top 3):**
1. Hardcoded absolute paths in `commands/reconcile.md` -- skill cannot work on any other machine or via plugin install
2. Context budget exhaustion -- ~42 skills fit at average description length before silent truncation; descriptions must be under 130 chars
3. Command naming collisions -- reserved name conflicts crash ALL command loading, not just the conflicting one

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Spec Compliance & Portability** - Fix what's broken before building anything new
   - Addresses: hardcoded paths, non-standard frontmatter, bin/ -> scripts/ rename, description length optimization, install tooling collision detection
   - Avoids: distributing a skill that only works on one machine; silent command loading failures
   - Risk: LOW -- mechanical changes, well-documented spec

2. **Plugin Packaging & Distribution** - Enable the native Claude Code install path
   - Addresses: `.claude-plugin/plugin.json`, dual distribution (plugin + manual symlink)
   - Avoids: requiring users to manually clone + symlink
   - Risk: LOW -- Anthropic's own `anthropics/skills` repo provides reference implementation with `strict: false` pattern
   - Architecture note: consider merging commands/ content into SKILL.md (skill IS the command) vs keeping separate commands/ for multi-command skills

3. **Script Hardening & Command Validation** - Fix scripts and verify commands work
   - Addresses: `/tmp` -> `~/.cache/` for upstream clones, `source` -> `grep`/`cut` for .versions parsing, full SHA hashes, `/skippy:reconcile` against real phases, `/skippy:update` reboot resilience
   - Avoids: shipping commands that error on real inputs; scripts that break on macOS reboot
   - Risk: MEDIUM -- may uncover workflow issues in reconciliation parsing; GSD coupling needs defensive coding

4. **Documentation & Polish** - Cold session context, dependency documentation
   - Addresses: PROJECT.md requirement for "cold session context", `DEPENDENCIES.md` listing every GSD assumption, reference doc metadata (`last_verified`, `source`, `assumes`)
   - Avoids: new sessions having no context; reference doc staleness creating false confidence
   - Risk: LOW

**Phase ordering rationale:**
- Phase 1 before Phase 2 because plugin packaging copies files -- if paths are still hardcoded, the copied files will be broken
- Phase 2 before Phase 3 because testing should include the plugin install path, not just manual symlinks
- Phase 3 before Phase 4 because documentation should describe working commands, not aspirational ones
- Script hardening folded into Phase 3 (not Phase 1) because the scripts work adequately for development; the `/tmp` and `source` issues only bite in production use

**Research flags for phases:**
- Phase 1: Standard patterns, unlikely to need research. Reserved command names list should be verified against current Claude Code version.
- Phase 2: Standard patterns, Anthropic reference implementation available. Test `plugin-name:skill-name` namespace interaction with existing `skippy:command` naming.
- Phase 3: May need phase-specific research on GSD's `.planning/` structure if reconciliation parsing is complex. GSD coupling assumptions need documenting.
- Phase 4: No research needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Agent Skills spec verified at agentskills.io. Claude Code plugin system verified at code.claude.com. Anthropic's own repo provides reference implementation. |
| Features | HIGH | Feature landscape well-understood. Table stakes defined by spec. Differentiators already designed in PROJECT.md. Context budget numbers empirically measured by community (alexey-pelykh). |
| Architecture | HIGH | Progressive disclosure documented in both Agent Skills spec and Claude Code docs. Discovery mechanisms and priority order verified from official docs. GSD/OMC/PAUL patterns analyzed from source. |
| Pitfalls | HIGH | Hardcoded paths verified by reading source files. Command collision bugs confirmed via GitHub issues (#13586, #22063). Context budget measured empirically. Script vulnerabilities identified from code analysis. |

## Gaps to Address

- **`${CLAUDE_SKILL_DIR}` expansion scope:** Confirmed in official docs for SKILL.md content, but known bug (#11011) with plugin scripts on first execution. Need to test in command .md files specifically.
- **Plugin namespace vs existing naming:** Skills get `plugin-name:skill-name` namespace when installed via plugin, but a bug (#22063) can flatten this when SKILL.md has a `name` field. Current `skippy:reconcile` naming uses `:` already -- need to verify interaction.
- **GSD `.planning/` structure stability:** Reconciliation command depends on GSD's internal file layout. GSD has changed field names (`depth` -> `granularity`) and paths before. Need defensive parsing.
- **`.versions` file format:** Currently `source`-d as bash -- unsafe. Need standardized, parseable format with full SHA hashes.
- **Commands/ to skills/ migration decision:** Whether to keep separate command .md files or merge into SKILL.md with `$ARGUMENTS` dispatch. Single skill recommended for now, but decision affects plugin packaging.

## Sources

- [Agent Skills Specification](https://agentskills.io/specification) -- HIGH confidence
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- HIGH confidence
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- HIGH confidence
- [Anthropic skills repo](https://github.com/anthropics/skills/) -- HIGH confidence
- [Agent Skills GitHub](https://github.com/agentskills/agentskills) -- HIGH confidence
- [Claude Code skill budget research](https://gist.github.com/alexey-pelykh/faa3c304f731d6a962efc5fa2a43abe1) -- MEDIUM confidence
- [GitHub Issue #13586: Reserved name collision](https://github.com/anthropics/claude-code/issues/13586) -- HIGH confidence
- [GitHub Issue #22063: Plugin namespace flattening](https://github.com/anthropics/claude-code/issues/22063) -- HIGH confidence
- [GitHub Issue #11011: Plugin script path resolution](https://github.com/anthropics/claude-code/issues/11011) -- HIGH confidence
- [SFEIR Institute: Common Skill Mistakes](https://institute.sfeir.com/en/claude-code/claude-code-custom-commands-and-skills/) -- MEDIUM confidence
