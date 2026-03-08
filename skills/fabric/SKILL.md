---
name: fabric
description: Process content through Fabric AI patterns (228+ available). Handles YouTube videos, URLs, and text input.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
  category: utility
---

# Fabric - AI Content Processing

Process content through Fabric's 228+ AI patterns. Handles YouTube videos, URLs, and text.

## When to Activate

- User says `/fabric`, "use fabric", "run fabric on..."
- User wants to process a YouTube video for insights
- User asks to extract wisdom, summarize, analyze content via fabric patterns
- User provides a YouTube URL and wants content extracted

## Core Workflow

### Step 1: Determine Input Type

| Input | Method |
|-------|--------|
| YouTube URL | Use `yt` shell function or `fabric -y "URL" --transcript` |
| Web URL | Use `fabric -u "URL"` |
| Text/file | Pipe content: `cat file \| fabric -p pattern` |
| Stdin | User provides text, pipe it to fabric |

### Step 2: Select Pattern

If user specifies a pattern (`-p pattern_name`), use it directly.

If user describes intent, auto-map:

| Intent | Pattern |
|--------|---------|
| "extract wisdom/insights" | `extract_wisdom` |
| "summarize" | `summarize` or `create_5_sentence_summary` |
| "analyze code" | `analyze_code` |
| "main ideas" | `extract_main_idea` |
| "improve writing" | `improve_writing` |
| "threat model" | `create_threat_model` |
| "rate/review" | `rate_content` |
| "recommendations" | `extract_recommendations` |

### Step 3: Execute

**Use your configured AI vendor flag** (e.g., `--vendor LiteLLM` if routing through a proxy).

```bash
# YouTube video
yt "https://youtu.be/VIDEO_ID" | fabric -p extract_wisdom --vendor <your-vendor>

# YouTube with timestamps
yt -t "https://youtu.be/VIDEO_ID" | fabric -p extract_wisdom --vendor <your-vendor>

# Web URL
fabric -u "https://example.com/article" -p summarize --vendor <your-vendor>

# File input
cat document.txt | fabric -p extract_wisdom --vendor <your-vendor>

# Specify model (optional)
yt "URL" | fabric -p extract_wisdom -m sonnet --vendor <your-vendor>
```

### Step 4: Handle Output

- Display results to user
- If user asked to update a project, apply relevant findings to project files
- Save raw fabric output if substantial

## Configuration

**Config file:** `~/.config/fabric/.env`
**Key fields:** `DEFAULT_VENDOR`, `DEFAULT_MODEL`, API keys for your vendor

### If Auth Fails (401)

1. Get current API key from your credential store
2. Update `~/.config/fabric/.env` with the correct key
3. Update shell env vars if applicable
4. Verify: `yt "any-url" | fabric -p summarize --vendor <your-vendor>`

## Common Patterns

### YouTube Video Analysis
```bash
yt "https://youtu.be/VIDEO_ID" | fabric -p extract_wisdom --vendor <your-vendor>
```

### Summarize Article
```bash
fabric -u "https://example.com/article" -p summarize --vendor <your-vendor>
```

### List All Available Patterns
```bash
fabric --listpatterns
```

## Key Principles

1. **Use your configured vendor** -- always pass `--vendor <your-vendor>`. Don't scatter direct API calls.
2. **yt function handles YouTube** -- wraps `fabric -y` with transcript extraction
3. **Pipe-friendly** -- fabric reads stdin, chain with any text source
4. **Pattern names are exact** -- use `fabric --listpatterns` if unsure
5. **Vendor probe warnings are harmless** -- Fabric probes all vendors on startup, ignore the noise

> **PAI enhancements available:** In PAI installations, this skill includes LiteLLM proxy configuration and specific vendor routing.
