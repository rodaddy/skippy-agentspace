<!-- Extracted from SKILL.md -- load on demand -->

# CLI Command Reference

## Basic Usage

```bash
mcp2cli <command> [options]
mcp2cli <service> <tool> [--params '{}']
```

## Commands

### Service Discovery

```bash
# List all configured services
mcp2cli services

# List tools for a specific service
mcp2cli <service> --help
mcp2cli n8n --help

# Get input schema for a tool
mcp2cli schema <service>.<tool>
mcp2cli schema n8n.n8n_list_workflows

# Search tool names/descriptions across all services
mcp2cli grep "pattern"
mcp2cli grep "workflow"
```

### Tool Invocation

```bash
# Invoke a tool (JSON params)
mcp2cli <service> <tool> --params '{"key": "value"}'
mcp2cli n8n n8n_list_workflows --params '{}'

# Dry run (preview without executing)
mcp2cli <service> <tool> --params '{}' --dry-run

# Output formatting
mcp2cli <service> <tool> --format json    # default
mcp2cli <service> <tool> --format table   # human-readable
mcp2cli <service> <tool> --format yaml
mcp2cli <service> <tool> --format csv
mcp2cli <service> <tool> --format ndjson

# Bypass schema cache
mcp2cli <service> <tool> --fresh
```

### Batch Mode

```bash
# NDJSON on stdin
echo '{"service":"n8n","tool":"n8n_list_workflows","params":{}}' | mcp2cli batch

# Multiple calls
cat <<EOF | mcp2cli batch
{"service":"n8n","tool":"n8n_list_workflows","params":{}}
{"service":"vaultwarden-secrets","tool":"list_secrets","params":{}}
EOF
```

### Cache Management

```bash
mcp2cli cache status    # check cache state
mcp2cli cache clear     # clear all cached schemas
```

### Skill Generation

```bash
# Generate skill files from service schemas
mcp2cli generate-skills <service>
mcp2cli generate-skills n8n
```

### Bootstrap

```bash
# Auto-configure from claude.json MCP config
mcp2cli bootstrap
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MCP2CLI_CONFIG` | Path to services.json | `~/.config/mcp2cli/services.json` |
| `MCP2CLI_AUTH_TOKEN` | Bearer token for daemon auth | (none) |
| `MCP2CLI_DAEMON_URL` | Remote daemon URL | (unix socket) |
| `MCP2CLI_TOKENS_FILE` | Path to tokens.json | `~/.config/mcp2cli/tokens.json` |
| `MCP2CLI_DAEMON` | Enable daemon mode (set to 1) | (none) |
| `MCP2CLI_LISTEN_HOST` | TCP bind host | `127.0.0.1` |
| `MCP2CLI_LISTEN_PORT` | TCP bind port | `9500` |
| `MCP2CLI_IDLE_TIMEOUT` | Idle shutdown (seconds, 0=disabled) | `60` (unix), `0` (tcp) |
| `MCP2CLI_POOL_MAX` | Max concurrent connections | `50` |
| `MCP2CLI_TOOL_TIMEOUT` | Tool call timeout (ms) | `30000` |
| `MCP2CLI_LOG_LEVEL` | Log level | `info` |
| `MCP2CLI_CACHE_DIR` | Schema cache directory | `~/.cache/mcp2cli` |

## Auth for Remote Daemon

**Both env vars must be set for remote auth:**

```bash
export MCP2CLI_DAEMON_URL=http://<MCP2CLI_IP>:9500
export MCP2CLI_AUTH_TOKEN=<your-token>
mcp2cli n8n --help
```

Or inline:

```bash
MCP2CLI_AUTH_TOKEN=<token> MCP2CLI_DAEMON_URL=http://<MCP2CLI_IP>:9500 mcp2cli services
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Validation error |
| 2 | Internal error |
| 3 | Auth error |
| 4 | Tool error |
| 5 | Connection error |
| 10 | Dry run (success, no side effects) |
