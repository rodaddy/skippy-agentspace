# Stack Research

**Domain:** Portable PAI infrastructure packaging -- shell-based skill/hook/command system for Claude Code
**Researched:** 2026-03-07
**Confidence:** HIGH

## Context: What Already Exists (DO NOT CHANGE)

These are validated v1.0 decisions. Listed here so roadmap consumers understand what's locked.

| Technology | Purpose | Status |
|------------|---------|--------|
| Bash (`#!/usr/bin/env bash`) | All scripts and tooling | Locked -- no build step, no runtime dependencies |
| Markdown | Rules, references, SKILL.md entry points | Locked -- Claude Code's native format |
| Symlinks | Installation mechanism (tools/install.sh) | Locked -- dual-target (skills/ and commands/) |
| `.claude-plugin/marketplace.json` | Plugin distribution | Locked -- strict:false, no plugin.json needed |
| Git hash tracking (`.versions`) | Upstream version monitoring | Locked -- key=value flat file |
| `~/.cache/skippy-upstream/` | Cloned upstream repos for diff comparison | Locked -- skippy-update.sh pattern |

## Stack Additions for v1.1

### What's Needed and Why

v1.1 adds five capabilities. Each needs specific tooling decisions. The critical constraint: **no new runtime dependencies**. Everything must work with vanilla Claude Code on a fresh macOS install with only `git`, `bash`, and standard POSIX tools.

---

### 1. OMC Analysis Tooling

**Need:** Clone OMC repo, diff against known hash, report interesting changes -- same pattern as existing GSD/PAUL tracking.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Bash (existing pattern) | N/A | `skippy-update.sh` extended with OMC entry | Same fetch_repo/report_changes pattern already works for GSD and PAUL. Adding OMC is ~20 lines. |
| Git CLI | System | Clone/fetch/diff OMC repo at `~/.cache/skippy-upstream/omc/` | Already used for GSD/PAUL. No new dependency. |

**What NOT to add:**
- No npm/bun to parse OMC's package.json -- just track git hashes like we do for GSD/PAUL
- No OMC CLI (`oh-my-claude-sisyphus`) -- we cherry-pick ideas as markdown references, we don't run their runtime

**Integration point:** Extend `.versions` with `omc_hash=none` line. Extend `skippy-update.sh` with a third `fetch_repo`/`report_changes` block for OMC.

**OMC repo URL:** `https://github.com/Yeachan-Heo/oh-my-claudecode.git`

---

### 2. Extensible Upstream Cherry-Pick System

