# ValidateSkill Workflow

**Purpose:** Check if an existing skill follows the canonical structure with proper TitleCase naming.

---

## Step 1: Read the Authoritative Source

**REQUIRED FIRST:** Read the canonical structure:

```
${PAI_HOME}/Skills/CORE/SkillSystem.md
```

---

## Step 2: Read the Target Skill

```bash
${PAI_HOME}/Skills/[SkillName]/SKILL.md
```

---

## Step 3: Check TitleCase Naming

### Skill Directory
```bash
ls ${PAI_HOME}/Skills/ | grep -i [skillname]
```

Verify TitleCase:
- ✓ `Research`, `Art`, `CreateSkill`
- ✗ `createskill`, `create-skill`, `CREATE_SKILL`

### Workflow Files
```bash
ls ${PAI_HOME}/Skills/[SkillName]/Workflows/
```

Verify TitleCase:
- ✓ `Create.md`, `UpdateInfo.md`, `SyncRepo.md`
- ✗ `create.md`, `update-daemon-info.md`, `SYNC_REPO.md`

---

## Step 4: Check YAML Frontmatter

Verify the YAML has:

### Single-Line Description with USE WHEN
```yaml
---
name: SkillName
description: [What it does]. USE WHEN [intent triggers using OR]. [Additional capabilities].
---
```

**Check for violations:**
- Multi-line description using `|` (WRONG)
- Missing `USE WHEN` keyword (WRONG)
- Separate `triggers:` array in YAML (OLD FORMAT - WRONG)
- Separate `workflows:` array in YAML (OLD FORMAT - WRONG)
- `name:` not in TitleCase (WRONG)

---

## Step 5: Check Markdown Body

Verify the body has:

### Workflow Routing Section
```markdown
## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **WorkflowOne** | "trigger phrase" | `Workflows/WorkflowOne.md` |
```

### Examples Section
```markdown
## Examples

**Example 1: [Use case]**
\`\`\`
User: "[Request]"
→ [Action]
→ [Result]
\`\`\`
```

**Check:** Examples section required (WRONG if missing)

---

## Step 6: Report Results

**COMPLIANT** if all checks pass.

**NON-COMPLIANT** if any check fails. Recommend using CanonicalizeSkill workflow.
