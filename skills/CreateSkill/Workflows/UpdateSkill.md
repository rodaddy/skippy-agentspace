# UpdateSkill Workflow

**Purpose:** Add workflows or modify an existing skill while maintaining canonical structure and TitleCase naming.

---

## Step 1: Read the Authoritative Source

**REQUIRED FIRST:** Read the canonical structure:

```
${PAI_HOME}/Skills/CORE/SkillSystem.md
```

---

## Step 2: Read the Current Skill

```bash
${PAI_HOME}/Skills/[SkillName]/SKILL.md
```

---

## Step 3: Make Changes

### To Add a New Workflow:

1. **Determine TitleCase name:**
   - ✓ `Create.md`, `UpdateInfo.md`, `SyncRepo.md`
   - ✗ `create.md`, `update-info.md`, `SYNC_REPO.md`

2. **Create the workflow file:**
```bash
touch ${PAI_HOME}/Skills/[SkillName]/Workflows/[WorkflowName].md
```

3. **Add entry to `## Workflow Routing` section in SKILL.md:**
```markdown
## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **ExistingWorkflow** | "existing trigger" | `Workflows/ExistingWorkflow.md` |
| **NewWorkflow** | "new trigger" | `Workflows/NewWorkflow.md` |
```

4. **Write the workflow content**

### To Update Triggers:

Modify the single-line `description` in YAML frontmatter:
```yaml
description: [What it does]. USE WHEN [updated intent triggers using OR]. [Capabilities].
```

---

## Step 4: Final Checklist

- [ ] New workflow files use TitleCase
- [ ] Routing table names match file names exactly
- [ ] YAML still has single-line description with USE WHEN
- [ ] All routes point to existing files

---

## Done

Skill updated while maintaining canonical structure and TitleCase naming.
