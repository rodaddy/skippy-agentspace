# Phase 9: Skill System - Research

**Researched:** 2026-03-08
**Domain:** Skill migration, selective installation, skill packaging
**Confidence:** HIGH

## Summary

Phase 9 transforms skippy-agentspace from a 2-skill repo into a full skill marketplace with selective install, an AI-driven migration command, and ~10-15 essential PAI skills ported to portable format. The existing infrastructure is solid -- install.sh, uninstall.sh, INDEX.md, index-sync.sh, and marketplace.json all need extension rather than rewriting. The migration challenge is primarily content sanitization (stripping private IPs, credentials, PAI-specific references) and structural flattening (Workflows/, Tools/, helpers/, templates/, bin/ all become references/ or scripts/).

There are 68 skills in `~/.config/pai/Skills/`. Source SKILL.md files range from 40 lines (Research) to 748 lines (n8n-code-python). Many use non-standard directory layouts (Workflows/, Tools/, helpers/, templates/, agents/, config/, tools/) that must be flattened to the portable format (SKILL.md + references/ + commands/ + scripts/). Several skills contain private infrastructure details (IPs, server names, credential names, port numbers) requiring sanitization during migration.

**Primary recommendation:** Extend install.sh incrementally (add `--core` flag + multi-positional args), create `/skippy:migrate` as a markdown AI command following the Phase 8 update.md pattern, migrate skills in priority order (daily drivers first, then foundational, then portable-value), and evolve INDEX.md/index-sync.sh for category grouping.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Skill Selection:**
- Primary criterion: daily driver frequency, then foundational chain, then portable value
- Hybrid discovery: AI scans ~/.config/pai/Skills/ and presents ranked candidates, user approves/rejects from their mental shortlist
- Duplicates flagged interactively during migration -- user picks which to keep/merge/drop
- Target count is a rough guide (~10-15), not a hard cap -- quality over count
- Unused duplicates cleaned up from the actual install during migration

**Migration Approach:**
- Migration tool is an AI command (markdown-based), not a shell script -- consistent with Phase 8 agent-driven operations decision
- PAI-specific features (persona references, LAW enforcement, hooks) stripped during migration with "PAI enhancements available" gap notes in SKILL.md
- Always dry-run first -- show file tree, SKILL.md preview, what gets stripped, then confirm before writing
- All skills flattened to standard layout: SKILL.md + references/ + commands/ + scripts/ -- consistency over preservation of source structure

**Install UX:**
- Flag style: positional args for skill names, --core and --all as special flags
  - `install.sh --core` installs core only
  - `install.sh skippy-dev` installs one skill
  - `install.sh skippy-dev homeassistant` installs multiple skills
  - `install.sh --all` installs everything
- No-arg behavior: show installed/available status table + usage help
- All skills are standalone -- no core dependency required. Maximum portability.
- uninstall.sh mirrors install.sh with selective uninstall (positional skill names, --all)

