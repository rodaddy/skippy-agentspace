# CanonicalizeSkill Workflow

**Purpose:** Restructure an existing skill to match the canonical format with proper naming conventions.

---

## Step 1: Read the Authoritative Source

**REQUIRED FIRST:** Read the canonical structure:

```
${PAI_HOME}/Skills/CORE/SkillSystem.md
```

---

## Step 2: Read the Current Skill

Identify what's wrong:
- Multi-line description using `|`?
- Separate `triggers:` array in YAML? (OLD FORMAT)
- Missing `USE WHEN` in description?
- Workflow routing missing from markdown body?
- **Workflow files not using TitleCase?**
- **Skill directory not using TitleCase?**

---

## Step 3: Backup

```bash
cp -r ${PAI_HOME}/Skills/[skill-name]/ ${PAI_HOME}/History/Backups/[skill-name]-backup-$(date +%Y%m%d)/
```

**Note:** Backups go to `${PAI_HOME}/History/Backups/`, NEVER inside skill directories.

---

## Step 4: Enforce TitleCase Naming

### Skill Directory Name
```
✗ WRONG: createskill, create-skill, create_skill, CREATESKILL
✓ CORRECT: Createskill (or CreateSkill for multi-word)
```

### Workflow File Names
```
✗ WRONG: create.md, CREATE.md, create-skill.md
✓ CORRECT: Create.md, UpdateInfo.md, SyncRepo.md
```

**Rename files if needed:**
```bash
cd ${PAI_HOME}/Skills/[SkillName]/Workflows/
mv create.md Create.md
mv update-info.md UpdateInfo.md
```

---

## Step 5: Enforce Flat Folder Structure

**Maximum 2 levels deep - `Skills/SkillName/Category/`**

Check for nested folders:
```bash
find ${PAI_HOME}/Skills/[SkillName]/ -type d -mindepth 2 -maxdepth 3
```

Fix violations:
- `Workflows/Company/DueDiligence.md` → `Workflows/CompanyDueDiligence.md`

---

## Step 6: Convert YAML Frontmatter

**From old format (WRONG):**
```yaml
---
name: skill-name
description: |
  What the skill does.

triggers:
  - USE WHEN user mentions X

workflows:
  - USE WHEN user wants to A: Workflows/a.md
---
```

**To new format (CORRECT):**
```yaml
---
name: SkillName
description: What the skill does. USE WHEN user mentions X OR user wants to Y.
---
```

---

## Step 7: Add Workflow Routing to Body

```markdown
## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **WorkflowOne** | "trigger phrase" | `Workflows/WorkflowOne.md` |
```

---

## Step 8: Add Examples Section

**REQUIRED:**

```markdown
## Examples

**Example 1: [Common use case]**
\`\`\`
User: "[Typical user request]"
→ Invokes WorkflowName workflow
→ [What skill does]
→ [What user gets back]
\`\`\`
```

---

## Step 9: Verify

Run checklist against SkillSystem.md.

---

## Done

Skill now matches the canonical structure.
