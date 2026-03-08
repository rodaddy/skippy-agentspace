# Add Todo Examples

## Single Project Todo

User says: "Add a todo to refactor the OAuth flow"

**CWD check:** `.planning/` exists -> project todo

**Output:**
```
Created: Refactor OAuth flow
Scope: project
Priority: medium
Location: .planning/todos/pending/refactor-oauth-flow.md
```

**File:**
```markdown
---
tags: [refactor, oauth]
project: my-project
added: 2026-02-25
priority: medium
---

# Refactor OAuth Flow

Current OAuth implementation is fragile and doesn't handle token refresh properly. Need to refactor to use a proper OAuth library and add monitoring for token expiration.

1. Research OAuth libraries
2. Implement token refresh logic
3. Add monitoring/alerting for token expiration
4. Update documentation
```

## Global Idea

User says: "Remember to add a /proxmox skill for bulk container updates"

**CWD check:** No `.planning/` directory -> global idea

**File:**
```markdown
---
tags: [infra, automation]
project: infrastructure
added: 2026-02-25
priority: medium
---

# Add bulk container update skill

Create a skill that can update multiple containers at once. Currently have to SSH to each container individually.

1. Design the skill interface
2. Implement via proxmox MCP
3. Add dry-run mode
4. Test on non-critical containers first
```

## With Existing Context

When detailed docs already exist, link rather than copy:

```markdown
# K3s Cluster Setup

3-node k3s cluster setup. Full planning completed 2026-02-24.

## References

- **Full plan:** `.reports/k3s-cluster-plan.md`
- **Session notes:** `.reports/session-2026-02-24_k3s-planning.md`

## Next Action

Phase 0: Local dev environment.
```
