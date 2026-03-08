# Feature Research

**Domain:** Portable AI assistant infrastructure packaging (Claude Code skills, bootstrap, upstream cherry-pick)
**Researched:** 2026-03-07
**Confidence:** MEDIUM-HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features the user (Rico, primary consumer) expects from a "portable PAI infrastructure package." Missing these means the repo fails its stated goal of "clone + install = working PAI."

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| One-command bootstrap | Dotfiles ecosystem standard (chezmoi, dotbot). `git clone && ./install` is the minimum bar. | MEDIUM | Must handle first-run vs update (idempotent). Existing `install.sh` handles skill symlinks but not full PAI infra. |
| Core infrastructure package | PROJECT.md explicitly lists "personas, LAWs, hooks, commands" as core. Without this, bootstrap has nothing to install. | HIGH | Must package CORE skill, hooks, commands, deep docs, CLAUDE.md template. Private vs public content split is the hard part. |
| Skill registry with selective install | User has ~70 skills. Can't install all on every machine. Need `./install --skill n8n --skill proxmox`. | MEDIUM | INDEX.md already exists. Extend install.sh with skill selection. oh-my-zsh `plugins=(git docker)` pattern. |
| Idempotent operations | Dotbot/chezmoi best practice. Re-running install should not break existing config or duplicate symlinks. | LOW | Current install.sh partially handles this (checks existing symlinks). Needs hardening. |
| Upstream version tracking | Already have `.versions` for GSD+PAUL. Adding OMC as third upstream is natural extension. | LOW | Extend existing `/skippy:update` pattern. Add OMC repo to tracked upstreams. |
| Slim SKILL.md + deep references | PROJECT.md constraint: "SKILL.md is the entry point (~150 lines max). Detail lives in references/." All skills must follow this pattern. | MEDIUM | Audit existing 70 skills. Many probably violate this today. Need restructuring pass. |
| Uninstall that actually works | Existing `uninstall.sh` handles skill symlinks. Must extend to full infra teardown. | LOW | Remove symlinks, don't delete source. Already proven pattern. |

### Differentiators (Competitive Advantage)

Features that make skippy-agentspace more valuable than "just copy my dotfiles." These separate a real infrastructure package from a tarball of config files.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| OMC cherry-pick system | Selectively absorb the best OMC ideas (like ralplan, learner, deepsearch patterns) without installing all 37 skills + 31 hooks + 28 agents. Same parasitic approach as PAUL. | HIGH | Requires: (1) OMC analysis to identify what's worth stealing, (2) reference doc extraction, (3) integration with existing `/skippy:update`. Not a fork -- reference docs only. |
| Extensible upstream registry | Add any git repo as an upstream source to cherry-pick from. Not hardcoded to GSD+PAUL+OMC. Future-proof for new frameworks. | MEDIUM | Config file listing upstreams + what was cherry-picked from each. `/skippy:update` iterates all. Pattern: `upstreams.json` with repo URL, tracked version, cherry-picked items. |
| Public/private content split | Core infra has two layers: public (shareable structure, personas, LAWs) and private (credentials refs, personal memory, specific hook configs). Bootstrap installs public; private is opt-in overlay. | HIGH | Key architectural decision. chezmoi solves this with templates + secrets manager integration. We solve with directory convention: `core/` (public) vs `private/` (gitignored or separate repo). |
| Add-on skill system | Skills as opt-in packages. Each declares its dependencies, what it hooks into, and whether it needs PAI or works standalone. | MEDIUM | Manifest per skill: `{ "standalone": true, "requires": ["CORE"], "hooks": ["skill-triggers"] }`. Install script reads manifest, validates deps. |
| Ralplan integration (from OMC) | Plan + Architect + Critic consensus loop before major work. Already referenced in CLAUDE.md but not formally packaged as a skill. | MEDIUM | Extract the pattern as a reference doc (like PAUL cherry-picks). Don't import OMC's implementation -- write our own skill following the pattern. Already used as `/oh-my-claudecode:ralplan`. |
| Session learner (from OMC) | Extract reusable skills from completed sessions. OMC's `learner` skill analyzes what was done and distills it into a new skill. | LOW | Reference doc describing the pattern. The actual skill creation already works via PAI's `skill-add` and `CreateSkill`. |
| Context-aware model routing | Route simple tasks to Haiku, complex to Opus. OMC does this with 30-50% token savings. | LOW | Reference doc only. Actual routing is already partially in PAI via agent-orchestration.md model selection guidance. |
| Bootstrap verification | After install, run a health check that confirms everything is wired correctly. Hooks fire, skills load, commands resolve. | MEDIUM | Extend existing `/gsd:health` pattern. Check symlink targets exist, CLAUDE.md loads, test one skill invocation. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Fork OMC/GSD/PAUL | "Just fork it and customize" | Massive maintenance burden. All three upstreams are actively evolving. Fork diverges within weeks. | Parasitic cherry-pick: reference docs + additive skills. Zero upstream maintenance. |
| Auto-merge upstream changes | "Keep everything in sync automatically" | Upstream changes can break assumptions. A GSD restructure could invalidate reconciliation logic. Silent breakage is worse than manual review. | `/skippy:update` reports diffs. Human reviews and decides. Already working in v1.0. |
| Install everything by default | "Just install all 70 skills" | Context budget is 2% of context window (~16K chars). 70 skill descriptions would blow the budget. Also most skills are domain-specific (n8n, proxmox, homeassistant) and irrelevant on many machines. | Selective install with sensible defaults. Core + explicitly chosen add-ons. |
| TypeScript/Node build step | "Use a real package manager for dependencies" | Kills zero-dep portability. Shell + markdown only means any machine with git + bash can bootstrap. No `bun install` required. | Shell scripts + markdown. Current constraint is correct. |
| MCP servers inside skills | "Skills should be able to connect to external services" | Skills are procedural knowledge (instructions for Claude), not connectivity. MCP servers are infrastructure, not skills. | MCP config lives in `.mcp.json` at project or user level. Skills reference MCP tools but don't bundle servers. |
| Cross-skill dependencies | "Skill A should import from Skill B" | Creates coupling. One skill change cascades. Installation order matters. Debugging becomes hell. | Self-contained skills. Duplicate shared content if needed. Small duplication beats tight coupling. |
| Hook-based enforcement | "Use hooks to enforce LAWs automatically" | Hooks can't detect semantic context (e.g., "is this agent being sarcastic enough for Skippy persona?"). Over-hooking creates false positives and user friction. | Rules are self-enforced via reference docs loaded into context. Hooks only for mechanical checks (#!/bin/bash, branch names). |
| GUI/web-based skill browser | "Build a UI to browse and install skills" | Over-engineering. Community marketplaces (SkillsMP, claude-plugins.dev) already exist. INDEX.md + CLI is sufficient for a personal repo. | INDEX.md as the browsable registry. `./install --list` for CLI discovery. |

