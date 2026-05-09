---
name: n8n
description: Build, deploy, and manage n8n workflows. Covers credential patterns, CLI deployment, Telegram/Discord notification templates, and community edition gotchas.
---

# n8n Workflow Management

## Triggers

- `/n8n` -- explicit invocation
- "n8n workflow", "deploy workflow", "n8n credential", "telegram notification", "discord webhook"
- Any mention of the n8n container, <N8N_IP>, or n8n.your-domain.example

## Instance Details

| Field | Value |
|-------|-------|
| Container | n8n LXC (see HOSTMAP.md for CT ID) |
| IP | <N8N_IP> |
| Port | 5678 |
| External URL | https://n8n.your-domain.example |
| LAN URL | http://<N8N_IP>:5678 |
| Version | 2.9.4 (Community Edition) |
| Login | user@your-domain.example (vaultwarden: "n8n.your-domain.example") |
| Env file | `/home/n8n/.n8n/env` (NOT `.env`) |
| Logs | `/var/log/n8n/n8n.log`, `n8n-error.log` |
| Binary | `/opt/n8n/node_modules/.bin/n8n` (NOT `/usr/bin/n8n`) |
| Service | systemd `n8n` (runs as user `n8n`) |
| DB | PostgreSQL container (<DB_IP>), db: `n8n`, user: `n8nops` (vaultwarden: "PostgreSQL n8n-ops") |
| Proxy | Caddy container (:443) -- NOT nginx |
| Tunnel | Cloudflare `--token` mode (dashboard-managed, local config.yml IGNORED) |

## API Access

**REST API works in Community Edition 2.x** -- use UI-generated JWT keys, NOT the `N8N_API_KEY` env var.

| Method | Works? | Notes |
|--------|--------|-------|
| `N8N_API_KEY` env var | NO | Returns 401. Legacy, ignored in 2.x |
| UI-generated API key (JWT) | YES | Settings > API > Create key. Stored in `user_api_keys` DB table |
| Header format | `X-N8N-API-KEY: <jwt>` | NOT `Authorization: Bearer` |

Current API key label: `claude` (created 2026-01-28, expires ~2027). Stored in vaultwarden.

## Tooling (Preferred Order)

> **CRITICAL: All n8n MCP tool calls MUST go through `mcp2cli`.** Never invoke `mcp__n8n__*` or `mcp__n8n-mcp__*` tools directly. Use `mcp2cli n8n <tool> --params '{...}'`.

1. **mcp2cli n8n** -- `mcp2cli n8n <tool> --params '{...}'`. 20 tools via CLI bridge. Run `mcp2cli n8n --help` for full tool list. Key tools: `n8n_update_partial_workflow` (diff-based edits), `validate_workflow`, `n8n_autofix_workflow`, `search_nodes` (1,236 nodes incl. community). See `n8n-mcp-tools-expert` skill for usage patterns.
2. **CLI Helper** -- `n8n-wf` in `~/.claude/bin/`. Supports name-based fuzzy lookup + local cache. Run `n8n-wf help`. Good for quick exports/imports and log tailing.
3. **Direct REST API** -- `curl -H "X-N8N-API-KEY: <jwt>" http://<N8N_IP>:5678/api/v1/workflows`
4. **CLI import/export** -- SSH + `n8n import:workflow` (see `references/cli-deployment.md`)
5. **DB surgery** -- Direct PostgreSQL (see `references/db-operations.md`). Last resort.

## Companion Skills (czlonkowski/n8n-skills)

These skills provide deep n8n authoring knowledge. Load via AGENT-INDEX.md:
- **n8n-mcp-tools-expert** -- how to use n8n-mcp tools effectively (HIGHEST PRIORITY)
- **n8n-code-javascript** -- Code node JS patterns, $input, execSync, DateTime
- **n8n-expression-syntax** -- {{ }} syntax, common mistakes, $env is PAID ONLY
- **n8n-validation-expert** -- validation profiles, error catalog, auto-fix
- **n8n-workflow-patterns** -- 5 architectural patterns (webhook, API, DB, AI, scheduled)
- **n8n-node-configuration** -- operation-aware config, property dependencies
- **n8n-code-python** -- Python Code nodes (standard library only, use JS for 95% of cases)

