# Project Research Summary

**Project:** skippy-agentspace v1.1 -- Portable PAI Infrastructure Packaging
**Domain:** Developer tooling / dotfiles infrastructure / Claude Code skill ecosystem
**Researched:** 2026-03-07
**Confidence:** MEDIUM-HIGH

## Executive Summary

skippy-agentspace v1.1 transforms this repo from a single-skill plugin (skippy-dev) into a portable infrastructure package that makes PAI (Personal AI Infrastructure) reproducible on any machine. The core problem: Rico's PAI system -- 69 skills, 25+ hooks, 4 personas, LAWs, rules, memory systems -- is scattered across `~/.config/pai/`, `~/.config/pai-private/`, and `~/.claude/`. None of it is version-controlled as a unit or installable from scratch. v1.1 fixes this with a "clone + bootstrap = working PAI" approach modeled on dotfiles managers (chezmoi, dotbot) but purpose-built for Claude Code's skill/hook/plugin architecture.

The recommended approach uses the same parasitic pattern proven in v1.0: ride upstream frameworks (GSD, PAUL) unchanged, inject enhancements as additive reference docs and self-contained skills. v1.1 extends this to OMC (oh-my-claudecode, 37 skills) as a third cherry-pick source and replaces the hardcoded upstream tracking with an extensible registry. The stack stays zero-dependency: bash scripts + markdown + symlinks. The only new runtime prerequisite is `jq` for non-destructive `settings.json` hook merging -- a justified addition given the alternative (hand-rolling JSON manipulation in bash).

The primary risks are: (1) hook installation complexity -- `settings.json` is shared by GSD, OMC, and PAI, and a botched merge destroys all three systems' hooks; (2) public/private content split -- some PAI content (contacts, security protocols, credential patterns) must never enter a git repo, requiring a clean architectural boundary before any packaging begins; (3) scope creep from migrating 68 skills -- the temptation to restructure everything will stall the project. Mitigation: install hooks via read-merge-write with `jq` (never overwrite), establish the public/private convention as an early architectural decision, and migrate only essential skills (~10) for v1.1 with bulk migration deferred.

## Key Findings

### Recommended Stack

The stack is deliberately minimal. v1.0 proved that bash + markdown + symlinks is sufficient for skill packaging. v1.1 adds no new languages or build steps.

**Core technologies (locked from v1.0):**
- **Bash 4+**: All scripts. Associative arrays needed. macOS ships 3.2, so `brew install bash` is a prerequisite.
- **Markdown**: Rules, references, SKILL.md entry points. Claude Code's native format.
- **Symlinks**: Installation mechanism. Repo is single source of truth; `git pull` updates everything.

**New for v1.1:**
- **Bash key=value conf files** (`upstreams/<name>/upstream.conf`): Extensible upstream registry. No YAML/JSON parser needed -- bash reads these natively.
- **`jq`**: Required for non-destructive `settings.json` hook merging. The only new dependency, justified by the alternative (fragile sed/awk on nested JSON).
- **Directory-per-upstream pattern**: `upstreams/<name>/` with `upstream.conf` + `CHERRY-PICKS.md`. Adding an upstream = creating a directory. No code changes.

**Explicitly avoided:** npm/yarn, Python, YAML/TOML parsers, Makefiles, Docker, Ansible, OMC's runtime (`oh-my-claude-sisyphus`).

See [STACK.md](STACK.md) for full rationale and alternatives considered.

### Expected Features

**Must have (table stakes):**
- One-command bootstrap (`git clone && ./bootstrap.sh`) -- dotfiles ecosystem standard
- Core infrastructure package (personas, LAWs, hooks, CLAUDE.md template) -- the whole point of the project
- Public/private content split -- some content is sensitive, must never be committed
- Selective skill install (`--core`, `--skill <name>`, `--all`) -- can't install all 70 skills on every machine
- Idempotent operations -- re-running install must not break existing config
- Upstream version tracking for OMC -- natural extension of existing GSD+PAUL tracking