**INDEX.md Evolution:**
- 4 categories: core, workflow, utility, domain
- Badge-style install markers inline (e.g., `core [installed]`) -- no extra column
- Grouped by category with section headers (## Core, ## Workflow, etc.)
- Each category has its own table with Skill, Path, Commands columns

### Claude's Discretion
- Error handling strategy for install.sh (continue-on-error vs stop-on-first based on severity)
- INDEX.md sync trigger mechanism (on sync vs on install/uninstall)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SKIL-01 | install.sh supports selective install (--core, --skill, --all flags) | Existing install.sh analyzed (203 lines). Argument parsing at lines 26-61 needs extension for --core flag and multi-positional args. install_skill() function reusable as-is. No-arg status table is new. |
| SKIL-02 | migrate-skill.sh imports skills from ~/.config/pai/Skills/ into portable format | All 68 source skills cataloged with line counts and directory structures. Migration is an AI command (per CONTEXT.md), not a shell script. Follows update.md pattern from Phase 8. |
| SKIL-03 | ~10 essential skills migrated with slim SKILL.md + deep references | Candidate analysis complete below. Many skills already under 150 lines. 5 structural patterns identified for flattening. Private content categories documented. |
| SKIL-04 | INDEX.md updated with categories and install status | Current INDEX.md is flat single table with Plugin Distribution footer. index-sync.sh (109 lines) generates from frontmatter. Needs category detection and install badge injection. |

</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash 4+ | 4.x/5.x | Shell scripts (install.sh, uninstall.sh, index-sync.sh) | Already the project standard, shebang `#!/usr/bin/env bash` |
| Markdown AI commands | N/A | /skippy:migrate command definition | Phase 8 established this as the pattern for AI-driven operations |
| jq | 1.7+ | JSON manipulation for marketplace.json | Already a project dependency (used in hook installer) |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| sed/grep | SKILL.md frontmatter extraction in index-sync.sh | Already used in current index-sync.sh |
| readlink | Symlink target resolution for install status detection | Already used in uninstall.sh |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shell script for migration | AI command (markdown) | AI command chosen -- more flexible, handles content decisions, consistent with Phase 8 |
| bun for JSON ops | jq | jq is lighter, already a dependency, no Node.js runtime needed for simple JSON edits |

## Architecture Patterns

### Target Portable Skill Layout
```
skills/<skill-name>/
  SKILL.md              # Entry point, <150 lines, YAML frontmatter
  references/           # Deep reference docs (optional)
    <topic>.md
  commands/             # Slash command definitions (optional)
    <command>.md
  scripts/              # Shell/TypeScript helpers (optional)
    <script>.sh
```

### Pattern 1: Source-to-Portable Directory Mapping
**What:** Flatten any PAI skill directory structure to the portable standard.
**When to use:** During every skill migration.

| Source Directory | Maps To | Notes |
|-----------------|---------|-------|
| `Workflows/` | `references/` | Rename files to lowercase-kebab |
| `Tools/` or `tools/` | `scripts/` (if executable) or `references/` (if docs) | TypeScript tools with node_modules are NOT portable -- document capability, don't copy runtime |
| `helpers/` | `scripts/` | Shell helpers are directly portable |
| `templates/` | `references/` | Config templates (nginx, systemd, etc.) |
| `agents/` | `references/` | Agent definitions become reference docs |
| `config/` | `references/` | Config files become reference docs |
| `workflows/` (lowercase) | `references/` | Same as Workflows/ |
| `bin/` | `scripts/` | Already handled by Phase 1 convention |

### Pattern 2: SKILL.md Slimming Strategy
**What:** Reduce oversized SKILL.md files to <150 lines while preserving all content.
**When to use:** When source SKILL.md exceeds 150 lines.

Strategy:
1. Keep in SKILL.md: frontmatter, 1-paragraph description, quick reference table, common operations summary, reference list, gotchas (top 5 only)
2. Move to references/: detailed workflows, extended gotchas, code examples, configuration details, API reference
3. The slim SKILL.md becomes an index -- each section points to a reference file

**Source skills already under 150 lines (no slimming needed):** 42 of 68 skills. These migrate with minimal changes.

**Source skills needing slimming (150+ lines):** 26 skills. The migration command handles this interactively.

### Pattern 3: Private Content Sanitization
**What:** Strip PAI infrastructure-specific content during migration.
**When to use:** Any skill referencing private infrastructure.

| Content Type | Example | Action |
|--------------|---------|--------|
| IP addresses | `10.71.1.31`, `10.71.20.51` | Replace with `<your-server-ip>` placeholder |
| Server names | `proxmox01`, `CT 202` | Replace with `<your-host>` placeholder |
| Credentials | `rico@rodaddy.live`, vaultwarden entries | Remove entirely, add "configure your credentials" note |
| Domain names | `rodaddy.live`, `n8n.rodaddy.live` | Replace with `<your-domain>` placeholder |
| Port/path specifics | `/home/n8n/.n8n/env` | Keep generic paths, replace user-specific ones |
| PAI tool references | `claudePy`, `qmd`, persona switching | Add "PAI enhancements available" gap note |

### Pattern 4: AI Command Structure (for /skippy:migrate)
**What:** Follow the established command markdown pattern from Phase 8.
**When to use:** Creating the migration command.

```markdown
---
name: skippy:migrate
description: Migrate a PAI skill into portable format
---

<objective>
[What the command does]
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>
## 1. [Step]
...
</process>
```

### Anti-Patterns to Avoid
- **Copying node_modules or bun.lock:** TypeScript tools with dependencies are NOT portable. Document the capability in references/, don't copy the runtime.
- **Preserving source directory names:** Workflows/, Tools/, helpers/ must be flattened to references/ or scripts/. Consistency over source fidelity.
- **Blind content copy:** Every SKILL.md must be reviewed for private content. The AI command handles this, but the planner must ensure it's a required step.
- **Hardcoding the skill list:** The migration command should scan and rank, not have a fixed list baked in.

## Skill Migration Candidates

### Tier 1: Daily Drivers (migrate first)
These are used in nearly every session per the CLAUDE.md "Skills You Keep Skipping" table.

| Skill | Lines | Has References | Private Content | Migration Complexity |
|-------|-------|---------------|-----------------|---------------------|
| session-wrap | 269 | No | Dev paths only | MEDIUM -- needs slimming, path placeholders |
| add-todo | 287 | No | Dev paths only | MEDIUM -- needs slimming, path placeholders |
| check-todos | 208 | No | Dev paths only | MEDIUM -- needs slimming, path placeholders |
| update-todo | 154 | No | Dev paths only | LOW -- barely over 150 lines |
| vaultwarden | 98 | Yes (2) | No (MCP-based) | LOW -- already slim, references/ exist |
| browser | 188 | No | Credential names | MEDIUM -- needs slimming, credential sanitization |
| Fabric | 127 | No | LiteLLM details | LOW -- under 150, strip LiteLLM specifics |

### Tier 2: Foundational Chain (infrastructure skills)
Skills that other skills depend on or that support the overall system.

| Skill | Lines | Has References | Private Content | Migration Complexity |
|-------|-------|---------------|-----------------|---------------------|
| deploy-service | 82 | Workflows/ + templates/ + helpers/ | Heavy (IPs, domains, NICs) | HIGH -- full sanitization + flatten |
| proxmox | 99 | Scripts (pve-call) | Heavy (IPs, server IDs) | HIGH -- full sanitization |
| homeassistant | 122 | Yes (5) | Heavy (IPs, VM IDs, paths) | HIGH -- full sanitization |
| litellm | 315 | Script (list-models.sh) | Heavy (IPs, endpoints) | HIGH -- needs slimming + sanitization |

### Tier 3: Portable Value (universally useful)
Skills that work without any PAI infrastructure.

| Skill | Lines | Has References | Private Content | Migration Complexity |
|-------|-------|---------------|-----------------|---------------------|
| excalidraw | 83 | Yes (4 + palettes) | No | LOW -- already portable |
| prd | 675 | No | No | MEDIUM -- heavy slimming needed |
| correct | 75 | No | No | LOW -- already portable |
| checkpoint | 141 | No | No | LOW -- under 150, portable |
| pai-init | 91 | No | No | LOW -- already portable |

### Recommended Initial Set (10-15 skills)

Based on the prioritization criteria (daily frequency > foundational > portable value):

1. **vaultwarden** -- LOW complexity, daily driver
2. **add-todo** -- MEDIUM, daily driver
3. **check-todos** -- MEDIUM, daily driver
4. **update-todo** -- LOW, daily driver
5. **session-wrap** -- MEDIUM, daily driver
6. **Fabric** -- LOW, daily driver
7. **browser** -- MEDIUM, daily driver
8. **excalidraw** -- LOW, universally portable
9. **correct** -- LOW, universally portable
10. **deploy-service** -- HIGH but essential, foundational
11. **homeassistant** -- HIGH, domain skill
12. **proxmox** -- HIGH, foundational
13. **prd** -- MEDIUM, universally portable

The AI migration command will present ranked candidates and let the user approve/reject, so this list is a starting recommendation, not final.

### Category Assignment

| Category | Skills |
|----------|--------|
| **core** | core (already exists) |
| **workflow** | skippy-dev, session-wrap, add-todo, check-todos, update-todo, correct |
| **utility** | vaultwarden, browser, excalidraw, Fabric, prd |
| **domain** | deploy-service, homeassistant, proxmox, litellm |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink management | Custom symlink logic | Extend existing install.sh | Already handles modern/legacy targets, plugin conflicts, error cases |
| JSON editing | sed/awk on marketplace.json | jq | JSON manipulation with sed is fragile, jq is already a dependency |
| SKILL.md frontmatter parsing | Custom parser | sed -n (already used in index-sync.sh) | Simple enough for sed, consistent with existing code |
| Install status detection | Custom check script | readlink + test -L (already in uninstall.sh) | Symlink presence = installed, readlink gives source |
| Skill content analysis | Shell script content parser | AI command (Claude reads and decides) | Content decisions (what's private, what to slim) require judgment, not regex |

**Key insight:** The hardest part of migration is content judgment (what to strip, what to keep, how to slim), which is exactly what AI commands excel at. Shell scripts handle the mechanical parts (symlinks, JSON, file copying).

## Common Pitfalls

### Pitfall 1: Copying Non-Portable Dependencies
**What goes wrong:** Skills like Art (has node_modules, bun.lock, TypeScript tools) get copied with their runtime dependencies, creating bloated non-portable skills.
**Why it happens:** Treating migration as file copy rather than content migration.
**How to avoid:** The migration command must classify each file: portable (copy), capability-doc (document in references/), or skip (node_modules, .DS_Store, backups).
**Warning signs:** skills/ directory growing with node_modules, lock files, or compiled artifacts.

### Pitfall 2: Incomplete Private Content Sanitization
**What goes wrong:** A migrated skill ships with real IPs (10.71.x.x), credentials, or server names.
**Why it happens:** Manual review misses embedded references in reference docs, not just SKILL.md.
**How to avoid:** The migration command must scan ALL files in the source skill, not just SKILL.md. Pattern list: IP regex `10\.71\.\d+\.\d+`, domain regex `rodaddy\.live`, credential patterns.
**Warning signs:** grep -r for IP patterns in skills/ after migration.

### Pitfall 3: Breaking Existing install.sh Behavior
**What goes wrong:** Adding --core and multi-positional args changes how `install.sh skippy-dev` works.
**Why it happens:** Argument parsing redesign accidentally breaks the existing single-skill install path.
**How to avoid:** Test existing behavior explicitly after changes: `install.sh skippy-dev`, `install.sh --all`, `install.sh --help` must all work identically to before.
**Warning signs:** The `SKILL_NAME` variable logic at line 53 conflicts with multi-positional args.

### Pitfall 4: INDEX.md Sync Drift
**What goes wrong:** INDEX.md shows wrong install status or missing skills after migration.
**Why it happens:** index-sync.sh regeneration overwrites manual edits, or install/uninstall doesn't trigger sync.
**How to avoid:** index-sync.sh must be the single source of truth. Category comes from SKILL.md frontmatter (add a `category:` field). Install status is detected at generation time by checking symlinks.
**Warning signs:** INDEX.md content doesn't match `ls skills/` or `ls ~/.claude/skills/`.

### Pitfall 5: SKILL.md Over 150 Lines After Slimming
**What goes wrong:** The migration produces a SKILL.md that's still over 150 lines because the slimming was too conservative.
**Why it happens:** Trying to keep "just the important parts" in SKILL.md without a clear cutoff strategy.
**How to avoid:** Hard rule: quick-reference table, description, reference list, top-5 gotchas, agent instructions. Everything else goes to references/. The migration command previews line count before confirming.
**Warning signs:** `wc -l skills/*/SKILL.md | sort -n` showing entries over 150.

## Code Examples

### install.sh Argument Parsing Extension

The current argument parsing (lines 26-61) uses a for loop with a case statement. The key change: `SKILL_NAME` becomes an array `SKILL_NAMES`, and a new `--core` flag is added.

```bash
# Current pattern (single skill):
SKILL_NAME=""
# ... case *) SKILL_NAME="$arg" ;;

# New pattern (multi-skill):
SKILL_NAMES=()
INSTALL_CORE=false
# ... case --core) INSTALL_CORE=true ;;
# ... case *) SKILL_NAMES+=("$arg") ;;
```

The no-arg status table uses the existing `list_skills()` function enhanced with install status detection:

```bash
show_status() {
    printf "%-20s %-12s %s\n" "SKILL" "STATUS" "DESCRIPTION"
    printf "%-20s %-12s %s\n" "-----" "------" "-----------"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name=$(basename "$skill_dir")
        local desc=$(sed -n '/^description:/s/^description: *//p' "$skill_dir/SKILL.md" 2>/dev/null | head -1)
        local status="available"
        if [[ -L "$HOME/.claude/skills/$name" ]] || [[ -L "$HOME/.claude/commands/$name" ]]; then
            status="installed"
        fi
        printf "%-20s %-12s %s\n" "$name" "[$status]" "${desc:-no description}"
    done
}
```

### INDEX.md Category Format

```markdown
# Skill Index

Auto-generated. Run `tools/index-sync.sh --generate` to rebuild.

## Core

| Skill | Path | Commands |
|-------|------|----------|
| core [installed] | `core/SKILL.md` | (none) |

## Workflow

| Skill | Path | Commands |
|-------|------|----------|
| skippy-dev [installed] | `skippy-dev/SKILL.md` | /skippy:reconcile, /skippy:update, /skippy:cleanup |
| session-wrap | `session-wrap/SKILL.md` | /skippy:session-wrap |
| add-todo | `add-todo/SKILL.md` | /skippy:add-todo |

## Utility

| Skill | Path | Commands |
|-------|------|----------|
| vaultwarden | `vaultwarden/SKILL.md` | (none) |
| excalidraw | `excalidraw/SKILL.md` | (none) |

## Domain

| Skill | Path | Commands |
|-------|------|----------|
| deploy-service | `deploy-service/SKILL.md` | (none) |
| homeassistant | `homeassistant/SKILL.md` | (none) |
```

### SKILL.md Frontmatter with Category

```yaml
---
name: vaultwarden
description: Credential access via vaultwarden-secrets MCP
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
  category: utility
---
```

### Migration Command Structure (commands/migrate.md)

Follows the Phase 8 update.md pattern:

```markdown
---
name: skippy:migrate
description: Migrate PAI skills into portable format
---

<objective>
Scan ~/.config/pai/Skills/, rank by priority, present candidates,
and migrate approved skills to portable format under skills/.
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>
## 1. Scan Source Skills
## 2. Rank and Present Candidates
## 3. Dry-Run Preview
## 4. Migrate (per skill)
## 5. Update INDEX.md and marketplace.json
</process>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Shell script for operations | AI command (markdown) | Phase 8 (08-03) | Migration tool follows this pattern |
| Single-skill install | Multi-skill positional args | This phase | install.sh UX improvement |
| Flat INDEX.md | Category-grouped INDEX.md | This phase | Better skill discovery |
| Manual skill porting | AI-driven migration with dry-run | This phase | Scalable to 68 skills |

## Open Questions

1. **SKILL.md `category` field placement**
   - What we know: 4 categories defined (core, workflow, utility, domain). INDEX.md groups by category.
   - What's unclear: Should category live in SKILL.md frontmatter (source of truth for index-sync.sh) or in a separate mapping file?
   - Recommendation: Add `category:` to SKILL.md frontmatter under `metadata:`. This keeps each skill self-describing and index-sync.sh can extract it with sed, same as description.

2. **marketplace.json scaling**
   - What we know: Currently has 2 plugin entries (core, skippy-dev). Each migrated skill needs an entry.
   - What's unclear: Should each skill be a separate plugin entry, or should they be grouped?
   - Recommendation: One plugin entry per skill. The `strict: false` flag means no plugin.json needed per skill -- the marketplace.json entry is sufficient. index-sync.sh or the migration command can append entries.

3. **Namespace collision with existing PAI skills**
   - What we know: Some source skills have uppercase names (CORE, Art, CreateSkill, Debug, Fabric, Git, etc.)
   - What's unclear: Should portable skill names preserve case or normalize to lowercase?
   - Recommendation: Normalize to lowercase-kebab (e.g., `Art` -> `art`, `CreateSkill` -> `create-skill`). This matches the existing `core` and `skippy-dev` naming convention.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash + manual verification |
| Config file | none -- shell scripts are the test harness |
| Quick run command | `bash tools/install.sh --help && bash tools/index-sync.sh --check` |
| Full suite command | `bash tools/install.sh --all && bash tools/index-sync.sh --check && bash tools/install.sh` (no-arg status) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SKIL-01 | install.sh --core installs core only | smoke | `bash tools/install.sh --core && ls -la ~/.claude/skills/core` | Wave 0 |
| SKIL-01 | install.sh <names> installs multiple | smoke | `bash tools/install.sh vaultwarden excalidraw && ls -la ~/.claude/skills/{vaultwarden,excalidraw}` | Wave 0 |
| SKIL-01 | install.sh no-arg shows status | smoke | `bash tools/install.sh` (visual check for table output) | Wave 0 |
| SKIL-02 | /skippy:migrate produces portable skill | manual-only | Run in Claude Code session, verify output structure | Manual -- AI command requires Claude runtime |
| SKIL-03 | Migrated skills have SKILL.md < 150 lines | unit | `wc -l skills/*/SKILL.md \| awk '$1 > 150'` (should return empty) | Wave 0 |
| SKIL-03 | Migrated skills follow standard layout | unit | `for d in skills/*/; do [[ -f "$d/SKILL.md" ]] \|\| echo "MISSING: $d"; done` | Wave 0 |
| SKIL-04 | INDEX.md has all skills with categories | smoke | `bash tools/index-sync.sh --check` | Exists (extend) |
| SKIL-04 | INDEX.md shows install status | smoke | `bash tools/index-sync.sh --generate && grep '\[installed\]' INDEX.md` | Wave 0 |

### Sampling Rate
- **Per task commit:** `bash tools/index-sync.sh --check && wc -l skills/*/SKILL.md | awk '$1 > 150'`
- **Per wave merge:** Full install/uninstall cycle + index check
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Extend index-sync.sh with category detection and install badge logic
- [ ] Add `category:` field to existing core and skippy-dev SKILL.md frontmatter
- [ ] No formal test harness -- validation is shell commands checking expected state

## Sources

### Primary (HIGH confidence)
- Existing codebase: `tools/install.sh` (203 lines), `tools/uninstall.sh` (114 lines), `tools/index-sync.sh` (109 lines)
- Existing skills: `skills/core/SKILL.md` (116 lines), `skills/skippy-dev/SKILL.md` (98 lines)
- Phase 8 command pattern: `skills/skippy-dev/commands/update.md` (77 lines)
- Source skill catalog: 68 skills in `~/.config/pai/Skills/` with full directory structure analysis

### Secondary (MEDIUM confidence)
- CONTEXT.md decisions from user discussion
- CONVENTIONS.md installation philosophy

### Tertiary (LOW confidence)
- None -- all findings are from direct codebase inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- extending existing tools, no new dependencies
- Architecture: HIGH -- patterns established by core and skippy-dev skills
- Pitfalls: HIGH -- derived from direct analysis of 68 source skills
- Skill candidates: HIGH -- based on complete catalog analysis with line counts and structure

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable -- no external dependencies changing)
