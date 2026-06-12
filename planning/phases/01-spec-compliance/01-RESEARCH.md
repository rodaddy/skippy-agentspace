# Phase 1: Spec Compliance - Research

**Researched:** 2026-03-07
**Domain:** Agent Skills spec compliance, portable path resolution, skill file structure
**Confidence:** HIGH

## Summary

Phase 1 is entirely mechanical -- fixing 5 hardcoded absolute paths, removing a non-standard frontmatter field, renaming a directory, and verifying progressive disclosure structure. No new libraries, no architectural decisions, no ambiguous trade-offs. The existing domain research (STACK.md, ARCHITECTURE.md, PITFALLS.md from 2026-03-06) already mapped every change needed with HIGH confidence from official sources.

The critical technical decision -- relative paths vs `${CLAUDE_SKILL_DIR}` -- is already locked by CONTEXT.md: use relative paths because `${CLAUDE_SKILL_DIR}` has a known bug (#11011) with plugin scripts on first execution. The `@` file reference syntax in command `.md` files supports relative paths from the file's own location, so `@../SKILL.md` from `commands/reconcile.md` resolves correctly to `skills/skippy/SKILL.md`.

**Primary recommendation:** Execute as a sequential sweep: paths first (most impactful), frontmatter second, directory rename third (touches the most files), progressive disclosure verification last.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Relative paths preferred over `${CLAUDE_SKILL_DIR}`** -- `${CLAUDE_SKILL_DIR}` has a known bug (#11011) with plugin scripts on first execution. Relative paths work everywhere.
- **Keep `commands/` subdirectory for now** -- research noted it's "legacy" but we have 3 commands with separate workflows. Merging into SKILL.md with `$ARGUMENTS` dispatch is a Phase 2 consideration, not Phase 1.
- **Shell scripts stay as shell** -- no TypeScript/Node build step. Just rename the directory.

### Claude's Discretion
- Whether a `docs/` directory is needed for project-level documentation separate from skill references (CONTEXT.md says "May need")
- Exact wording of the trimmed description (must be under 130 chars)
- Whether INDEX.md needs updating beyond the bin/ -> scripts/ rename

### Deferred Ideas (OUT OF SCOPE)
- Merging commands/ into SKILL.md with `$ARGUMENTS` dispatch (Phase 2)
- Plugin packaging (.claude-plugin/plugin.json) (Phase 2)
- Script hardening (/tmp -> ~/.cache/, source -> grep/cut) (Phase 3)
- Reference doc metadata (last_verified, source, assumes) (Phase 3+)
- Collision detection in install.sh (Phase 2)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SPEC-01 | All skill files use portable paths -- no hardcoded absolute paths | 5 hardcoded `@/Users/rico/...` paths identified across 3 command files. 2 additional `/Volumes/ThunderBolt/` paths in cleanup.sh and SKILL.md. Replace with relative paths per locked decision. |
| SPEC-02 | SKILL.md frontmatter aligned to Agent Skills standard | Remove `triggers:` field (not in spec). Add `metadata:` block with version/author. Trim description to under 130 chars. Target frontmatter already defined in CONTEXT.md. |
| SPEC-03 | `bin/` directory renamed to `scripts/` | Rename directory. Update 4 references in SKILL.md (2), update.md (1), cleanup.md (1). Also update CLAUDE.md file tree and INDEX.md. |
| STRU-01 | Skill follows progressive disclosure pattern | Already 84 lines (well under 150 limit). 5 reference docs properly separated. INDEX.md exists. Verify navigation index lists references. Consider adding `docs/` for project-level docs. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Agent Skills spec | 1.0 | SKILL.md format standard | Adopted by 30+ tools. Required fields: `name`, `description`. Optional: `metadata`, `allowed-tools` |
| Claude Code skills | current | Skill discovery and execution | Native runtime. Supports `${CLAUDE_SKILL_DIR}`, `@` file references, auto-discovery |
| Bash | 5.x+ | Script runtime | Zero dependencies, already in use, project constraint |
| Markdown | -- | All skill content | No build step, native to all AI coding agents |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| YAML frontmatter | -- | Skill metadata in SKILL.md | Always -- required by Agent Skills spec |
| `@` file references | -- | Load external files into command context | In command .md files to reference SKILL.md and reference docs |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Relative paths | `${CLAUDE_SKILL_DIR}` | Bug #11011 on first plugin execution. Relative paths work everywhere. CONTEXT.md locked this decision. |

**Installation:**
No installation needed for Phase 1. This is file editing only.

## Architecture Patterns

### Recommended Project Structure (Post-Phase 1)
```
skills/skippy/
  SKILL.md                # Entry point -- frontmatter + instructions (< 150 lines)
  commands/               # Kept for Phase 1 (merge to SKILL.md deferred to Phase 2)
    reconcile.md          # @../SKILL.md, @../references/reconciliation.md, @../references/state-consistency.md
    update.md             # @../SKILL.md
    cleanup.md            # @../SKILL.md
  references/             # On-demand docs (5 files)
    context-brackets.md
    reconciliation.md
    task-anatomy.md
    plan-boundaries.md
    state-consistency.md
  scripts/                # Renamed from bin/
    skippy-update.sh
    skippy-cleanup.sh
  .versions               # Upstream version tracking
```

### Pattern 1: Relative Path References in Command Files
**What:** Command `.md` files use `@` directives with relative paths to load supporting files into context.
**When to use:** Any command file that needs to reference SKILL.md or reference docs.
**Example:**
```markdown
<!-- In commands/reconcile.md -->
<execution_context>
@../SKILL.md
@../references/reconciliation.md
@../references/state-consistency.md
</execution_context>
```
**Source:** Claude Code docs confirm `@` file references resolve relative to the file's location. Verified via ARCHITECTURE.md research (HIGH confidence).

### Pattern 2: Portable Script References in SKILL.md
**What:** SKILL.md references scripts using paths relative to the skill directory, not absolute paths.
**When to use:** Any SKILL.md that tells Claude to run a script.
**Example:**
```markdown
### /skippy:update
1. Run `${CLAUDE_SKILL_DIR}/scripts/skippy-update.sh`
```
**Note:** `${CLAUDE_SKILL_DIR}` is used here (inside SKILL.md body) because this is a runtime instruction to Claude, not an `@` file reference. The bug #11011 affects plugin script hooks, not SKILL.md body content. Relative paths in SKILL.md body text would be ambiguous (relative to what?), so `${CLAUDE_SKILL_DIR}` is correct here.

### Pattern 3: Agent Skills Spec-Compliant Frontmatter
**What:** SKILL.md frontmatter uses only spec-defined fields.
**When to use:** Every SKILL.md.
**Example:**
```yaml
---
name: skippy
description: Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency
metadata:
  version: "0.1.0"
  author: "rodaddy"
  source: "https://github.com/rodaddy/skippy-agentspace"
---
```
**Source:** Agent Skills spec at agentskills.io + Claude Code docs at code.claude.com/docs/en/skills (HIGH confidence).

### Anti-Patterns to Avoid
- **Hardcoded absolute paths in `@` references:** `@/Users/rico/...` breaks portability. Use `@../` relative paths.
- **Non-spec frontmatter fields:** `triggers:` is ignored by Claude Code and other Agent Skills-compatible tools. Put trigger keywords in `description`.
- **`bin/` directory naming:** Agent Skills spec uses `scripts/`. Using `bin/` may not be recognized by other compatible tools.
- **Loading all reference docs per command:** Each command should load only the references it needs, not all 5.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Path resolution | Custom path expansion logic | `@../` for command files, `${CLAUDE_SKILL_DIR}` in SKILL.md body | Claude Code handles resolution natively |
| Skill discovery | Custom loader/indexer | Claude Code auto-discovery via `~/.claude/skills/` scan | Built-in, scans all skill locations automatically |
| Frontmatter validation | Custom YAML parser | `skills-ref` CLI from agentskills/agentskills repo (or manual review) | Standard tooling exists |

**Key insight:** Phase 1 changes are purely mechanical text replacements and a directory rename. No custom tooling needed.

## Common Pitfalls

### Pitfall 1: Relative Path Direction in Command Files
**What goes wrong:** Using `@./references/reconciliation.md` (relative to cwd) instead of `@../references/reconciliation.md` (relative to the command file).
**Why it happens:** Ambiguity about whether `@` paths resolve from the file's location or the working directory.
**How to avoid:** `@` paths in `.md` files resolve relative to the file's own location. `commands/reconcile.md` is one level deep from the skill root, so references/ is at `../references/`.
**Warning signs:** "File not found" or empty context when invoking the command.

### Pitfall 2: Forgetting to Update Script Path References After Rename
**What goes wrong:** `bin/` renamed to `scripts/` but references in SKILL.md, command files, CLAUDE.md, and INDEX.md still say `bin/`.
**Why it happens:** References are scattered across many files. Easy to miss one.
**How to avoid:** Full grep sweep: `grep -r 'bin/skippy' .` after rename. The complete list of files needing updates:
- `skills/skippy/SKILL.md` (lines 54, 64) -- references `bin/skippy-update.sh` and `bin/skippy-cleanup.sh`
- `skills/skippy/commands/update.md` (line 19) -- references `bin/skippy-update.sh`
- `skills/skippy/commands/cleanup.md` (line 23) -- references `bin/skippy-cleanup.sh`
- `CLAUDE.md` (file tree shows `bin/`)
- `INDEX.md` (if it references bin/)
**Warning signs:** Script invocation fails with "no such file or directory".

### Pitfall 3: Description Length Exceeding Budget
**What goes wrong:** Current description is 154 chars. Budget recommendation is 130 chars max for efficient skill metadata loading.
**Why it happens:** Description written for human readability, not token efficiency.
**How to avoid:** Trim to under 130 chars while preserving key trigger words. Proposed (127 chars):
`Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency`
(Drops the second sentence "Augments GSD with best-of-breed ideas from the PAUL framework." which is context, not trigger keywords.)
**Warning signs:** Skill exceeds metadata budget contribution, reducing room for future skills.

### Pitfall 4: Quarantine Path in cleanup.sh is Machine-Specific
**What goes wrong:** `skippy-cleanup.sh` hardcodes `/Volumes/ThunderBolt/_tmp/skippy-cleanup/` as quarantine directory. This path only exists on Rico's machine.
**Why it happens:** Script written for personal use before portability was a goal.
**How to avoid:** This is a Phase 3 script hardening concern per CONTEXT.md, but the SKILL.md reference to this path (line 65) should at minimum note it's configurable or use a generic description.
**Warning signs:** Quarantine mode fails on any machine without `/Volumes/ThunderBolt/`.

### Pitfall 5: SKILL.md Body References to Absolute Paths
**What goes wrong:** SKILL.md lines 54, 64, and 73-80 reference `~/.config/pai/Skills/skippy/...` -- these are PAI-installation-specific paths that won't work when the skill is loaded from a plugin cache or a different install location.
**Why it happens:** SKILL.md was written assuming PAI's install location.
**How to avoid:** Replace with `${CLAUDE_SKILL_DIR}/...` for script execution paths. For the "For Agents" section, use `${CLAUDE_SKILL_DIR}/references/...` pattern.

## Code Examples

Verified patterns from official sources:

### Relative Path Reference in Command File
```markdown
<!-- Source: Claude Code docs -- @ file references resolve relative to file location -->
<!-- File: skills/skippy/commands/reconcile.md -->
<execution_context>
@../SKILL.md
@../references/reconciliation.md
@../references/state-consistency.md
</execution_context>
```

### SKILL.md Script Reference with CLAUDE_SKILL_DIR
```markdown
<!-- Source: Claude Code docs -- ${CLAUDE_SKILL_DIR} substitution variables -->
<!-- File: skills/skippy/SKILL.md -->
### /skippy:update

Check GSD and PAUL repos for upstream changes worth absorbing.

**Workflow:**

1. Run `${CLAUDE_SKILL_DIR}/scripts/skippy-update.sh`
2. Review the diff report
3. Human decides what to absorb -- no auto-merge
```

### Spec-Compliant Frontmatter
```yaml
# Source: Agent Skills spec (agentskills.io) + CONTEXT.md target frontmatter
---
name: skippy
description: Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency
metadata:
  version: "0.1.0"
  author: "rodaddy"
  source: "https://github.com/rodaddy/skippy-agentspace"
---
```

### For Agents Section with Portable Paths
```markdown
<!-- Source: Architecture research Pattern 3 -->
## For Agents

When spawning GSD agents (planner, executor, verifier), you can enhance their prompts:

Read ${CLAUDE_SKILL_DIR}/references/task-anatomy.md
# Include when the agent is creating plans

Read ${CLAUDE_SKILL_DIR}/references/plan-boundaries.md
# Include when the plan needs scope protection

Read ${CLAUDE_SKILL_DIR}/references/state-consistency.md
# Include when the agent touches state files
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `~/.claude/commands/` directory | `~/.claude/skills/` directory | Claude Code v2.1.3+ | Skills support auto-discovery, `${CLAUDE_SKILL_DIR}`, plugin system. Commands still work but are legacy. |
| `triggers:` frontmatter field | `description:` field for discovery | Agent Skills spec v1.0 | Claude uses description for semantic matching. triggers: is ignored. |
| `bin/` script directory | `scripts/` script directory | Agent Skills spec convention | Cross-tool compatibility with 30+ AI coding tools |
| Hardcoded absolute paths | `${CLAUDE_SKILL_DIR}` + relative paths | Always best practice | Required for portability and plugin system compatibility |

**Deprecated/outdated:**
- `triggers:` frontmatter field -- not in Agent Skills spec, silently ignored by Claude Code
- `bin/` directory name -- works but non-standard per Agent Skills spec convention

## Complete Change Inventory

Every file that needs modification in Phase 1, with exact changes:

### File: `skills/skippy/commands/reconcile.md`
| Line | Current | Target |
|------|---------|--------|
| 12 | `@/Users/rico/.config/pai/Skills/skippy/SKILL.md` | `@../SKILL.md` |
| 13 | `@/Users/rico/.config/pai/Skills/skippy/references/reconciliation.md` | `@../references/reconciliation.md` |
| 14 | `@/Users/rico/.config/pai/Skills/skippy/references/state-consistency.md` | `@../references/state-consistency.md` |

### File: `skills/skippy/commands/update.md`
| Line | Current | Target |
|------|---------|--------|
| 12 | `@/Users/rico/.config/pai/Skills/skippy/SKILL.md` | `@../SKILL.md` |
| 19 | `~/.config/pai/Skills/skippy/bin/skippy-update.sh` | `${CLAUDE_SKILL_DIR}/scripts/skippy-update.sh` |

### File: `skills/skippy/commands/cleanup.md`
| Line | Current | Target |
|------|---------|--------|
| 12 | `@/Users/rico/.config/pai/Skills/skippy/SKILL.md` | `@../SKILL.md` |
| 17 | `/Volumes/ThunderBolt/_tmp/skippy-cleanup/` | `a configurable quarantine directory` (or similar generic description) |
| 23 | `~/.config/pai/Skills/skippy/bin/skippy-cleanup.sh [--quarantine|--nuke]` | `${CLAUDE_SKILL_DIR}/scripts/skippy-cleanup.sh [--quarantine|--nuke]` |

### File: `skills/skippy/SKILL.md`
| Area | Current | Target |
|------|---------|--------|
| Frontmatter | Has `triggers:` field | Remove `triggers:`, add `metadata:` block |
| Description | 154 chars | Trim to ~127 chars |
| Line 54 | `~/.config/pai/Skills/skippy/bin/skippy-update.sh` | `${CLAUDE_SKILL_DIR}/scripts/skippy-update.sh` |
| Line 64 | `~/.config/pai/Skills/skippy/bin/skippy-cleanup.sh` | `${CLAUDE_SKILL_DIR}/scripts/skippy-cleanup.sh` |
| Line 65 | `/Volumes/ThunderBolt/_tmp/skippy-cleanup/` | Generic description (e.g., "a quarantine directory") |
| Lines 73-80 | `~/.config/pai/Skills/skippy/references/...` (3 occurrences) | `${CLAUDE_SKILL_DIR}/references/...` |

### File: `skills/skippy/bin/` -> `skills/skippy/scripts/`
- `git mv skills/skippy/bin/ skills/skippy/scripts/`

### File: `CLAUDE.md`
- Update file tree: `bin/` -> `scripts/`

### File: `INDEX.md`
- Verify/update if it references `bin/`

## Open Questions

1. **Should cleanup.md mention `/Volumes/ThunderBolt/` at all?**
   - What we know: The quarantine path is hardcoded in the shell script (Phase 3 fix) and referenced in cleanup.md and SKILL.md
   - What's unclear: Whether to just remove the specific path from the .md files now (Phase 1) or leave it since the script itself won't be fixed until Phase 3
   - Recommendation: Replace specific path with generic language in .md files now ("moves to a quarantine directory for later review"). The script fix is Phase 3 but the documentation should not advertise a machine-specific path.

2. **Does `@../SKILL.md` work in Claude Code command files?**
   - What we know: Claude Code docs confirm `@` paths resolve relative to the file location. Research says relative paths are preferred (CONTEXT.md decision).
   - What's unclear: No direct test confirms `@../` traversal works in command .md files specifically (vs SKILL.md body)
   - Recommendation: HIGH confidence it works based on docs. Verify after implementation by invoking each command.

3. **Should a `docs/` directory be added (STRU-01)?**
   - What we know: CONTEXT.md says "May need a `docs/` directory for project-level documentation"
   - What's unclear: What project-level docs would go there vs in references/
   - Recommendation: Skip for Phase 1. The 5 reference docs are skill-level (PAUL enhancements). If project-level docs are needed (origin story, architecture decisions), that's a Phase 4 documentation concern. STRU-01 only requires "detail in `references/` and `docs/`" -- references/ alone satisfies this.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification (bash + grep) |
| Config file | none -- shell commands only |
| Quick run command | `grep -r '/Users/rico\|/Volumes/ThunderBolt' skills/` |
| Full suite command | See full validation commands below |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPEC-01 | No absolute paths in skill files | smoke | `grep -rn '/Users/\|/Volumes/' skills/ \| grep -v '.planning/'` | N/A -- inline command |
| SPEC-02 | Frontmatter has name, description, metadata; no triggers | smoke | `head -20 skills/skippy/SKILL.md \| grep -c 'triggers:'` (expect 0) | N/A -- inline command |
| SPEC-03 | scripts/ exists, bin/ does not, no broken refs | smoke | `test -d skills/skippy/scripts/ && ! test -d skills/skippy/bin/ && ! grep -rn 'bin/skippy' skills/` | N/A -- inline command |
| STRU-01 | SKILL.md under 150 lines, references exist, index present | smoke | `wc -l skills/skippy/SKILL.md` (expect < 150) + `ls skills/skippy/references/*.md \| wc -l` (expect 5) + `test -f INDEX.md` | N/A -- inline command |

### Sampling Rate
- **Per task commit:** `grep -rn '/Users/\|/Volumes/' skills/` -- zero matches expected
- **Per wave merge:** All 4 validation commands above
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
None -- all validation is inline shell commands. No test framework or fixtures needed.

## Sources

### Primary (HIGH confidence)
- Agent Skills Specification (agentskills.io) -- frontmatter fields, directory conventions, progressive disclosure
- Claude Code Skills Documentation (code.claude.com/docs/en/skills) -- `${CLAUDE_SKILL_DIR}`, `@` file references, auto-discovery
- Project research: `.planning/research/STACK.md` -- stack decisions, spec compliance gaps
- Project research: `.planning/research/ARCHITECTURE.md` -- discovery mechanisms, path resolution patterns
- Project research: `.planning/research/PITFALLS.md` -- hardcoded paths, naming collisions, context budget

### Secondary (MEDIUM confidence)
- CONTEXT.md locked decisions (relative paths, keep commands/, shell scripts stay)
- SFEIR Institute common skill mistakes guide -- description length recommendations

### Tertiary (LOW confidence)
- None -- all findings verified from official sources or direct code inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Agent Skills spec and Claude Code docs are definitive
- Architecture: HIGH -- patterns verified from official docs and existing research
- Pitfalls: HIGH -- every pitfall verified by reading actual source files and cross-referencing with known bugs
- Change inventory: HIGH -- complete grep of all affected files performed

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stable domain, unlikely to change)
