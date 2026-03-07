# Phase 7: Hook Installation - Research

**Researched:** 2026-03-07
**Domain:** Claude Code settings.json hook management -- manifest, install, uninstall, idempotency, backup
**Confidence:** HIGH

## Summary

Phase 7 is about building a hook manifest, installer, and uninstaller that safely merge PAI hooks into Claude Code's `~/.claude/settings.json` without destroying existing hooks from GSD, OMC, or other systems. The settings.json hooks schema is well-documented and the existing hook ecosystem (currently 50+ hooks across 7 event types) provides clear patterns for the hook contract, shared utilities, and JSON I/O format.

The current settings.json has hooks registered from three distinct path namespaces: `~/.claude/hooks/` (PAI law-enforcement and safety), `~/.config/pai/hooks/` (PAI infrastructure), and GSD/OMC hooks (node scripts at `~/.claude/hooks/gsd-*.js` and OMC plugin hooks). Phase 7 creates 15 portable hook scripts under `skills/core/hooks/` that enforce all 15 LAWs, plus the tooling (manifest, installer, uninstaller) to register them in settings.json. Ten hooks are ports of existing scripts; five are new implementations for LAWs currently marked "Manual (Phase 7 gap)."

The critical technical challenge is the JSON merge operation -- settings.json hooks are nested arrays of objects grouped by event type and matcher pattern, and the installer must add new matcher groups without modifying existing ones. The user has decided on a multi-backend JSON approach (bun preferred, python3/uv fallback, jq last resort) with a shell script orchestrating the flow.

**Primary recommendation:** Build the manifest first (single source of truth), then the hook scripts (10 ports + 5 new), then the installer/uninstaller. Use the existing `shared/` utility pattern from `~/.claude/hooks/law-enforcement/shared/` as the template for the portable `skills/core/hooks/lib/` shared library.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- PAI hooks identified by command path containing `skills/core/hooks/`
- Uninstaller uses double-check: path substring match AND manifest cross-reference
- Only hooks matching both criteria are removed -- belt and suspenders safety
- GSD hooks use `~/.claude/get-shit-done/`, OMC hooks use `plugins/cache/omc/` -- no collision risk
- All hook scripts live under `skills/core/hooks/` in the repo
- Written in TypeScript, run via `bun`
- Shared context utility at `skills/core/hooks/lib/context.ts` -- injects active persona + project path into hook context
- Each hook imports the shared utility for consistent contract
- This overrides the project constraint "no TypeScript/Node dependencies" -- bun is already required
- All 15 LAWs get hook scripts under `skills/core/hooks/`
- 10 existing hooks ported to TypeScript + wrapper pattern -- not copied verbatim
- 5 missing hooks (LAWs 6, 10, 12, 13, 14) written fresh
- After installation, PAI hooks are self-contained -- no dependency on GSD or PAI hook paths
- Manifest declares all 15 hooks with event type, matcher, and command path
- Markdown-first installer (INSTALL.md designed for AI agents to follow)
- Script secondary (convenience shell script wraps same operations for humans)
- Multi-backend JSON: bun preferred, python3/uv fallback, jq last resort
- Prerequisites validated first (Phase 10 prereqs.sh), then installer uses available JSON tool
- Shell script handles flow: backup, validation, reporting. Delegates JSON merge to detected backend
- settings.json backed up before any modification (HOOK-05)
- Timestamped backup: `settings.json.backup-YYYY-MM-DD-HHMMSS`
- Running installer twice produces same result (HOOK-04)
- Uninstaller only removes hooks matching both path convention AND manifest entry (HOOK-03)
- Hook manifest is JSON at `skills/core/hooks/manifest.json`
- Manifest declares: event type, matcher pattern, command path, description, LAW reference

### Claude's Discretion
- Exact manifest JSON schema (beyond required fields above)
- How to detect active persona in the shared context utility
- Specific jq/TypeScript/Python implementations for the JSON merge
- Hook script internal structure (beyond using shared context utility)
- Whether to split hooks into subdirectories by event type or keep flat

