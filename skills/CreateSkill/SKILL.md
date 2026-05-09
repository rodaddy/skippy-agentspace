---
name: CreateSkill
description: Create and validate skills. USE WHEN create skill, new skill, skill structure, canonicalize. SkillSearch('createskill') for docs.
---

# CreateSkill

MANDATORY skill creation framework for ALL skill creation requests.

## Authoritative Source

**Before creating ANY skill, READ:** `${PAI_HOME}/Skills/CORE/SkillSystem.md`

## TitleCase Naming Convention

**All naming must use TitleCase (PascalCase).**

| Component | Format | Example |
|-----------|--------|---------|
| Skill directory | TitleCase | `Research`, `Art`, `CreateSkill` |
| Workflow files | TitleCase.md | `Create.md`, `UpdateInfo.md` |
| Reference docs | TitleCase.md | `ApiReference.md` |
| Tool files | TitleCase.ts | `Analyze.ts` |

**Wrong (NEVER use):**
- `createskill`, `create-skill`, `CREATE_SKILL`
- `create.md`, `update-info.md`, `SYNC_REPO.md`

---

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **CreateSkill** | "create a new skill" | `Workflows/CreateSkill.md` |
| **ValidateSkill** | "validate skill", "check skill" | `Workflows/ValidateSkill.md` |
| **UpdateSkill** | "update skill", "add workflow" | `Workflows/UpdateSkill.md` |
| **CanonicalizeSkill** | "canonicalize", "fix skill structure" | `Workflows/CanonicalizeSkill.md` |

## Examples

**Example 1: Create a new skill from scratch**
\`\`\`
User: "Create a skill for managing my recipes"
→ Invokes CreateSkill workflow
→ Reads SkillSystem.md for structure requirements
→ Creates skill directory with TitleCase naming
→ Creates SKILL.md, Workflows/, Tools/
→ Generates USE WHEN triggers based on intent
\`\`\`

**Example 2: Fix an existing skill that's not routing properly**
\`\`\`
User: "The research skill isn't triggering - validate it"
→ Invokes ValidateSkill workflow
→ Checks SKILL.md against canonical format
→ Verifies TitleCase naming throughout
→ Verifies USE WHEN triggers are intent-based
→ Reports compliance issues with fixes
\`\`\`

**Example 3: Canonicalize a skill with old naming**
\`\`\`
User: "Canonicalize the daemon skill"
→ Invokes CanonicalizeSkill workflow
→ Renames workflow files to TitleCase
→ Updates routing table to match
→ Ensures Examples section exists
→ Verifies all checklist items
\`\`\`
