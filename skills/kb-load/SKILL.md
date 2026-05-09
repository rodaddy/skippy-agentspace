---
name: kb-load
description: Load code knowledge base for a repository into context. AUTO-TRIGGERS on /load-kb command. USE WHEN user wants architecture context for a repo before working on it.
---

# kb-load - Load Code Knowledge Base

**Load indexed code KB into session context for architecture-aware development.**

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **LoadKB** | "/load-kb", "load kb", "load knowledge base" | `Workflows/LoadKB.md` |

## Usage

**Auto-detect from current directory:**
```
/load-kb
```

**Explicit repo name:**
```
/load-kb homelab-media-automation
/load-kb ai-second-brain
```

## Examples

**Example 1: Load KB for current repo**
```
User: /load-kb
→ Detects CWD is <DEV_DIR>/homelab-media-automation
→ Reads ~/.config/pai-private/knowledge/code/homelab-media-automation/architecture-v2.json
→ Shows: "Loaded homelab-media-automation KB: 7 decisions, 4 patterns, 3 integrations"
```

**Example 2: Load specific repo KB**
```
User: /load-kb ai-second-brain
→ Reads ~/.config/pai-private/knowledge/code/ai-second-brain/architecture-v2.json
→ Shows: "Loaded ai-second-brain KB: 1 decision, 1 pattern, 1 integration"
```

**Example 3: No KB found**
```
User: /load-kb some-repo
→ Checks ~/.config/pai-private/knowledge/code/some-repo/architecture-v2.json
→ Shows: "No KB found. Run: bun Tools/code-kb-extract-v2.ts /path/to/some-repo"
```

---

## What Gets Loaded

From `architecture-v2.json`:
- Architecture decisions (CRITICAL/HIGH/MEDIUM impact)
- Design patterns used in codebase
- External integrations and data flows
- Anti-patterns to avoid
- Best practices and code examples
- Technology stack metadata

---

## When to Use

**Use this skill when:**
- Starting work on an indexed repository
- Need architecture context before making changes
- Want to understand design patterns before coding
- Checking integrations before adding new ones
- Reviewing anti-patterns before refactoring

**Don't use if:**
- Already loaded KB this session (wastes context)
- Working on repo without indexed KB (extract first)
- Doing quick one-line fixes (overkill)

---

## Available KBs

Check what repos have indexed KBs:
```bash
ls -1 ~/.config/pai-private/knowledge/code/
```

Extract new KB:
```bash
bun Tools/code-kb-extract-v2.ts /path/to/repo
```

---

**Related Skills:**
- `kb-extraction` - Extract/update code KBs
