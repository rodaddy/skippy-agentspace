# skippy-agentspace

Standalone Claude Code skill framework with patterns adapted from [GSD](https://github.com/gsd-build/get-shit-done), [PAUL](https://github.com/ChristopherKahler/paul), and [OMC](https://github.com/anthropics/oh-my-claudecode).

PAI (Personal AI) is a multi-persona AI infrastructure for Claude Code -- think dotfiles for AI assistants. This repo packages PAI's best skills as portable, installable modules.

12 skills across 4 categories. 18 reference docs distilling workflow patterns from 3 upstream frameworks. Self-contained -- no cross-skill imports. Works with vanilla Claude Code -- PAI enhancements are optional.

## Quick Start

**In Claude Code:**
```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install core@skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Install individual skills: `/plugin install <skill-name>@skippy-agentspace`

**Manual install (alternative):**
```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
bash tools/prereqs.sh
bash tools/install.sh --all    # or: install.sh --core, install.sh <skill-name>
bash tools/verify.sh
```

Run `/clear` in Claude Code to pick up new skills.

## Try It

After install, try these in any project with Claude Code:
- `/check-todos` -- see project and global todos
- `/add-todo fix the login bug` -- capture an idea
- `/skippy:reconcile` -- compare planned vs actual work

## What's Inside

### Skills (12)

| Category | Skills | Requires |
|----------|--------|----------|
| Core | personas, LAWs, 15 hooks, templates | bun |
| Workflow (6) | add-todo, check-todos, update-todo, correct, session-wrap, skippy-dev | Standalone |
| Utility (4) | browser, excalidraw, fabric, vaultwarden | Infrastructure |
| Domain (1) | deploy-service (LXC + nginx + DNS) | Proxmox |

See [INDEX.md](INDEX.md) for the full catalog with portability badges.

### Reference Docs (18)

Workflow patterns adapted from 3 frameworks, distilled into standalone reference docs in `skills/skippy-dev/references/`:

**From PAUL (5)** -- planning discipline:
- Context brackets, reconciliation, plan structure (task format), plan boundaries, state consistency

**From OMC (4)** -- execution readiness:
- Ambiguity scoring, compaction resilience, parallel file ownership, pre-execution gate

**From GSD (5)** -- execution patterns:
- Phased execution, state tracking, checkpoints, plan structure (plan format), verification loops

**Cross-source (3)** -- synthesized patterns:
- Model routing, structured deliberation, session persistence

**Original (1)** -- from v1.1 audit process:
- Audit swarm

### Upstream Tracking

Three upstream frameworks tracked with live SHAs in `upstreams/*/upstream.json`. Run `/skippy:update` to check for changes.

| Upstream | What We Take | Patterns Adapted |
|----------|-------------|-----------------|
| [GSD](https://github.com/gsd-build/get-shit-done) | Historical source of phased execution patterns | 5 |
| [PAUL](https://github.com/ChristopherKahler/paul) | 5 planning discipline ideas | 5 |
| [OMC](https://github.com/anthropics/oh-my-claudecode) | 4 execution readiness patterns | 4 |

## Tools

| Tool | What It Does |
|------|-------------|
| `tools/install.sh` | Selective installer (`--core`, `--all`, positional args) |
| `tools/uninstall.sh` | Selective uninstaller (scoped -- only removes its own symlinks) |
| `tools/verify.sh` | brew-doctor-style health check (25+ checks across 5 categories) |
| `tools/prereqs.sh` | Cross-platform prerequisite checker with interactive install |
| `tools/validate-hooks.sh` | Hook manifest validation (6 checks) |
| `tools/index-sync.sh` | INDEX.md validation and regeneration |
| `tools/integration-test.sh` | 36 automated tests, fully sandboxed |
| `tools/backup-restore.sh` | Snapshot/restore ~/.claude/ before testing |
| `tools/bump-version.sh` | Version bump across all 25 version locations |

## Documentation

| Doc | Purpose |
|-----|---------|
| [SETUP.md](SETUP.md) | First-time setup (clone to working PAI in 7 steps) |
| [INSTALL.md](INSTALL.md) | Adding or removing individual skills |
| [UPGRADE.md](UPGRADE.md) | Updating to newer versions |
| [INDEX.md](INDEX.md) | Full skill catalog with portability badges |
| [CLAUDE.md](CLAUDE.md) | AI agent context and project architecture |
| [CONVENTIONS.md](CONVENTIONS.md) | Content classification and upstream registry |

## Requirements

- git, bash 4.0+, bun (Node.js runtime), jq (JSON processor)

Run `bash tools/prereqs.sh` to check and install missing tools.

## Testing

```bash
# Unit tests (bats-core, sandboxed HOME)
./tests/bats/bin/bats tests/

# Health check
bash tools/verify.sh

# Full integration suite
bash tools/integration-test.sh
bash tools/integration-test.sh --quick    # Skip upstream clones
bash tools/integration-test.sh --verbose  # Show full output
```

All tests run in sandboxed `$HOME` -- never touches your real `~/.claude/`.

## License

MIT. See [LICENSE](LICENSE).
