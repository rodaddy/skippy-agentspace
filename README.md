# skippy-agentspace

Portable Claude Code skill repo. Cherry-picks the best workflow ideas from [GSD](https://github.com/gsd-build/get-shit-done) and [PAUL](https://github.com/ChristopherKahler/paul) into standalone, installable skills.

12 skills across 4 categories: core identity, workflow automation, utility tools, and domain-specific deployment. Each skill is self-contained with no cross-skill imports. Works with vanilla Claude Code -- PAI enhancements are optional.

## Quick Start

```bash
git clone <repo-url>
cd skippy-agentspace
bash tools/prereqs.sh
bash tools/install.sh --all
bash tools/verify.sh
```

Run `/clear` in Claude Code to pick up the new skills.

## Documentation

| Doc | Purpose |
|-----|---------|
| [SETUP.md](SETUP.md) | First-time setup with detailed steps |
| [INSTALL.md](INSTALL.md) | Adding or removing individual skills |
| [UPGRADE.md](UPGRADE.md) | Updating to newer versions |
| [CLAUDE.md](CLAUDE.md) | AI agent context and project architecture |
| [INDEX.md](INDEX.md) | Full skill catalog by category |
| [CONVENTIONS.md](CONVENTIONS.md) | Content classification and upstream registry |

## Skills

| Category | Count | Examples |
|----------|-------|---------|
| Core | 1 | Personas, LAWs, rules, hooks, templates |
| Workflow | 6 | add-todo, check-todos, session-wrap, skippy-dev |
| Utility | 4 | browser, excalidraw, fabric, vaultwarden |
| Domain | 1 | deploy-service (LXC + nginx + DNS) |

See [INDEX.md](INDEX.md) for the complete list with descriptions and install status.

## Requirements

- git
- bash 4.0+
- bun (Node.js runtime)
- jq (JSON processor)

Run `bash tools/prereqs.sh` to check and install missing tools. See [SETUP.md](SETUP.md) for platform-specific details.

## License

See [LICENSE](LICENSE) for details.