### Deferred Ideas (OUT OF SCOPE)
- Hook testing framework -- automated tests for hooks (run hook, check output)
- Hook hot-reload -- detect settings.json changes and reload without restart
- Per-project hook overrides -- allow project-level CLAUDE.md to disable specific LAW hooks
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| HOOK-01 | Hook manifest declares all hooks and their settings.json registrations | Manifest schema designed based on actual settings.json structure; all 15 LAWs mapped to event types and matchers |
| HOOK-02 | Hook installer merges into settings.json via jq without destroying existing hooks | Multi-backend JSON merge strategy researched; settings.json array-of-matcher-groups structure understood |
| HOOK-03 | Hook uninstaller cleanly removes only our hooks | Double-check identification strategy (path + manifest) researched; existing hook namespaces catalogued |
| HOOK-04 | Hook operations are idempotent (safe to re-run) | Idempotency requires checking command path existence before adding; dedup by command string |
| HOOK-05 | settings.json is backed up before any modification | Timestamped backup pattern established |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bun | 1.x (installed) | TypeScript runtime for hook scripts | Already required by project, matches existing hook ecosystem |
| jq | System | JSON manipulation fallback for installer | Standard CLI JSON tool, available on most systems |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| python3/uv | System | JSON manipulation fallback | When bun unavailable for installer JSON merge |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TypeScript hooks | Bash hooks | Bash hooks are simpler but can't import shared utilities or parse JSON natively |
| Multi-backend JSON | Bun-only | Bun-only is simpler but less portable for non-PAI users |

**No installation needed** -- all tools are already available in the environment.

## Architecture Patterns

### Recommended Project Structure
```
skills/core/hooks/
  manifest.json                  # Single source of truth for all hook registrations
  lib/
    context.ts                   # Shared utility: persona detection, project path
    types.ts                     # TypeScript interfaces for hook I/O
    feedback.ts                  # Violation message builder (port of feedback-builder.ts)
  law-01-never-assume.ts         # Per-LAW hook scripts (flat, not nested by event)
  law-02-checkbox-questions.ts
  ...
  law-15-no-litellm-self-surgery.ts
  install-hooks.sh               # Shell installer (human-facing)
  uninstall-hooks.sh             # Shell uninstaller
  INSTALL.md                     # Markdown installer (agent-facing)
```

### Pattern 1: Hook Script Contract
**What:** Every hook script reads JSON from stdin, outputs JSON to stdout, exits 0/2
**When to use:** All 15 LAW enforcement hooks
**Example:**
```typescript
// Source: Verified from Claude Code docs + existing hooks at ~/.claude/hooks/
#!/usr/bin/env bun

import { getContext } from "./lib/context.ts";
import { allowDecision, blockDecision, createViolation } from "./lib/feedback.ts";
import type { HookInput } from "./lib/types.ts";

async function main() {
  const input: HookInput = JSON.parse(await Bun.stdin.text());
  const ctx = getContext(); // persona, project path

  // Check tool name
  if (input.tool_name !== "Bash") {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Enforcement logic here...
  const command = (input.tool_input as any).command || "";

  if (violationDetected(command)) {
    console.log(JSON.stringify(blockDecision(
      createViolation({ law: "Law Name", lawNumber: N, ... })
    )));
    return;
  }

  console.log(JSON.stringify(allowDecision()));
}

try { await main(); }
catch { console.log(JSON.stringify(allowDecision())); } // fail open
```

### Pattern 2: Hook Input JSON Schema
**What:** The JSON that Claude Code sends to hooks on stdin
**When to use:** Understanding what data hooks have access to
```typescript
// Source: https://code.claude.com/docs/en/hooks
interface HookInput {
  // Common fields (all events)
  session_id: string;
  transcript_path: string;
  cwd: string;
  permission_mode: "default" | "plan" | "acceptEdits" | "dontAsk" | "bypassPermissions";
  hook_event_name: string;

  // PreToolUse / PostToolUse specific
  tool_name?: string;        // "Bash", "Write", "Edit", etc. -- this is what matcher filters on
  tool_input?: Record<string, unknown>;

  // PostToolUse specific
  tool_response?: Record<string, unknown>;

  // SessionStart specific
  source?: "startup" | "resume" | "clear" | "compact";
  model?: string;

  // Subagent fields (when inside a subagent)
  agent_id?: string;
  agent_type?: string;
}
```

