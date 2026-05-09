---
name: log
description: Toggle real-time session transcript logging to .session/ in CWD. Type /log to start, /log again to stop. Opens transcript in VS Code split view.
user_invocable: true
---

# /log -- Session Transcript Toggle

Toggle real-time markdown transcript of this Claude session.

## What It Does

- **Start:** Creates `.session/.active` flag -- the session-transcript hook begins appending every tool call and user prompt to `.session/transcript-<date>-<session>.md`
- **Stop:** Removes `.session/.active` flag -- hook goes dormant, no more writes

## Instructions

When the user invokes `/log`, do this:

1. Check if `.session/.active` exists in the current working directory
2. **If it exists (logging is ON):**
   - Remove `.session/.active`
   - List the transcript file(s) to get the actual filename
   - Tell the user: "Session logging stopped." and print the **full absolute path** to the transcript file (e.g. `<DEV_DIR>/my-project/.session/transcript-2026-04-06-abc123.md`)
3. **If it does NOT exist (logging is OFF):**
   - Create `.session/` directory if needed
   - Create `.session/.gitignore` with `*` if it doesn't exist
   - Create `.session/.active` (empty file)
   - List the transcript file(s) to get the actual filename that was/will be created
   - Tell the user: "Session logging started." and print the **full absolute path** to the transcript file
   - Suggest opening it in VS Code: `code <full-path>`

**CRITICAL:** Always print the full absolute path to the transcript file (e.g. `<DEV_DIR>/my-project/.session/transcript-2026-04-06-e13eed06.md`). Never use globs, relative paths, or `.session/transcript-...` shorthand -- those aren't clickable in terminals.

Do NOT use any external tools beyond Bash to check/create/remove the flag file. This is a simple toggle.
