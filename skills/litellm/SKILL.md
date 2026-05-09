---
name: litellm
description: LiteLLM proxy reference -- available models, endpoints, API usage, and MCP gateway patterns. Quick reference for making API calls through the gateway.
triggers:
  - /litellm
  - /litellm models
  - litellm models
  - what models are available
  - how to use litellm
  - list models
---

# LiteLLM - Gateway Reference

Quick reference for the LiteLLM proxy -- endpoints, available models, and usage patterns.

## Live Model List

To get the current list of models from the live endpoint, run:

```bash
~/.config/pai/Skills/litellm/list-models.sh
```

Use `--raw` for just the model IDs (pipe-friendly):

```bash
~/.config/pai/Skills/litellm/list-models.sh --raw
```

**When the user asks "what models are available" or "list models", run the script above instead of showing the static table.**

## Endpoint

| Purpose | URL |
|---------|-----|
| **Health check** | `http://<LITELLM_IP>:4000/health` |
| **OpenAI-compatible API** | `http://<LITELLM_IP>:4000/v1` |
| **Admin UI** | `http://<LITELLM_IP>:4000/ui/` |
| **MCP REST Gateway** | `http://<LITELLM_IP>:4000/mcp-rest/tools/{list,call}` |
| **Prometheus metrics** | `http://<LITELLM_IP>:4000/metrics` |

**Container:** LXC 204 (`second-brain-litellm`) on proxmox02
**SSH:** `ssh root@<LITELLM_IP>`
**Config (live):** `/home/litellm/litellm-config.yaml`
**Config (repo):** `infrastructure/services/litellm/config.yaml`

## Available Models

All models route through Vertex AI with automatic fallbacks.

### Claude Models

| Alias | Model | Fallback | Use For |
|-------|-------|----------|---------|
| `sonnet` / `main` | claude-sonnet-4-6 | gemini-3-pro | Default workhorse -- most tasks |
| `opus` / `quality` | claude-opus-4-6 | gemini-3-pro | Complex reasoning, high-stakes work |
| `haiku` / `fast` | claude-haiku-4-5@20251001 | gemini-3-flash | Quick, cheap operations |
| `opus4.6[1M]` | claude-opus-4-6 | gemini-3-pro | Opus with 1M context window |
| `sonnet4.6[1M]` | claude-sonnet-4-6 | gemini-3-pro | Sonnet with 1M context window |

### Gemini Models

| Alias | Model | Use For |
|-------|-------|---------|
| `pro` / `fallback` | gemini-3-pro-preview | Claude fallback target |
| `flash` | gemini-3-flash-preview | Fast Gemini operations |
| `gemini-3.1-pro` | gemini-3.1-pro-preview | Latest Gemini 3.x |
| `image` | gemini-3-pro-image-preview | Image generation |

### Reviewer/Antagonist Models (No Semantic Cache)

| Alias | Model | Use For |
|-------|-------|---------|
| `sonnet-nocache` | claude-sonnet-4-6 | Default reviewer -- no cache poisoning |
| `opus-nocache` | claude-opus-4-6 | Complex architectural reviews |
| `gemini-3.1-pro-nocache` | gemini-3.1-pro-preview | Cross-vendor reviewer, adjustable think tiers |
| `gemini-deep-think-nocache` | gemini-3-deep-think | Ultra-complex reasoning reviews |

### Utility Models

| Alias | Model | Use For |
|-------|-------|---------|
| `embeddings` | text-embedding-004 | Vector embeddings |

## Usage Examples

### Chat Completion (curl)

```bash
curl -s http://<LITELLM_IP>:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sonnet",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 1024
  }' | jq '.choices[0].message.content'
```

### With OpenAI SDK (TypeScript/Bun)

```typescript
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://<LITELLM_IP>:4000/v1",
  apiKey: process.env.LITELLM_API_KEY,
});

const response = await client.chat.completions.create({
  model: "sonnet",          // Use any alias from the table above
  messages: [{ role: "user", content: "Hello" }],
  max_tokens: 1024,
});

console.log(response.choices[0].message.content);
```

### With OpenAI SDK (Python)

```python
from openai import OpenAI
import os

client = OpenAI(
    base_url="http://<LITELLM_IP>:4000/v1",
    api_key=os.environ["LITELLM_API_KEY"],
)

response = client.chat.completions.create(
    model="sonnet",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=1024,
)

print(response.choices[0].message.content)
```

### Image Generation (Gemini)

```bash
curl -s http://<LITELLM_IP>:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "image",
    "messages": [{"role": "user", "content": "Generate an image of a sunset over mountains"}],
    "max_tokens": 4096
  }' | jq '.choices[0].message.content'
```

### Embeddings

```bash
curl -s http://<LITELLM_IP>:4000/v1/embeddings \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "embeddings",
    "input": "Text to embed"
  }' | jq '.data[0].embedding[:5]'
```

### MCP REST Gateway (Tool Calling)

List available tools on an MCP server:
```bash
curl -s http://<LITELLM_IP>:4000/mcp-rest/tools/list \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"server_id": "<server-id>"}' | jq '.[].name'
```

Call an MCP tool:
```bash
curl -s http://<LITELLM_IP>:4000/mcp-rest/tools/call \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<tool-name>",
    "arguments": {},
    "server_id": "<server-id>"
  }' | jq '.'
```

## API Key

Use `$LITELLM_API_KEY` from the environment. It's already set in `~/.zshrc` and available in all shells.

For new projects, reference the env var -- never hardcode keys:

```bash
# .env (gitignored)
LITELLM_API_KEY=${LITELLM_API_KEY}
```

