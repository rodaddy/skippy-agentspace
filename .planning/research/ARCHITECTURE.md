# Architecture Research

**Domain:** Portable PAI infrastructure packaging -- Claude Code skill marketplace with core system bootstrap
**Researched:** 2026-03-07
**Confidence:** HIGH (based on direct filesystem inspection of all components)

## System Overview -- Current State

```
~/.claude/
  settings.json          # Hooks config, permissions, plugins, model
  commands/gsd/          # GSD commands (32 .md files)
  commands/skippy -> symlink
  hooks/                 # Mix of symlinks + direct files
    law-enforcement -> ~/.config/pai-private/hooks/law-enforcement/
    safety          -> ~/.config/pai-private/hooks/safety/
    bash-helpers    -> ~/.config/pai-private/hooks/bash-helpers/
    skill-triggers  -> ~/.config/pai-private/hooks/skill-triggers/
    quality         -> ~/.config/pai/hooks/quality/
    formatters/          # Direct (not symlinked)
    gsd-*.js             # GSD hook scripts (3 files)
  plugins/cache/
    omc/oh-my-claudecode/4.7.3/   # 37 skills, 22 agents
    claude-plugins-official/       # Frontend, LSPs, etc.
  skills/                # Modern skill target (auto-detected)

~/.config/pai/
  Skills/                # 69 skill directories (source of truth)
    CORE/                # Personas, LAWs, contacts, stack
      personas/          # Skippy.md, Bob.md, Clarisa.md, April.md
    [68 other skills]
    AGENT-INDEX.md       # Agent skill discovery index
  hooks/                 # PAI-owned hooks (enforce-skill-usage, etc.)

~/.config/pai-private/
  hooks/                 # Private/sensitive hooks
    law-enforcement/     # 15 hook scripts + shared/ library
    safety/              # 7 git-safety hooks
    quality/             # 1 file-size hook
    bash-helpers/        # 1 cd-unset hook
    skill-triggers/      # 2 auto-trigger hooks
    post-session/        # 1 knowledge extraction hook
  rules/                 # Markdown rule files (laws, architecture, security, stack, style)
  memory/                # Persistent memory files
  knowledge/             # Extracted knowledge base

skippy-agentspace/       # THIS REPO (development copy)
  skills/skippy-dev/     # Single skill (v1.0)
  tools/                 # install.sh, uninstall.sh, index-sync.sh
  .claude-plugin/        # marketplace.json
```

## Proposed Architecture -- v1.1 Target

