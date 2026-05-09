---
name: explain-before-doing
description: Automatically enforce explanation-before-action for ALL file operations. Triggers when about to modify files, create files, run scripts, or make ANY code changes. Blocks Write, Edit, NotebookEdit, and Bash operations until user receives explanation of WHAT, WHY, and SCOPE. Examples <example>User asks 'Add error handling to all handlers' → Trigger detected (multiple file modifications)</example> <example>User says 'Create new utility module' → Trigger detected (file creation)</example> <example>User requests 'Fix the imports' → Trigger detected (code modification)</example> Pauses when user says 'pause explanations' or enables auto-accept mode.
---

# 🚨 MANDATORY INVOCATION REQUIREMENT 🚨

**BEFORE YOU USE THESE TOOLS, YOU MUST INVOKE THIS SKILL FIRST:**

- `Write` tool
- `Edit` tool
- `NotebookEdit` tool
- `Bash` tool (when running scripts in `scripts/` directory)
- Any file creation/modification/deletion operation

**HOW TO INVOKE:**
Call the Skill tool with command "explain-before-doing" BEFORE using any of the tools listed above.

**THIS IS NOT OPTIONAL. THIS IS A HARD BLOCKER. YOU CANNOT USE WRITE/EDIT WITHOUT INVOKING THIS SKILL FIRST.**

---

# Explain Before Doing Skill

## What This Skill Does

When invoked, this skill requires you to provide a complete explanation that includes:

1. **WHAT** - Describe the operation you're about to perform
2. **WHY** - Explain why this change is necessary
3. **SCOPE** - Show what will be affected (file count, line count)
4. **APPROVAL** - Wait for user confirmation or give them chance to abort

**The Rule:** 1 file or 20 files, 2 lines or complete rewrite - ALWAYS explain first.

## Required Explanation Pattern

```
I need to [WHAT YOU'RE DOING]

The problem:
- [WHY THIS IS BROKEN/NEEDED]

My plan:
1. [STEP 1]
2. [STEP 2]
3. [STEP 3]

Files affected:
- file1.py
- file2.py
- (X more...)

Should I proceed?
```

## When This Applies

This skill MUST be invoked for:

- **ALL file modifications** (Edit, Write, NotebookEdit tools)
- **Single line changes** (even changing 1 character)
- **Complete file rewrites** (replacing entire files)
- **Batch operations** (affecting multiple files)
- **Script execution** (running scripts that modify files)
- **Migrations/refactors** (database or code changes)
- **File creation/deletion** (new files or removing files)
- **ANY code change operation whatsoever**

## Example: Good vs Bad

### ❌ BAD - Just doing stuff without explanation:
```
[Immediately uses Edit tool to modify 50 files]
✅ Fixed 50 files!
```

### ✅ GOOD - Explain first, then execute:
```
I need to fix import placement issues in 17 files.

The problem:
- Migration script inserted imports in the middle of multi-line imports
- This breaks Python syntax and Black cannot parse these files

My plan:
1. Read each of the 17 affected files
2. Locate the misplaced state import
3. Move it after all import blocks complete
4. Verify syntax with Black

Files affected:
- allowed_users_handler.py
- channel_creation/user_source_selector.py
- (15 more...)

Should I proceed?
```

## Key Principles

- **Explain the WHY** - Don't just say "fixing imports", explain WHY they're broken
- **Show the SCOPE** - How many files? What exactly will change?
- **Give user control** - Let them say "no wait, do it differently"
- **Save context** - Clear explanation means user understands without reading 50 tool calls

## Benefits

1. **Saves context** - User understands from explanation, not from reading all tool calls
2. **Prevents mistakes** - User can stop you if approach is wrong
3. **Builds trust** - Shows you're thoughtful, not just rushing
4. **Better outcomes** - User might suggest a better approach you didn't consider

## Pause/Resume Control

Users can temporarily disable this skill when they need rapid iteration.

### Pause Commands
- "Pause explanations"
- "Don't ask for now"
- "Skip explanations temporarily"
- "Auto-approve for this session"

### Resume Commands
- "Resume explanations"
- "Start asking again"
- "Re-enable explanations"

### Auto-Accept Mode
If user enables auto-accept mode in Claude Code:
- Skill automatically pauses
- No explanations required during auto-accept period
- Automatically resumes when auto-accept is disabled

**Note:** Pause state does NOT persist across sessions - skill re-engages automatically in new conversations.

## Exceptions (When to Skip Explanation)

Skip explanation ONLY when:
- Continuing an already-approved plan (same file, same type of change)
- User has paused explanations via "pause explanations" command
- Auto-accept mode is enabled

### NEVER Skip For:
- ❌ "Single file edits" - ALWAYS explain, even for 1 file
- ❌ "Small changes" - ALWAYS explain, even for 2 lines
- ❌ User said "fix it" - STILL explain what you're going to do first
- ❌ "It's obvious" - Still explain it
- ❌ "Just a quick change" - Still explain it

## Why This Matters

This skill enforces Constitutional Law #1 from the global CLAUDE.md configuration. The law exists because:

1. User needs to understand what's happening without reading verbose tool output
2. User can catch mistakes before they happen
3. User might have a better approach you haven't considered
4. Transparency builds trust and improves collaboration

**Remember: It's ALWAYS better when checking first. User has stated this explicitly.**
