---
name: gh-review
description: Set up Claude Code review workflow with self-hosted runner for any GitHub repo. Registers runner, configures secrets, creates workflow file.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: utility
---

# gh-review -- GitHub CI Review Setup

Automates the full setup of Claude Code PR reviews on a self-hosted runner for any GitHub repo.

## What It Does

1. Registers a runner instance on the shared review LXC
2. Sets up LiteLLM API key as a GitHub secret
3. Creates `claude-code-review.yml` workflow
4. Verifies the runner comes online

## Prerequisites

| Requirement | How to Check |
|-------------|-------------|
| SSH access to runner LXC | `ssh root@10.71.1.114 hostname` |
| `gh` CLI authenticated | `gh auth status` |
| LiteLLM API key in vaultwarden | `mcp2cli vaultwarden-secrets get_secret --params '{"name": "LiteLLM"}'` |
| Claude Code on runner LXC | `ssh root@10.71.1.114 "su - runner -c 'claude --version'"` |

## Infrastructure

| Property | Value |
|----------|-------|
| Runner LXC | 106 (gh-runner) at 10.71.1.114 |
| Runner user | `runner` |
| Runner base | `/home/runner/` |
| Node | v24+ at `/usr/local/bin/node` |
| Bun | `/usr/local/bin/bun` |
| Claude Code | `/home/runner/.local/bin/claude` |
| LiteLLM proxy | `http://10.71.20.33:4000` |

## Commands

| Command | What |
|---------|------|
| `/gh-review:setup` | Full setup for a repo (register runner, secret, workflow) |

## Gotchas

- **Vaultwarden key lookup:** Use `get_secret` with name `"LiteLLM"` (returns `text` field). Do NOT use `get_credential` with `"LiteLLM API Key - gh_runner"` -- that entry stores the key in a non-password field and returns empty.
- **Runner PATH:** The runner service doesn't inherit the user's login PATH. You must add `PATH=...` to the runner's `.env` file so it can find node, bun, and claude.
- **Claude Code on runner:** `su - runner -c 'claude --version'` will fail if `/usr/local/bin` isn't in PATH. Use `export PATH=/usr/local/bin:$PATH` first.
- **Workflow activation:** New workflow files only activate from the default branch (main). A workflow added on a feature branch won't trigger until merged -- or cherry-pick just the workflow file to main.
- **Node 24 + actions/checkout@v6:** Set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"` as env var to use Node 24 with v6 actions.

## Active Runners

| Repo | Runner Name | Label | Status |
|------|-------------|-------|--------|
| rodaddy/skippy-agentspace | gh-runner-skippy | skippy | online |
| rodaddy/mcp2cli | gh-runner | (default) | online |
| rodaddy/king-ng | king-ng | king-ng | online |
| rodaddy/king-ng | king-uat | king-uat | online |

## References

- King-ng workflow: `gh api repos/rodaddy/king-ng/contents/.github/workflows/claude-code-review.yml`
- Runner docs: https://docs.github.com/en/actions/hosting-your-own-runners