```
skippy-agentspace/
  .claude-plugin/
    marketplace.json           # Updated: lists core + all add-on skills

  core/                        # NEW -- Core infrastructure package
    SKILL.md                   # Entry point: personas, LAWs summary, memory
    personas/                  # Skippy.md, Bob.md, Clarisa.md, April.md
    rules/                     # Portable subset of pai-private/rules
      laws/                    # LAW definitions (detailed docs)
      architecture/            # Output locations, minimal-claude-dir
      security/                # no-secrets-in-git
      stack/                   # python-prefs, typescript-prefs
      style/                   # communication-style
    hooks/                     # Hook scripts (source of truth)
      hook-manifest.json       # Declares symlinks + settings.json registrations
      law-enforcement/         # All 15+ enforcement hooks
        shared/                # types.ts, feedback-builder.ts, etc.
      safety/                  # Git safety hooks
      quality/                 # File size, etc.
      bash-helpers/            # Utility hooks
    memory/                    # Template memory files (not private data)
    scripts/
      bootstrap.sh             # Main bootstrap entry point
      install-hooks.sh         # Register hooks in settings.json
      install-core.sh          # Symlink core skill + rules

  skills/                      # All skills live here (flat, no category dirs)
    skippy-dev/                # EXISTING -- unchanged
    add-todo/                  # MIGRATED from ~/.config/pai/Skills/
    n8n/                       # MIGRATED (with references/)
    [... 60+ more]             # Each follows SKILL.md + references/ pattern

  upstreams/                   # NEW -- Extensible upstream system
    registry.json              # Upstream definitions (name, repo, hash, tracked_paths)
    gsd/                       # Per-upstream config
      tracked-paths.json
      cherry-picks.md          # What we've taken, what we've rejected
    paul/
    omc/
    scripts/
      upstream-check.sh        # Generic upstream checker (replaces skippy-update.sh)
      upstream-diff.sh         # Deep diff for a specific upstream
      upstream-add.sh          # Add a new upstream to registry

  tools/
    install.sh                 # Updated: handles core + skills + hooks
    uninstall.sh               # Updated: reverses everything
    bootstrap.sh               # NEW: clone + install = working PAI
    index-sync.sh              # Updated: handles expanded skill set
    migrate-skill.sh           # NEW: copy skill from ~/.config/pai/Skills/ into repo
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| `core/` | Personas, LAWs, rules, hooks -- the "operating system" layer | settings.json, SKILL.md auto-load |
| `core/hooks/` | Source of truth for enforcement hooks | `~/.claude/hooks/` via symlinks |
| `skills/` | Individual add-on skills, each self-contained | `~/.claude/skills/` via symlinks |
| `upstreams/` | Track external repos, detect changes, report diffs | `~/.cache/skippy-upstream/` |
| `tools/` | Installation, migration, indexing | All other components |

## Integration Points -- Existing to New

### 1. OMC Cherry-Pick Alongside PAUL Cherry-Pick

**Current:** Two hardcoded repos in `skippy-update.sh` with `.versions` tracking.

**New:** `upstreams/registry.json` with generic `upstream-check.sh`:

```json
{
  "upstreams": [
    {
      "name": "gsd",
      "repo": "https://github.com/gsd-build/get-shit-done.git",
      "branch": "main", "hash": "abc123",
      "tracked_paths": ["workflows/", "templates/", "bin/"]
    },
    {
      "name": "paul",
      "repo": "https://github.com/ChristopherKahler/paul.git",
      "branch": "main", "hash": "def456",
      "tracked_paths": ["."]
    },
    {
      "name": "omc",
      "repo": "https://github.com/Yeachan-Heo/oh-my-claudecode.git",
      "branch": "main", "hash": "ghi789",
      "tracked_paths": ["skills/", "agents/", "hooks/"]
    }
  ]
}
```

**What changes:**
- `.versions` -> `upstreams/registry.json` (richer, extensible)
- `skippy-update.sh` -> `upstream-check.sh` (reads registry, generic)
- Per-upstream `cherry-picks.md` for provenance

**What stays:** Human decides what to absorb. Cloned repos in `~/.cache/skippy-upstream/`.

**OMC cherry-pick targets** (from inspecting v4.7.3):

| OMC Feature | Worth It | Rationale |
|-------------|----------|-----------|
| `ralplan` (plan + architect + critic) | YES | Already used via slash command |
| 22 agent role definitions | YES | Well-defined personas (analyst, critic, etc.) |
| `security-review` | YES | Structured audit pattern |
| `ultraqa` / `ultrawork` | MAYBE | Multi-agent quality patterns |
| `code-review` | MAYBE | We have our own review patterns |
| Session management | NO | PAI has its own system |
| `omc-teams` / `omc-setup` | NO | OMC-specific orchestration |

### 2. Core Infrastructure Package

**Current:** Scattered across `~/.config/pai/Skills/CORE/`, `~/.config/pai-private/rules/`, `~/.config/pai-private/hooks/`, `~/.config/pai/hooks/`, `~/.claude/settings.json`.

**New:** `core/` directory is single source of truth.

**Private data separation:** Persona files contain personality/style definitions (portable). Personal info stays in `~/.config/pai-private/memory/` (already referenced by CORE SKILL.md, not packaged).

**Hook installation is the hardest part.** The `settings.json` hooks section is complex JSON -- matchers, arrays of hooks per matcher, order matters. Multiple systems write to it (GSD, OMC, PAI). Solution: `hook-manifest.json` declares our hooks, `install-hooks.sh` uses `jq` for non-destructive read-merge-write:

1. Read hook-manifest.json (what we want registered)
2. Read current settings.json
3. For each hook: check if already registered (by command path), skip if so
4. Append new hooks to appropriate matcher arrays
5. Write back, validate JSON

**Idempotency is critical.** Running install twice must produce the same result.

### 3. Add-On Skill Organization (68 Skills)

**Keep skills flat under `skills/`.** Do NOT use nested category directories because:
- `install.sh --all` and `index-sync.sh` expect `skills/*/SKILL.md`
- Symlinks target `~/.claude/skills/<name>/` -- no category prefix
- Categories belong in `INDEX.md` metadata, not filesystem

**Migration tool:** `tools/migrate-skill.sh <name>` copies from `~/.config/pai/Skills/<name>/`, validates SKILL.md frontmatter, normalizes structure, updates INDEX.md.

**Slim-core enforcement:** SKILL.md 150 lines max, deep docs in `references/`, commands in `commands/`, scripts in `scripts/`.

**Install granularity:**
- `install.sh <name>` -- single skill
- `install.sh --all` -- everything
- `install.sh --category n8n` -- all n8n-* skills
- `install.sh --core` -- core only
- `install.sh --bootstrap` -- core + essential skills

### 4. Bootstrap Flow

**Goal:** `git clone` + `./bootstrap.sh` = working PAI.

**Prerequisites:** macOS + Homebrew, `bun`, `jq`, Claude Code.

**Sequence:** Prerequisites check -> Directory setup (`~/.claude/`, `~/.config/pai/`, `~/.config/pai-private/`) -> Core install (symlink core/ to CORE/) -> Hooks install (symlink dirs + merge settings.json) -> Essential skills install -> Index generation -> Verification (symlinks resolve, JSON valid, print summary).

**Essential skills** (bootstrap default): CORE, skippy-dev, add-todo, check-todos, update-todo, session-wrap, checkpoint, correct, pai-init, skill-add. Everything else opt-in.

### 5. Hook Installation -- Portable Mechanics

**Current hook sources** (from settings.json inspection):

| Source | Path Pattern | Count |
|--------|-------------|-------|
| PAI private | `~/.claude/hooks/law-enforcement/*` | 15 |
| PAI private | `~/.claude/hooks/safety/*` | 7 |
| PAI private | `~/.claude/hooks/quality/*` | 1 |
| PAI private | `~/.claude/hooks/bash-helpers/*` | 1 |
| PAI public | `~/.config/pai/hooks/*` | 12+ |
| GSD | `~/.claude/hooks/gsd-*.js` | 3 |

**Hook manifest** (`core/hooks/hook-manifest.json`) declares:
- `symlinks`: directory name -> source path mappings
- `registrations`: event -> matcher -> array of hook commands

**`install-hooks.sh`** reads manifest, creates symlinks (update existing, warn on non-symlink conflicts), merges registrations via `jq`, validates result.

**Uninstall:** `uninstall.sh --hooks` removes symlinks and strips our registrations from settings.json (matched by command path prefix).

## Architectural Patterns

### Pattern 1: Symlink-as-Package-Manager

All installation is symlinks from repo to Claude Code discovery paths. Single source of truth, `git pull` updates everything, uninstall is `unlink`. Trade-off: repo must stay at stable path.

### Pattern 2: Slim-Core Skill Pattern

SKILL.md ~150 lines max. Deep docs in `references/`. Agents load on demand. Minimizes context window consumption.

### Pattern 3: Non-Destructive JSON Merge

When modifying `settings.json`: read-merge-write with `jq`. Never overwrite. Detect existing entries by command path. Requires `jq` dependency but coexists safely with GSD, OMC, manual entries.

### Pattern 4: Registry-Driven Upstream Tracking

`upstreams/registry.json` defines all tracked repos. Scripts are generic. Adding a new upstream is config, not code.

## Anti-Patterns

| Anti-Pattern | Why Wrong | Do This Instead |
|-------------|-----------|-----------------|
| Category directories in skills/ | Breaks install.sh paths, inconsistent symlinks | Flat `skills/<name>/`, categories in INDEX.md |
| Copying hooks instead of symlinking | Two copies diverge, updates need re-install | Symlink directories |
| Overwriting settings.json | Destroys GSD/OMC/user config | Read-merge-write with jq |
| Forking upstream repos | Maintenance burden, divergence | Parasitic: ride upstream, cherry-pick ideas |
| Monolithic SKILL.md (500+ lines) | Eats context window | 150-line SKILL.md + references/ |

## New vs Modified vs Unchanged Components

### New

| Component | Dependencies |
|-----------|-------------|
| `core/` directory | None (replaces scattered files) |
| `core/hooks/` + hook-manifest.json | `bun` runtime, shared/ library |
| `core/scripts/bootstrap.sh` | `jq`, `bun` |
| `core/scripts/install-hooks.sh` | `jq` |
| `upstreams/` directory + registry.json | None |
| `upstreams/scripts/upstream-check.sh` | `git` |
| `tools/migrate-skill.sh` | None |

### Modified

| Component | Change | Risk |
|-----------|--------|------|
| `tools/install.sh` | Add `--core`, `--bootstrap`, `--category` flags | LOW |
| `tools/uninstall.sh` | Add hook removal, core removal | LOW |
| `tools/index-sync.sh` | Handle 68+ skills, categories | LOW |
| `.claude-plugin/marketplace.json` | List core + all skills | LOW |
| `skills/skippy-dev/commands/update.md` | Point to new upstream-check.sh | LOW |
| `skills/skippy-dev/.versions` | DEPRECATED -> upstreams/registry.json | MEDIUM |

### Unchanged

`skills/skippy-dev/SKILL.md`, all 6 reference docs, `reconcile.md`, `cleanup.md` -- v1.0 works as-is.

## Suggested Build Order

```
Phase 1: Upstream System (no deps on other new components)
  upstreams/registry.json, upstream-check.sh, per-upstream config
  Update /skippy:update, migrate .versions data

Phase 2: Core Infrastructure (no deps on new components)
  core/SKILL.md, personas/, rules/, hooks/, hook-manifest.json

Phase 3: Hook Installation (depends on Phase 2)
  install-hooks.sh (jq-based merge), uninstall support, idempotency testing

Phase 4: Skill Migration (parallelizable with 1-3)
  migrate-skill.sh, essential skills first, slim-core enforcement, batch remaining

Phase 5: Bootstrap (depends on 1-4)
  bootstrap.sh, prerequisites check, end-to-end testing

Phase 6: Index & Documentation (depends on all)
  INDEX.md with categories, AGENT-INDEX.md, marketplace.json, CLAUDE.md
```

**Phases 1, 2, and 4 can run in parallel.** Phase 3 depends on 2. Phase 5 depends on 1-4.

## Scaling Considerations

| Concern | At 10 skills (now) | At 70 skills (v1.1) | At 200+ (future) |
|---------|-------------------|---------------------|-------------------|
| Index generation | Instant | ~1 second | Cache/incremental |
| Install --all | Instant | ~2 seconds | Parallel symlinks |
| settings.json size | ~200 lines | ~400 lines | Watch for limits |
| Upstream checks | 2 repos | 3-5 repos | Parallel fetch |

No scaling concerns at v1.1. 70-skill flat directory is well within limits.

## Sources

- Direct filesystem inspection of `~/.config/pai/Skills/` (69 directories)
- Direct filesystem inspection of `~/.config/pai-private/hooks/` (6 subdirs, 25+ scripts)
- Direct inspection of `~/.claude/settings.json` hooks configuration (full JSON)
- Direct inspection of `~/.claude/plugins/cache/omc/oh-my-claudecode/4.7.3/` (37 skills, 22 agents)
- Existing `skills/skippy-dev/` architecture (v1.0 working implementation)
- Existing `tools/install.sh` dual-target implementation
- Claude Code hook API: PreToolUse/PostToolUse decision format (types.ts, feedback-builder.ts)

---
*Architecture research for: skippy-agentspace v1.1 -- Portable PAI Infrastructure*
*Researched: 2026-03-07*
