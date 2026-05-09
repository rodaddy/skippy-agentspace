<!-- Extracted from SKILL.md -- load on demand -->
# n8n 2.x Upgrade Gotchas

Lessons from upgrading n8n 1.123.1 -> 2.8.3 on the n8n container (2026-02-25).
Full postmortem: `Development/.reports/resumeUpdate/n8n-2x-upgrade-postmortem.md`

## Breaking Changes Summary

| Change | Impact | Fix |
|--------|--------|-----|
| `executeCommand` node removed | Workflows using it fail to activate | Replace with Code node + `require('child_process').execSync()` |
| `$env` access denied | All expression-based env refs break | Hardcode values or use Code node `process.env` |
| Code node sandboxed | `require()` blocked | `NODE_FUNCTION_ALLOW_BUILTIN=child_process,fs` in env |
| Draft/publish model | Webhooks don't register on unpublished workflows | Must publish via DB or UI |
| API uses PATCH not PUT | Workflow update API calls fail | Use PATCH method |
| Archive before delete | DELETE returns 400 | Archive first, then delete |
| API key auth broken | N8N_API_KEY returns 401 | Use DB access or browser UI |
| Switch V3 node format | `rules.rules` -> `rules.values` | Rename in workflow JSON |
| Telegram node requires explicit fields | Import fails | Add `resource` + `operation` to every Telegram node |

## Draft/Publish Model (Most Critical)

n8n 2.x has THREE tables for workflow storage:

1. **`workflow_entity`** -- main record (active flag, versionId)
2. **`workflow_history`** -- versioned node snapshots (actual execution source)
3. **`workflow_published_version`** -- maps workflowId -> published version

**Key insight:** n8n executes from `workflow_history`, NOT `workflow_entity.nodes`. Direct DB updates to `workflow_entity.nodes` have ZERO effect on execution.

**Symptoms of unpublished workflows:**
- Log shows "Processed 14 draft workflows, 0 published workflows"
- Webhooks don't register even though workflow shows as "active"

**Fix:** See `db-operations.md` for publish SQL.

## Telegram Webhook Secret Token

n8n 2.x auto-generates a `secret_token` when registering Telegram webhooks via `setWebhook`. Telegram includes this as `X-Telegram-Bot-Api-Secret-Token` header.

**NEVER manually call `setWebhook`.** It breaks the secret handshake.

**If broken:**
1. `curl "https://api.telegram.org/bot<TOKEN>/deleteWebhook?drop_pending_updates=true"`
2. `systemctl restart n8n`
3. n8n re-registers with correct secret on startup
4. Verify: `curl "https://api.telegram.org/bot<TOKEN>/getWebhookInfo" | jq .`

## Cloudflare Access Blocks Webhooks

CF Access application covering `*.your-domain.example` blocked Telegram callbacks with 403 Forbidden.

IP-based bypass does NOT work -- CF Access evaluates at CF edge, sees CF's own IPs, not Telegram's.

**Resolution:** Removed CF Access app for n8n. n8n has its own auth. Don't re-add CF Access.

## Caddy HTTP -> HTTPS Redirect

Caddy auto-redirects HTTP to HTTPS. Cloudflare tunnel sends to `http://localhost:80`.

**Fix:** Explicit HTTP block in the Caddy container's Caddyfile:
```
http://n8n.your-domain.example {
    reverse_proxy <N8N_IP>:5678
}
```

## Switch V3 Node Format Change

n8n 2.x Switch V3 expects `parameters.rules.values` not `parameters.rules.rules`.

**Fix:** In workflow JSON, rename `"rules": { "rules": [...] }` to `"rules": { "values": [...] }`.

## Telegram Node Requires Explicit Fields

n8n 2.x Telegram node (typeVersion 1.2) requires:
```json
{
  "resource": "message",
  "operation": "sendMessage"
}
```
Workflows from 1.x may omit these. Add them before importing.

**Do NOT use skeleton import + API PATCH.** PATCHing via REST API blanks the n8n canvas.

## npm Install -- @aws-sdk/core

n8n's dependency tree references unpublished versions. Fix with wrapper package.json overrides:
```json
{
  "overrides": { "@aws-sdk/core": "3.973.13" }
}
```

## node-helpers.js -- Don't Edit

Never use `sed` on minified JS files in n8n's node_modules. A bad sed on `node-helpers.js` caused a crash loop. Use targeted string replacement (Python) if you must edit.

## Cloudflare Tunnel Config

The Caddy container's cloudflared uses `--token` mode. The local `config.yml` is IGNORED. All tunnel config is in the Cloudflare Zero Trust dashboard.

Verify: `systemctl cat cloudflared | grep ExecStart` -- look for `--token` flag.
