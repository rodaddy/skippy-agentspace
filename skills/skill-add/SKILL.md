---
name: skill-add
description: Scaffolds a new PAI skill with slim SKILL.md + references/ architecture. Creates directory, generates files, registers symlink. Use when adding any new skill.
triggers:
  - /skill-add
  - add skill
  - create skill
  - new skill
user-invocable: true
---

# Skill Add - Create New PAI Skills

Scaffolds a new skill following the slim architecture pattern: core directives in SKILL.md (~80-150 lines), detailed reference material in `references/` subdirectory. Registers via symlink for discovery.

## Step 0: Skill vs Memory Gate

**Rule: If no custom workflow, scripts, or reference files -- create a memory file instead.**

Simple procedures using only existing tools belong in memory (`~/.config/pai-private/memory/`), not skills. Skills exist when there's a repeatable workflow with reference material that should load on demand.

**If memory is the right fit:** Create `~/.config/pai-private/memory/<name>.md`, skip remaining steps, report creation.

## Step 1: Gather Information

Ask user (via AskUserQuestion):

1. **Skill name** -- kebab-case (e.g., `homeassistant`). Validate uniqueness against existing skills.
2. **One-line description** -- For SKILL.md frontmatter and skill list.
3. **Trigger phrases** -- At least `/<name>` plus natural language triggers.
4. **Location** -- Global (default), private, or project-specific.
5. **Reference files needed?** -- What detailed docs should live in `references/`. Examples: field references, troubleshooting guides, architecture docs, command references, gotchas.

See **references/skill-locations.md** for location details and symlink rules.

## Step 2: Generate SKILL.md

Use template from **references/skill-template.md**. Keep SKILL.md under ~150 lines.

**Architecture rules:**
- SKILL.md has: triggers, workflow steps, critical rules, References section linking to `references/`
- `references/` has: detailed tables, command references, architecture docs, gotchas, examples
- Reference docs use `<!-- Extracted from SKILL.md -- load on demand -->` header
- Reference docs are loaded by spawning a haiku explore agent, not read into main context

## Step 3: Generate Reference Files

For each reference file identified in Step 1:
1. Create with `<!-- Extracted from SKILL.md -- load on demand -->` header
2. Write comprehensive content -- this is where detail lives
3. Reference files can grow over time as knowledge accumulates

## Step 4: Preview All Changes

**LAW #5: Present complete preview before applying changes.**

Show:
- Skill name, location, description
- Files to create (SKILL.md + each reference file)
- First 15 lines of SKILL.md
- Symlink to register

Wait for user approval.

## Step 5: Apply Changes

1. Create skill directory + `references/` subdirectory
2. Write SKILL.md
3. Write all reference files
4. Register symlink:

```bash
# Global (default)
ln -s ~/.config/pai/Skills/<name> ~/.claude/skills/<name>

# Private
ln -s ~/.config/pai-private/Skills/<name> ~/.claude/skills/<name>

# Project -- no symlink needed, discovered from <project>/.claude/skills/
```

## Step 6: Register in Skill Inventory

**MANDATORY:** Update `references/existing-skills.md` with the new skill entry. This prevents duplicates and keeps the inventory current.

```bash
# Add row to the skill table in alphabetical order
# Format: | <name> | <one-line description> |
```

## Step 7: Verify

```bash
# Confirm symlink
ls -la ~/.claude/skills/<name>

# Confirm SKILL.md readable
head -5 ~/.claude/skills/<name>/SKILL.md

# Confirm references
ls ~/.claude/skills/<name>/references/ 2>/dev/null

# Confirm inventory updated
grep "<name>" ~/.config/pai/Skills/skill-add/references/existing-skills.md
```

## Output

```
Skill created: <name>
   Source: ~/.config/pai/Skills/<name>/SKILL.md
   References: <count> files in references/
   Registered: ~/.claude/skills/<name> -> source
   Triggers: /<name>, <other triggers>

   Available next session (or test now with: "<trigger phrase>")
```

## References

- **references/skill-template.md** -- Full SKILL.md template structure
- **references/skill-locations.md** -- Location types, symlink rules, discovery
- **references/existing-skills.md** -- Current skill inventory (check for duplicates)

## Notes

- **All new skills MUST follow the slim architecture.** SKILL.md for workflow, `references/` for detail.
- Reference files are the living knowledge base -- append to them as we learn new things.
- Preview before applying (LAW #5). Get confirmation before creating files.
- Remind user skill appears in system-reminder list next session.