## Feature Dependencies

```
[Bootstrap Script]
    |--requires--> [Core Infrastructure Package]
    |                  |--requires--> [Public/Private Content Split]
    |                  |--requires--> [Slim SKILL.md Restructuring]
    |
    |--requires--> [Skill Registry]
    |                  |--requires--> [Add-on Skill System]
    |                  |--requires--> [Skill Manifests]
    |
    |--optional---> [Bootstrap Verification]

[OMC Cherry-Pick]
    |--requires--> [Extensible Upstream Registry]
    |                  |--requires--> [Upstream Version Tracking] (exists)
    |
    |--produces--> [Ralplan Reference Doc]
    |--produces--> [Learner Reference Doc]
    |--produces--> [Model Routing Reference Doc]

[Extensible Upstream Registry]
    |--enhances--> [/skippy:update command] (exists)

[Add-on Skill System]
    |--requires--> [Skill Registry] (INDEX.md exists)
    |--requires--> [Selective Install in install.sh]
    |--enhances--> [Slim SKILL.md pattern]
```

### Dependency Notes

- **Bootstrap requires Core Package:** Can't bootstrap without defining what "core" means. This is the first thing to build.
- **Core Package requires Public/Private Split:** Must decide what's shareable vs private before packaging. This is an architectural decision, not code.
- **OMC Cherry-Pick requires Upstream Registry:** Need the extensible upstream system before adding OMC as a third source. Otherwise it's another hardcoded special case.
- **Add-on System requires Skill Registry:** Need to know what's available before offering selective install. INDEX.md exists but needs manifest metadata.
- **Bootstrap Verification is optional but recommended:** Can ship bootstrap without it. Should add within same milestone for confidence.

## MVP Definition

### Launch With (v1.1)

Minimum viable infrastructure package -- what's needed to clone this repo on a new machine and get a working PAI.

