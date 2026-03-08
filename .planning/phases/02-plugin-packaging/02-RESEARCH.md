# Phase 2: Plugin Packaging - Research

**Researched:** 2026-03-07
**Domain:** Claude Code plugin system, marketplace distribution, dual-target install
**Confidence:** HIGH

## Summary

The Claude Code plugin system is well-documented and stable as of v2.1.71. The system uses two files for distribution: `marketplace.json` (in `.claude-plugin/`) catalogs available plugins, and `plugin.json` (also in `.claude-plugin/`) describes a single plugin's metadata. Crucially, `plugin.json` is OPTIONAL -- when a marketplace entry sets `strict: false`, the marketplace entry itself becomes the complete plugin definition, and no `plugin.json` is needed. This is the pattern Anthropic uses in their own `anthropics/skills` repo.

For skippy-agentspace, the cleanest approach is the "single-repo marketplace" pattern: the repo IS the marketplace AND the plugin. `marketplace.json` lives at `.claude-plugin/marketplace.json`, defines one plugin entry with `source: "./"` and `strict: false`, and explicitly lists the skills directory. No `plugin.json` is needed. Users install with `/plugin marketplace add owner/repo` then `/plugin install skippy-dev@skippy-agentspace`.

The dual-target install requirement (STRU-03) is straightforward. `~/.claude/skills/` is the modern path (skill directories with SKILL.md), `~/.claude/commands/` is legacy (standalone .md files). Both coexist. Detection is simple: check if `~/.claude/skills/` exists (modern Claude Code) and prefer it; fall back to `~/.claude/commands/` for legacy. The current install.sh only targets commands/ -- it needs a new code path for skills/.

**Primary recommendation:** Use the Anthropic `strict: false` + `source: "./"` single-repo marketplace pattern. Create `marketplace.json` only (no `plugin.json`). Update `install.sh` to detect and use `~/.claude/skills/` when available, falling back to `~/.claude/commands/`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SPEC-04 | Plugin packaging -- `.claude-plugin/plugin.json` and `marketplace.json` enable native `/plugin install` from this repo | Marketplace schema fully documented. `strict: false` pattern means NO plugin.json needed -- marketplace.json alone suffices. Anthropic's own skills repo validates this approach. |
| STRU-03 | Install tooling supports both `~/.claude/skills/` (modern) and `~/.claude/commands/` (legacy) targets | Skills docs confirm both paths work. Skills take precedence over commands with same name. Detection logic: check directory existence + Claude Code version. |
</phase_requirements>

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| marketplace.json | Claude Code 2.1+ | Plugin catalog for distribution | Official plugin marketplace format -- the ONLY way to distribute via `/plugin marketplace add` |
| `strict: false` | Claude Code 2.1+ | Declare plugin entirely in marketplace entry | Anthropic's own `anthropics/skills` repo uses this pattern for all their plugins |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `plugin.json` | Per-plugin manifest | NOT needed when using `strict: false` in marketplace entry. Only needed for `strict: true` (default) plugins. |
| `claude plugin validate .` | Validate marketplace/plugin JSON | Run after creating marketplace.json to catch syntax errors |
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to plugin install dir | Use in hooks, MCP servers, scripts within plugin context. NOT the same as `${CLAUDE_SKILL_DIR}`. |
| `${CLAUDE_SKILL_DIR}` | Absolute path to skill directory | Use in SKILL.md content for referencing scripts/files. Bug #11011 still OPEN -- avoid in `@` references. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `strict: false` (no plugin.json) | `strict: true` with plugin.json | Adds a second JSON file to maintain for no benefit. Only useful when marketplace operator wants to override plugin's own manifest. |
| Single-repo marketplace | Separate marketplace repo | Adds a separate repo to maintain. Only useful when distributing plugins from multiple sources. |
| npm source | Relative path source | Project constraint explicitly rejects npm publishing. |

## Architecture Patterns

### Recommended Directory Structure (After Phase 2)

