# Phase 6: Core Infrastructure - Research

**Researched:** 2026-03-07
**Domain:** Markdown-based AI persona/rules packaging, portable skill architecture
**Confidence:** HIGH

## Summary

Phase 6 packages PAI's essential operating layer -- personas, LAWs, style rules, and project templates -- as a portable `core/` skill following the established slim SKILL.md + deep references pattern. The source material already exists across `~/.config/pai/Skills/CORE/`, `~/.claude/docs/laws.md`, and `~/.config/pai-private/rules/`. This phase is primarily an extraction and restructuring task, not a creation task.

The key challenge is fitting the content into the established patterns: SKILL.md must stay under 150 lines, individual files under 750 lines, and the structure must use the same `references/` deep-doc pattern proven in `skills/skippy/`. The existing persona files (112-169 lines each) are already well-sized. The LAWs doc (211 lines) needs splitting into 15 individual files. Style rules are currently scattered across private rules and need consolidation into a public-safe format.

**Primary recommendation:** Create `core/` as a peer to `skills/skippy/` in the `skills/` directory, following the exact same SKILL.md + references pattern. Extract personas verbatim, split LAWs into individual files with enforcement metadata, create a public-safe rules template, and build an opinionated CLAUDE.md template with placeholder syntax.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Directory Layout:** Maximally minimal top level -- ONLY SKILL.md at `core/` root. Everything else under `references/` with topic subdirectories: `references/personas/`, `references/laws/`, `references/rules/`, `references/templates/`
- **LAW Files:** Individual files per LAW (`law-01-never-assume.md`, etc.). ALL LAWs must be hook-enforced -- if a LAW can't be hook-enforced, it should be adjusted or removed until it can. No separate index file -- SKILL.md's topic section points to the `laws/` directory
- **Persona Files:** Full persona prompt fragments, self-contained injectable units. Content structure inspired by OpenClaw's soul.md pattern: personality, core values, behavioral boundaries, style rules, example responses, switching triggers. PAI naming convention: `references/personas/skippy.md` (not `skippy-soul.md`)
- **user.md Concept:** user.md is a first-class core concept. Template lives in `core/references/templates/user.md.template`. Actual user content stays external/private
- **CLAUDE.md Template:** Opinionated starter (~80-100 lines). Placeholders with defaults for stack preferences (`{package_manager: bun}`, `{python_runner: uv}`, etc.). Per-project persona selection via `{default_persona}` placeholder. Includes LAW references, persona default, stack preferences, skills-first reminder, verification loop, key files table, corrections section

### Claude's Discretion
- Exact line counts per file (within 150-line SKILL.md and 750-line file limits)
- How to extract content from existing PAI definitions (which files to read, how to restructure)
- Persona example response selection (which examples best illustrate each persona)
- Template placeholder syntax (curly braces, comments, or other convention)

