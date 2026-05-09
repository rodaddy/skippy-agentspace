---
name: browser-harness
description: Control Chrome browser via CDP (headless default). Screenshots, clicks, navigation, form fills, JS execution. No Allow dialogs, no GUI needed. USE WHEN browsing, scraping, testing web UIs, reading articles, filling forms, or any browser interaction.
triggers:
  - /browser-harness
  - browse to
  - open browser
  - check the dashboard
  - log into
  - scrape this page
  - read this article
  - read this page
  - medium.com
  - what do you think of this
  - open this url
  - navigate to
  - screenshot this page
---

# browser-harness

Chrome browser control via CDP. Headless by default -- no Allow dialogs, no GUI windows, minimal RAM.

**Repo:** `$DEV_DIR/browser-harness` (where `$DEV_DIR` = contents of `~/.config/pai/.dev-dir`, defaults to `~/Development`)
**Binary:** `~/.local/bin/browser-harness`

## Launch Pattern (Headless -- Default)

Start headless Chrome, get the WS URL, then use browser-harness:

```bash
# 1. Detect Chrome binary (macOS vs Linux)
if [[ "$(uname -s)" == "Darwin" ]]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  CHROME="$(which google-chrome 2>/dev/null || which google-chrome-stable 2>/dev/null || which chromium-browser 2>/dev/null)"
fi

# 2. Kill any existing Chrome debugger (safe -- only kills headless instances)
pkill -f "chrome.*--headless.*--remote-debugging-port" 2>/dev/null || true
rm -f /tmp/bu-default.sock /tmp/bu-default.pid

# 3. Launch headless Chrome (--no-sandbox needed on Linux)
"$CHROME" --headless --remote-debugging-port=9222 --no-sandbox &>/dev/null &
sleep 3

# 4. Get websocket URL and export it
export BU_CDP_WS=$(curl -s http://127.0.0.1:9222/json/version | jq -r .webSocketDebuggerUrl)

# 5. Use browser-harness normally
browser-harness <<'PY'
new_tab("https://example.com")
wait_for_load()
screenshot()
print(page_info())
PY
```

For headed mode (user needs to see the browser), launch without `--headless` and enable
remote debugging via `chrome://inspect/#remote-debugging`.

## Invocation Pattern

```bash
browser-harness <<'PY'
# Python code. All helpers.py functions are pre-imported.
new_tab("https://example.com")
wait_for_load()
screenshot()
print(page_info())
PY
```

## Critical Rules

- **Always launch headless first** -- the launch pattern above must run before any browser-harness call
- **First navigation:** `new_tab(url)`, NOT `goto(url)` -- goto clobbers the active tab
- **After every action:** `screenshot()` to verify it worked
- **Auth walls:** Stop and ask the user. Never type credentials from screenshots.
- **Delegate to agents:** Spawn a sonnet agent for browser work to keep raw content out of main context
- **Clean up when done:** `pkill -f "chrome.*--headless.*--remote-debugging-port"` after task completes

## Key Functions (from helpers.py)

| Function | Purpose |
|----------|---------|
| `new_tab(url)` | Open URL in new tab (preferred for first nav) |
| `goto(url)` | Navigate current tab (only after new_tab) |
| `wait_for_load(timeout=15)` | Wait for page complete |
| `screenshot(path="/tmp/shot.png", full=False)` | Capture viewport or full page |
| `page_info()` | URL, title, viewport, scroll position |
| `click(x, y)` | Click at coordinates (works through iframes/shadow DOM) |
| `type_text(text)` | Type at cursor |
| `press_key(key, modifiers=0)` | Keyboard input (Enter, Tab, arrows, etc.) |
| `scroll(x, y, dy=-300)` | Mouse wheel scroll |
| `js(expression)` | Execute JS, return result |
| `list_tabs()` | All open tabs |
| `switch_tab(target_id)` | Switch to tab by ID |
| `ensure_real_tab()` | Recover from stale/internal tabs |
| `upload_file(selector, path)` | File input via CDP |
| `http_get(url)` | Pure HTTP, no browser (bulk fetches) |
| `cdp(method, **params)` | Raw CDP escape hatch |

## Agent Delegation Pattern

```
Agent(subagent_type: "general-purpose", model: "sonnet", prompt: "
  Use browser-harness to [task]. The tool is a CLI -- pipe Python into it via heredoc.
  Read ~/Development/browser-harness/SKILL.md for full docs.
  Read ~/Development/browser-harness/helpers.py for all available functions.
  Workflow: screenshot -> analyze -> act -> screenshot to verify.
  Return a concise summary of what you found/did.
")
```

## Full Documentation

For domain skills, interaction skills, gotchas, and advanced usage:
- Full SKILL.md: `~/Development/browser-harness/SKILL.md`
- Helpers reference: `~/Development/browser-harness/helpers.py`
- Domain skills: `~/Development/browser-harness/domain-skills/`
- Interaction skills: `~/Development/browser-harness/interaction-skills/`

## Troubleshooting

- `browser-harness --doctor` -- diagnose daemon, browser, updates
- **Stale daemon:** `rm -f /tmp/bu-default.sock /tmp/bu-default.pid` then retry
- **Stale websocket:** restart daemon with `restart_daemon()` inside a harness call
- **Port 9222 in use:** `lsof -i :9222` to find what's bound, kill it, relaunch headless
- **"no close frame":** daemon is stale from a previous Chrome session. Clear socket files and relaunch

## Fallback

If browser-harness fails, `gsd-browser` CLI is still available as a fallback.
