# skippy-agentspace

Portable Claude Code skill repo. Cherry-picks the best workflow ideas from [GSD](https://github.com/gsd-build/get-shit-done), [PAUL](https://github.com/ChristopherKahler/paul), and [OMC](https://github.com/anthropics/oh-my-claudecode) into standalone, installable skills.

PAI (Personal AI) is a multi-persona AI infrastructure for Claude Code -- think dotfiles for AI assistants. This repo packages PAI's best skills as portable, installable modules.

12 skills across 4 categories. 15 reference docs distilling workflow patterns from 3 upstream frameworks. Self-contained -- no cross-skill imports. Works with vanilla Claude Code -- PAI enhancements are optional.

## Quick Start

```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
bash tools/prereqs.sh
bash tools/install.sh --all
bash tools/verify.sh
```

Run `/clear` in Claude Code to pick up the new skills.

## Try It

After install, try these in any project with Claude Code:
- `/check-todos` -- see project and global todos
- `/add-todo fix the login bug` -- capture an idea
- `/skippy:reconcile` -- compare planned vs actual work (requires GSD)

## What's Inside

### Skills (12)

| Category | Skills | Requires |
|----------|--------|----------|
| Core | personas, LAWs, 15 hooks, templates | bun |
| Workflow (6) | add-todo, check-todos, update-todo, correct, session-wrap, skippy-dev | Standalone |
| Utility (4) | browser, excalidraw, fabric, vaultwarden | Infrastructure |
| Domain (1) | deploy-service (LXC + nginx + DNS) | Proxmox |

See [INDEX.md](INDEX.md) for the full catalog with portability badges.

### Cherry-Picked Reference Docs (15)

Best ideas stolen from 3 frameworks, distilled into actionable reference docs in `skills/skippy-dev/references/`:

**From PAUL (5)** -- planning discipline:
- Context brackets, reconciliation, task anatomy, plan boundaries, state consistency

**From OMC (4)** -- execution readiness:
- Pre-execution gate, ambiguity scoring, compaction resilience, parallel file ownership

**From GSD + PAI (6)** -- workflow patterns:
- Model routing, verification loops, skill extraction, structured deliberation, session persistence, GSD dependency map

### Upstream Tracking

Three upstream frameworks tracked with live SHAs in `upstreams/*/upstream.json`. Run `/skippy:update` to check for changes.

| Upstream | What We Take | Cherry-Picks |
|----------|-------------|-------------|
| [GSD](https://github.com/gsd-build/get-shit-done) | Phased execution framework (used as-is) | 0 (dependency) |
| [PAUL](https://github.com/ChristopherKahler/paul) | 5 planning discipline ideas | 5 |
| [OMC](https://github.com/anthropics/oh-my-claudecode) | 4 execution readiness patterns | 4 |

## Tools

| Tool | What It Does |
|------|-------------|
| `tools/install.sh` | Selective installer (`--core`, `--all`, positional args) |
| `tools/uninstall.sh` | Selective uninstaller (scoped -- only removes its own symlinks) |
| `tools/verify.sh` | brew-doctor-style health check (24 checks across 5 categories) |
| `tools/prereqs.sh` | Cross-platform prerequisite checker with interactive install |
| `tools/validate-hooks.sh` | Hook manifest validation (6 checks) |
| `tools/index-sync.sh` | INDEX.md validation and regeneration |
| `tools/integration-test.sh` | 36 automated tests, fully sandboxed |
| `tools/backup-restore.sh` | Snapshot/restore ~/.claude/ before testing |

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
bash tools/integration-test.sh          # Full test suite (36 tests, clones upstreams)
bash tools/integration-test.sh --quick  # Skip upstream clones
bash tools/integration-test.sh --verbose # Show full output
```

All tests run in sandboxed `$HOME` -- never touches your real `~/.claude/`.

## License

MIT. See [LICENSE](LICENSE).
