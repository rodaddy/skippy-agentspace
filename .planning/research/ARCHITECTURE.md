# Architecture Research

**Domain:** Claude Code portable skill distribution and discovery
**Researched:** 2026-03-06
**Confidence:** HIGH

## How Claude Code Discovers Skills (The Foundation)

Claude Code has three discovery mechanisms, verified against official docs at [code.claude.com/docs/en/slash-commands](https://code.claude.com/docs/en/slash-commands).

### Discovery Mechanism 1: Skills (Current Standard)

**Location priority (highest wins):**

| Level | Path | Scope |
|-------|------|-------|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin is enabled |
| Nested | `packages/<pkg>/.claude/skills/<name>/SKILL.md` | Monorepo sub-packages |

**Key behavior:** Skill descriptions are loaded into context automatically so Claude knows what is available. Full skill content loads only when invoked. Description budget is 2% of context window (~16,000 chars fallback).

**SKILL.md frontmatter (verified from official docs):**

```yaml
---
name: my-skill               # becomes /my-skill (lowercase, hyphens, max 64 chars)
description: What it does     # Claude uses this for auto-invocation decisions
argument-hint: "[args]"       # Autocomplete hint
disable-model-invocation: true  # Only user can invoke (prevents auto-trigger)
user-invocable: false         # Only Claude can invoke (background knowledge)
allowed-tools: Read, Grep     # Tool permissions when skill is active
model: opus                   # Model override
context: fork                 # Run in subagent (isolated context)
agent: Explore                # Subagent type when context: fork
---
```

**Substitution variables:** `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`

**Auto-discovery from additional dirs:** Skills in `.claude/skills/` within `--add-dir` directories are loaded automatically and support live change detection.

### Discovery Mechanism 2: Commands (Legacy, Still Works)

**Locations:**
- `~/.claude/commands/<name>.md` -- personal, all projects
- `.claude/commands/<name>.md` -- project-scoped

**Namespacing via subdirectories:**
- `~/.claude/commands/gsd/execute-phase.md` becomes `/gsd:execute-phase`
- `~/.claude/commands/skippy/reconcile.md` becomes `/skippy:reconcile`

**Important:** If a skill and a command share the same name, the skill takes precedence. Commands support the same frontmatter as skills. Anthropic recommends skills over commands for new work because skills support supporting files (references, scripts, templates) and `${CLAUDE_SKILL_DIR}`.

### Discovery Mechanism 3: Plugins

**Structure:**
```
my-plugin/
  .claude-plugin/
    plugin.json              # Metadata: name, description, author
  skills/
    <skill-name>/
      SKILL.md               # Standard skill format
      references/            # Optional supporting files
      scripts/               # Optional scripts
```

**Marketplace registration:** `known_marketplaces.json` maps marketplace names to GitHub repos. Plugins are installed to `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`. Plugin skills are namespaced as `plugin-name:skill-name`.

**Key insight for skippy-agentspace:** The plugin system IS a skill distribution mechanism. A plugin is just a git repo with `.claude-plugin/plugin.json` and a `skills/` directory. Adding this 8-line JSON file unlocks the entire plugin install flow.

## Framework Comparison: How GSD, OMC, and PAUL Organize

### GSD (get-shit-done) -- Commands + Workflows + References

```
~/.claude/commands/gsd/          # 30+ command shims (thin .md files)
  execute-phase.md               #   frontmatter + @workflow reference
  plan-phase.md                  #   delegates to workflow file
  new-project.md

~/.claude/get-shit-done/         # Heavy implementation
  workflows/                     # 34 workflow .md files (the actual logic)
    execute-phase.md             #   <step> blocks, full process
    plan-phase.md
  references/                    # 13 reference docs (loaded on demand)
    checkpoints.md
    model-profiles.md
  templates/                     # 19 templates (project artifacts)
    project.md
    roadmap.md
  bin/                           # 1 Node.js tool (gsd-tools.cjs)
    gsd-tools.cjs
  VERSION
```

**Pattern:** Command shims in `~/.claude/commands/gsd/` are thin -- they contain frontmatter (name, description, allowed-tools) and an `<execution_context>` block that references the real workflow file via `@` path. The workflow file contains the actual multi-step logic. This is a **shim + implementation** separation.

**Example shim** (`~/.claude/commands/gsd/execute-phase.md`):
```yaml
---
name: gsd:execute-phase
description: Execute all plans in a phase
allowed-tools: [Read, Write, Edit, Bash, Task, ...]
---
<execution_context>
@/Users/rico/.claude/get-shit-done/workflows/execute-phase.md
@/Users/rico/.claude/get-shit-done/references/ui-brand.md
</execution_context>
```

### OMC (oh-my-claudecode) -- Plugin with Skills + Agents

```
omc/                             # GitHub repo = plugin
  .claude-plugin/
    marketplace.json             # Marketplace metadata (name, plugins[], version)
    plugin.json                  # Plugin metadata (name, version, skills path)
  skills/                        # 32 skills, each a folder with SKILL.md
    analyze/SKILL.md
    autopilot/SKILL.md
    ralplan/SKILL.md
    team/SKILL.md
  agents/                        # 28 agent definitions (.md files)
    architect.md
    critic.md
    executor.md
    planner.md
  AGENTS.md                      # Agent index
```

**Pattern:** OMC uses the official Claude Code plugin format. Each skill is self-contained in its own directory with SKILL.md. Skills reference agents by name using `Task(subagent_type="oh-my-claudecode:architect", ...)`. Agent definitions are flat .md files. The `plugin.json` declares `"skills": "./skills/"` to point Claude to the skills directory.

**Key difference from GSD:** OMC skills are fully self-contained -- no separate "workflow" files. The SKILL.md IS the workflow. They use structured XML-ish sections (`<Purpose>`, `<Steps>`, `<Examples>`, `<Final_Checklist>`) to organize content within the single file.

### PAUL -- Monolithic System Prompt

PAUL does not use Claude Code's discovery mechanisms at all. It is a single large system prompt / CLAUDE.md that injects all rules into every session. No commands, no skills, no separation of concerns. This is the anti-pattern for portability -- it works by dumping everything into context.

### PAI Skills -- Symlink-Based Distribution (Current State)

```
~/.config/pai/Skills/            # Source of truth
  skippy-dev/
    SKILL.md
    commands/
    references/
    bin/
  n8n/
    SKILL.md
    references/
  vaultwarden/
    SKILL.md
    references/
  AGENT-INDEX.md                 # Centralized index for agent discovery

~/.claude/skills/                # Symlinks for Claude Code discovery
  n8n -> ~/.config/pai/Skills/n8n
  fabric -> ~/.config/pai/Skills/Fabric
  vaultwarden -> ~/.config/pai/Skills/vaultwarden

~/.claude/commands/              # Symlinks for command discovery (legacy)
  skippy -> ~/.config/pai/Skills/skippy-dev/commands
```

**Pattern:** PAI stores skills in `~/.config/pai/Skills/` and creates symlinks into both `~/.claude/skills/` (for Claude auto-discovery) and `~/.claude/commands/` (for slash command discovery). The `AGENT-INDEX.md` is a hand-maintained table that tells subagents which skill to read for a given domain.

## Recommended Architecture for skippy-agentspace

### System Overview

```
skippy-agentspace/                    # The portable skill repo
+-----------------------------------------+
|  Distribution Layer                     |
|  .claude-plugin/plugin.json             |
|  (Makes repo installable as plugin)     |
+-----------------------------------------+
           |
+-----------------------------------------+
|  Skill Layer                            |
|  skills/                                |
|    <skill-name>/                        |
|      SKILL.md          (entry point)    |
|      references/       (on-demand docs) |
|      scripts/          (executables)    |
|      agents/           (if needed)      |
+-----------------------------------------+
           |
+-----------------------------------------+
|  Tooling Layer (dev-only)               |
|  tools/                                 |
|    install.sh    (manual symlink)       |
|    uninstall.sh  (manual removal)       |
|    index-sync.sh (registry validation)  |
|  INDEX.md        (auto-gen registry)    |
+-----------------------------------------+
```

### Target Directory Layout

```
skippy-agentspace/
  .claude-plugin/
    plugin.json               # Plugin manifest (8 lines of JSON)
  skills/
    skippy-dev/
      SKILL.md                # Entrypoint -- frontmatter + instructions
      references/             # On-demand reference docs
        context-brackets.md
        reconciliation.md
        task-anatomy.md
        plan-boundaries.md
        state-consistency.md
      scripts/                # Executable scripts (renamed from bin/)
        skippy-update.sh
        skippy-cleanup.sh
  tools/                      # Development/maintenance tooling
    install.sh                # Manual skill installation (symlinks)
    uninstall.sh              # Manual skill removal
    index-sync.sh             # INDEX.md validation/generation
  INDEX.md                    # Auto-generated skill registry
  CLAUDE.md                   # Project instructions
```

**Change from current state:** `commands/` subdirectory is dropped from the skill. Command content merges into SKILL.md (which is how the skill system works -- SKILL.md IS the command). The `bin/` directory becomes `scripts/` to match the Anthropic convention seen in skill-creator and the official docs.

### Component Responsibilities

| Component | Responsibility | Boundary |
|-----------|---------------|----------|
| `.claude-plugin/plugin.json` | Plugin metadata -- makes the repo installable as a Claude Code plugin | Repo identity. Never contains skill logic. |
| `skills/<name>/SKILL.md` | Skill entry point -- frontmatter + instructions + references to supporting files | Each skill is fully self-contained. No cross-skill imports. Max ~500 lines. |
| `skills/<name>/references/` | Detailed reference documentation loaded on demand | Referenced from SKILL.md. Never loaded automatically. |
| `skills/<name>/scripts/` | Executable scripts (bash, python) that skills invoke | Scripts must work standalone. Use `${CLAUDE_SKILL_DIR}` for paths. |
| `skills/<name>/agents/` | Agent definitions for `context: fork` subagent patterns | Only needed if skill spawns specialized agents. |
| `tools/install.sh` | Manual installation via symlinks to `~/.claude/skills/` | For users who don't use the plugin system. Migrate target from commands/ to skills/. |
| `tools/uninstall.sh` | Clean removal of symlinks | Inverse of install.sh. Never deletes source files. |
| `tools/index-sync.sh` | Validates INDEX.md matches actual `skills/` contents | Pre-commit safety net. |
| `INDEX.md` | Machine-readable skill registry | Auto-generated. Human-readable table format. |

### Why This Structure

**Dual distribution model:** The repo should work as both:
1. A **Claude Code plugin** (add the repo as a marketplace, install via plugin system) -- this is the future
2. A **manual install** (clone repo, run `tools/install.sh` to symlink into `~/.claude/skills/`) -- this is the fallback

The plugin path is the future -- it is how OMC, skill-creator, and all community frameworks distribute. The manual symlink path is the fallback for PAI integration and users who want fine-grained control.

**Why migrate from commands/ to skills/:** The `~/.claude/commands/` convention still works but is legacy. Skills (`.claude/skills/`) are the current standard and support auto-discovery (Claude finds them without user invocation), supporting files via `${CLAUDE_SKILL_DIR}`, subagent forking with `context: fork`, and the plugin distribution system. Commands cannot do any of this.

**Why not adopt PAUL's approach:** Monolithic system prompts scale poorly. Every instruction eats context even when irrelevant. Skill-based discovery only loads what is needed.

## Data Flow

### Skill Discovery Flow

```
User types "/" in Claude Code
    |
    v
Claude Code scans discovery locations (in priority order):
    Enterprise managed settings
    ~/.claude/skills/*/SKILL.md         (personal skills)
    .claude/skills/*/SKILL.md           (project skills)
    ~/.claude/plugins/cache/*/skills/   (installed plugins)
    ~/.claude/commands/*.md             (legacy commands)
    ~/.claude/commands/*/*.md           (namespaced legacy commands)
    |
    v
Skill descriptions loaded into context (~2% of context window budget)
    |
    v
User invokes /skill-name  OR  Claude auto-invokes based on description match
    |
    v
Full SKILL.md content loaded into context
    |
    v
Claude follows instructions, optionally reading references/ and running scripts/
```

### Installation Flow (Manual -- Current)

```
User clones skippy-agentspace repo
    |
    v
tools/install.sh <skill-name>
    |
    v
Validates skills/<name>/SKILL.md exists
    |
    v
Creates symlink: ~/.claude/skills/<name> -> <repo>/skills/<name>/
    |
    v
User runs /clear to refresh skill list
    |
    v
Claude Code discovers skill via ~/.claude/skills/ scan
```

### Installation Flow (Plugin -- Future)

```
User adds repo as marketplace source (or installs directly)
    |
    v
Claude Code clones repo to ~/.claude/plugins/marketplaces/<name>/
    |
    v
Plugin system reads .claude-plugin/plugin.json
    |
    v
Skills discovered via plugin.json "skills" path pointer
    |
    v
Skills available as <plugin-name>:<skill-name>
```

## Architectural Patterns

### Pattern 1: Progressive Disclosure (Core Pattern)

**What:** Layer skill content so context consumption scales with task complexity.
**When to use:** Always -- this is THE architecture pattern for skills.
**Trade-offs:** More files to organize, but dramatically better context efficiency.

```
Layer 1: Metadata (~100 tokens)
  name + description in frontmatter
  Loaded for ALL skills at startup
  Must contain keywords for auto-matching

Layer 2: Instructions (< 500 lines / ~5000 tokens)
  SKILL.md body after frontmatter
  Loaded only when skill activates
  Core workflow steps, rules, command docs

Layer 3: References (variable, on demand)
  Separate files in references/
  Loaded only when Claude needs specific depth
  Can be large (templates, detailed specs, examples)

Layer 4: Scripts (execution, not context)
  Shell scripts that DO things
  Never loaded into context -- executed via Bash tool
  Output returned to Claude
```

### Pattern 2: Self-Contained Skill (OMC Pattern)

**What:** Each skill is a single directory with SKILL.md as entry point. All logic, references, and scripts live within that directory. No external references.
**When to use:** Always, unless you have cross-skill shared code (which you should avoid).
**Trade-offs:** Some duplication if two skills need the same reference. Worth it for portability -- any skill can be copied or removed independently.

### Pattern 3: Portable Path Resolution

**What:** Use Claude Code's built-in variables instead of absolute paths.
**When to use:** Any time a skill references its own files.

```markdown
# WRONG -- breaks on any machine except the author's
@/Users/rico/.config/pai/Skills/skippy-dev/references/reconciliation.md

# RIGHT -- resolves to skill's actual location at runtime
Read ${CLAUDE_SKILL_DIR}/references/reconciliation.md

# ALSO RIGHT -- relative reference in markdown
See [reconciliation guide](references/reconciliation.md) for the template.
```

### Pattern 4: Graceful Enhancement Detection

**What:** Skills detect PAI infrastructure presence and adapt without failing.
**When to use:** Any skill that has PAI-enhanced capabilities.

```markdown
## For PAI Users

If `~/.config/pai/` exists, you can also:
- Use `/vaultwarden` for credential access
- Use personas (Skippy, Bob, Clarisa, April) for style variation

These are optional. The skill works identically without them.
```

### Pattern 5: Skill as Prompt, Not Code

**What:** Skills are instructions Claude follows, not programs Claude runs.
**When to use:** Deciding what goes in SKILL.md vs scripts/.

```
SKILL.md = "Here's how to do reconciliation" (instructions)
scripts/ = "Run this to get git diff data" (automation)

The skill tells Claude what to do.
Scripts handle the parts that are faster/more reliable as shell commands.
```

## Anti-Patterns

### Anti-Pattern 1: Monolithic System Prompt

**What people do:** Dump all skill content into CLAUDE.md or a single massive file that loads every session.
**Why it's wrong:** Wastes context on irrelevant instructions. Every token of CLAUDE.md loads every session. Skills only load when relevant.
**Do this instead:** Keep CLAUDE.md for repo-level constraints. Put domain knowledge in skills with descriptive `description` fields.

### Anti-Pattern 2: Cross-Skill Dependencies

**What people do:** Skill A imports or references files from Skill B's directory.
**Why it's wrong:** Breaks portability. Can't install Skill A without Skill B. Can't update either independently.
**Do this instead:** Duplicate shared content if small. If large, extract into a shared reference skill that both can recommend reading.

### Anti-Pattern 3: Hardcoded Absolute Paths

**What people do:** Reference files with full paths like `/Users/rico/.config/pai/Skills/skippy-dev/references/task-anatomy.md`.
**Why it's wrong:** Skill only works on one machine. Breaks for any other user.
**Do this instead:** Use `${CLAUDE_SKILL_DIR}` for references within the skill. Use relative markdown links.

### Anti-Pattern 4: Separate Commands Directory Within Skills

**What people do:** Create a `commands/` subdirectory inside a skill, then symlink it to `~/.claude/commands/` so that each command is a separate slash command.
**Why it's wrong:** This is the legacy pattern. The skill system already makes SKILL.md a slash command. If you need multiple commands from one skill, create multiple skills. If they're tightly coupled, keep them as one skill with `$ARGUMENTS` dispatch.
**Do this instead:** Let SKILL.md be the command. Use `$ARGUMENTS` for subcommand routing (e.g., `/skippy-dev reconcile` vs `/skippy-dev update`). Or split into separate skills if they're independent enough.

### Anti-Pattern 5: Building What Claude Code Already Does

**What people do:** Custom skill discovery, loading, indexing, or update mechanisms.
**Why it's wrong:** Claude Code's native skill system handles auto-discovery, progressive disclosure, namespace isolation, and plugin distribution. Custom mechanisms will break when Claude Code updates.
**Do this instead:** Use native Claude Code patterns. `tools/` scripts are for developer convenience during development, not for end-user skill management.

## Migration Path: Commands to Skills

The current skippy-agentspace uses `~/.claude/commands/skippy/` for command discovery. The migration:

| Current | Future | Change |
|---------|--------|--------|
| `install.sh` symlinks to `~/.claude/commands/<name>/` | Symlinks to `~/.claude/skills/<name>/` | Change target directory in install.sh |
| Commands invoked as `/skippy:reconcile` | Skills invoked as `/skippy-dev` (single skill) or `/reconcile` (if split) | Name changes |
| `commands/` subdirectory holds separate .md files | SKILL.md IS the command; references/ holds supporting docs | Merge command content into SKILL.md |
| `bin/` directory for scripts | `scripts/` directory (Anthropic convention) | Rename directory |

**Design decision: One skill or many?**

Current `skippy-dev` has 3 commands + 5 references. Two viable approaches:

| Approach | Pros | Cons |
|----------|------|------|
| **Single skill** with `$ARGUMENTS` dispatch | Simple, one install, one SKILL.md | SKILL.md grows larger; all 3 commands share one description |
| **Multiple skills** (reconcile, update, cleanup) | Each has focused description for auto-discovery; smaller SKILL.md per skill | More directories; references must be duplicated or split |

**Recommendation:** Keep as single `skippy-dev` skill for now. The 3 commands are tightly coupled (they all operate on the same `.planning/` project structure) and the 5 references are shared context. Split only if a command grows complex enough to warrant its own references.

## Scalability Considerations

| Concern | 1 skill (now) | 5-10 skills | 50+ skills |
|---------|---------------|-------------|------------|
| Discovery overhead | Negligible | ~500-1000 tokens for descriptions | May hit description budget limit (2% of context, ~16k chars). Set `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var to override. |
| Plugin packaging | Single plugin bundle | Still one plugin, skills share a namespace | Consider splitting into thematic bundles (like OMC's approach of 32 skills in one plugin) |
| INDEX.md maintenance | Manual is fine | `tools/index-sync.sh --generate` | Pre-commit hook running index-sync |
| Install complexity | One command | Still one command | Marketplace with categories/tags in plugin.json |

### First bottleneck: Description budget

At ~50 skills with 100-token descriptions each, you hit ~5000 tokens just for descriptions. The 2% budget on a 200k context window is ~4000 tokens. Solutions: shorter descriptions, `SLASH_COMMAND_TOOL_CHAR_BUDGET` override, or splitting into multiple plugins.

## Build Order Implications

Dependencies between components determine implementation order:

```
Phase 1: Skill Content (the value)
  skills/*/SKILL.md + references/ + scripts/
  Everything else is distribution wrapper.
     |
     v
Phase 2: Index & Validation
  INDEX.md + tools/index-sync.sh
  Verify skills are well-formed and indexed.
     |
     v
Phase 3: Install Tooling Migration
  tools/install.sh (migrate target from commands/ to skills/)
  tools/uninstall.sh (update accordingly)
  Enable symlink-based installation to ~/.claude/skills/
     |
     v
Phase 4: Plugin Manifest (independent of Phase 3)
  .claude-plugin/plugin.json
  Enable plugin-based installation.
     |
     v
Phase 5: Documentation & Distribution
  README.md, contribution guidelines
  Enable other people to find and use it.
```

**Critical note:** Phases 3 and 4 are independent of each other (can be built in parallel). Both depend on Phase 1 (skills must exist before you can install them). Phase 2 depends on Phase 1 (can't index skills that don't exist). Phase 5 depends on everything.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| GSD framework | Skills read GSD's `.planning/` directory structure | Read-only. Never modify GSD files. |
| PAUL concepts | Absorbed as reference docs within skills | No runtime dependency on PAUL repo |
| PAI infrastructure | Optional enhancement detection (`~/.config/pai/` exists?) | Graceful degradation when absent |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| SKILL.md to references/ | `Read ${CLAUDE_SKILL_DIR}/references/<name>.md` | On-demand loading |
| SKILL.md to scripts/ | `Bash ${CLAUDE_SKILL_DIR}/scripts/<name>.sh` | Execution, not context loading |
| tools/ to skills/ | File system scanning (`ls skills/*/SKILL.md`) | Dev-time only, not runtime |
| INDEX.md to skills/ | Generated from SKILL.md frontmatter by index-sync.sh | One-directional: skills -> INDEX.md |

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/slash-commands) -- official docs, HIGH confidence
- [Agent Skills Spec v1.0](https://agentskills.io) via `~/.claude/plugins/marketplaces/anthropic-agent-skills/agent_skills_spec.md` -- official spec, HIGH confidence
- GSD framework source: `~/.claude/get-shit-done/` (34 workflows, 13 references, 19 templates) -- direct inspection, HIGH confidence
- OMC framework source: `~/.claude/plugins/marketplaces/omc/` (32 skills, 28 agents) -- direct inspection, HIGH confidence
- PAI skills structure: `~/.config/pai/Skills/` (20+ skills, AGENT-INDEX.md) -- direct inspection, HIGH confidence
- Claude Code plugin system: `~/.claude/plugins/installed_plugins.json`, `known_marketplaces.json` -- direct inspection, HIGH confidence
- Anthropic skill-creator plugin: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/` -- reference implementation, HIGH confidence
- [Claude Code Custom Commands Guide](https://skillsplayground.com/guides/claude-code-slash-commands/) -- community guide, MEDIUM confidence
- [wshobson/commands](https://github.com/wshobson/commands) -- community commands collection, MEDIUM confidence

---
*Architecture research for: Claude Code portable skill distribution*
*Researched: 2026-03-06*