### Deferred Ideas (OUT OF SCOPE)
- **Command packaging (CORE-05)** -- Defer to a later phase. Many existing commands are LAW reinforcement for context degradation. Todo commands need research across GSD, PAUL, OpenClaw implementations first
- **Todo system cherry-pick** -- Survey todo implementations across all upstream packages first
- **OpenClaw cascade resolution** -- Full cascade (global -> agent -> workspace) revisit for Phase 9-10
- **LAW enforcement gap analysis** -- LAWs 10-14 currently "convention-enforced". User decision: all LAWs must be hook-enforced. Gap analysis needed but deferred
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CORE-01 | Personas (Skippy, Bob, Clarisa, April) packaged as portable definitions | Source files exist at `~/.config/pai/Skills/CORE/personas/` (112-169 lines each). Restructure to soul.md-inspired format with PAI naming. Copy to `core/references/personas/` |
| CORE-02 | LAWs (15) packaged with enforcement descriptions | Source at `~/.claude/docs/laws.md` (211 lines, 15 LAWs). Split into individual files `law-01-*.md` through `law-15-*.md` under `core/references/laws/`. Each file gets enforcement metadata |
| CORE-03 | Style rules and communication conventions packaged | Source at `~/.config/pai-private/rules/style/communication-style.md` plus stack preferences. Create public-safe versions in `core/references/rules/`. Private content stays external |
| CORE-04 | CLAUDE.md template available for new projects | Build opinionated ~80-100 line template at `core/references/templates/claude-md.template`. Includes placeholder defaults for stack, persona, LAW refs |
| CORE-05 | All 10 claude commands packaged for portable install | **DEFERRED** -- per CONTEXT.md decision. Do NOT plan for this requirement |
| CORE-06 | Core follows slim SKILL.md + deep references pattern | `core/SKILL.md` under 150 lines with topic sections pointing to `references/` subdirectories. Proven pattern from `skills/skippy/SKILL.md` (87 lines) |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown | N/A | All content files | Project constraint: shell scripts + markdown only, no build step |
| Agent Skills frontmatter | YAML | SKILL.md metadata | Established in v1.0, required by plugin system |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tools/index-sync.sh` | existing | Regenerate INDEX.md | After adding core/ skill entry |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Individual LAW files | Single laws.md | Individual files enable independent iteration; single file easier to read but couples all LAWs |
| Markdown placeholders | JSON config | Markdown placeholders are human-readable and editable; JSON requires tooling |

**No installation needed.** This phase creates markdown files only.

## Architecture Patterns

### Target Directory Structure
```
skills/
  core/
    SKILL.md                          # <150 lines, topic sections only
    references/
      personas/
        skippy.md                     # ~120 lines, self-contained persona
        bob.md                        # ~150 lines
        clarisa.md                    # ~150 lines
        april.md                      # ~170 lines
      laws/
        law-01-never-assume.md        # ~15-25 lines each
        law-02-checkbox-questions.md
        law-03-procon-analysis.md
        law-04-critical-thinking.md
        law-05-explain-before-doing.md
        law-06-interview-first.md
        law-07-never-ancient-bash.md
        law-08-never-work-on-main.md
        law-09-file-size-limits.md
        law-10-qmd-first.md
        law-11-no-secrets-in-git.md
        law-12-private-repos-default.md
        law-13-no-silent-autopilot.md
        law-14-network-share-protocol.md
        law-15-no-litellm-self-surgery.md
      rules/
        communication-style.md        # Public-safe style conventions
        stack-preferences.md          # bun/uv/brew defaults
        output-locations.md           # File routing rules
        minimal-claude-dir.md         # Symlink-only ~/.claude/
      templates/
        claude-md.template            # Opinionated CLAUDE.md starter
        user.md.template              # user.md structure prompts
```

### Pattern 1: Slim SKILL.md + Deep References
**What:** Entry-point file stays under 150 lines with topic sections that point to subdirectories. Agents do a second lookup only when relevant.
**When to use:** Every skill in the agentspace repo.
**Proven by:** `skills/skippy/SKILL.md` (87 lines, 5 reference docs, 3 commands).

```markdown
# Example SKILL.md structure (core)

---
name: core
description: PAI core infrastructure -- personas, LAWs, rules, templates
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
---

# core -- PAI Infrastructure

## Personas
[2-3 line summary table pointing to references/personas/]

## LAWs
[1-2 line description pointing to references/laws/]

## Rules
[1-2 line description pointing to references/rules/]

## Templates
[1-2 line description pointing to references/templates/]
```

### Pattern 2: Self-Contained Injectable Persona
**What:** Each persona file is a complete prompt fragment that can be injected into any LLM context without additional dependencies.
**When to use:** Persona files under `references/personas/`.
**Inspired by:** OpenClaw's soul.md pattern -- personality, core values, behavioral boundaries, style rules, example responses.

**Recommended persona file structure:**
```markdown
# [Name] - [Title]

**Name:** [Full name]
**Role:** [One-line role description]

## Core Personality
[Trait list with descriptions]

## Personality Calibration
[Trait/value table]

## Vocal & Linguistic Patterns
[Tone, phrases, opening lines]

## Communication Patterns
[How to structure responses in this persona]

## Interaction Protocol
[How to receive, solve, handle]

## Critical Thinking Style
[How this persona implements LAW 4]

## Core Directive
[Ultimate goal and method statement]
```

### Pattern 3: LAW Individual File with Enforcement Metadata
**What:** Each LAW in its own file with a consistent structure: name, description, enforcement mechanism, rules, examples.
**When to use:** All 15 LAW files under `references/laws/`.

```markdown
# LAW [N]: [Name]