**IMPORTANT NOTE on field naming:** The official Claude Code docs use `tool_name` and `tool_input` (snake_case), while some existing PAI hooks use `toolName` and `toolInput` (camelCase). The existing hooks at `~/.claude/hooks/law-enforcement/shared/types.ts` define `toolName` and `toolInput`, and these hooks work correctly. This suggests Claude Code may support both formats, or the camelCase hooks may have been written against an older version. **The portable hooks MUST use `tool_name` / `tool_input` (snake_case) per the current official documentation**, with a compatibility shim if needed.

### Pattern 3: Hook Output JSON Schema
**What:** The JSON hooks output to control Claude Code behavior
**When to use:** All PreToolUse hooks (blocking decisions)
```typescript
// Source: https://code.claude.com/docs/en/hooks

// PreToolUse output -- uses hookSpecificOutput
interface PreToolUseOutput {
  hookSpecificOutput: {
    hookEventName: "PreToolUse";
    permissionDecision: "allow" | "deny" | "ask";
    permissionDecisionReason?: string;
    updatedInput?: Record<string, unknown>;  // modify tool input before execution
    additionalContext?: string;              // inject context for Claude
  };
}

// PostToolUse / Stop / UserPromptSubmit -- uses top-level decision
interface TopLevelDecisionOutput {
  decision: "block";
  reason: string;
}

// Universal fields (any event)
interface UniversalOutput {
  continue?: boolean;       // false = stop Claude entirely
  stopReason?: string;      // message when continue=false
  suppressOutput?: boolean; // hide from verbose mode
  systemMessage?: string;   // warning to user
}
```

### Pattern 4: Settings.json Hooks Structure
**What:** How hooks are organized in settings.json
**When to use:** Understanding the merge target for installer
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",           // regex pattern
        "hooks": [                     // array of handlers
          {
            "type": "command",
            "command": "bun run path/to/hook.ts"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bun run another-hook.ts" },
          { "type": "command", "command": "bun run second-hook.ts", "timeout": 30 }
        ]
      },
      {
        "matcher": "*",              // wildcard -- matches all tools
        "hooks": [
          { "type": "command", "command": "bun run global-hook.ts", "async": true }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "bun run session-hook.ts" }
        ]
      }
    ]
  }
}
```

**Key structural insight:** Each event type contains an array of matcher groups. Each matcher group has a `matcher` string and a `hooks` array. Multiple matcher groups can have the same matcher (they are independent entries). The installer should add NEW matcher groups rather than merging into existing ones -- this avoids modifying other systems' hook entries.

### Pattern 5: Manifest Schema
**What:** The hook manifest declaring all registrations
**When to use:** Single source of truth for installer and uninstaller
```json
{
  "version": "1.0",
  "description": "PAI LAW enforcement hooks for Claude Code",
  "hooks": [
    {
      "id": "law-01",
      "law": 1,
      "name": "Never Assume",
      "description": "Block implementation on vague/ambiguous requests",
      "event": "PreToolUse",
      "matcher": "Write|Edit|Bash",
      "command": "bun run ${SKILL_DIR}/hooks/law-01-never-assume.ts",
      "blocking": true,
      "async": false
    },
    {
      "id": "law-07",
      "law": 7,
      "name": "Never Ancient Bash",
      "description": "Block #!/bin/bash in Write/Edit operations",
      "event": "PreToolUse",
      "matcher": "Write|Edit",
      "command": "bun run ${SKILL_DIR}/hooks/law-07-never-ancient-bash.ts",
      "blocking": true,
      "async": false
    }
  ]
}
```

### Pattern 6: JSON Merge Strategy
**What:** How the installer adds hooks without destroying existing ones
**When to use:** The core of HOOK-02
```
For each hook in manifest:
  1. Read settings.json
  2. Navigate to hooks[event_type] array
  3. Check if a matcher group with our command already exists (idempotency)
  4. If not found: append a new matcher group object with our matcher + hooks array
  5. If found: skip (already installed)
  6. Write updated settings.json