## Critical Rules

1. **$env is PAID ONLY.** `$env.VAR` does NOT work in community edition. Pass data through `$json` fields from Code nodes, or hardcode values.
2. **API key: use JWT from UI, not env var.** The `N8N_API_KEY` env var is ignored in 2.x. See API Access above.
3. **Draft/Publish model.** n8n 2.x runs from `workflow_history` table, NOT `workflow_entity.nodes`. Must publish workflows for webhooks to register. See `references/upgrade-gotchas.md`.
4. **Never manually register Telegram webhooks.** n8n manages secret tokens. Manual `setWebhook` breaks callback auth. See `references/upgrade-gotchas.md`.
5. **Always restart after CLI import.** `systemctl restart n8n` after any CLI import/update. MCP/REST API updates don't need restart.
6. **Include workflow ID in import JSON.** Without it, each import creates a duplicate.

## Workflow: Deploy/Update a Workflow

**Preferred: mcp2cli** (`mcp2cli n8n update_workflow`, `mcp2cli n8n activate_workflow`)

**CLI helper:**
1. `n8n-wf export "workflow name"` -- pull current version
2. Edit JSON locally
3. `n8n-wf import workflow.json --activate` -- push + restart
4. `n8n-wf execs "workflow name"` -- verify execution

**Manual (last resort):**
1. Prepare workflow JSON locally (include `id` field if updating existing)
2. SCP to n8n container: `scp workflow.json root@<N8N_IP>:/tmp/`
3. Import via CLI (see `references/cli-deployment.md` for exact command)
4. Restart: `ssh root@<N8N_IP> 'systemctl restart n8n'`
5. Verify in UI: open workflow, check active + published status

## Workflow: Add a Credential

1. Browser to https://n8n.your-domain.example -> Credentials -> Add Credential
2. Select type, fill fields
3. For OAuth: ensure redirect URL matches exactly (no trailing slash)
4. Save, then update any workflow nodes to reference the new credential
5. Store credential details in vaultwarden for backup

## Workflow: Debug a Failing Workflow

1. Check recent executions: `mcp2cli n8n list_executions --params '{"workflowId":"ID"}'` or `n8n-wf execs "name"`
2. Check logs: `ssh root@<N8N_IP> 'tail -50 /var/log/n8n/n8n.log'`
3. Check service: `ssh root@<N8N_IP> 'systemctl status n8n'`
4. Check published status: SQL query in `references/db-operations.md`
5. If webhook issue: check Cloudflare tunnel + Caddy config on the Caddy container

## References

Load these on demand (spawn explore agent to summarize):

- **references/credentials.md** -- All credential IDs, vaultwarden entries, OAuth lifecycle
- **references/workflows.md** -- Full workflow inventory with IDs, webhooks, triggers
- **references/db-operations.md** -- PostgreSQL access, SSH quoting, DB surgery patterns
- **references/upgrade-gotchas.md** -- n8n 2.x breaking changes, draft/publish, Telegram secrets
- **references/notification-patterns.md** -- Telegram/Discord node templates, webhook URLs
- **references/cli-deployment.md** -- Import/export commands, env var requirements
- **references/content-sourcing.md** -- RSS feeds, Medium authors, YouTube via yt-dlp, FlareSolverr
- **references/wiring-patterns.md** -- Chaining workflows via webhooks (1 node per workflow, not monoliths)

## Gotchas