Or just read it directly from the environment in code (preferred).

## Router & Reliability

- **Strategy:** `usage-based-routing-v2` -- distributes load across model deployments
- **Retries:** 2 retries per request, 5s delay between
- **Fallback:** 3 consecutive failures triggers automatic fallback (Claude -> Gemini)
- **Caching:** Semantic cache via Redis + text-embedding-004 (1hr TTL, 0.8 similarity)
- **Logging:** All requests logged to PostgreSQL (<DB_IP>:5432/litellm)

## Grafana Dashboards

| Dashboard | UID | Purpose |
|-----------|-----|---------|
| LiteLLM Overview | litellm-overview | Request rates, latency, error rates, model usage |
| LiteLLM Users & Caching | litellm-users-caching | Per-user spend, Anthropic prompt cache savings, cache ROI |

**URL pattern:** `http://<YOUR_IP>:3000/d/<uid>`

### Prompt Cache Data (Gotcha)

Anthropic prompt cache tokens are in the JSONB `metadata` column, NOT the `cache_hit` column:
- `cache_hit` -- tracks LiteLLM's disabled semantic cache (always false)
- `metadata->'additional_usage_values'->>'cache_read_input_tokens'` -- actual Anthropic prompt cache reads
- `metadata->'additional_usage_values'->>'cache_creation_input_tokens'` -- cache creation tokens

### Dashboard Build & Deploy

```bash
cd ~/Development/infrastructure/observability
make build                                    # compile all jsonnet to JSON
make deploy-one DASH=litellm-users-caching    # deploy single dashboard (needs GRAFANA_PASS)
```

Grafana admin password in vaultwarden is stale. Use SA token instead:
```bash
# Get token: get_credential(query: "Grafana SA")
curl -sf -H "Authorization: Bearer $TOKEN" -X POST -H "Content-Type: application/json" \
  "http://<YOUR_IP>:3000/api/dashboards/db" \
  -d "$(jq -n --argjson dashboard "$(cat dashboards/DASH.json)" '{dashboard: $dashboard, overwrite: true}')"
```

## New App/Project Setup

When starting a new app or project that needs AI, follow this checklist:

### 1. Environment Variables

`$LITELLM_API_KEY` is already in the shell environment. No `.env` needed unless the framework requires one:

```bash
# .env (only if framework needs it, gitignored)
LITELLM_API_BASE=http://<LITELLM_IP>:4000/v1
LITELLM_API_KEY=${LITELLM_API_KEY}
```

### 2. Install the SDK

**TypeScript (Bun):**
```bash
bun add openai
```

**Python (uv):**
```bash
uv add openai
```

### 3. Create an AI Client Module

**TypeScript -- `src/ai.ts`:**
```typescript
import OpenAI from "openai";

export const ai = new OpenAI({
  baseURL: process.env.LITELLM_API_BASE || "http://<LITELLM_IP>:4000/v1",
  apiKey: process.env.LITELLM_API_KEY,
});

// Quick helper for chat completions
export async function ask(prompt: string, model = "sonnet") {
  const res = await ai.chat.completions.create({
    model,
    messages: [{ role: "user", content: prompt }],
    max_tokens: 4096,
  });
  return res.choices[0].message.content;
}
```

**Python -- `ai.py`:**
```python
import os
from openai import OpenAI

ai = OpenAI(
    base_url=os.environ.get("LITELLM_API_BASE", "http://<LITELLM_IP>:4000/v1"),
    api_key=os.environ["LITELLM_API_KEY"],
)

def ask(prompt: str, model: str = "sonnet") -> str:
    res = ai.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=4096,
    )
    return res.choices[0].message.content
```

### 4. Pick Your Model

| Need | Model | Why |
|------|-------|-----|
| General tasks | `sonnet` | Best quality/speed/cost balance |
| Complex reasoning | `opus` | Most capable, higher cost |
| Quick/cheap ops | `haiku` | Fast, low cost |
| Long documents | `sonnet4.6[1M]` or `opus4.6[1M]` | 1M context window |
| Image generation | `image` | Gemini 3 image model |
| Embeddings | `embeddings` | text-embedding-004 |
| Claude is down | `pro` or `flash` | Gemini fallback |

### 5. That's It

`$LITELLM_API_KEY` is already in the environment. Just use it.

## Gotchas

1. **No self-surgery** -- Don't modify LiteLLM config from a session that routes through it. Switch to direct Vertex first.
2. **Region matters** -- Claude uses `vertex_location: global`, Gemini uses `us-central1`. Wrong region = silent failures.
3. **1M context models** -- The `[1M]` variants override LiteLLM's default 200K cap. Use when you need long context.
4. **Config sync** -- Live config at `/home/litellm/litellm-config.yaml` must match repo copy. After editing, restart: `ssh root@<LITELLM_IP> "systemctl restart litellm"`
5. **Disk watch** -- LXC 204 at ~91% disk (21G/25G). Monitor pip caches.

## Workflow

When this skill is invoked:

### Step 1: Identify What User Needs
- **List models?** Run `~/.config/pai/Skills/litellm/list-models.sh`
- **New project setup?** Walk through the "New App/Project Setup" section.
- **Model selection guidance?** Show the model picker table.
- **Code example?** Show the relevant SDK snippet.
- **Debugging?** Check health endpoint first, then logs.
- **Admin task?** Point to the UI or key management API.

### Step 2: Provide Reference
Show the relevant section from above. Don't dump everything -- give them what they asked for.

### Step 3: Verify (if making changes)
If modifying config or keys, always verify with a health check or test call after.
