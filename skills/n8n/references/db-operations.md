<!-- Extracted from SKILL.md -- load on demand -->
# n8n Database Operations

## Connection Details

| Field | Value |
|-------|-------|
| Host | PostgreSQL container (<DB_IP>) — see HOSTMAP.md for CT ID |
| Port | 5432 |
| Database | `n8n` |
| User | `n8nops` |
| Password | `<DB_PASSWORD>` (vaultwarden: "PostgreSQL n8n-ops") |

## SSH + PostgreSQL Access Pattern

Use heredoc piped to psql stdin. This preserves PostgreSQL double-quoted column names without shell escaping issues.

```bash
ssh "root@<N8N_IP>" "PGPASSWORD='<DB_PASSWORD>' psql -h <DB_IP> -U n8nops -d n8n -t -A" <<'ENDSQL'
SELECT "workflowId", "publishedVersionId"
FROM workflow_published_version;
ENDSQL
```

**NEVER** use `-c 'SQL'` when SQL contains double-quoted PostgreSQL identifiers. The single-quote wrapping mangles double quotes through shell expansion layers.

**NEVER** store complex SQL in a bash variable with escaped quotes -- fragile and causes `set -u` errors.

## Common Queries

### Check active/published status
```sql
SELECT w.id, w.name, w.active,
       p."publishedVersionId" IS NOT NULL as published
FROM workflow_entity w
LEFT JOIN workflow_published_version p ON w.id = p."workflowId"
WHERE w.active = true;
```

### Publish all unpublished active workflows
```sql
INSERT INTO workflow_published_version ("workflowId", "publishedVersionId")
SELECT w.id, w."activeVersionId"
FROM workflow_entity w
LEFT JOIN workflow_published_version p ON w.id = p."workflowId"
WHERE w.active = true
  AND w."activeVersionId" IS NOT NULL
  AND p."workflowId" IS NULL;
```

### Get active version's nodes for a workflow
```sql
SELECT nodes FROM workflow_history
WHERE "versionId" = (
  SELECT "activeVersionId" FROM workflow_entity WHERE id = 'WORKFLOW_ID'
);
```

### Check recent executions
```sql
SELECT id, "workflowId", status, "startedAt"
FROM execution_entity ORDER BY id DESC LIMIT 10;
```

### Check specific workflow executions
```sql
SELECT id, status, "startedAt", "stoppedAt"
FROM execution_entity
WHERE "workflowId" = 'WORKFLOW_ID'
ORDER BY id DESC LIMIT 5;
```

## DB Surgery for Workflow Updates (n8n 2.x)

**CRITICAL:** n8n 2.x runs workflows from `workflow_history` table, NOT `workflow_entity.nodes`.

Three tables involved:

| Table | Purpose |
|-------|---------|
| `workflow_entity` | Main record. Has `active`, `versionId`, `activeVersionId` |
| `workflow_history` | Versioned snapshots of nodes/connections. Keyed by `versionId` |
| `workflow_published_version` | Maps workflowId -> publishedVersionId. Must exist for webhooks |

### To update a running workflow via DB:

1. Update nodes in `workflow_history` WHERE `versionId` = the active version
2. Also update `workflow_entity.nodes` for consistency
3. Restart n8n: `systemctl restart n8n`

### To update credential references in a workflow:

```sql
-- Get current nodes JSON
SELECT nodes FROM workflow_history
WHERE "versionId" = (
  SELECT "activeVersionId" FROM workflow_entity WHERE id = 'WORKFLOW_ID'
);

-- Update nodes (use Python/jq locally, then write back)
-- MUST update BOTH tables
UPDATE workflow_history SET nodes = '<NEW_NODES_JSON>'
WHERE "versionId" = (
  SELECT "activeVersionId" FROM workflow_entity WHERE id = 'WORKFLOW_ID'
);

UPDATE workflow_entity SET nodes = '<NEW_NODES_JSON>'
WHERE id = 'WORKFLOW_ID';
```

Always restart after: `ssh root@<N8N_IP> 'systemctl restart n8n'`