- [ ] **Core infrastructure package** -- Define and package: CORE skill, personas, LAWs summary, CLAUDE.md template, essential hooks, essential commands. Public layer only.
- [ ] **Public/private content split** -- Convention for what lives in repo vs what's in `~/.config/pai-private/`. Bootstrap creates private dirs with placeholder files.
- [ ] **Extensible upstream registry** -- `upstreams.json` config listing tracked repos + cherry-picked items. Replaces hardcoded GSD+PAUL in `/skippy:update`.
- [ ] **OMC analysis + cherry-pick** -- Analyze OMC, identify 3-5 ideas worth stealing, create reference docs. Same pattern as PAUL cherry-picks.
- [ ] **Selective skill install** -- `./install --core` for infrastructure, `--skill <name>` for add-ons, `--all` for everything. Idempotent.
- [ ] **Bootstrap script** -- `git clone && ./bootstrap` installs core + chosen skills + creates private dirs. Works on fresh macOS.

### Add After Validation (v1.x)

Features to add once core bootstrap is proven on a real second machine.

- [ ] **Skill restructuring audit** -- Check all ~70 PAI skills against slim SKILL.md pattern. Restructure violators. Trigger: when adding skills to this repo.
- [ ] **Bootstrap verification** -- Post-install health check. Trigger: after first successful bootstrap on new machine.
- [ ] **Skill scaffolding** -- `new-skill.sh` template generator (deferred from v1.0 as TOOL-01). Trigger: when adding the third skill.
- [ ] **Cross-machine sync** -- Mechanism to keep two machines' skill selections aligned. Trigger: when a second machine is actively used.

### Future Consideration (v2+)

- [ ] **Skill dependency resolution** -- Auto-install required skills when a skill declares dependencies. Defer because self-contained is simpler and current skill count doesn't warrant it.
- [ ] **Plugin marketplace publishing** -- Publish to community registries (claude-plugins.dev, SkillsMP). Defer because this is a private/personal repo.
- [ ] **Multi-user support** -- Config profiles for different users of the same machine. Defer because single-user is the current reality.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Depends On |
|---------|------------|---------------------|----------|------------|
| Core infrastructure package | HIGH | HIGH | P1 | Public/private split |
| Public/private content split | HIGH | MEDIUM | P1 | None (architectural decision) |
| Extensible upstream registry | HIGH | MEDIUM | P1 | None |
| OMC analysis + cherry-pick | HIGH | MEDIUM | P1 | Upstream registry |
| Bootstrap script | HIGH | MEDIUM | P1 | Core package, selective install |
| Selective skill install | HIGH | MEDIUM | P1 | Skill registry |
| Idempotent install hardening | MEDIUM | LOW | P2 | Existing install.sh |
| Slim SKILL.md audit | MEDIUM | MEDIUM | P2 | None |
| Bootstrap verification | MEDIUM | MEDIUM | P2 | Bootstrap script |
| Skill scaffolding | LOW | LOW | P3 | None |
| Cross-machine sync | LOW | MEDIUM | P3 | Bootstrap working |

**Priority key:**
- P1: Must have for v1.1 milestone
- P2: Should have, add when possible within v1.1
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | OMC | GSD | chezmoi/dotbot | Our Approach |
|---------|-----|-----|----------------|--------------|
| Skill packaging | 37 skills, monolithic plugin install | Commands in `commands/` dir, all-or-nothing | N/A (not AI-specific) | Selective install per skill. Core vs add-on split. |
| Bootstrap | `/omc-setup` wizard | No bootstrap (per-project) | `git clone && ./install` one-liner | `git clone && ./bootstrap` with interactive skill selection |
| Upstream tracking | Self-contained, no upstream concept | Self-contained | Self-contained | Explicit upstream registry tracking multiple sources |
| Cherry-picking | Everything or nothing -- install full plugin | N/A | N/A | Parasitic -- reference docs from any upstream, never fork |
| Persistence/memory | `.omc/notepad.md`, project-memory.json, 3-tier memory | `.planning/` state files | N/A | `~/.config/pai-private/memory/` for personal, `.planning/` for project |
| Model routing | Automatic Haiku/Sonnet/Opus routing | No routing (uses whatever model is configured) | N/A | Reference doc with routing guidance, not automated |
| Agent system | 28 specialized agents | Researcher, planner, executor (spawned per phase) | N/A | CORE agents (verification-agent) + per-skill agents. Slim definitions. |
| Content split | Public repo, everything visible | Per-project, everything in `.planning/` | Templates + secrets manager | Public repo + `pai-private/` gitignored overlay |
| Hooks | 31 hooks for lifecycle events | Phase lifecycle hooks | N/A | Selective hooks: law-enforcement, safety, skill-triggers. Not 31. |
| Idempotency | Unknown | N/A (per-project) | Core design principle in chezmoi/dotbot | Required. Install must be safe to re-run. |

