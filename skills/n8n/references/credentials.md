<!-- Extracted from SKILL.md -- load on demand -->
# n8n Credentials Reference

## Credentials in n8n Credential Store

| Name | Type | n8n ID | Used For | Vaultwarden Entry |
|------|------|--------|----------|-------------------|
| Skippy Bot TG API | Telegram API | `<CREDENTIAL_ID>` | General Telegram notifications | `telegram-skippy-bot` |
| LinkedIn Pipeline Telegram Bot | Telegram API | `<CREDENTIAL_NAME>` | LinkedIn + infra notifications | `Telegram Bot Token` |
| LiteLLM API | Header Auth | `<CREDENTIAL_ID>` | AI proxy calls | `LiteLLM` (login.password) |
| LinkedIn account | LinkedIn OAuth2 API | `<CREDENTIAL_ID>` | LinkedIn posting | `linkedin-developer-app` |
| Postgres account | Postgres | -- | Database access | `PostgreSQL n8n` |
| Discord Bot Trigger account | Discord Bot Trigger API | -- | Discord bot trigger | -- |
| Discord Skippy Bot | Discord Bot API | -- | Discord bot | `Discord Bot Token` |

## Secret Retrieval Commands

Quick-reference for the exact vaultwarden calls when you need credentials:

```
# LiteLLM API key (used in HTTP Request nodes for AI calls)
mcp__vaultwarden-secrets__get_credential(query="LiteLLM", field="login.password")

# n8n API key (JWT for REST API calls)
mcp__vaultwarden-secrets__get_credential(query="n8n API Key - claude", field="login.password")

# Pipeline DB password (PostgreSQL container)
mcp__vaultwarden-secrets__get_credential(query="PostgreSQL n8n-ops", field="login.password")

# Discord bot token
mcp__vaultwarden-secrets__get_credential(query="Discord Bot Token", field="login.password")

# LinkedIn OAuth (client secret)
mcp__vaultwarden-secrets__get_credential(query="linkedin-developer-app", field="login.password")

# Telegram bot token
mcp__vaultwarden-secrets__get_credential(query="telegram-skippy-bot", field="login.password")
```

## Telegram Credentials

**Chat ID:** `<TELEGRAM_CHAT_ID>` (your personal Telegram)

Two bot credentials exist:
- **Skippy Bot TG API** -- original bot, used for general notifications
- **LinkedIn Pipeline Telegram Bot** -- created for LinkedIn pipeline, also handles infra alerts

Both use the same chat ID. The credential name in workflow nodes must match exactly.

## LinkedIn OAuth2

| Field | Value |
|-------|-------|
| n8n Credential Name | LinkedIn account |
| n8n Credential ID | `<CREDENTIAL_ID>` |
| Client ID | `<LINKEDIN_CLIENT_ID>` |
| Company Page | https://www.linkedin.com/company/<LINKEDIN_COMPANY_ID>/ |
| Redirect URL | `https://n8n.your-domain.example/rest/oauth2-credential/callback` |
| App Name | <YOUR_APP_NAME> |
| Vaultwarden | `linkedin-developer-app` |
| Person ID (sub) | `<LINKEDIN_PERSON_ID>` |

### LinkedIn Posting Method (CRITICAL)

**DO NOT use the built-in `n8n-nodes-base.linkedIn` node.** It is unreliable and returns 403 errors.

**USE HTTP Request nodes** with `predefinedCredentialType: linkedInOAuth2Api`. This uses the same OAuth credential but gives direct API control.

**Working pattern (verified in execution 4360):**

1. **Get Person ID** -- HTTP Request GET `https://api.linkedin.com/v2/userinfo`
   - Auth: `predefinedCredentialType` / `linkedInOAuth2Api`
   - Returns `sub` field (person ID: `<LINKEDIN_PERSON_ID>`)

2. **Post to LinkedIn** -- HTTP Request POST `https://api.linkedin.com/v2/ugcPosts`
   - Auth: `predefinedCredentialType` / `linkedInOAuth2Api`
   - Headers: `X-Restli-Protocol-Version: 2.0.0`, `LinkedIn-Version: 202402`
   - Body (JSON.stringify expression):
     ```
     {
       author: "urn:li:person:" + person_id,
       lifecycleState: "PUBLISHED",
       specificContent: {
         "com.linkedin.ugc.ShareContent": {
           shareCommentary: { text: post_text },
           shareMediaCategory: "NONE"
         }
       },
       visibility: {
         "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
       }
     }
     ```
   - Timeout: 30000ms
   - onError: continueErrorOutput

**Post Now webhook:** `POST /webhook/post-now` -- bypasses schedule, posts immediately from approved queue.

### OAuth Token Lifecycle

| Token Type | Lifetime | Action |
|-----------|----------|--------|
| Access token | 60 days | Re-authorize in n8n when alerted |
| Refresh token | 365 days | n8n may handle automatically |

**Token metadata file:** `/data/linkedin-token-meta.json` on the n8n container

After every re-authorization:
1. Go to n8n Credentials -> LinkedIn account -> Reconnect
2. Complete OAuth flow
3. Update `/data/linkedin-token-meta.json` with new `authorized_at` ISO timestamp
4. `expires_at` = authorized_at + 60 days

The **OAuth Token Monitor** workflow (`<WORKFLOW_ID>`) sends Telegram alerts:
- 14 days before expiry: info alert
- 7 days before expiry: daily warning
- Expired: daily critical
- Health check failure: immediate critical

### Troubleshooting OAuth

| Problem | Cause | Fix |
|---------|-------|-----|
| "Redirect URI mismatch" | URL doesn't match exactly | No trailing slash, must be https |
| "Invalid scope" | Share on LinkedIn not approved | Wait for product approval |
| "Access denied" | Wrong LinkedIn account | Log in with app owner account |
| "Not connected" after Allow | SSL/proxy issue | Check n8n logs on the n8n container |

## Environment Variables on the n8n Container

These are in `/home/n8n/.n8n/env` but **cannot be accessed via `$env`** (community edition):

```
TELEGRAM_BOT_TOKEN=<in env file>
TELEGRAM_CHAT_ID=<TELEGRAM_CHAT_ID>
DISCORD_DIGEST_WEBHOOK=<in env file>
DISCORD_NEEDS_REVIEW_WEBHOOK=<in env file>
DISCORD_SKIPPY_INBOX_WEBHOOK=<in env file>
LITELLM_API_KEY=<in env file>
LITELLM_PROXY_URL=<in env file>
```

Whitelisted via `N8N_AVAILABLE_ENV_VARS` but only useful for Code node `process.env` access, NOT `$env` expressions.

## Adding New Credentials

1. Browser to https://n8n.your-domain.example -> Credentials -> Add Credential
2. Select type, fill fields from vaultwarden
3. For OAuth types: redirect URL must be `https://n8n.your-domain.example/rest/oauth2-credential/callback`
4. Save credential, note the ID from the URL bar
5. Update workflow nodes to reference the new credential by name
6. Store details in vaultwarden for backup
7. Update this file with the new entry