```

**The installer must NOT:**
- Merge hooks into existing matcher groups (those belong to GSD/OMC/other)
- Remove or modify any existing entries
- Reorder existing entries

**The installer SHOULD:**
- Add PAI hooks as distinct matcher groups with their own entries
- Group multiple hooks with the same event+matcher into a single matcher group for efficiency
- Use the `skills/core/hooks/` path prefix as the ownership marker

### Anti-Patterns to Avoid
- **Merging into existing matcher groups:** Each system (GSD, OMC, PAI) should have its own matcher groups. Don't append PAI hook commands into a GSD matcher group.
- **Deep-cloning the entire settings.json:** Only modify the `hooks` key. Leave all other settings untouched.
- **Using `sed` for JSON manipulation:** Never. Use proper JSON parsers (jq, bun, python).
- **Hardcoding absolute paths in manifest:** Use `${SKILL_DIR}` or relative references that the installer resolves at install time.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parsing/manipulation | Custom string parsing | jq / Bun JSON API / python json module | JSON has edge cases (escaping, nested structures, unicode) that string ops will miss |
| Backup file naming | Custom timestamp logic | `date +%Y-%m-%d-%H%M%S` | Standardized, sortable format |
| Hook I/O types | Custom type definitions per hook | Shared types.ts module | Consistency across 15 hooks, single point of update |
| Violation message formatting | Inline string building per hook | Shared feedback.ts builder | Consistent LAW violation UX across all hooks |
| Path resolution | Hardcoded paths | Environment variables (`$CLAUDE_PROJECT_DIR`, `$HOME`) | Portability across different machine setups |

**Key insight:** The existing PAI hooks at `~/.claude/hooks/law-enforcement/shared/` already solved the shared utility problem. Port this pattern to `skills/core/hooks/lib/` -- don't reinvent it.

## Common Pitfalls

### Pitfall 1: Field Name Case Mismatch
**What goes wrong:** Hooks use `toolName` (camelCase) but Claude Code sends `tool_name` (snake_case)
**Why it happens:** Older hook implementations used camelCase; the official docs specify snake_case
**How to avoid:** Use `tool_name` and `tool_input` per official docs. Add a compatibility layer that checks both formats.
**Warning signs:** Hooks silently fail to match tool names or extract tool input

### Pitfall 2: Destructive JSON Write
**What goes wrong:** Installer overwrites non-hook settings in settings.json (permissions, env, model, plugins)
**Why it happens:** Reading JSON, modifying the hooks key, but writing only the hooks key back -- or serialization changes formatting
**How to avoid:** Read full JSON, modify only `hooks` property, write full JSON back. Use `JSON.stringify(obj, null, 2)` to maintain readable formatting.
**Warning signs:** Missing permissions, env vars, or plugin config after hook install

### Pitfall 3: Matcher Group Collision
**What goes wrong:** PAI hooks get appended into a GSD matcher group, so uninstaller can't cleanly separate them
**Why it happens:** Installer finds existing `"matcher": "Bash"` group and appends to its hooks array instead of creating a new group
**How to avoid:** Always create new matcher groups for PAI hooks. Never modify existing matcher groups.
**Warning signs:** After uninstall, some GSD hooks are missing or the GSD matcher group has been modified

### Pitfall 4: Non-Idempotent Install
**What goes wrong:** Running installer twice creates duplicate hook entries
**Why it happens:** Installer appends without checking if the hook command already exists
**How to avoid:** Before adding, scan all matcher groups in the event type for any hooks with commands containing `skills/core/hooks/`. If found, skip.
**Warning signs:** Same hook running twice per event, performance degradation

### Pitfall 5: Path Resolution at Install Time
**What goes wrong:** Hook commands use relative paths that break when Claude Code runs them from different working directories
**Why it happens:** Manifest uses `${SKILL_DIR}` but installer doesn't resolve it to an absolute path
**How to avoid:** The installer MUST resolve all path variables to absolute paths at install time. Claude Code hooks run from the project directory, not the skill directory.
**Warning signs:** "command not found" errors when hooks fire

### Pitfall 6: Backup Race Condition
**What goes wrong:** Two rapid installs in the same second create backups with identical timestamps, and one gets overwritten
**Why it happens:** Timestamp only resolves to seconds
**How to avoid:** Include seconds in the timestamp format. If backup file already exists, append a numeric suffix.
**Warning signs:** Lost backup when reverting

### Pitfall 7: Exit Code Handling
**What goes wrong:** Hook errors crash and produce non-zero exit codes other than 2, silently failing
**Why it happens:** Unhandled exceptions in TypeScript hooks
**How to avoid:** Every hook must have a top-level try/catch that outputs `allowDecision()` and exits 0 on any error (fail open). Only exit 2 for intentional blocking.
**Warning signs:** Hooks appear to not work, but are actually crashing silently

## Code Examples

### Hook Manifest (Complete)

Based on analysis of all 15 LAW files and their enforcement metadata:

```json
// Source: Analysis of skills/core/references/laws/*.md enforcement fields
{
  "version": "1.0",
  "description": "PAI LAW enforcement hooks",
  "path_prefix": "skills/core/hooks",
  "identifier": "skills/core/hooks/",
  "hooks": [
    {
      "id": "law-01", "law": 1, "name": "Never Assume",
      "event": "PreToolUse", "matcher": "Write|Edit|Bash",
      "script": "law-01-never-assume.ts", "blocking": true
    },
    {
      "id": "law-02", "law": 2, "name": "Checkbox Questions",
      "event": "PreToolUse", "matcher": "*",
      "script": "law-02-checkbox-questions.ts", "blocking": true
    },
    {
      "id": "law-03", "law": 3, "name": "Pro/Con Analysis",
      "event": "PreToolUse", "matcher": "Write|Edit|Bash",
      "script": "law-03-procon-analysis.ts", "blocking": true
    },
    {
      "id": "law-04", "law": 4, "name": "Critical Thinking",
      "event": "PreToolUse", "matcher": "Write|Edit|Bash",
      "script": "law-04-critical-thinking.ts", "blocking": true
    },
    {
      "id": "law-05", "law": 5, "name": "Explain Before Doing",
      "event": "PreToolUse", "matcher": "Write|Edit|Bash",
      "script": "law-05-explain-before-doing.ts", "blocking": true
    },
    {
      "id": "law-06", "law": 6, "name": "Interview-First",
      "event": "PreToolUse", "matcher": "Write|Edit|Bash",
      "script": "law-06-interview-first.ts", "blocking": true
    },
    {
      "id": "law-07", "law": 7, "name": "Never Ancient Bash",
      "event": "PreToolUse", "matcher": "Write|Edit",
      "script": "law-07-never-ancient-bash.ts", "blocking": true
    },
    {
      "id": "law-08", "law": 8, "name": "Never Work on Main",
      "event": "PreToolUse", "matcher": "Bash",
      "script": "law-08-never-work-on-main.ts", "blocking": true
    },
    {
      "id": "law-09", "law": 9, "name": "File Size Limits",
      "event": "PreToolUse", "matcher": "Write|Edit",
      "script": "law-09-file-size-limits.ts", "blocking": true
    },
    {
      "id": "law-10", "law": 10, "name": "qmd First",
      "event": "PreToolUse", "matcher": "Read|Glob|Grep",
      "script": "law-10-qmd-first.ts", "blocking": true
    },
    {
      "id": "law-11", "law": 11, "name": "No Secrets in Git",
      "event": "PreToolUse", "matcher": "Bash",
      "script": "law-11-no-secrets-in-git.ts", "blocking": true
    },
    {
      "id": "law-12", "law": 12, "name": "Private Repos Default",
      "event": "PreToolUse", "matcher": "Bash",
      "script": "law-12-private-repos-default.ts", "blocking": true
    },
    {
      "id": "law-13", "law": 13, "name": "No Silent Autopilot",
      "event": "UserPromptSubmit", "matcher": null,
      "script": "law-13-no-silent-autopilot.ts", "blocking": true
    },
    {
      "id": "law-14", "law": 14, "name": "Network Share Protocol",
      "event": "PreToolUse", "matcher": "Bash",
      "script": "law-14-network-share-protocol.ts", "blocking": true
    },
    {
      "id": "law-15", "law": 15, "name": "No LiteLLM Self-Surgery",
      "event": "PreToolUse", "matcher": "Bash",
      "script": "law-15-no-litellm-self-surgery.ts", "blocking": true
    }
  ]
}
```

### Shared Context Utility
```typescript
// Source: Based on existing ~/.config/pai/hooks/lib/pai-paths.ts pattern
// skills/core/hooks/lib/context.ts