## OMC Cherry-Pick Assessment

Based on OMC repo analysis (37 skills, 22 agents, hooks system), here are candidates ranked by value-to-effort:

### Worth Cherry-Picking (as reference docs)

| OMC Feature | What to Extract | Why Worth It | Effort |
|-------------|----------------|--------------|--------|
| **Ralplan** (plan + architect + critic loop) | Consensus planning pattern. Already used ad-hoc via `/oh-my-claudecode:ralplan`. | Prevents shipping half-baked plans. Three-perspective validation catches blind spots. | LOW -- pattern already understood, just needs reference doc |
| **Persistent notepad** (.omc/notepad.md) | Priority-tiered notes that survive context compaction. | PAI already has `~/.config/pai-private/memory/` but lacks the "survives compaction" framing and priority tiers. | LOW -- enhancement to existing memory system |
| **Learner** (skill extraction from sessions) | Pattern for analyzing a session and distilling reusable skills. | PAI has `skill-add` and `CreateSkill` but no systematic "what did I learn this session?" workflow. | LOW -- reference doc describing when/how to extract |
| **Deepsearch** (parallel research agents) | Parallel scientist agents for comprehensive research. | GSD already spawns researcher agents, but OMC's "fan out, synthesize" pattern is more structured. | MEDIUM -- needs agent definition + reference doc |
| **Model routing guidance** | When to use Haiku vs Sonnet vs Opus for subagents. | Already partially in agent-orchestration.md. OMC's categories (simple/medium/complex) are clearer. | LOW -- enhance existing doc |

### Not Worth Cherry-Picking

| OMC Feature | Why Not | What We Do Instead |
|-------------|---------|-------------------|
| Autopilot/Ultrapilot execution modes | Heavy runtime dependency on tmux, state management, worker pools. Over-engineered for solo dev. | GSD's phase execution + parallel subagents. Already works. |
| Team/Swarm orchestration | Requires OMC runtime (bridge/, team-bridge.cjs). Not portable without OMC installed. | GSD's agent spawning is simpler and doesn't need a runtime. |
| 28 specialized agents | Most are thin wrappers. architect.md, critic.md are useful patterns but 28 is bloat. | Cherry-pick 3-4 agent patterns (architect, critic, explore). Skip the rest. |
| 31 hooks | Lifecycle management overkill. Each hook adds latency and complexity. | Keep mechanical hooks only (law-enforcement, safety). Rules via reference docs for everything else. |
| .omc/ state directory | Couples to OMC runtime. project-memory.json is auto-populated by OMC hooks. | `.planning/` for project state (GSD standard). `~/.config/pai-private/memory/` for personal. |
| Writer-memory skill | Domain-specific (fiction writing). Not relevant to dev infrastructure. | Skip entirely. |
| Multi-provider routing (Codex, Gemini) | Requires 3 paid subscriptions. Complexity without clear solo-dev value. | Single provider (Anthropic). Use model tiers within Claude. |

## Sources

- [oh-my-claudecode GitHub repo](https://github.com/Yeachan-Heo/oh-my-claudecode) -- OMC structure, skills, agents analysis (HIGH confidence)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- SKILL.md format, context budget, auto-discovery (HIGH confidence)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Plugin structure, marketplace.json format (HIGH confidence)
- [dotfiles.github.io bootstrap repos](https://dotfiles.github.io/bootstrap/) -- Bootstrap patterns, idempotency (HIGH confidence)
- [chezmoi documentation](https://www.chezmoi.io/) -- Template system, secrets management, one-command setup (HIGH confidence)
- [dotbot GitHub](https://github.com/anishathalye/dotbot) -- Lightweight bootstrapping, symlink management (HIGH confidence)
- [Antidote/oh-my-zsh cherry-pick pattern](https://joshfrankel.me/blog/a-perfect-terminal-with-zsh-antidote-on-my-zsh-powerlevel10k-mise/) -- Selective plugin loading from upstream frameworks (MEDIUM confidence)
- [OMC Documentation](https://yeachan-heo.github.io/oh-my-claudecode-website/docs.html) -- Skill descriptions, execution modes (MEDIUM confidence)
- [Ralplan on skills.sh](https://skills.sh/yeachan-heo/oh-my-claudecode/ralplan) -- Ralplan skill details (MEDIUM confidence)
- Existing PAI infrastructure at `~/.config/pai/` and `~/.config/pai-private/` -- Direct filesystem inspection (HIGH confidence)

---
*Feature research for: Portable PAI Infrastructure Packaging*
*Researched: 2026-03-07*