**Enforcement:** [hook name or "Manual -- gap analysis pending"]
**Severity:** MANDATORY

## Rule
[Clear statement of the law]

## Why
[Rationale]

## Enforcement Details
[Hook behavior, trigger conditions, what gets blocked]

## Examples
[Correct vs incorrect examples]

## Exceptions
[If any]
```

### Pattern 4: Template with Placeholder Defaults
**What:** Template files use a consistent placeholder syntax showing default values that can be customized.
**When to use:** `claude-md.template` and `user.md.template`.

**Recommended placeholder syntax** (Claude's discretion area):
```markdown
<!-- CUSTOMIZE: package_manager (default: bun) -->
- `{bun}` for Node.js, `{uv}` for Python -- never npm/yarn/pip
```

Use HTML comments for customization instructions (invisible in rendered markdown) with the actual default value inline. This is more readable than `{package_manager: bun}` curly-brace syntax and works in any markdown renderer.

### Anti-Patterns to Avoid
- **Monolithic SKILL.md:** Don't embed persona/LAW content in SKILL.md. It should only contain pointers.
- **Cross-references between persona files:** Each persona must be self-contained. Don't `see also skippy.md` from bob.md.
- **Private content in public files:** Style rules can reference the existence of user.md but never embed private content. IP addresses, personal details, specific credentials patterns stay in `~/.config/pai-private/`.
- **Hardcoded paths:** Use relative references within the skill structure. Absolute paths like `~/.config/pai/` belong in documentation only, not in injectable prompt fragments.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Persona structure | New format from scratch | Extract from existing `~/.config/pai/Skills/CORE/personas/` | 4 well-tested personas already exist (563 total lines) |
| LAW definitions | Rewrite all LAWs | Extract from `~/.claude/docs/laws.md` | 211 lines of battle-tested LAW definitions |
| Style conventions | Invent new style rules | Extract from `~/.config/pai-private/rules/style/communication-style.md` | Existing rules are actively enforced and working |
| SKILL.md format | New entry-point pattern | Follow `skills/skippy/SKILL.md` exactly | Proven pattern, 87 lines, works with plugin system |
| INDEX.md registration | Manual INDEX.md editing | Run `tools/index-sync.sh --generate` | Existing tool handles this correctly |

**Key insight:** This phase is 90% extraction/restructuring and 10% new content (user.md.template and the CLAUDE.md template). Every source file already exists and is battle-tested.

## Common Pitfalls

### Pitfall 1: Private Content Leaking into Public Files
**What goes wrong:** Rules files contain PAI-private content (IP addresses, infrastructure details, personal preferences) that shouldn't be in a public repo.
**Why it happens:** Extracting from `~/.config/pai-private/rules/` without sanitizing.
**How to avoid:** Create public-safe versions of rules. Reference the *pattern* without the *private values*. Example: "Reports go to `{reports_dir}` (default: `Development/.reports/<project>/`)" instead of embedding the actual path structure.
**Warning signs:** Any file containing IP addresses (`10.71.*`), specific server names, or personal information.

### Pitfall 2: Persona Files Losing Character
**What goes wrong:** Restructuring persona files strips out the personality-defining content in favor of clean structure.
**Why it happens:** Over-editing during extraction. The persona files are intentionally written in-character.
**How to avoid:** Preserve the original voice in each persona file. Skippy's file should sound like Skippy wrote it. Bob's should be structured and analytical. Clarisa's should be warm. April's should be visual.
**Warning signs:** All 4 persona files reading the same way, generic language replacing character-specific phrases.

### Pitfall 3: SKILL.md Exceeding 150 Lines
**What goes wrong:** Trying to include too much summary content in the entry-point file.
**Why it happens:** Natural tendency to explain rather than point. The existing `~/.config/pai/Skills/CORE/SKILL.md` is 47 lines and includes persona table, critical thinking, and memory references.
**How to avoid:** Use topic sections with 2-3 line summaries and table pointers. Each section says "what's here" and "where to find details," nothing more. Target ~80-100 lines (leaves margin below 150).
**Warning signs:** SKILL.md has code examples, detailed rules, or more than a brief table per topic.

### Pitfall 4: LAW Enforcement Column Dishonesty
**What goes wrong:** Marking LAWs as "hook-enforced" when they're actually convention-enforced (manual).
**Why it happens:** User decided all LAWs must be hook-enforced, but LAWs 6, 10, 12, 13, 14 are currently manual.
**How to avoid:** Be honest about current enforcement state. Mark these as "Manual -- hook required (Phase 7 gap)" or similar. The user's decision means these LAWs need hooks, but Phase 6 packages what exists. Phase 7 handles hook creation.
**Warning signs:** All 15 LAWs showing hook enforcement when source material clearly shows 5 are manual.

### Pitfall 5: Template Placeholder Inconsistency
**What goes wrong:** Using different placeholder syntaxes across files, making templates confusing.
**Why it happens:** No established convention for template placeholders in this repo.
**How to avoid:** Pick one syntax and document it. Recommend HTML comments for instructions + inline defaults for values. Apply consistently across claude-md.template and user.md.template.
**Warning signs:** Mix of `{variable}`, `{{variable}}`, `<!-- variable -->`, `[REPLACE]` across different template files.

### Pitfall 6: Forgetting INDEX.md and marketplace.json Updates
**What goes wrong:** core/ skill exists but isn't registered in the plugin system or skill index.
**Why it happens:** Focus on content creation, forgetting integration points.
**How to avoid:** Final task in the phase should update INDEX.md (via `tools/index-sync.sh`) and add core to marketplace.json plugins array.
**Warning signs:** `core/` directory exists but `/plugin install core@skippy-agentspace` fails.

## Code Examples

### Example: core/SKILL.md (~80-100 lines target)

```markdown
---
name: core
description: PAI core infrastructure -- personas, LAWs, rules, and project templates
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
---