export interface HookContext {
  persona: string;       // "skippy" | "bob" | "clarisa" | "april"
  projectDir: string;    // Current project directory
  skillDir: string;      // Path to skills/core/hooks/
}

export function getContext(): HookContext {
  // Detect active persona from environment or session file
  const persona = process.env.PAI_PERSONA
    || detectPersonaFromSession()
    || "skippy";  // default

  return {
    persona,
    projectDir: process.env.CLAUDE_PROJECT_DIR || process.cwd(),
    skillDir: import.meta.dir,  // Bun: directory of current file
  };
}

function detectPersonaFromSession(): string | null {
  try {
    const sessionFile = `${process.env.HOME}/.config/pai/.current-session`;
    const data = JSON.parse(require("fs").readFileSync(sessionFile, "utf-8"));
    return data.persona || null;
  } catch {
    return null;
  }
}
```

### Install Script Core Logic
```bash
#!/usr/bin/env bash
# Source: Pattern from tools/install.sh + CONTEXT.md decisions

SETTINGS="$HOME/.claude/settings.json"
BACKUP_DIR="$HOME/.claude/backups"
MANIFEST="$(dirname "$0")/manifest.json"

# Step 1: Backup
backup_settings() {
  mkdir -p "$BACKUP_DIR"
  local ts
  ts=$(date +%Y-%m-%d-%H%M%S)
  cp "$SETTINGS" "$BACKUP_DIR/settings.json.backup-$ts"
  echo "Backup: $BACKUP_DIR/settings.json.backup-$ts"
}

