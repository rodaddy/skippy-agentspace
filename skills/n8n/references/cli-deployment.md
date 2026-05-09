<!-- Extracted from SKILL.md -- load on demand -->
# n8n CLI Deployment

## Prerequisites

The n8n CLI needs explicit DB environment variables. It defaults to SQLite, but we use PostgreSQL.

Required env vars for every CLI command:
```
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<DB_IP>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8nops
DB_POSTGRESDB_PASSWORD=<DB_PASSWORD>
N8N_USER_FOLDER=/home/n8n/.n8n
```

## Preferred: n8n-wf CLI Helper

The `n8n-wf` helper at `~/.claude/bin/n8n-wf` wraps all CLI operations with fuzzy name lookup and local caching.

```bash
n8n-wf help          # Show all commands
n8n-wf list          # Active workflows
n8n-wf status        # All workflows with ON/OFF + PUB flags
n8n-wf export "name" # Export by fuzzy name
n8n-wf import f.json --activate  # Import + activate + publish + restart
n8n-wf execs "name" 5  # Recent executions
n8n-wf nodes "name"    # List node names
n8n-wf publish "name"  # Publish (required for webhooks)
n8n-wf logs 50         # Tail n8n log
n8n-wf errors 30       # Tail error log
```

**Fuzzy matching:** Prefers active non-archived workflows. Archived workflows use `old_YYYY-MM-DD_name` naming convention.

## Manual Import (when n8n-wf isn't available)

### Update existing workflow (include ID)

```bash
# SCP workflow to n8n container
scp workflow.json root@<N8N_IP>:/tmp/workflow.json

# Import as n8n user
ssh root@<N8N_IP> "su - n8n -s /bin/bash -c 'export DB_TYPE=postgresdb DB_POSTGRESDB_HOST=<DB_IP> DB_POSTGRESDB_PORT=5432 DB_POSTGRESDB_DATABASE=n8n DB_POSTGRESDB_USER=n8nops DB_POSTGRESDB_PASSWORD=<DB_PASSWORD> N8N_USER_FOLDER=/home/n8n/.n8n && n8n import:workflow --input=/tmp/workflow.json'"

# Activate + publish via DB (update:workflow is DEPRECATED in n8n 2.x)
ssh "root@<N8N_IP>" "PGPASSWORD='<DB_PASSWORD>' psql -h <DB_IP> -U n8nops -d n8n -t -A" <<'ENDSQL'
UPDATE workflow_entity SET active = true WHERE id = 'WORKFLOW_ID';
INSERT INTO workflow_published_version ("workflowId", "publishedVersionId")
  SELECT 'WORKFLOW_ID', "activeVersionId" FROM workflow_entity WHERE id = 'WORKFLOW_ID'
  ON CONFLICT ("workflowId")
  DO UPDATE SET "publishedVersionId" = EXCLUDED."publishedVersionId";
ENDSQL

# MUST restart
ssh root@<N8N_IP> 'systemctl restart n8n'
```

### Create new workflow (no ID)

Same command but without ID in JSON. Note: this creates a NEW workflow every time.

**Gotcha:** If you import without an ID, you get a duplicate. Always include `"id"` for updates.

## Export Workflow

```bash
n8n-wf export "workflow name" output.json
```

**Gotcha:** CLI export wraps the workflow in an array. `n8n-wf` auto-unwraps with `jq '.[0]'`.

## Activate/Deactivate

**DEPRECATED:** `n8n update:workflow --active=true` no longer works in n8n 2.x.

Use DB-based activate + publish instead (see import section above), or use:
- mcp2cli: `mcp2cli n8n activate_workflow` / `mcp2cli n8n deactivate_workflow`
- n8n-wf: `n8n-wf import file.json --activate`

## Service Management

```bash
ssh root@<N8N_IP> 'systemctl status n8n'
ssh root@<N8N_IP> 'systemctl restart n8n'
n8n-wf logs 50     # or: ssh root@<N8N_IP> 'tail -50 /var/log/n8n/n8n.log'
n8n-wf errors 30   # or: ssh root@<N8N_IP> 'tail -30 /var/log/n8n/n8n-error.log'
ssh root@<N8N_IP> 'journalctl -u n8n -f'  # follow logs
```

## Post-Import Checklist

1. Restart n8n: `systemctl restart n8n`
2. Check logs for errors: `n8n-wf errors 20`
3. Verify workflow is published: `n8n-wf status`
4. If webhook-based: verify webhook is registered in n8n UI
5. Test with manual execution in n8n UI
