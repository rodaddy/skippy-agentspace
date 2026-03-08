---
name: browser
description: Browser automation via agent-browser MCP and browse CLI. Navigate, interact, extract data from web UIs.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: utility
---

# Browser Automation

Two interfaces, pick the right one:

| Interface | When to Use |
|-----------|-------------|
| **`browse` CLI** | Cloudflare-protected sites, paywalled content, anything needing real Chrome + login cookies |
| **MCP tools** | Internal dashboards, simple pages, no Cloudflare |

The `browse` CLI wrapper uses real Chrome with stealth flags and persistent login profiles.

## Delegate to Agents (CRITICAL)

**Never read full page content in main context.** Spawn a sonnet agent to do browser work and return a summary.

## `browse` CLI Reference

```bash
browse --session <name> open <url>
browse --session <name> snapshot
browse --session <name> find text "<text>" click
browse --session <name> eval '<javascript>'
browse --session <name> get text "<selector>"
browse --session <name> close
```

Session names: `<context>-<target>` (e.g., `read-medium`, `check-dashboard`).

## MCP Tool Reference

| Tool | Purpose | Key Args |
|------|---------|----------|
| `browser_navigate` | Open URL, back, forward, reload, close | `action`, `url` |
| `browser_snapshot` | Get accessibility tree with refs | (none) |
| `browser_interact` | Click, fill, type, press, select, hover, scroll | `action`, `selector`, `value` |
| `browser_get` | Extract text, html, value, attr, title, url, count | `what`, `selector` |
| `browser_find` | Semantic search by role, text, label, placeholder, testid | `by`, `value` |
| `browser_screenshot` | Capture PNG or PDF | `format`, `path` |
| `browser_wait` | Wait for selector, time, url pattern, or text | `for`, `value` |
| `browser_eval` | Run JS in browser page context | `script` |

## Login Pattern

```
1. navigate(open, url, session)
2. snapshot()
3. interact(fill, "input[type='email']", email)
4. interact(fill, "input[type='password']", password)
5. interact(click, "button:has-text('Sign in')")
6. snapshot()   # verify logged in
```

**Credentials:** Always use your credential manager (e.g., vaultwarden MCP). Never hardcode.

## Wait Strategy (DO NOT BLOCK)

`browser_wait` has NO timeout -- it blocks until condition is met or MCP times out.

- **`wait(time)`** -- 2000ms max for short settling
- **Prefer snapshot polling** -- call `snapshot()` twice instead of waiting

## Known Gotchas

- **Refs are ephemeral** -- re-snapshot after any navigation/DOM change
- **Strict mode** -- selectors matching multiple elements fail, use `:has-text()` or more specific CSS
- **`browser_eval` runs in browser context** -- `document.querySelector` works, `page.getByRole` does not
- **Profile lock** -- only one browser instance per profile, close/unlock before reuse
- **Always close sessions** -- every session MUST be closed, no zombie Chrome processes

## When NOT to Use Browser

- **API available** -- prefer curl/fetch over browser automation
- **CLI available** -- prefer CLI tools over browser UI
- **Simple static content** -- use WebFetch (unless Cloudflare-protected)

## References

- `references/medium-pattern.md` -- Medium article and list extraction patterns
- `references/profile-management.md` -- Chrome profile setup for persistent logins

> **PAI enhancements available:** In PAI installations, this skill includes dashboard credential mappings and specific service URLs.