# Step 2: Detect JSON backend
detect_backend() {
  if command -v bun &>/dev/null; then echo "bun"
  elif command -v python3 &>/dev/null; then echo "python3"
  elif command -v jq &>/dev/null; then echo "jq"
  else echo "none"; fi
}

# Step 3: Merge hooks (delegates to backend-specific helper)
merge_hooks() {
  local backend
  backend=$(detect_backend)
  case "$backend" in
    bun)     bun run "$(dirname "$0")/lib/merge.ts" "$SETTINGS" "$MANIFEST" ;;
    python3) python3 "$(dirname "$0")/lib/merge.py" "$SETTINGS" "$MANIFEST" ;;
    jq)      bash "$(dirname "$0")/lib/merge-jq.sh" "$SETTINGS" "$MANIFEST" ;;
    none)    echo "ERROR: No JSON tool found (need bun, python3, or jq)"; exit 1 ;;
  esac
}
```

### Uninstall Script Core Logic
```bash
#!/usr/bin/env bash
# Double-check removal: path substring AND manifest cross-reference

remove_hooks() {
  local backend
  backend=$(detect_backend)
  # The removal script:
  # 1. Reads settings.json
  # 2. For each event type, filters out matcher groups where ALL hooks
  #    have commands containing "skills/core/hooks/" AND the command
  #    matches an entry in manifest.json
  # 3. Writes the filtered settings.json back
}
```

## LAW-to-Hook Mapping (Complete)

All 15 LAWs mapped to their hook event types, matchers, and implementation status:

| LAW | Name | Event | Matcher | Status | Source Hook |
|-----|------|-------|---------|--------|-------------|
| 1 | Never Assume | PreToolUse | Write\|Edit\|Bash | Port | pre-implementation.ts |
| 2 | Checkbox Questions | PreToolUse | * | Port | pre-communication.ts |
| 3 | Pro/Con Analysis | PreToolUse | Write\|Edit\|Bash | Port | pre-decision.ts |
| 4 | Critical Thinking | PreToolUse | Write\|Edit\|Bash | Port | pre-decision.ts |
| 5 | Explain Before Doing | PreToolUse | Write\|Edit\|Bash | Port | pre-implementation.ts |
| 6 | Interview-First | PreToolUse | Write\|Edit\|Bash | **NEW** | -- |
| 7 | Never Ancient Bash | PreToolUse | Write\|Edit | Port | pre-ancient-bash-blocker.ts |
| 8 | Never Work on Main | PreToolUse | Bash | Port | pre-bash-protected-branch-commit.ts |
| 9 | File Size Limits | PreToolUse | Write\|Edit | Port | pre-edit-file-size.ts |
| 10 | qmd First | PreToolUse | Read\|Glob\|Grep | **NEW** | -- |
| 11 | No Secrets in Git | PreToolUse | Bash | Port | (ggshield; hook adds Claude-side check) |
| 12 | Private Repos Default | PreToolUse | Bash | **NEW** | -- |
| 13 | No Silent Autopilot | UserPromptSubmit | (none) | **NEW** | -- |
| 14 | Network Share Protocol | PreToolUse | Bash | **NEW** | -- |
| 15 | No LiteLLM Self-Surgery | PreToolUse | Bash | Port | pre-litellm-self-surgery.ts |

**Note on LAWs 1/5 and 3/4:** LAWs 1+5 currently share `pre-implementation.ts`, and LAWs 3+4 share `pre-decision.ts`. In the portable version, each LAW gets its own script file. The shared logic can be extracted into `lib/` utilities. This makes the manifest 1:1 with LAWs and simplifies the uninstaller.

**Note on LAW 13:** This is the only hook using `UserPromptSubmit` event type, which does not support matchers. All other hooks use `PreToolUse`.

**Note on LAW 11:** ggshield handles the git hook side. The Claude Code hook adds a pre-check before `git commit` or `git push` commands, warning about potential secrets in staged files. It's complementary to ggshield, not a replacement.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `toolName` / `toolInput` (camelCase) | `tool_name` / `tool_input` (snake_case) | Claude Code hooks v2 (2025-2026) | Existing hooks may use old format -- new hooks MUST use snake_case |
| Exit code only (0 = allow, 2 = block) | JSON output with `hookSpecificOutput` | Claude Code hooks v2 | JSON gives finer control: allow/deny/ask, updatedInput, additionalContext |
| Command hooks only | Command + HTTP + Prompt + Agent hooks | 2026 | New hook types available but command hooks are sufficient for LAW enforcement |
| No matcher on some events | Matchers are regex patterns | Current | `Write\|Edit` syntax works; `*` or omitted matcher matches everything |
| Hooks run sequentially | Hooks within a matcher group run in parallel | Current | Identical commands are auto-deduplicated by Claude Code |

**Deprecated/outdated:**
- Direct JSON output without `hookSpecificOutput` wrapper for PreToolUse -- the existing hooks at `~/.claude/hooks/` use the older flat format (`permissionDecision` at top level). The official docs show both `hookSpecificOutput` wrapper and flat format are supported, but the wrapper is the documented standard.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual validation (no automated test framework in project) |
| Config file | none -- see Wave 0 |
| Quick run command | `bash tools/validate-hooks.sh` (to be created) |
| Full suite command | `bash tools/validate-hooks.sh --full` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOOK-01 | Manifest declares all 15 hooks | smoke | `jq '.hooks | length' skills/core/hooks/manifest.json` (expect 15) | Wave 0 |
| HOOK-02 | Installer merges without destroying | integration | Install on test settings.json, verify GSD hooks preserved | Wave 0 |
| HOOK-03 | Uninstaller removes only PAI hooks | integration | Uninstall, verify GSD hooks intact, PAI hooks gone | Wave 0 |
| HOOK-04 | Idempotent install | integration | Install twice, diff settings.json (expect identical) | Wave 0 |
| HOOK-05 | Backup created | smoke | Check backup file exists after install | Wave 0 |

### Sampling Rate
- **Per task commit:** Manual verification of modified files
- **Per wave merge:** Run full validation script
- **Phase gate:** All 5 HOOK requirements verified before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tools/validate-hooks.sh` -- verification script for all HOOK requirements
- [ ] Test fixture: sample settings.json with GSD/OMC hooks for integration testing