1. **Debug mode is paid only** -- Can't use in community edition
2. **Code node can't access credentials** -- Build URLs in Code node, pass as `$json` to HTTP Request
3. **IF node has two outputs** -- Index 0 = true, 1 = false. Both need connections or flow hangs
4. **Webhook responseMode: "responseNode"** -- Requires Respond to Webhook node or webhook hangs
5. **Optional chaining (?.) works in Code nodes** -- But test carefully
6. **Cloudflare Access blocks webhooks** -- CF Access was removed for n8n. Don't re-add it.
7. **JWT key quoting in shell** -- The API key is a long JWT. Use a script file or heredoc, not inline variable assignment with `&&`.
8. **CLI import leaves activeVersionId NULL** -- After `n8n import:workflow`, `workflow_entity.activeVersionId` is often NULL. Must query latest from `workflow_history` table before publishing. `n8n-wf` handles this automatically.
9. **PostgreSQL double-quoted columns over SSH** -- Use heredoc piped to psql stdin (`<<'ENDSQL'`). Never `-c 'SQL'` with double-quoted identifiers.
10. **Never use the built-in LinkedIn node** -- `n8n-nodes-base.linkedIn` returns 403. Use HTTP Request nodes with `predefinedCredentialType: linkedInOAuth2Api` instead. See `references/credentials.md` for the exact pattern.
11. **n8n 2.x manual Execute uses cached version** -- "Execute workflow" button in the editor may not use the latest published version. After changes, restart n8n (`systemctl restart n8n`) before testing. Or use webhooks for testing.
12. **Post Now webhook** -- `POST /webhook/post-now` bypasses the schedule and posts the next approved post immediately. Use for testing or manual posting.
13. **Clean up test artifacts from approved queue** -- Test posts left in `/data/approved-posts/` WILL get posted to LinkedIn by the schedule or Post Now webhook. Always delete test files after testing.
14. **Telegram appendAttribution** -- Always set `appendAttribution: false` on every Telegram node. Defaults to `true`, which appends "Sent using n8n" footer. Every workflow has been audited and fixed (2026-02-28).
15. **DB user is `n8nops`** -- NOT `n8nuser`. Credential in vaultwarden: "PostgreSQL n8n-ops". Shell-safe password. Stop second-guessing this.
16. **Never grep env files for credentials** -- Don't `cat` or `grep` `/home/n8n/.n8n/env` to find passwords. Use `mcp__vaultwarden-secrets__get_secret("PostgreSQL n8n-ops")`. Grepping env files leaks passwords into terminal output.
17. **Credential lookup order** -- vaultwarden MCP first (`get_secret` or `get_service`), never env files, never guessing. If vaultwarden doesn't have it, ask the user.
18. **claudePy is local-only** -- `claudePy` only exists on the Mac. For Python on the n8n container or any remote host, use `python3 -c` via SSH. Don't try to run `claudePy` over SSH.
19. **Post Now webhook fires without approval** -- The `/webhook/post-now` endpoint reads directly from `/data/approved-posts/` and posts the first available item. No Telegram approval, no schedule check. Any file in that directory is fair game. This is how a test post went live on LinkedIn (2026-02-28).
20. **Hardcoded API keys in workflow exports** -- n8n Community Edition can't use `$env`. Code nodes hardcode the LiteLLM key (`api_key` variable). When exporting workflows to git, the key is visible in JSON. Retrieve via: `mcp__vaultwarden-secrets__get_credential(query="LiteLLM", field="login.password")`. See `references/credentials.md` for all secret retrieval commands.
21. **THREE tables store workflow nodes** -- `workflow_entity` (draft), `workflow_history` (versions), `workflow_published_version` (pointer to live version). n8n runs the PUBLISHED version. Updating `workflow_entity` alone does NOTHING. Must update all three + restart. See DB surgery deploy sequence below.
22. **Code node `https` module times out** -- The task runner kills async Promise-based HTTP calls after 60s. Use `execSync('curl -sS ...')` from `child_process` instead. This is synchronous and completes reliably.
23. **Google SA credential type is for Google nodes only** -- "Google Service Account API" credential works with Sheets, Drive, Calendar nodes. Does NOT work with generic HTTP Request nodes for Vertex AI/Imagen. Use Code node JWT auth instead (crypto.createSign + curl token exchange).
24. **PostgreSQL node v2.5 parameterized queries broken** -- `$1` with `queryParams` field doesn't work. Use expression interpolation in the query string: `WHERE id = {{ $json.body.post_id }}`. Prefix query with `=` for expression mode.
25. **File permissions on /data/v2-images/** -- Must be owned by n8n:n8n. Scripts running as root create files n8n can't overwrite. Run `chown -R n8n:n8n /data/v2-images/` after any manual file creation.
26. **All workflow timezones must be America/New_York** -- Instance default `GENERIC_TIMEZONE=America/New_York`. Check all workflow JSON settings blocks. Never use UTC.
27. **$env is PAID ONLY** -- `$env.VAR` in expressions does NOT work on Community Edition. `N8N_AVAILABLE_ENV_VARS` env setting is ignored. Never reference env vars in workflow expressions. Hardcode values or pass through `$json` from Code nodes.

## DB Surgery Deploy (when CLI import doesn't stick)

```sql
-- Get nodes/connections JSON from your local workflow file
-- Escape single quotes: replace ' with ''

-- 1. Update draft
UPDATE workflow_entity SET nodes = '<json>', connections = '<json>'
WHERE id = '<workflow_id>';

-- 2. Update ALL history versions (n8n may run any of these)
UPDATE workflow_history SET nodes = '<json>', connections = '<json>'
WHERE "workflowId" = '<workflow_id>';

-- 3. Delete published pointer so n8n re-reads fresh
DELETE FROM workflow_published_version
WHERE "workflowId" = '<workflow_id>';
```

Then: `ssh root@<N8N_IP> "systemctl restart n8n"` and wait 15s.

Generate the SQL with:
```python
claudePy -c "
import json
with open('workflows/my-workflow.json') as f:
    wf = json.load(f)
nodes = json.dumps(wf['nodes']).replace(\"'\", \"''\")
conns = json.dumps(wf['connections']).replace(\"'\", \"''\")
sql = f\"UPDATE workflow_entity SET nodes='{nodes}', connections='{conns}' WHERE id='ID';\"
# ... etc
"
```

## Vertex AI / Imagen Auth Pattern (for Code nodes)

Working pattern for Google Vertex AI auth from n8n Code node:

```javascript
// 1. Read SA key + build JWT (crypto works in Code nodes)
const crypto = require('crypto');
const sa = JSON.parse(require('fs').readFileSync('/home/n8n/.n8n/google-sa.json', 'utf8'));
const header = Buffer.from(JSON.stringify({alg:'RS256',typ:'JWT'})).toString('base64url');
const now = Math.floor(Date.now()/1000);
const claims = Buffer.from(JSON.stringify({
  iss: sa.client_email,
  scope: 'https://www.googleapis.com/auth/cloud-platform',
  aud: sa.token_uri, iat: now, exp: now+3600
})).toString('base64url');
const sign = crypto.createSign('RSA-SHA256');
sign.update(header+'.'+claims);
const signature = sign.sign(sa.private_key, 'base64url');
const jwt = header+'.'+claims+'.'+signature;

// 2. Exchange for token via curl (NOT https module -- it times out)
const { execSync } = require('child_process');
const tokenResp = execSync(
  'curl -sS -X POST ' + JSON.stringify(sa.token_uri) + ' ' +
  '-H "Content-Type: application/x-www-form-urlencoded" ' +
  '-d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt + '"',
  { encoding: 'utf8', timeout: 15000 }
);
const token = JSON.parse(tokenResp).access_token;

// 3. Pass token to downstream HTTP Request node
return [{ json: { access_token: token, ...otherData } }];
```

Then HTTP Request node uses: `Authorization: Bearer {{ $json.access_token }}`
