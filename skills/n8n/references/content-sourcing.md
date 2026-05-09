<!-- Extracted from SKILL.md -- load on demand -->
# Content Sourcing Patterns

## RSS Feed Sources (Phase 3 Workflow)

Workflow ID: `<WORKFLOW_ID>`

### Current Feed List

**Trading/Finance:**
- https://www.thetradenews.com/feed/
- https://www.waterstechnology.com/feed/rss
- https://www.marketsmedia.com/feed/

**Crypto:**
- https://www.coindesk.com/arc/outboundfeeds/rss/
- https://www.theblock.co/rss.xml
- https://blockworks.co/feed

**AI/Fintech:**
- https://www.finextra.com/rss/headlines.aspx
- https://techcrunch.com/category/fintech/feed/
- https://decrypt.co/feed

**DevOps/SRE:**
- https://sreweekly.com/feed/
- https://www.datadoghq.com/blog/feed/
- https://www.elastic.co/blog/feed

**Medium Authors (added 2026-02-28):**
- https://medium.com/feed/@richardhightower (Rick Hightower -- enterprise AI)
- https://medium.com/feed/@alirezarezvani (Reza Rezvani -- AI MedTech CTO)
- https://medium.com/feed/@abvijaykumar (A B Vijay Kumar -- IBM Fellow, GenAI)
- https://medium.com/feed/@joe.njenga (Joe Njenga -- AI automation engineer)
- https://medium.com/feed/@shawhin (Shaw Talebi -- data science, PhD)
- https://medium.com/feed/@sdw-online (Stephen David-Williams -- data engineering)

### Adding New Feeds

1. Get RSS URL (test with `curl -s <URL> | head -10` to verify it returns XML)
2. Add URL to the "Feed URLs Config" Set node's `feedUrls` value (newline-separated)
3. Add domain -> category mapping to the "Split Feed URLs" Code node's `categoryMap`
4. Deploy via DB surgery (see `db-operations.md`) -- update both tables + restart

### Category Map

| Category | Description |
|----------|-------------|
| `trading_tech` | Trading systems, market structure, exchange tech |
| `crypto_infra` | Crypto exchanges, blockchain infrastructure |
| `ai_fintech` | AI, fintech, automation, data science |
| `devops_sre` | DevOps, SRE, monitoring, observability |

## Medium RSS Feeds

Medium author RSS format: `https://medium.com/feed/@username`

### Finding Medium Authors to Follow

Use FlareSolverr (<SERVICE_IP>:8191, see HOSTMAP.md for CT ID) to bypass Cloudflare challenge on Medium:

```bash
# Get a user's public following list
curl -s -X POST http://<SERVICE_IP>:8191/v1 \
  -H "Content-Type: application/json" \
  -d '{"cmd": "request.get", "url": "https://medium.com/@USERNAME/following", "maxTimeout": 30000}' \
  | jq -r '.solution.response' > /tmp/medium-following.html

# Extract usernames from the embedded JSON
grep -oE '"username":"[a-zA-Z0-9._-]+"' /tmp/medium-following.html \
  | sed 's/"username":"//;s/"//' | sort -u

# Get name + username pairs
grep -o '"name":"[^"]*","username":"[^"]*"' /tmp/medium-following.html | sort -u
```

### Medium Collection RSS

Medium publication/collection feeds: `https://medium.com/feed/COLLECTION-SLUG`

Example: `https://medium.com/feed/pythonic-af`

## YouTube Content Sourcing

**YouTube killed RSS feeds** as of early 2026. The `videos.xml?channel_id=` endpoint returns 404 for all channels.

### n8n Workflow: YouTube Content Sourcing

- **Workflow ID:** `<WORKFLOW_ID>`
- **Schedule:** 8am + 8pm UTC (offset 1hr from RSS)
- **Binary:** `/usr/local/bin/yt-dlp` v2026.02.21 (standalone ELF binary, not pipx)
- **Dedup file:** `/home/n8n/.n8n/yt-processed.json`
- **Output:** Writes to same queue as RSS (`/home/n8n/.n8n/curated-articles.json`)

Flow: Schedule -> List recent videos (yt-dlp --flat-playlist) -> Filter already-processed -> Download auto-subs -> Clean VTT transcript -> Append to article queue

### yt-dlp Commands

```bash
# List last 5 videos from a channel (titles + IDs)
/usr/local/bin/yt-dlp --flat-playlist --playlist-items 1-5 \
  --print "%(id)s|%(title)s" \
  "https://www.youtube.com/@CHANNEL_HANDLE"

# Download auto-generated subtitles (no video)
/usr/local/bin/yt-dlp --write-auto-sub --sub-lang en --skip-download \
  -o "/tmp/yt-sub-%(id)s" \
  "https://www.youtube.com/watch?v=VIDEO_ID"
# Output: /tmp/yt-sub-VIDEO_ID.en.vtt
```

### yt-dlp Gotchas

- **apt version is ancient** (2023.03.04) -- YouTube breaks it constantly. Use standalone binary.
- **pipx install** puts binary in `/root/.local/bin/` with root-only venv shebang. n8n user can't run it.
- **Standalone binary** from GitHub releases (`yt-dlp_linux`) is the only reliable option for the n8n user.
- **No JS runtime warning** is harmless -- video listing and subtitle download still work.
- **VTT cleanup needed** -- auto-subs have duplicate lines, timestamp tags, position markers. Strip all of these.

### Target YouTube Channels

| Handle | Channel | Focus | Category |
|--------|---------|-------|----------|
| @t3dotgg | Theo - t3.gg | TypeScript, React, web dev opinions | tech |
| @NateBJones | Nate B Jones | Tech career, engineering culture | tech_career |

Channel IDs (for API use):
- @t3dotgg: `UCbRP3c757lWg9M-U7TyEkXA`
- @NateBJones: `UC0C-17n9iuUQPylguM1d-lQ`

### Adding New YouTube Channels

1. Find channel handle (the `@username` from YouTube URL)
2. Test with: `/usr/local/bin/yt-dlp --flat-playlist --playlist-items 1-3 --print "%(id)s|%(title)s" "https://www.youtube.com/@HANDLE"`
3. Add to "YouTube Channel Config" Set node: `@handle|Display Name|category`
4. Deploy via DB surgery or n8n UI

## FlareSolverr Reference

**Location:** FlareSolverr container, <SERVICE_IP>:8191 (see HOSTMAP.md for CT ID)
**Purpose:** Bypass Cloudflare challenges for web scraping
**Docker:** Running in host network mode

### Basic Usage

```bash
curl -s -X POST http://<SERVICE_IP>:8191/v1 \
  -H "Content-Type: application/json" \
  -d '{
    "cmd": "request.get",
    "url": "https://TARGET_URL",
    "maxTimeout": 30000
  }' | jq '.solution'
```

### Response Fields

| Field | Description |
|-------|-------------|
| `.solution.response` | Full HTML body |
| `.solution.cookies` | Array of cookies (including cf_clearance) |
| `.solution.status` | HTTP status code |
| `.solution.url` | Final URL after redirects |

### Gotchas

- FlareSolverr cookies are tied to its User-Agent -- they won't transfer to other browsers
- httpOnly cookies can't be set via JavaScript in another browser session
- For pages requiring login, FlareSolverr only bypasses Cloudflare -- you still need auth cookies
- Medium renders following lists client-side, but the data is embedded in the initial HTML as JSON blobs