## Open Questions

1. **snake_case vs camelCase field names**
   - What we know: Official docs use `tool_name` / `tool_input`. Existing PAI hooks use `toolName` / `toolInput` and work fine.
   - What's unclear: Whether Claude Code normalizes both formats or if the existing hooks work by coincidence
   - Recommendation: Use snake_case in new hooks per official docs. Add a compatibility shim: `const toolName = input.tool_name || (input as any).toolName`

2. **Flat vs hookSpecificOutput JSON format**
   - What we know: Existing hooks output `{ permissionDecision: "allow" }` at top level. Docs show `{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "allow" } }`.
   - What's unclear: Whether both formats are fully supported or if one is deprecated
   - Recommendation: Use `hookSpecificOutput` wrapper per official docs. The existing flat format may still work but isn't documented as the primary approach.

3. **Installer path resolution for `${SKILL_DIR}`**
   - What we know: The manifest uses relative script paths. The installer must resolve to absolute paths at install time.
   - What's unclear: Whether `import.meta.dir` (Bun) reliably resolves through symlinks (skills are symlinked into `~/.claude/skills/`)
   - Recommendation: Have the installer resolve the real path (following symlinks) and embed the absolute path in settings.json. This is what existing PAI hooks do -- all commands use absolute paths like `~/.claude/hooks/law-enforcement/pre-implementation.ts`.

