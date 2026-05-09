---
name: specify
description: Generate specifications from JIRA tickets. Fetches ticket summary/description/acceptance criteria, asks clarifying questions, writes 3-document spec (spec.md, requirements.md, architecture.md).
triggers:
  # Replace PROJ with your actual JIRA project key (e.g., MYAPP-, INFRA-, PLAT-)
  - "create a spec for PROJ-"
  - "write a spec for PROJ-"
  - "spec PROJ-"
---

# Specification Generator from JIRA

**Generates architecture-focused specifications from JIRA tickets.**

## Workflow

### 1. Fetch JIRA (Targeted Fields Only)

```javascript
mcp__plugin_my-jira_atlassian__getJiraIssue({
  cloudId: "https://your-org.atlassian.net",
  issueIdOrKey: "PROJ-XXXXX",  // Replace PROJ with your JIRA project key
  fields: ["summary", "description", "customfield_10224", "parent"]
  // Only: summary, description, acceptance criteria, parent epic
})
```

### 2. Ask Clarifying Questions (Batched)

Use AskUserQuestion with 4 questions:

1. **Detail level:** Architecture-focused (default) | Implementation-ready | Hybrid
2. **Code research:** Yes - read files | No - JIRA only | Partial
3. **Tooling:** Bun/TypeScript (default) | Python (if codebase is Python) | Bash
4. **Output:** Both specs/ and specs/temp/ (default) | Final only

### 3. Read Code (If Requested)

Use Read tool to examine relevant files mentioned in JIRA description or inferred from ticket scope.

### 4. Write Specs

Write 3 files to `specs/{TICKET}/` using templates:

- **spec.md** - Use `templates/spec-template.md`
- **requirements.md** - Use `templates/requirements-template.md`
- **architecture.md** - Use `templates/architecture-template.md`

Templates located at: `~/.config/pai/Skills/specify/templates/`

## Key Rules

- **Bun/TypeScript default** for scripts (NOT Python unless codebase is Python-only)
- **Architecture-focused** by default (high-level design, trade-offs)
- **Single iteration** - complete on first pass
- **Batch questions** - all 4 at once, not iteratively

## Anti-Patterns

❌ Don't fetch full JIRA (burns 10K tokens) - use fields parameter
❌ Don't embed templates inline - reference template files
❌ Don't use agents for single spec - direct approach only
❌ Don't assume Python - default to Bun unless asked

## Output Structure

```
specs/{TICKET}/
├── spec.md              # Problem, solution, acceptance criteria
├── requirements.md      # Functional + technical requirements
└── architecture.md      # Design, trade-offs, implementation plan

specs/temp/              # Working files (optional)
└── questions/{TICKET}-questions.md
```

---

**Last Updated:** 2026-01-10
**Template Location:** `~/.config/pai/Skills/specify/templates/`
