# CreateSkill Workflow

Create a new skill following the canonical structure with proper TitleCase naming.

## Step 1: Read the Authoritative Sources

**REQUIRED FIRST:**

1. Read the skill system documentation: `${PAI_HOME}/Skills/CORE/SkillSystem.md`

## Step 2: Understand the Request

Ask the user:
1. What does this skill do?
2. What should trigger it?
3. What workflows does it need?

## Step 3: Determine TitleCase Names

**All names must use TitleCase (PascalCase).**

| Component | Format | Example |
|-----------|--------|---------|
| Skill directory | TitleCase | `Research`, `Art`, `CreateSkill` |
| Workflow files | TitleCase.md | `Create.md`, `UpdateInfo.md` |
| Tool files | TitleCase.ts | `Analyze.ts` |

**Wrong naming (NEVER use):**
- `create-skill`, `create_skill`, `CREATESKILL` → Use `CreateSkill`
- `create.md`, `CREATE.md`, `create-info.md` → Use `Create.md`, `CreateInfo.md`

## Step 4: Create the Skill Directory

```bash
mkdir -p ${PAI_HOME}/Skills/[SkillName]/Workflows
mkdir -p ${PAI_HOME}/Skills/[SkillName]/Tools
```

## Step 5: Create SKILL.md

Follow this exact structure:

```yaml
---
name: SkillName
description: [What it does]. USE WHEN [intent triggers using OR]. [Additional capabilities].
---

# SkillName

[Brief description]

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **WorkflowOne** | "trigger phrase" | `Workflows/WorkflowOne.md` |
| **WorkflowTwo** | "another trigger" | `Workflows/WorkflowTwo.md` |

## Examples

**Example 1: [Common use case]**
\`\`\`
User: "[Typical user request]"
→ Invokes WorkflowOne workflow
→ [What skill does]
→ [What user gets back]
\`\`\`

**Example 2: [Another use case]**
\`\`\`
User: "[Different request]"
→ [Process]
→ [Output]
\`\`\`

## [Additional Documentation]

[Any other relevant info]
```

## Step 6: Create Workflow Files

For each workflow in the routing section:

```bash
touch ${PAI_HOME}/Skills/[SkillName]/Workflows/[WorkflowName].md
```

## Step 7: Verify TitleCase

Run this check:
```bash
ls ${PAI_HOME}/Skills/[SkillName]/
ls ${PAI_HOME}/Skills/[SkillName]/Workflows/
ls ${PAI_HOME}/Skills/[SkillName]/Tools/
```

Verify ALL files use TitleCase.

## Step 8: Final Checklist

### Naming (TitleCase)
- [ ] Skill directory uses TitleCase
- [ ] All workflow files use TitleCase
- [ ] All tool files use TitleCase
- [ ] Routing table workflow names match file names exactly

### YAML Frontmatter
- [ ] `name:` uses TitleCase
- [ ] `description:` is single-line with embedded `USE WHEN` clause
- [ ] No separate `triggers:` or `workflows:` arrays
- [ ] Description under 1024 characters

### Markdown Body
- [ ] `## Workflow Routing` section with table format
- [ ] All workflow files have routing entries
- [ ] `## Examples` section with 2-3 concrete usage patterns

### Structure
- [ ] `Tools/` directory exists (even if empty)
- [ ] No `backups/` directory inside skill

## Done

Skill created following canonical structure with proper TitleCase naming throughout.