## Sources

### Primary (HIGH confidence)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- Full schema, event types, JSON I/O, matchers, exit codes
- `~/.claude/settings.json` -- Current live configuration with 50+ hooks across 7 event types
- `~/.claude/hooks/law-enforcement/` -- 17 existing TypeScript hook scripts showing established patterns
- `~/.claude/hooks/safety/` -- 7 existing safety hook scripts
- `skills/core/references/laws/*.md` -- 15 LAW files with enforcement metadata
- `~/.config/pai/hooks/lib/` -- Existing shared utility library (pai-paths.ts, etc.)

### Secondary (MEDIUM confidence)
- `~/.claude/hooks/law-enforcement/shared/` -- types.ts, feedback-builder.ts, pattern-detection.ts patterns (working code, but may use older API format)
- WebSearch results on Claude Code hooks schema -- consistent with official docs

### Tertiary (LOW confidence)
- Field name format (snake_case vs camelCase) -- needs runtime verification that both work

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- bun/TypeScript is the established hook ecosystem, no new dependencies
- Architecture: HIGH -- existing hooks provide clear patterns, manifest schema follows settings.json structure
- Pitfalls: HIGH -- observed from real settings.json and existing hook implementations
- LAW mapping: HIGH -- derived directly from each LAW file's enforcement metadata
- JSON merge strategy: MEDIUM -- strategy is sound but multi-backend implementation has complexity risk

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (30 days -- Claude Code hooks API is stable)