**Should have (differentiators):**
- Extensible upstream registry -- future-proof for frameworks beyond GSD/PAUL/OMC
- OMC cherry-pick system -- selectively absorb best ideas (ralplan, learner, deepsearch, security-review) without installing all 37 skills
- Add-on skill system with dependency declarations -- skills declare what they need
- Bootstrap verification -- post-install health check confirms everything is wired correctly

**Defer (v2+):**
- Skill dependency auto-resolution -- self-contained skills are simpler at current scale
- Plugin marketplace publishing -- private/personal repo
- Multi-user support -- single-user reality
- Cross-machine sync -- solve after bootstrap proven on second machine
- Full 68-skill audit/restructuring -- migrate only essentials for v1.1

See [FEATURES.md](FEATURES.md) for dependency graph, MVP definition, and competitor analysis.

### Architecture Approach

The architecture extends v1.0's flat `skills/<name>/` pattern with two new top-level components: `core/` (infrastructure package) and `upstreams/` (extensible tracking). All installation remains symlink-based. The hardest integration point is hook installation, which requires merging into the shared `settings.json` without destroying GSD or OMC hook registrations.

**Major components:**
1. **`core/`** -- Personas, LAWs, rules, hooks, CLAUDE.md template. The "operating system" layer. Source of truth for everything currently scattered across `~/.config/pai/` and `~/.config/pai-private/`.
2. **`core/hooks/` + `hook-manifest.json`** -- Declares all hooks and their `settings.json` registrations. `install-hooks.sh` does read-merge-write via `jq`.
3. **`skills/`** -- Flat directory of self-contained add-on skills. Each has SKILL.md (150 lines max) + `references/` for deep docs.
4. **`upstreams/`** -- Directory-per-upstream with `upstream.conf` (bash key=value) and `CHERRY-PICKS.md` (provenance log). Generic `upstream-check.sh` replaces hardcoded `skippy-update.sh`.
5. **`tools/`** -- Extended install/uninstall/bootstrap scripts. New `migrate-skill.sh` for importing skills from `~/.config/pai/Skills/`.

**Key patterns:** Symlink-as-package-manager. Slim-core SKILL.md (150 lines max, deep docs in references/). Non-destructive JSON merge for settings.json. Registry-driven upstream tracking.

See [ARCHITECTURE.md](ARCHITECTURE.md) for full component diagram, integration points, and build order.

### Critical Pitfalls

*Note: PITFALLS.md was not produced by the pitfalls researcher. The following are derived from anti-pattern sections across the other three research files.*

1. **settings.json corruption during hook install** -- Multiple systems (GSD, OMC, PAI) write to this file. Overwriting it destroys all hook registrations. Prevention: read-merge-write with `jq`, detect existing entries by command path, validate JSON before writing. Always back up before modifying.
2. **Private content leaking into git** -- PAI infrastructure includes contacts, security protocols, credential patterns. If `core/` packaging isn't careful, sensitive content enters a potentially-public repo. Prevention: establish public/private split as the first architectural decision. Use `.gitignore` on `core/private/`. Never auto-package from `~/.config/pai-private/` without explicit filtering.
3. **Scope creep from 68-skill migration** -- Attempting to migrate and restructure all 68 PAI skills will stall the project indefinitely. Many skills violate the slim-core pattern and need restructuring. Prevention: migrate only ~10 essential skills for v1.1. Build `migrate-skill.sh` for the pattern, defer bulk migration.
4. **Breaking existing install by changing .versions** -- Current `skippy-update.sh` reads `.versions`. Replacing it with `upstreams/registry.json` without a migration path breaks the existing command. Prevention: keep `.versions` as legacy fallback during v1.1, deprecate in v1.2.
5. **Bootstrap assuming clean machine** -- Bootstrap script that fails on a machine with existing partial PAI setup. Prevention: idempotent operations throughout. Check for existing symlinks before creating. Detect and skip already-installed components.

## Implications for Roadmap

Based on research, suggested phase structure (6 phases):