**Need:** Go from hardcoded GSD+PAUL+OMC to a registry where new upstream sources can be added without modifying core scripts.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Directory-based registry | N/A | `upstreams/<name>/upstream.conf` -- one dir per tracked upstream | Follows the same pattern as `skills/<name>/SKILL.md`. No parser needed beyond `source` or key=value read. |
| Bash key=value conf files | N/A | `upstream.conf` with `repo_url=`, `branch=`, `track_paths=`, `hash=` | Flat config that bash can read natively. No YAML/JSON parser dependency. |
| `diff --stat` + `log --oneline` | Git CLI | Report what changed in tracked paths only | Filter noise -- only show changes in paths we care about (e.g., OMC's `skills/` not their `benchmarks/`) |

**Registry format (`upstreams/<name>/upstream.conf`):**

```bash
# Required
repo_url=https://github.com/Yeachan-Heo/oh-my-claudecode.git
branch=main

# Optional -- restrict tracking to specific paths (space-separated)
track_paths=skills/ agents/ hooks/ CLAUDE.md

# Managed by skippy-update (do not edit manually)
known_hash=none
last_check=never
```

**Each upstream also gets:**
- `upstreams/<name>/CHERRY-PICKS.md` -- log of what was absorbed and when
- `upstreams/<name>/notes/` -- analysis notes, rejection rationale

**Why directory-based over a single JSON/YAML registry:**
- Adding an upstream = creating a directory with a conf file. No merge conflicts, no parser.
- Each upstream's cherry-pick history is self-contained.
- `ls upstreams/` is the registry. No index file to sync.

**Migration from current `.versions`:**
- Move GSD, PAUL, OMC tracking into `upstreams/gsd/`, `upstreams/paul/`, `upstreams/omc/`
- Keep `.versions` as a legacy fallback during transition, remove in v1.2

---

### 3. Core Infrastructure Package

**Need:** Package personas, LAWs, hooks, commands, and rules from `~/.config/pai/` and `~/.config/pai-private/` into installable, portable units.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Skill directory pattern | N/A | `skills/pai-core/SKILL.md` + `references/` + `templates/` | Same slim-core pattern as skippy-dev. Proven portable. |
| Bash installer extension | N/A | `tools/install.sh` extended with `--core` flag for infrastructure setup | Reuses existing installer. Adds symlink targets for hooks, CLAUDE.md fragments, and settings. |
| Template/fragment system | N/A | `core/templates/CLAUDE.md.fragment` -- snippets that get concatenated | Allows modular CLAUDE.md assembly. User's project CLAUDE.md includes fragments via path references, not copy-paste. |

**What gets packaged (from audit):**

| Component | Source Location | Package Location | Install Target |
|-----------|----------------|-----------------|----------------|
| 4 Personas (Skippy, Bob, Clarisa, April) | `~/.config/pai/Skills/CORE/personas/` | `core/personas/` | `~/.config/pai/Skills/CORE/personas/` |
| LAW definitions | `~/.config/pai-private/rules/laws/` | `core/laws/` | `~/.config/pai-private/rules/laws/` |
| Communication style | `~/.config/pai-private/rules/style/` | `core/rules/style/` | `~/.config/pai-private/rules/style/` |
| CLAUDE.md (global) | `~/.claude/CLAUDE.md` | `core/templates/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Core hooks (safety, quality, law-enforcement) | `~/.config/pai-private/hooks/` | `core/hooks/` | `~/.claude/hooks/` via symlinks |
| settings.json (permissions, env) | `~/.claude/settings.json` | `core/templates/settings.json.example` | Manual merge (never auto-overwrite) |

**Critical design decision: public vs private split.**

Some content is sensitive (contacts, security protocols, credentials patterns). The repo needs a clear boundary:

| Tier | Contents | Handling |
|------|----------|----------|
| **Public** (committed) | Personas, LAW definitions, style rules, hook scripts, CLAUDE.md template | Normal git tracking |
| **Private** (gitignored) | Contacts, security protocols, credential patterns, personal memory | `core/private/` directory, gitignored, populated by bootstrap from a separate encrypted source |

**What NOT to add:**
- No TypeScript/Bun for hooks in the package -- hooks that need TS (like law-enforcement hooks) keep their source in the core but need `bun` as a runtime dependency documented in prerequisites
- No attempt to package MCP server configs -- those are machine-specific (IP addresses, ports)
- No `settings.json` auto-merge -- provide an example file and a diff tool, never overwrite

**Hooks dependency note:** The existing PAI hooks at `~/.config/pai/hooks/` use TypeScript executed via `bun`. This is a runtime prerequisite, not a build dependency. The bootstrap script must verify `bun` is available. The hooks themselves have a `package.json` with `pg` (PostgreSQL client) as the only dependency -- this is for the brain/knowledge system and should be optional.

---

### 4. Add-On Skill Installation System

**Need:** Install individual skills from the repo without installing everything. Skills are opt-in, each self-contained.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Extended `tools/install.sh` | N/A | `install.sh <skill-name>` already works, needs `--list-available` and dependency checking | Existing installer already handles single-skill install. Just needs polish. |
| Skill dependency declaration | N/A | Optional `requires:` field in SKILL.md frontmatter | Lets a skill declare it needs `pai-core` installed first. Installer checks and warns. |
| Skill categories in INDEX.md | N/A | Category column in the auto-generated index table | `tools/index-sync.sh` extended to parse `category:` from frontmatter |

**Skill frontmatter additions:**

```yaml
---
name: skippy-dev
description: Development workflow enhancements
metadata:
  version: 0.1.0
  author: Rico
  category: workflow        # NEW -- used by INDEX.md and install --list
  requires: []              # NEW -- skill dependencies (e.g., ["pai-core"])
  tier: public              # NEW -- public (committed) or private (gitignored)
---
```

**Install command extensions:**

```bash
# Existing (unchanged)
tools/install.sh skippy-dev
tools/install.sh --all

# New
tools/install.sh --list              # Show available skills with categories
tools/install.sh --category workflow # Install all skills in a category
tools/install.sh --check             # Verify all installed skills have deps met
```

**What NOT to add:**
- No version resolution or semver -- skills are always latest (from the repo checkout)
- No remote fetching of individual skills -- the repo is the package, `git pull` updates everything
- No lock files -- symlinks point to repo checkout, always current

---

### 5. New Machine Bootstrap

**Need:** `git clone` + one command = working PAI infrastructure on a fresh macOS machine.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Bash bootstrap script | N/A | `tools/bootstrap.sh` -- idempotent setup script | Single entry point. Runs install.sh --all, sets up core, verifies prerequisites. |
| Prerequisite checker | N/A | Verify `git`, `bash` (4+), `bun`, `brew` are available | Fail fast with clear instructions if something is missing. |
| XDG-aware paths | N/A | Respect `$XDG_CONFIG_HOME` if set, default to `~/.config/` | Standard on Linux, works on macOS. Future-proof. |

**Bootstrap flow:**

```
1. Clone repo
2. cd skippy-agentspace
3. ./tools/bootstrap.sh
   a. Check prerequisites (git, bash 4+, bun)
   b. Install core infrastructure (personas, LAWs, hooks, CLAUDE.md)
   c. Install all default skills
   d. Set up upstream tracking directories
   e. Run index-sync --generate
   f. Verify installation (install.sh --check)
   g. Print next steps (private config, MCP servers, etc.)
```

**Prerequisites to verify:**

| Tool | Why Needed | Install Command |
|------|-----------|-----------------|
| `git` | Cloning, upstream tracking | `brew install git` (or Xcode CLT) |
| `bash` 4+ | Associative arrays, better globbing | `brew install bash` (macOS ships 3.2) |
| `bun` | Running TypeScript hooks | `brew install oven-sh/bun/bun` |
| `brew` | Installing prerequisites | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |

**What NOT to add:**
- No Docker/container-based bootstrap -- this is a dotfiles-style repo, not a service
- No Ansible/Chef/Puppet -- overkill for a single-user workstation setup
- No cloud sync -- private config comes from a separate encrypted repo or manual setup
- No auto-install of MCP servers -- those require per-machine configuration (API keys, network addresses)

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Bash key=value conf | YAML/TOML config | If the project ever needs nested config structures (unlikely -- flat is fine for upstream tracking) |
| Directory-per-upstream | Single JSON registry | If you need atomic updates to the full registry (we don't -- each upstream is independent) |
| Symlinks for installation | Copy-based install | If you need skills to work when the repo is deleted (we don't -- the repo IS the source of truth) |
| Template fragments for CLAUDE.md | Full CLAUDE.md overwrite | Never -- users have project-specific content that must be preserved |
| `bun` for TS hooks | `node` for TS hooks | If bun is unavailable; but `bun` is a PAI prerequisite, so always prefer it |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| npm/yarn/pnpm | PAI uses bun exclusively; adding another package manager creates confusion | `bun` for any JS/TS needs |
| Python for scripts | Adds a runtime dependency; bash is universal on target machines | Bash for all scripts |
| JSON/YAML parsers (jq, yq) | External dependency; not guaranteed on fresh macOS | Bash key=value conf, `grep`/`sed` for simple parsing |
| Makefile | Adds complexity; bash scripts are more readable for this use case | Direct bash scripts |
| OMC's npm package (`oh-my-claude-sisyphus`) | We cherry-pick ideas as markdown, not run their runtime | Read their SKILL.md files, extract patterns into our own references |
| Hardcoded upstream URLs in scripts | Breaks extensibility; new upstreams require code changes | `upstreams/<name>/upstream.conf` registry |
| Auto-merge of upstream changes | Risk of breaking local customizations | Report changes, human decides -- existing `/skippy:update` pattern |
| `settings.json` auto-overwrite | Destroys user's permission grants and custom paths | Provide `.example` template, manual merge instructions |

## Stack Patterns by Capability

**If adding a new upstream source:**
- Create `upstreams/<name>/upstream.conf` with repo_url, branch, track_paths
- Run `/skippy:update` -- it auto-discovers all `upstreams/*/upstream.conf` files
- No code changes needed

**If adding a new skill:**
- Create `skills/<name>/SKILL.md` with frontmatter (name, description, category, requires, tier)
- Add `references/` dir for deep docs, `commands/` dir for slash commands
- Run `tools/index-sync.sh --generate` to update INDEX.md
- Run `tools/install.sh <name>` to install

**If packaging PAI hooks:**
- Hooks are TypeScript files run by `bun` -- they stay as `.ts` files
- `core/hooks/` contains the source, `tools/install.sh --core` symlinks them to `~/.claude/hooks/`
- `package.json` in hooks dir declares any npm dependencies (currently just `pg`)
- Bootstrap runs `bun install` in the hooks directory after symlinking

**If bootstrapping a new machine:**
- `./tools/bootstrap.sh` is the single entry point
- It's idempotent -- safe to run multiple times
- Exits with clear error if prerequisites are missing
- Prints manual steps for private/machine-specific config at the end

## Version Compatibility

| Component | Requires | Notes |
|-----------|----------|-------|
| All bash scripts | Bash 4.0+ | macOS ships 3.2; `brew install bash` needed. Scripts use associative arrays. |
| TypeScript hooks | Bun 1.0+ | Any recent bun version works. Hooks use `Bun.file()` and `Bun.spawn()`. |
| Git operations | Git 2.20+ | For `--quiet` flag support and modern fetch behavior. Any recent git works. |
| Claude Code | Any version with skills/ support | Skills dir (`~/.claude/skills/`) is the modern target. Commands dir (`~/.claude/commands/`) is legacy fallback. |
| GSD | 1.22+ | Current version is 1.22.4. Workflows in `~/.claude/get-shit-done/workflows/`. |
| OMC | 4.7+ | Current cached version is 4.7.3. We only read their SKILL.md files for ideas. |

## Sources

- Existing codebase: `tools/install.sh`, `tools/uninstall.sh`, `tools/index-sync.sh`, `skills/skippy-dev/scripts/skippy-update.sh` -- patterns for all new tooling [HIGH confidence]
- PAI infrastructure audit (`.planning/PAI-INFRASTRUCTURE-AUDIT.md`) -- 68 skills, 12 agents, 34 workflows catalogued [HIGH confidence]
- OMC GitHub repo ([Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)) -- skill structure is single SKILL.md per directory, 38 skills in v4.7.3 [HIGH confidence]
- OMC v4.7.3 cached at `~/.claude/plugins/cache/omc/oh-my-claudecode/4.7.3/` -- direct inspection of skill files [HIGH confidence]
- PAI hooks at `~/.config/pai/hooks/` -- TypeScript, `bun` runtime, `pg` dependency [HIGH confidence]
- GSD at `~/.claude/get-shit-done/` -- v1.22.4, Node.js `gsd-tools.cjs` for CLI utilities [HIGH confidence]
- PAI CORE skill at `~/.config/pai/Skills/CORE/` -- 4 personas, laws, contacts, security protocols [HIGH confidence]

---
*Stack research for: Portable PAI Infrastructure Packaging (v1.1)*
*Researched: 2026-03-07*
