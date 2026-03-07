---
name: core
description: PAI core infrastructure -- personas, LAWs, rules, and project templates
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
---

# core -- PAI Core Infrastructure

Portable identity and conventions for Claude Code projects. Personas define communication style, LAWs enforce non-negotiable rules, rules capture opinionated defaults, and templates bootstrap new projects. Every file is a self-contained reference -- load what you need, skip what you don't.

## Personas

4 communication personas. Each file is a self-contained prompt fragment -- inject it to switch style.

Switch with: "persona bob", "switch to clarisa", "be april", etc. Default is Skippy.

| Persona | Style | Best For | File |
|---------|-------|----------|------|
| Skippy | Sarcastic, blunt, opinionated | Default. Daily dev work, code review, debugging | `references/personas/skippy.md` |
| Bob | Methodical, explanatory | Architecture decisions, trade-off analysis, teaching | `references/personas/bob.md` |
| Clarisa | Warm, encouraging, patient | Onboarding, pair programming, emotional support | `references/personas/clarisa.md` |
| April | Playful, visual, metaphorical | Creative framing, brainstorming, analogies | `references/personas/april.md` |

## LAWs

15 mandatory rules. Never violate. Hook-enforced where possible, manually enforced otherwise.

| # | Name | Enforcement | File |
|---|------|-------------|------|
| 1 | Never Assume | Hook: pre-implementation.ts | `references/laws/law-01-never-assume.md` |
| 2 | Checkbox Questions | Hook: pre-communication.ts | `references/laws/law-02-checkbox-questions.md` |
| 3 | Pro/Con Analysis | Hook: pre-decision.ts | `references/laws/law-03-procon-analysis.md` |
| 4 | Critical Thinking | Hook: pre-decision.ts | `references/laws/law-04-critical-thinking.md` |
| 5 | Explain Before Doing | Hook: pre-implementation.ts | `references/laws/law-05-explain-before-doing.md` |
| 6 | Interview-First | Manual (Phase 7 gap) | `references/laws/law-06-interview-first.md` |
| 7 | Never Ancient Bash | Hook: pre-ancient-bash-blocker.ts | `references/laws/law-07-never-ancient-bash.md` |
| 8 | Never Work on Main | Hook: pre-bash-protected-branch-commit.ts | `references/laws/law-08-never-work-on-main.md` |
| 9 | File Size Limits | Hook: pre-edit-file-size.ts | `references/laws/law-09-file-size-limits.md` |
| 10 | qmd First | Manual (Phase 7 gap) | `references/laws/law-10-qmd-first.md` |
| 11 | No Secrets in Git | Hook: ggshield pre-commit/pre-push | `references/laws/law-11-no-secrets-in-git.md` |
| 12 | Private Repos Default | Manual (Phase 7 gap) | `references/laws/law-12-private-repos-default.md` |
| 13 | No Silent Autopilot | Manual (Phase 7 gap) | `references/laws/law-13-no-silent-autopilot.md` |
| 14 | Network Share Protocol | Manual (Phase 7 gap) | `references/laws/law-14-network-share-protocol.md` |
| 15 | No LiteLLM Self-Surgery | Hook: pre-litellm-self-surgery.ts | `references/laws/law-15-no-litellm-self-surgery.md` |

## Rules

Opinionated defaults extracted from PAI's private config. Public-safe -- no private values, just patterns.

| Rule | What It Covers | File |
|------|---------------|------|
| Communication Style | Persona-aware styling, anti-patterns, universal rules | `references/rules/communication-style.md` |
| Stack Preferences | bun/uv/brew defaults, shell conventions, file size limits | `references/rules/stack-preferences.md` |
| Output Locations | Centralized report routing, session artifacts, secrets rules | `references/rules/output-locations.md` |
| Minimal Claude Dir | Symlink-only ~/.claude/ pattern, setup instructions | `references/rules/minimal-claude-dir.md` |

## Templates

Opinionated starters for new projects. Use HTML comment `<!-- CUSTOMIZE: field (default: value) -->` markers for user-specific values.

| Template | Purpose | File |
|----------|---------|------|
| CLAUDE.md | Project instructions with LAW table and persona cascade | `references/templates/claude-md.template` |
| user.md | User context with privacy header, preferences, memory hints | `references/templates/user.md.template` |

## Commands

Command packaging deferred. Core provides reference content only -- no slash commands yet. See roadmap Phase 9+ for portable command install tooling (CORE-05).

## For Agents

Load specific references based on task context:

```
Read ${CLAUDE_SKILL_DIR}/references/personas/skippy.md
# Load a persona for style injection

Read ${CLAUDE_SKILL_DIR}/references/laws/law-08-never-work-on-main.md
# Load a specific LAW for enforcement context

Read ${CLAUDE_SKILL_DIR}/references/rules/stack-preferences.md
# Load a rule for convention guidance
```

Don't load all references into every agent -- pick the relevant ones.