```
skippy-agentspace/
  .claude-plugin/
    marketplace.json          # NEW -- marketplace catalog
  skills/
    skippy-dev/
      SKILL.md                # Existing -- skill entry point
      commands/               # Existing -- slash commands
      references/             # Existing -- enhancement docs
      scripts/                # Existing -- utility scripts
      .versions               # Existing -- upstream tracking
  tools/
    install.sh                # MODIFIED -- dual target support
    uninstall.sh              # MODIFIED -- dual target support
    index-sync.sh             # Existing
  INDEX.md                    # Existing
```

### Pattern 1: Single-Repo Marketplace (Anthropic Pattern)

**What:** The repo serves as both marketplace AND plugin. `marketplace.json` points to `"./"` (repo root) as the plugin source.

**When to use:** Single-plugin repos where the repo IS the plugin.

**Example (from Anthropic's `anthropics/skills`):**

```json
// .claude-plugin/marketplace.json
{
  "name": "skippy-agentspace",
  "owner": {
    "name": "Rico",
    "email": "rico@example.com"
  },
  "metadata": {
    "description": "Development workflow enhancements for Claude Code",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "skippy-dev",
      "description": "Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency",
      "source": "./",
      "strict": false,
      "version": "0.1.0",
      "skills": [
        "./skills/skippy-dev"
      ]
    }
  ]
}
```

**Source: Verified from `anthropics/skills` repo via GitHub API (HIGH confidence)**

Key properties of this pattern:
- `source: "./"` -- plugin is the entire repo
- `strict: false` -- no plugin.json needed, marketplace entry is the complete definition
- `skills: [...]` -- explicit list of skill directories to expose
- No `plugin.json` file exists anywhere in the repo

### Pattern 2: Dual-Target Install Detection

**What:** install.sh detects whether `~/.claude/skills/` or `~/.claude/commands/` should be used, and symlinks appropriately.

**When to use:** Manual installs (not via plugin marketplace).

**Logic:**

```bash
# Modern: ~/.claude/skills/<name>/  (directory with SKILL.md)
# Legacy: ~/.claude/commands/<name>  (symlink to commands/ dir)
#
# Detection: ~/.claude/skills/ exists = modern target
# Fallback: ~/.claude/commands/ always works
# Override: --target=skills|commands flag

if [[ -d "$HOME/.claude/skills" ]]; then
    # Modern: symlink entire skill directory
    ln -s "$skill_dir" "$HOME/.claude/skills/$name"
else
    # Legacy: symlink commands/ subdirectory only
    mkdir -p "$HOME/.claude/commands"
    ln -s "$skill_dir/commands" "$HOME/.claude/commands/$name"
fi
```

**Source: Official Claude Code docs confirm both paths work (HIGH confidence)**

### Pattern 3: Plugin Namespace Awareness

**What:** When installed via plugin marketplace, skills get namespaced as `plugin-name:skill-name`.

**When to use:** Understanding how the installed skill will appear to users.

**Details:**
- Plugin install: `/skippy-agentspace:skippy-dev` (namespaced)
- Manual install to `~/.claude/skills/`: `/skippy-dev` (no namespace)
- Manual install to `~/.claude/commands/`: `/skippy:reconcile`, `/skippy:update`, `/skippy:cleanup` (directory-based)

**Known bug #22063:** If SKILL.md has a `name` field, the namespace prefix may be stripped, causing the skill to appear as `/skippy-dev` instead of `/skippy-agentspace:skippy-dev`. Bug is closed (inactive), status unclear. Anthropic's own skills all use `name:` in frontmatter, suggesting they accept this behavior or the bug is effectively a feature.

### Anti-Patterns to Avoid

- **Creating plugin.json when using strict: false:** Causes conflict error: "Plugin has conflicting manifests: both plugin.json and marketplace entry specify components." If `strict: false`, marketplace.json is the ONLY definition.
- **Putting skills/ inside .claude-plugin/:** Components must be at plugin root, not inside `.claude-plugin/`. Only `plugin.json` and `marketplace.json` go there.
- **Using `../` paths in plugin files:** Plugin install copies to cache (`~/.claude/plugins/cache`). External paths break. Everything must be self-contained.
- **Setting version in both marketplace.json and plugin.json:** plugin.json wins silently, causing confusion. Pick one place (marketplace.json for `strict: false`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plugin distribution | Custom install scripts for marketplace users | `marketplace.json` + `/plugin marketplace add` | Claude Code's native plugin system handles caching, versioning, and updates automatically |
| Version tracking for plugin users | Custom version check scripts | `version` field in marketplace.json | Claude Code compares versions and auto-updates |
| Plugin validation | Manual JSON checks | `claude plugin validate .` or `/plugin validate .` | Built-in validator catches schema errors, duplicate names, path traversal |

**Key insight:** The plugin system handles the hard parts (caching, versioning, updates, validation). Our job is just creating the right JSON files and ensuring the directory structure is correct. The manual install.sh is for users who prefer symlinks over the plugin system.

## Common Pitfalls

### Pitfall 1: Plugin Caching Breaks External References

**What goes wrong:** After plugin install, skill files reference paths that don't exist because the plugin was copied to `~/.claude/plugins/cache/`.
**Why it happens:** Plugin install copies the plugin directory, not files outside it. Paths like `../shared/` or absolute paths break.
**How to avoid:** Everything the skill needs must be inside the plugin directory tree. All our skill files are already under `skills/skippy-dev/` -- verify no references escape this boundary.
**Warning signs:** "File not found" errors after plugin install that don't happen with manual symlink install.

### Pitfall 2: strict: false with Existing plugin.json

**What goes wrong:** Plugin fails to load with "conflicting manifests" error.
**Why it happens:** `strict: false` means marketplace.json is the complete definition. If plugin.json also exists and declares components, it's a conflict.
**How to avoid:** Do NOT create `.claude-plugin/plugin.json` when using `strict: false`. Only create `marketplace.json`.
**Warning signs:** Error message: "Plugin my-plugin has conflicting manifests."

### Pitfall 3: CLAUDE_SKILL_DIR Bug with Plugin Scripts (#11011 -- OPEN)

**What goes wrong:** `${CLAUDE_SKILL_DIR}` doesn't resolve correctly on first plugin execution, causing script paths to fail.
**Why it happens:** Bug #11011 in Claude Code -- path resolution race on first load after plugin install.
**How to avoid:** Phase 1 already addressed this by using relative `@../` paths for command file context references. For scripts called from SKILL.md body, `${CLAUDE_SKILL_DIR}` is used (works after first load). The plugin marketplace caches files, so the issue may manifest differently.
**Warning signs:** Scripts work on second run but fail on first run after fresh install.

### Pitfall 4: Namespace Flattening (#22063)

**What goes wrong:** Plugin skill appears as `/skippy-dev` instead of `/skippy-agentspace:skippy-dev` because SKILL.md has `name: skippy-dev`.
**Why it happens:** Bug #22063 -- `name` field in frontmatter bypasses plugin namespace prefix.
**How to avoid:** Anthropic's own skills have `name` fields and presumably accept this behavior. For our case, this is actually desirable -- users probably WANT `/skippy-dev` not `/skippy-agentspace:skippy-dev`. Keep the `name` field.
**Warning signs:** None -- this behavior is arguably better for usability.

### Pitfall 5: install.sh Doesn't Handle Both Targets

**What goes wrong:** User has modern Claude Code with `~/.claude/skills/` but install.sh only symlinks to `~/.claude/commands/`, meaning skill is discovered as commands-only (no SKILL.md auto-loading, no supporting files).
**Why it happens:** Current install.sh only knows about `~/.claude/commands/`.
**How to avoid:** Update install.sh to detect `~/.claude/skills/` and symlink the entire skill directory there. When targeting skills/, symlink `skills/skippy-dev/` to `~/.claude/skills/skippy-dev/`. When targeting commands/, symlink `skills/skippy-dev/commands/` to `~/.claude/commands/skippy/`.
**Warning signs:** Skill works as slash commands but Claude doesn't auto-invoke it based on description.

## Code Examples

### marketplace.json for skippy-agentspace

```json
// Source: Pattern derived from anthropics/skills repo (verified via GitHub API)
// File: .claude-plugin/marketplace.json
{
  "name": "skippy-agentspace",
  "owner": {
    "name": "Rico"
  },
  "metadata": {
    "description": "Development workflow enhancements for Claude Code -- augments GSD with best ideas from PAUL",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "skippy-dev",
      "description": "Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency",
      "source": "./",
      "strict": false,
      "version": "0.1.0",
      "author": {
        "name": "Rico"
      },
      "skills": [
        "./skills/skippy-dev"
      ]
    }
  ]
}
```

### Dual-Target install.sh (Conceptual)

```bash
#!/usr/bin/env bash
# Source: Derived from official docs on skill/command locations
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET="${2:-auto}"  # auto, skills, commands

detect_target() {
    case "$TARGET" in
        skills)   echo "skills" ;;
        commands) echo "commands" ;;
        auto)
            if [[ -d "$HOME/.claude/skills" ]]; then
                echo "skills"
            else
                echo "commands"
            fi
            ;;
    esac
}

install_skill_modern() {
    local name="$1"
    local src="$SKILLS_DIR/$name"
    local dest="$HOME/.claude/skills/$name"
    mkdir -p "$HOME/.claude/skills"
    [[ -L "$dest" ]] && unlink "$dest"
    ln -s "$src" "$dest"
    echo "  INSTALLED (skills): $name -> $dest"
}

install_skill_legacy() {
    local name="$1"
    local src="$SKILLS_DIR/$name/commands"
    local dest="$HOME/.claude/commands/$name"
    mkdir -p "$HOME/.claude/commands"
    [[ -L "$dest" ]] && unlink "$dest"
    ln -s "$src" "$dest"
    echo "  INSTALLED (commands): $name -> $dest"
}
```

### Dual-Target uninstall.sh (Conceptual)

```bash
#!/usr/bin/env bash
# Source: Derived from official docs
set -euo pipefail

SKILL_NAME="${1:-}"

# Check both locations
for dir in "$HOME/.claude/skills" "$HOME/.claude/commands"; do
    local link="$dir/$SKILL_NAME"
    if [[ -L "$link" ]]; then
        unlink "$link"
        echo "UNINSTALLED: $SKILL_NAME from $dir"
    fi
done
```

### Validation Command

```bash
# After creating marketplace.json, validate:
claude plugin validate /Volumes/ThunderBolt/Development/skippy-agentspace

# Or from within Claude Code session:
# /plugin validate .
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `~/.claude/commands/` only | `~/.claude/skills/` preferred, commands/ still works | Claude Code 2.0+ | Skills get auto-discovery, supporting files, frontmatter control. Commands are "legacy but working." |
| `plugin.json` required | `strict: false` makes plugin.json optional | Claude Code 2.1+ | Simpler setup for marketplace-defined plugins. Anthropic's own repos use this. |
| Manual install only | `/plugin marketplace add` + `/plugin install` | Claude Code 2.0+ | Native distribution, caching, versioning, auto-updates |
| `triggers:` in frontmatter | `description:` drives auto-discovery | Agent Skills spec 1.0 | Phase 1 already fixed this |

**Deprecated/outdated:**
- `commands/` for new plugins -- still works but `skills/` is preferred. New plugins should use `skills/` structure.
- `triggers:` frontmatter field -- never was standard; removed in Phase 1.
- Manual-only distribution -- plugin marketplace is the standard distribution channel now.

## Open Questions

1. **Does `commands/` subdirectory get discovered when plugin uses `skills: [...]`?**
   - What we know: The `skills` field in marketplace.json points to skill directories (with SKILL.md). Commands inside a skill's `commands/` subdirectory are a separate discovery mechanism.
   - What's unclear: When installed via plugin with `strict: false` and `skills: ["./skills/skippy-dev"]`, will the `commands/reconcile.md` etc. inside that skill directory also be discovered as slash commands? The official docs say "commands/ directory in plugin root" is the default location, but our commands are nested inside a skill.
   - Recommendation: Test this during implementation. If commands aren't auto-discovered, add `"commands": ["./skills/skippy-dev/commands/"]` to the marketplace plugin entry. This is a supplemental path (doesn't replace defaults).

2. **How does the `skippy` symlink in `~/.claude/commands/` interact with plugin-installed skills?**
   - What we know: Rico currently has `~/.claude/commands/skippy -> ../../.config/pai/Skills/skippy-dev/commands` as a symlink. Plugin install would add skills to `~/.claude/plugins/cache/`.
   - What's unclear: Does having the same skill accessible via both commands/ symlink AND plugin cache cause conflicts or duplicate slash commands?
   - Recommendation: Document that users should run `tools/uninstall.sh` before installing via plugin marketplace to avoid duplicate registration. Add a check to install.sh that warns if plugin-installed version is detected.

3. **Reserved marketplace names**
   - What we know: Official docs list reserved names: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`. Names that impersonate official marketplaces are also blocked.
   - What's unclear: Whether `skippy-agentspace` could ever collide with reserved names.
   - Recommendation: `skippy-agentspace` is fine -- no collision risk. No action needed.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual validation (shell scripts + Claude Code plugin system) |
| Config file | none -- see Wave 0 |
| Quick run command | `claude plugin validate /Volumes/ThunderBolt/Development/skippy-agentspace` |
| Full suite command | Manual: validate JSON, test plugin install, verify skill loads |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPEC-04 | marketplace.json is valid and plugin installs | smoke | `claude plugin validate .` | No -- Wave 0 |
| SPEC-04 | Plugin install via marketplace loads skill without errors | manual | `/plugin marketplace add ./` then `/plugin install skippy-dev@skippy-agentspace` | No -- manual |
| STRU-03 | install.sh detects skills/ target correctly | smoke | `bash tools/install.sh --all --target=skills && ls -la ~/.claude/skills/skippy-dev` | No -- Wave 0 |
| STRU-03 | install.sh falls back to commands/ target | smoke | `bash tools/install.sh --all --target=commands && ls -la ~/.claude/commands/skippy-dev` | No -- Wave 0 |

### Sampling Rate

- **Per task commit:** `claude plugin validate .`
- **Per wave merge:** Full manual test: validate, install via marketplace, verify skill loads, test both install targets
- **Phase gate:** All validation checks pass before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `marketplace.json` -- the primary deliverable (does not exist yet)
- [ ] Validation script or checklist for plugin install smoke test
- [ ] Updated install.sh with dual-target logic
- [ ] Updated uninstall.sh with dual-target cleanup

## Sources

### Primary (HIGH confidence)

- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- complete marketplace.json schema, strict mode, plugin sources, caching behavior
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- plugin.json manifest schema, directory structure, environment variables, validation
- [Claude Code Skills](https://code.claude.com/docs/en/skills) -- skills vs commands, discovery locations, frontmatter reference, ${CLAUDE_SKILL_DIR}
- `anthropics/skills` repo marketplace.json (fetched via `gh api`) -- real-world `strict: false` pattern with `source: "./"` and explicit `skills: [...]` arrays
- `anthropics/claude-plugins-official` repo marketplace.json (fetched via `gh api`) -- official plugin catalog showing multiple patterns

### Secondary (MEDIUM confidence)

- [GitHub Issue #22063](https://github.com/anthropics/claude-code/issues/22063) -- namespace flattening when SKILL.md has `name` field (CLOSED, inactive)
- [GitHub Issue #11011](https://github.com/anthropics/claude-code/issues/11011) -- ${CLAUDE_SKILL_DIR} path resolution bug on first execution (OPEN)

### Tertiary (LOW confidence)

- WebSearch results on `~/.claude/skills/` vs `~/.claude/commands/` migration -- community discussion, not official guidance

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- verified from official docs and Anthropic's own repos
- Architecture: HIGH -- pattern directly copied from Anthropic's `anthropics/skills` repo
- Pitfalls: HIGH -- bugs verified from GitHub issues with reproduction steps
- Dual-target install: MEDIUM -- detection logic is straightforward but the interaction between plugin-installed and manually-installed skills needs testing

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stable -- plugin system is mature)