### Phase 1: Foundation -- Public/Private Split and Upstream Registry
**Rationale:** These are architectural decisions with zero dependencies on other new components. The public/private boundary must be defined before any content packaging. The upstream registry must exist before OMC tracking.
**Delivers:** `upstreams/` directory structure with `upstream.conf` per tracked repo. Public/private content convention documented. Migration of `.versions` data into new format.
**Addresses:** Extensible upstream registry (P1), upstream version tracking (table stakes)
**Avoids:** Hardcoded upstream special cases, private content leakage

### Phase 2: Core Infrastructure Package
**Rationale:** Depends on Phase 1's public/private split decision. This is the highest-value deliverable -- without it, bootstrap has nothing to install.
**Delivers:** `core/` directory with personas, LAWs, rules, CLAUDE.md template, memory templates. `core/SKILL.md` as entry point.
**Addresses:** Core infrastructure package (P1), slim SKILL.md pattern (table stakes)
**Avoids:** Monolithic SKILL.md, including private content in public package

### Phase 3: Hook Installation System
**Rationale:** Depends on Phase 2 (hooks live in `core/hooks/`). This is the technically hardest part -- `settings.json` merging. Isolating it lets the team focus on getting it right.
**Delivers:** `hook-manifest.json`, `install-hooks.sh` (jq-based merge), idempotent hook registration/unregistration.
**Addresses:** Core infrastructure package (hooks portion), idempotent operations
**Avoids:** settings.json corruption, clobbering GSD/OMC hooks

### Phase 4: OMC Analysis and Cherry-Pick
**Rationale:** Depends on Phase 1's upstream registry. Can partially overlap with Phases 2-3. Produces reference docs that enrich the skill ecosystem.
**Delivers:** OMC added to upstream registry. 3-5 cherry-picked reference docs (ralplan, persistent notepad, learner, deepsearch pattern, model routing). Updated `/skippy:update` to use generic `upstream-check.sh`.
**Addresses:** OMC cherry-pick (P1), extensible upstream registry validation
**Avoids:** Forking OMC, importing their runtime, installing all 37 skills

### Phase 5: Skill System and Selective Install
**Rationale:** Depends on Phase 2 (core must exist as a skill). Extends existing `install.sh` with new flags. Migrates ~10 essential skills.
**Delivers:** Extended `install.sh` (`--core`, `--skill`, `--category`, `--list`, `--check`). `migrate-skill.sh` tool. ~10 essential skills migrated with proper frontmatter. Updated INDEX.md with categories.
**Addresses:** Selective skill install (P1), add-on skill system (differentiator), skill registry (table stakes)
**Avoids:** Migrating all 68 skills, cross-skill dependencies, category subdirectories

### Phase 6: Bootstrap and Verification
**Rationale:** Depends on all previous phases. This is the integration phase -- `bootstrap.sh` calls everything else.
**Delivers:** `bootstrap.sh` (idempotent, prerequisite-checking, works on fresh macOS). Optional post-install verification. Updated documentation (CLAUDE.md, README if needed).
**Addresses:** One-command bootstrap (table stakes), bootstrap verification (differentiator)
**Avoids:** Non-idempotent operations, assuming clean machine, auto-installing MCP servers

### Phase Ordering Rationale

