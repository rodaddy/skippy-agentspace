# Dogfooding Playbook

How to set up and verify a full PAI + skippy-agentspace environment on a new machine.

## The Right Way to Install

**Do NOT use `tools/install.sh` for real environments.** Shell scripts are a fallback for machines without Claude Code. The proper install is Claude-guided:

1. Clone the repo on the target machine
2. Open a Claude Code session in the repo directory
3. Say: `Read docs/install-process.md and install skippy-agentspace on this machine`

Claude follows the 18-step interactive process: backup, discovery, diff, skill copy, hook wiring, smoke test, and verification handoff.

For updates: `Read docs/update-process.md and update skippy-agentspace`

## Full Environment Setup

A complete PAI environment requires more than just skills. Here's what the 2026-03-22 dogfood verified end-to-end.

### Prerequisites

| Requirement | How to Check | Install |
|-------------|-------------|---------|
| bash 4.0+ | `bash --version` | System package |
| git + GitHub SSH access | `ssh -T git@github.com` | Generate key, add to GitHub |
| bun | `bun --version` | `curl -fsSL https://bun.sh/install -o /tmp/bun.sh && bash /tmp/bun.sh` |
| rsync | `which rsync` | `apt install rsync` (Debian) / built-in (macOS) |
| Claude Code CLI | `claude --version` | See Anthropic docs |
| LiteLLM access | `curl $ANTHROPIC_BASE_URL` | Set ANTHROPIC_BASE_URL + ANTHROPIC_API_KEY |

### Step-by-Step (what we actually did)

```bash
# 1. Clone repos
git clone git@github.com:rodaddy/skippy-agentspace.git ~/skippy-agentspace
git clone git@github.com:rodaddy/pai-infrastructure.git ~/.config/pai-full

# 2. Merge PAI repo into config (preserves existing skills)
rsync -a ~/.config/pai-full/ ~/.config/pai/

# 3. Rsync skippy skills into PAI Skills (additive)
cd ~/skippy-agentspace
for skill_dir in skills/*/; do
  name=$(basename "$skill_dir")
  rsync -a "$skill_dir" ~/.config/pai/Skills/"$name"/
done

# 4. Set up symlink architecture
ln -sfn ~/.config/pai/Skills ~/.claude/skills

# 5. Install hook dependencies
cd ~/.config/pai/hooks && bun install

# 6. Install LAW enforcement hooks (merges into settings.json)
cd ~/skippy-agentspace && bash skills/core/hooks/install-hooks.sh

# 7. Push settings.json (permissions, model, session hooks)
# Copy from a known-good environment and adapt paths:
#   - Replace /home/<user> paths for the target user
#   - Remove macOS-specific entries for Linux targets
#   - Remove Open Brain hooks if OB not available

# 8. Sync any pai hooks not yet in the GitHub repo
# These may need rsync from a working environment:
#   pre-session-wrap-delegate.ts, pre-exec-guard.ts,
#   post-bash-large-output.ts, intent-skill-router.ts

# 9. Test
source ~/.cc-env  # or set ANTHROPIC_BASE_URL + ANTHROPIC_API_KEY
claude -p 'List your skills and run /skippy:progress' \
  --dangerously-skip-permissions --output-format text
```

### What Gets Installed

| Component | Location | Source |
|-----------|----------|--------|
| PAI infrastructure | `~/.config/pai/` | `rodaddy/pai-infrastructure` repo |
| Skippy skills (24) | `~/.config/pai/Skills/<name>/` | `rodaddy/skippy-agentspace` repo |
| Skills symlink | `~/.claude/skills` -> `~/.config/pai/Skills` | Created during setup |
| LAW hooks (15) | Merged into `~/.claude/settings.json` | `skills/core/hooks/install-hooks.sh` |
| Session hooks | Merged into `~/.claude/settings.json` | Copied from working environment |
| Hook dependencies | `~/.config/pai/hooks/node_modules/` | `bun install` |

### pai-private is NOT required

The cc-* containers and Air all run without `pai-private`. LAW enforcement comes from skippy's core hooks (`skills/core/hooks/`). Session lifecycle comes from the pai repo hooks. No dependency on private repos for the core workflow.

## Structural Evals

111 assertions across 23 categories. Run anytime:

```bash
bash evals/structural/runner.sh
# Expected: 111/111 (100%)
```

These verify repo integrity (file structure, frontmatter, JSON validity, naming conventions, lifecycle). They do NOT verify the full PAI environment -- for that, test a Claude session.

## Updating Environments

After making changes locally:

```bash
# Push skippy changes to GitHub, then on each target:
cd ~/skippy-agentspace && git pull

# Rsync updated skills into PAI
for skill_dir in skills/*/; do
  name=$(basename "$skill_dir")
  rsync -a "$skill_dir" ~/.config/pai/Skills/"$name"/
done

# Re-run hook installer (idempotent)
bash skills/core/hooks/install-hooks.sh

# For pai hooks not yet in GitHub, rsync from local:
# rsync -av ~/.config/pai/hooks/<file>.ts <target>:~/.config/pai/hooks/
```

## Verification History

| Date | Environment | OS | Bash | Evals | Claude Session | Skills |
|------|-------------|-----|------|-------|----------------|--------|
| 2026-03-22 | ThunderBolt (local) | macOS 25.3.0 (x86_64) | 5.2 | 111/111 | Baseline | 86 |
| 2026-03-22 | cc-king (LXC 320) | Debian Linux 6.17.13 | 5.2.37 | 111/111 | /skippy:progress works | 86 |
| 2026-03-22 | cc-kevin (LXC 321) | Debian Linux 6.17.13 | 5.2.37 | 111/111 | /skippy:progress works | 72 |
| 2026-03-22 | cc-geetesh (LXC 322) | Debian Linux 6.17.13 | 5.2.37 | 111/111 | /skippy:progress works | 73 |
| 2026-03-22 | Air | macOS 25.3.0 (ARM64) | 5.3.9 | 111/111 | Skills visible | 81 |

## Known Issues

### pai repo on GitHub is behind local

Several hooks exist locally but aren't pushed to `pai-infrastructure` yet. Until the repo is synced, new environments need these files rsynced manually: `pre-session-wrap-delegate.ts`, `pre-exec-guard.ts`, `post-bash-large-output.ts`, `intent-skill-router.ts`.

### install.sh conflicts with existing PAI skills

`tools/install.sh` creates symlinks. If `~/.claude/skills/` already has real directories (PAI-managed), install.sh refuses to overwrite. Use `rsync` directly into `~/.config/pai/Skills/` instead.

### Skill count varies by environment

Environments with the full PAI repo have more skills (70+) than skippy alone (24). This is expected -- PAI ships its own skills alongside skippy's.

## Replicating for Other Projects

1. Copy `evals/structural/` (runner + categories) as a starting point
2. Replace skill-focused assertions with your project's invariants
3. Keep the runner pattern: category files, pass/fail counting, score output
4. Target multiple environments via SSH
5. Record results with dates and environment details
6. Assertions must be binary, automated, and environment-agnostic
