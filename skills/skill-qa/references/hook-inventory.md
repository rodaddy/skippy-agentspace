<!-- Extracted from SKILL.md -- load on demand -->

# Hook Inventory (Baseline 2026-04-08)

Sourced from ~/.claude/settings.json and hook survey.

## Runtime

All hooks are Bun TypeScript. Inputs: JSON on stdin with `toolName`, `toolInput`, `recentMessages[]`. Subagent detection via `process.env.CLAUDE_CODE_AGENT`.

## Pre-Tool Hooks by Matcher

### Write Matcher
| Hook | Enforces | Blocks? | Subagent Bypass? |
|------|----------|---------|-----------------|
| pre-autopilot-check.ts | LAW 13 (no silent autopilot) | Yes (6+ consecutive) | Yes |
| pre-implementation.ts | LAW 1 + LAW 5 | Yes | Yes |
| pre-decision.ts | LAW 3 + LAW 4 | Yes | Yes |
| pre-lsp-first.ts | LSP before infrastructure edits | **BROKEN** (wrong input format) | Yes |
| pre-visible-logs-and-scripts.ts | No /tmp writes (LAW 8) | Yes | Yes |
| pre-ancient-bash-blocker.ts | LAW 7 (no #!/bin/bash) | Yes | Yes |
| pre-skill-enforcer.ts | Skills-First (12 regex rules) | Yes | Yes |

### Edit Matcher
Same as Write, plus:
| Hook | Enforces | Blocks? | Subagent Bypass? |
|------|----------|---------|-----------------|
| pre-edit-file-size.ts | LAW 9 (750 line limit) | **No** (warn only) | N/A |
| pre-backup-verify.ts | Backup before critical config | **No** (warn only) | N/A |

### Bash Matcher
| Hook | Enforces | Blocks? | Subagent Bypass? |
|------|----------|---------|-----------------|
| pre-bash-unset-cd.ts | CD behavior control | Unknown | Unknown |
| pre-implementation.ts | LAW 1 + LAW 5 | Yes | Yes |
| pre-visible-logs-and-scripts.ts | No /tmp writes | Yes | Yes |
| pre-infrastructure-verify.ts | Infra safety checks | **No** (ask only) | Yes |
| enforce-skill-usage.ts | Skills-First (fuzzy) | Yes (for indexed paths) | Yes |
| security-validator.ts | Multi-tier security | Yes (tiers 1-2) | Partial |
| verify-ssh-target.ts | SSH target validation | Yes (via AIShell Guard) | Unknown |
| pre-bash-no-heredoc.ts | No file-writing heredocs | Yes | Unknown |
| pre-bash-type-check.ts | Bash type safety | Unknown | Unknown |
| pre-bash-git-commit.ts | Secret scanning (ggshield) | Yes | Unknown |
| pre-bash-protected-branch-commit.ts | LAW 8 (no main commits) | Yes | Unknown |
| pre-bash-destructive-git.ts | No destructive git | Yes (FAIL CLOSED) | **No bypass** |
| pre-bash-no-cd-git-chain.ts | No cd && git chains | Yes | Unknown |
| pre-litellm-self-surgery.ts | LAW 15 (no self-surgery) | Yes (exit 2) | Unknown |
| pre-python3-blocker.ts | No direct python3 | Yes | Unknown |
| pre-private-repos.ts | LAW 12 (private repos) | Yes | Unknown |
| pre-skill-enforcer.ts | Skills-First (regex) | Yes | Yes |

### Glob/Grep Matcher
| Hook | Enforces | Blocks? | Subagent Bypass? |
|------|----------|---------|-----------------|
| pre-qmd-first.ts | LAW 10 (search OB first) | Yes | Yes |
| enforce-skill-usage.ts | Skills-First (fuzzy) | Yes (Glob/Grep on indexed) | Yes |

### Wildcard (*) Matcher (all tools)
| Hook | Enforces | Blocks? | Subagent Bypass? |
|------|----------|---------|-----------------|
| pre-mcp2cli-enforcer.ts | mcp2cli over direct MCP | Yes | Unknown |
| pre-communication.ts | LAW 2 (use AskUserQuestion) | Yes | Unknown |

### AskUserQuestion Matcher
| Hook | Enforces | Blocks? | Subagent Bypass? |
|------|----------|---------|-----------------|
| pre-ask-search-ob.ts | LAW 10 (search OB before asking) | Yes | Unknown |

### UserPromptSubmit Matcher
| Hook | Enforces | Blocks? |
|------|----------|---------|
| intent-skill-router.ts | Soft skill routing | Never blocks (inject only) |
| law2-option-reminder.ts | LAW 2 reminder | Never blocks |

## Post-Tool Hooks

| Hook | Matcher | Purpose | Blocks? |
|------|---------|---------|---------|
| post-infra-doc-reminder.ts | Bash | Doc update reminder after SSH | No |
| post-skill-execution-reminder.ts | Skill | Reminder to execute workflow | No |
| post-document-changes.ts | Write, Edit | Doc update reminder | No |
| post-bash-auto-fix.ts | Write, Edit | Auto-patches #!/bin/bash | No (auto-fix) |
| post-auto-format.ts | Write, Edit | Auto-formatting | No |
| post-init-inject-laws.ts | Write | Inject LAWs into new files | No |

## Known Issues

1. **pre-lsp-first.ts** -- Wrong input format. Reads `tool`/`params`/`toolHistory`, CC sends `toolName`/`toolInput`/`recentMessages`. Never fires.
2. **pre-backup-verify.ts** -- Only warns, never blocks. Name implies enforcement.
3. **security-validator.ts curl path** -- Exits 0 for curl/wget, just logs to stderr. Not a gate.
4. **Two skill enforcers** -- pre-skill-enforcer.ts (regex) and enforce-skill-usage.ts (fuzzy) overlap.
5. **pre-qmd-first.ts bypass** -- Grep patterns >40 chars skip LAW 10 check.
6. **pre-implementation.ts LAW 5** -- Trivially satisfied by generic explanation text.
7. **Universal subagent bypass** -- All hooks except pre-bash-destructive-git.ts and security-validator.ts (tiers 1-2) let subagents through.
