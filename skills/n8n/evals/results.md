# n8n Skill Eval Results

- **Date:** 2026-03-13
- **Score:** 20/20 (100%)
- **Iterations:** 3
- **Model:** Claude Opus 4.6

## Assertion Results

| # | Category | Result | Evidence |
|---|----------|--------|----------|
| 1 | env-vars | PASS | Critical Rule #1 + Gotcha #27: "$env is PAID ONLY" |
| 2 | env-vars | PASS | notification-patterns.md "Code Node Data Passing" shows $json workaround |
| 3 | auth | PASS | API Access table: X-N8N-API-KEY with UI JWT, NOT N8N_API_KEY env var |
| 4 | credentials | PASS | Gotchas #16-17: vaultwarden MCP first, never env files |
| 5 | credentials | PASS | Gotcha #15 + Instance Details DB row: user n8nops, NOT n8nuser |
| 6 | telegram | PASS | Critical Rule #4: "Never manually register Telegram webhooks" |
| 7 | telegram | PASS | Gotcha #14: "Always set appendAttribution: false on every Telegram node" |
| 8 | code-node | PASS | Gotcha #2: "Build URLs in Code node, pass as $json to HTTP Request" |
| 9 | code-node | PASS | Gotcha #22: execSync('curl ...') from child_process, NOT https module |
| 10 | code-node | PASS | upgrade-gotchas.md: NODE_FUNCTION_ALLOW_BUILTIN=child_process,fs |
| 11 | if-node | PASS | Gotcha #3: "Both need connections or flow hangs" |
| 12 | webhook | PASS | Vacuous (test uses Telegram Trigger, no responseMode: responseNode) |
| 13 | publish | PASS | Critical Rule #3: draft/publish model, must publish for webhooks |
| 14 | publish | PASS | Gotcha #21 + DB Surgery section: all 3 tables updated |
| 15 | postgresql | PASS | db-operations.md: heredoc <<'ENDSQL' pattern, never -c |
| 16 | import | PASS | Critical Rule #5: "Always restart after CLI import" |
| 17 | import | PASS | Critical Rule #6: "Include workflow ID in import JSON" |
| 18 | timezone | PASS | Gotcha #26: "All workflow timezones must be America/New_York" |
| 19 | mcp2cli | PASS | Tooling section: CRITICAL mcp2cli warning + all refs updated |
| 20 | service | PASS | Instance Details: Binary + Env file paths both present |

## Changes Per Iteration

### Iteration 1 (18/20)

**Failures:** #19 (mcp2cli), #20 (binary path)

**Fix applied:** Assertion #19 -- replaced all direct `mcp__n8n__*` / `mcp__n8n-mcp__*` references with `mcp2cli n8n` commands across SKILL.md and cli-deployment.md. Added CRITICAL warning block in Tooling section.

Files changed:
- `SKILL.md` -- Tooling section rewritten, Deploy/Update section updated, Debug section updated
- `references/cli-deployment.md` -- Activate/Deactivate section updated

Commit: `eval: fix assertion #19 -- replace direct mcp__n8n__* with mcp2cli n8n`

### Iteration 2 (19/20)

**Failure:** #20 (binary path)

**Fix applied:** Assertion #20 -- added Binary row to Instance Details table: `/opt/n8n/node_modules/.bin/n8n` (NOT `/usr/bin/n8n`)

Files changed:
- `SKILL.md` -- Instance Details table, new Binary row

Commit: `eval: fix assertion #20 -- add binary path to Instance Details table`

### Iteration 3 (20/20)

All assertions pass. No changes needed.

## Fragile Assertions (pass but could be stronger)

These assertions pass but rely on readers finding the information in gotchas/reference files rather than in primary templates:

- **#7 (appendAttribution):** Template in notification-patterns.md does NOT include `appendAttribution: false`. Relies on Gotcha #14 being read. Consider adding it directly to the Telegram node templates.
- **#10 (NODE_FUNCTION_ALLOW_BUILTIN):** SKILL.md Gotcha #22 says to use execSync but doesn't mention the env var requirement. Relies on upgrade-gotchas.md being loaded. Consider adding the env var note to Gotcha #22.
