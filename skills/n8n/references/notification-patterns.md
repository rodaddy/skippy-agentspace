<!-- Extracted from SKILL.md -- load on demand -->
# n8n Notification Patterns

## Telegram Node (ALWAYS Use This for Telegram)

Never use HTTP Request nodes for Telegram. Always use the native Telegram node.

```json
{
  "parameters": {
    "resource": "message",
    "operation": "sendMessage",
    "chatId": "5715313778",
    "text": "={{ $json.telegramMsg }}",
    "additionalFields": {
      "parse_mode": "HTML"
    }
  },
  "name": "Send Telegram",
  "type": "n8n-nodes-base.telegram",
  "typeVersion": 1.2,
  "credentials": {
    "telegramApi": {
      "id": "<CREDENTIAL_NAME>",
      "name": "LinkedIn Pipeline Telegram Bot"
    }
  }
}
```

### Telegram Inline Buttons (for approval flows)

```json
{
  "parameters": {
    "resource": "message",
    "operation": "sendMessage",
    "chatId": "5715313778",
    "text": "={{ $json.previewText }}",
    "additionalFields": {
      "parse_mode": "HTML",
      "replyMarkup": "inlineKeyboard",
      "inlineKeyboard": {
        "rows": [
          {
            "row": [
              { "text": "Approve", "callbackData": "approve_{{ $json.postId }}" },
              { "text": "Reject", "callbackData": "reject_{{ $json.postId }}" }
            ]
          },
          {
            "row": [
              { "text": "Edit", "callbackData": "edit_{{ $json.postId }}" },
              { "text": "Regenerate", "callbackData": "regen_{{ $json.postId }}" }
            ]
          }
        ]
      }
    }
  }
}
```

## Discord Webhook Pattern

Discord uses HTTP Request nodes with hardcoded webhook URLs (not credentials).

```json
{
  "parameters": {
    "method": "POST",
    "url": "={{ 'WEBHOOK_URL_HERE' }}",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ JSON.stringify({ embeds: [{ title: $json.discordTitle, description: $json.discordDesc, color: $json.discordColor, timestamp: $json.timestamp, footer: { text: 'Footer Text' } }] }) }}",
    "options": {}
  },
  "name": "Send Discord",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2
}
```

### Discord Webhook URLs

Stored in `/home/n8n/.n8n/env` on the n8n container. Cannot access via `$env` -- must hardcode in nodes.

| Channel | Env Var |
|---------|---------|
| Digest | `DISCORD_DIGEST_WEBHOOK` |
| Needs Review | `DISCORD_NEEDS_REVIEW_WEBHOOK` |
| Skippy Inbox | `DISCORD_SKIPPY_INBOX_WEBHOOK` |

To get actual URLs: `ssh root@<N8N_IP> 'grep DISCORD /home/n8n/.n8n/env'`

## Standard Webhook Flow Pattern

```
Webhook Trigger (POST)
  -> Code Node (parse/format, ALL data transformation here)
  -> IF Node (should act?)
     -> True: Action nodes -> Respond to Webhook
     -> False: Respond to Webhook
```

**Key principle:** Code node does ALL transformation. Downstream nodes only reference simple `$json.fieldName` values. No complex expressions in HTTP Request nodes.

## Code Node Data Passing

Since `$env` doesn't work, pass everything through `$json`:

```javascript
// In Code node -- prepare all data for downstream nodes
const items = $input.all();
return items.map(item => ({
  json: {
    telegramMsg: `<b>Alert:</b> ${item.json.title}\n${item.json.details}`,
    discordTitle: item.json.title,
    discordDesc: item.json.details,
    discordColor: 16711680, // red
    timestamp: new Date().toISOString(),
    shouldNotify: item.json.severity === 'critical'
  }
}));
```