- **Phase 1 first** because every other phase depends on either the public/private boundary or the upstream registry pattern. These are architectural decisions, not code -- they're fast to establish.
- **Phases 2, 3, 4 are partially parallelizable.** Phase 3 depends on Phase 2 (hooks are in core/), but Phase 4 (OMC cherry-pick) only depends on Phase 1. In practice, Phase 2 should come before 3 sequentially, while Phase 4 can overlap.
- **Phase 5 before 6** because bootstrap needs the install system to exist. But Phase 5 can start as soon as Phase 2 delivers `core/`.
- **Phase 6 last** because it's pure integration -- it calls everything built in Phases 1-5.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Hook Installation):** The `settings.json` structure is complex and underdocumented. Need to map the exact JSON schema for hook registrations, understand matcher precedence, and test `jq` merge operations against real configs. Research the Claude Code hook API surface.
- **Phase 4 (OMC Cherry-Pick):** Need targeted analysis of OMC's ralplan, learner, and deepsearch skills. The v4.7.3 cache exists locally but specific extraction decisions require reading each skill file.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** Well-established patterns -- bash conf files, directory conventions. STACK.md already specifies the exact format.
- **Phase 2 (Core Package):** Direct packaging of existing files. Source material is known and inspected. No unknowns.
- **Phase 5 (Skill System):** Extending existing `install.sh`. Patterns established in v1.0. STACK.md specifies the exact frontmatter additions.
- **Phase 6 (Bootstrap):** Standard dotfiles bootstrap patterns. chezmoi/dotbot precedent is well-documented.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All decisions extend proven v1.0 patterns. Sources are direct filesystem inspection. Only new dependency (jq) is well-justified. |
| Features | MEDIUM-HIGH | Feature list is clear and well-prioritized. OMC cherry-pick targets need validation during Phase 4 planning. Competitor analysis is solid. |
| Architecture | HIGH | Based on direct inspection of all component sources (69 skills, 25+ hooks, settings.json). Build order accounts for dependencies. |
| Pitfalls | MEDIUM | No dedicated PITFALLS.md was produced. Pitfalls derived from anti-pattern sections in other files. May be missing edge cases around macOS-specific issues, Claude Code version compatibility, or skill context budget limits. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **PITFALLS.md missing:** The pitfalls researcher did not produce output. Risk areas were derived from anti-pattern sections in the other three files, but a dedicated pitfalls analysis would improve coverage -- particularly around Claude Code version compatibility, context window budget constraints at 70 skills, and macOS-specific bash 3.2 gotchas.
- **Hook registration JSON schema:** The exact structure of `settings.json` hook registrations needs validation during Phase 3 planning. The architecture research references it but doesn't include the full schema.
- **OMC cherry-pick validation:** The specific OMC skills worth extracting (ralplan, learner, deepsearch) need hands-on analysis of their SKILL.md files during Phase 4. Current assessment is from high-level repo inspection.
- **Context budget at scale:** Claude Code limits skill context to ~2% of the context window. With 70 skills, even slim SKILL.md files may hit the budget. Need to verify whether only installed (symlinked) skills count, or all skills in the repo.
- **`jq` availability on fresh macOS:** `jq` is not included with macOS. Bootstrap must either require `brew install jq` as a prerequisite or bundle a fallback. This needs a decision during Phase 3 planning.

## Sources

### Primary (HIGH confidence)
- Direct filesystem inspection: `~/.config/pai/Skills/` (69 directories), `~/.config/pai-private/hooks/` (25+ scripts), `~/.claude/settings.json`, `~/.claude/plugins/cache/omc/oh-my-claudecode/4.7.3/`
- Existing codebase: `tools/install.sh`, `tools/uninstall.sh`, `tools/index-sync.sh`, `skills/skippy-dev/` (v1.0 working implementation)
- PAI infrastructure audit (`.planning/PAI-INFRASTRUCTURE-AUDIT.md`) -- 68 skills, 12 agents, 34 workflows catalogued

### Secondary (MEDIUM confidence)
- [oh-my-claudecode GitHub repo](https://github.com/Yeachan-Heo/oh-my-claudecode) -- skill/agent/hook structure analysis
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- SKILL.md format, context budget, auto-discovery
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- marketplace.json format
- [dotfiles.github.io](https://dotfiles.github.io/bootstrap/) -- bootstrap patterns, idempotency conventions
- [chezmoi docs](https://www.chezmoi.io/) -- template system, secrets management patterns

### Tertiary (needs validation)
- OMC cherry-pick targets (ralplan, learner, deepsearch) -- assessed from repo structure, not hands-on usage
- Context budget limits at 70 skills -- needs empirical testing

---
*Research completed: 2026-03-07*
*Ready for roadmap: yes*