# core -- PAI Infrastructure

Core operating principles for PAI (Personal AI Infrastructure). Multi-persona system with mandatory rules (LAWs), communication conventions, and project templates.

## Personas

| Persona | Style | Best For | File |
|---------|-------|----------|------|
| **Skippy** (default) | Sarcastic, brilliant | General use, sass | `references/personas/skippy.md` |
| **Bob** | Methodical, analytical | Analysis, structured thinking | `references/personas/bob.md` |
| **Clarisa** | Warm, supportive | Encouragement, goals | `references/personas/clarisa.md` |
| **April** | Creative, visual | Fresh perspectives, design | `references/personas/april.md` |

Switch: "persona bob", "switch to clarisa", "be april"

Load the relevant persona file when switching. Each file is a self-contained prompt fragment.

## LAWs

15 mandatory rules. Never violate. Individual files in `references/laws/`.

| # | Name | File |
|---|------|------|
| 1 | Never Assume | `references/laws/law-01-never-assume.md` |
| 2 | Checkbox Questions | `references/laws/law-02-checkbox-questions.md` |
...
| 15 | No LiteLLM Self-Surgery | `references/laws/law-15-no-litellm-self-surgery.md` |

## Rules

Communication and operational conventions. Details in `references/rules/`.

| Rule | File |
|------|------|
| Communication Style | `references/rules/communication-style.md` |
| Stack Preferences | `references/rules/stack-preferences.md` |

## Templates

Project starters in `references/templates/`.

| Template | Purpose | File |
|----------|---------|------|
| CLAUDE.md | Opinionated project config | `references/templates/claude-md.template` |
| user.md | User context structure | `references/templates/user.md.template` |
```

### Example: Individual LAW File (law-07-never-ancient-bash.md)

```markdown
# LAW 7: Never Ancient Bash

**Enforcement:** `pre-ancient-bash-blocker.ts` (PreWrite, PreEdit hooks)
**Severity:** MANDATORY

## Rule

Use `#!/usr/bin/env bash` (or `zsh`, `sh`). NEVER `#!/bin/bash`.

## Why

macOS system bash is v3.2.57 (2007). Homebrew bash is v5.3.9. The `env` shebang uses whichever is in PATH, ensuring modern bash features work.

## Shell Selection

| Syntax Needed | Shebang |
|---------------|---------|
| Zsh-specific | `#!/usr/bin/env zsh` |
| POSIX portable | `#!/usr/bin/env sh` |
| General scripts | `#!/usr/bin/env bash` |
| Sourced files | No shebang (inherit parent) |

## Enforcement Details

- Pre-Write hook blocks any file containing `#!/bin/bash`
- Post-write auto-fix hook corrects to `#!/usr/bin/env bash`
- Applies to all `.sh` files and any file with a shebang line
```

### Example: user.md.template

```markdown
# User Context

<!-- This file contains personal context about the user.
     Place your completed version at the path your agent knows to check.
     NEVER commit this file to a public repository. -->

## Identity

<!-- CUSTOMIZE: Your name and role -->
- **Name:** [Your name]
- **Role:** [Your primary role/title]

## Preferences

<!-- CUSTOMIZE: Your tool and workflow preferences -->
- **Editor:** [Your preferred editor]
- **Shell:** [bash/zsh/fish]
- **OS:** [macOS/Linux/Windows]

## Communication Style

<!-- CUSTOMIZE: How you want your AI to talk to you -->
- **Default persona:** [skippy/bob/clarisa/april]
- **Verbosity:** [concise/normal/detailed]
- **Assume expertise in:** [Your domains of expertise]

## Context

<!-- CUSTOMIZE: Anything the AI should know about your work -->
- **Current focus:** [What you're working on]
- **Infrastructure:** [Key systems, servers, services]
- **Constraints:** [Time, budget, technical constraints]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Monolithic CORE/SKILL.md (47 lines, summary only) | Slim SKILL.md + deep references (topic sections + subdirs) | v1.1 architecture decision | All skills use the same progressive disclosure pattern |
| Personas in private pai config | Personas as portable injectable files | Phase 6 | Anyone can install and use the persona system |
| LAWs in single `docs/laws.md` (211 lines) | Individual LAW files with enforcement metadata | Phase 6 | Each LAW can be iterated independently |
| soul.md framework (4 files: SOUL/STYLE/SKILL/MEMORY) | PAI adaptation (single persona file per character) | Phase 6 design | Simpler -- one file per persona with all sections inline |
| Convention-enforced LAWs (5 of 15) | All LAWs must be hook-enforced | User decision (Phase 6 context) | LAWs 6, 10, 12, 13, 14 need hooks (Phase 7 work) |

**Deprecated/outdated:**
- `~/.config/pai/Skills/CORE/` will be superseded by `skills/core/` in the agentspace repo
- `~/.config/pai/Skills/CORE/laws-summary.md` (18 lines) will be replaced by individual LAW files

## Open Questions

1. **LAW enforcement gap for LAWs 6, 10, 12, 13, 14**
   - What we know: These 5 LAWs are currently "Manual" enforcement. User decided ALL LAWs must be hook-enforced.
   - What's unclear: What hooks would enforce LAWs like "Interview-First" (LAW 6) or "Private Repos by Default" (LAW 12)? Some may need creative hook design.
   - Recommendation: Package these LAWs honestly with current enforcement state. Add a `gap: true` or similar marker. Phase 7 (Hook Installation) addresses the actual hook creation. Phase 6 documents the gap, doesn't solve it.

2. **Where does `core/` live -- `skills/core/` or top-level `core/`?**
   - What we know: CONTEXT.md says "under `core/`" but the existing pattern has skills under `skills/`. The roadmap success criteria says "under `core/`". INDEX.md and marketplace.json track `skills/*/`.
   - What's unclear: Whether the user intends `skills/core/` (consistent with existing pattern) or a top-level `core/` directory (special status).
   - Recommendation: Use `skills/core/` to maintain consistency with the skill system, INDEX.md, and marketplace.json. The install.sh and index-sync.sh tooling already knows how to find `skills/*/SKILL.md`. Creating a top-level `core/` would require tooling changes. The planner should confirm this with the user if ambiguity matters, but `skills/core/` is the path of least resistance.

3. **Public-safe rules extraction depth**
   - What we know: Private rules contain PAI-specific details (IP addresses in LAW 14, infrastructure in output-locations.md). Communication-style.md is already fairly public-safe.
   - What's unclear: How deep to go on sanitizing rules for public consumption vs. creating generic templates.
   - Recommendation: Create public-safe versions that show the *pattern* without private values. Stack preferences (bun/uv) are already public. Communication style is already public. Output locations and minimal-claude-dir can be genericized. LAW 14 (Network Share Protocol) and LAW 15 (LiteLLM Self-Surgery) are inherently PAI-specific -- package them as-is since the whole repo targets PAI users anyway.

4. **Persona file permissions**
   - What we know: Existing persona files have mixed permissions -- Skippy is `644` (readable) but Bob, Clarisa, April are `600` (owner-only). In the public repo, all files should be `644`.
   - What's unclear: Whether any persona content should be considered private.
   - Recommendation: All persona files in the public repo should be `644`. The personas define behavioral patterns, not secrets.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Shell-based validation (no test framework -- markdown-only project) |
| Config file | none -- see Wave 0 |
| Quick run command | `bash -c 'test -f skills/core/SKILL.md && echo PASS'` |
| Full suite command | `bash tools/validate-core.sh` (to be created) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-01 | 4 persona files exist with required sections | smoke | `ls skills/core/references/personas/{skippy,bob,clarisa,april}.md` | N/A Wave 0 |
| CORE-02 | 15 LAW files exist with enforcement metadata | smoke | `ls skills/core/references/laws/law-{01..15}-*.md \| wc -l` (expect 15) | N/A Wave 0 |
| CORE-03 | Style/communication rules exist | smoke | `ls skills/core/references/rules/*.md` | N/A Wave 0 |
| CORE-04 | CLAUDE.md template exists with placeholders | smoke | `test -f skills/core/references/templates/claude-md.template` | N/A Wave 0 |
| CORE-05 | DEFERRED | N/A | N/A | N/A |
| CORE-06 | SKILL.md under 150 lines | unit | `test $(wc -l < skills/core/SKILL.md) -lt 150` | N/A Wave 0 |

### Sampling Rate
- **Per task commit:** Quick file existence checks
- **Per wave merge:** Full validation (file existence + line counts + content spot-checks)
- **Phase gate:** All smoke tests pass, SKILL.md under 150 lines, all 4 personas + 15 LAWs present

### Wave 0 Gaps
- [ ] `tools/validate-core.sh` -- validates core/ structure (file existence, line counts, required sections)
- [ ] No test framework needed -- shell file checks are sufficient for a markdown-only skill

## Sources

### Primary (HIGH confidence)
- `~/.config/pai/Skills/CORE/personas/` -- 4 persona files (563 total lines), direct source material
- `~/.claude/docs/laws.md` -- 15 LAWs with enforcement details (211 lines), direct source material
- `~/.config/pai-private/rules/style/communication-style.md` -- style conventions (29 lines), direct source material
- `~/.config/pai-private/rules/stack/` -- python-preferences.md (28 lines) + typescript-preferences.md (33 lines)
- `skills/skippy/SKILL.md` -- proven slim SKILL.md pattern (87 lines), architectural template
- `CONVENTIONS.md` -- public/private boundary documentation, content classification rules

### Secondary (MEDIUM confidence)
- [OpenClaw soul.md pattern](https://github.com/aaronjmars/soul.md) -- persona structure inspiration (SOUL.md, STYLE.md, SKILL.md, MEMORY.md). Verified structure via WebFetch. PAI adapts the concept (single file per persona) rather than adopting the 4-file split.
- [OpenClaw USER.md concept](https://medium.com/@hugolu87/openclaw-vs-claude-code-in-5-mins-1cf02124bc08) -- USER.md contains user bio, preferences, work context. PAI creates a template for this pattern.

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- markdown-only, no libraries, no dependencies
- Architecture: HIGH -- pattern proven by skippy, source material fully audited
- Pitfalls: HIGH -- based on direct examination of source files and known constraints
- Persona extraction: HIGH -- all 4 persona files read in full, content well-understood
- LAW extraction: HIGH -- full laws.md read, all 15 LAWs with enforcement status documented
- Template design: MEDIUM -- user.md.template is new content (no existing source to extract from)

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stable -- markdown patterns don't change)
