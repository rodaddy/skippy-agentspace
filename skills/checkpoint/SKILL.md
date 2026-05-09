---
name: checkpoint
description: Generate a compact resume prompt before clearing/compacting context. Analyzes current session state and outputs a copy-paste-ready first message to continue seamlessly.
triggers:
  - /checkpoint
  - save state
  - save my state
  - before I clear
  - give me a resume prompt
  - checkpoint this
  - save progress
---

# Checkpoint - Session State Generator

Generate a **compact, copy-paste-ready first message** that captures current session state so the user can resume seamlessly after `/clear` or `/compact`.

## What To Analyze

Scan the current conversation for:

1. **Project Context**
   - Working directory / project name
   - What we're building or fixing
   - Current phase or milestone

2. **Task State**
   - Check TaskList for pending/in-progress tasks
   - What was just completed
   - What's next

3. **Infrastructure State** (if applicable)
   - Servers, containers, services
   - What's running vs needs setup
   - Key endpoints, ports, IPs

4. **Key Files**
   - Files we've been editing
   - Config files that matter
   - Credentials location (NOT the values)

5. **Blockers or Context**
   - Any decisions made
   - Approaches chosen
   - Things to NOT do (learned the hard way)

## Output Format

Generate a markdown block the user can copy-paste as their first message:

```markdown
## Continue: [Project Name] - [Phase/Task]

### Context
[1-2 sentences: what we're doing and why]

### Current State
| Component | Status | Notes |
|-----------|--------|-------|
[Compact table - only what's relevant]

### Completed This Session
- [Bullet list of what got done]

### Next Action
[Single, specific next step - be precise]

### Key Files
- `path/to/file` - [why it matters]

### Credentials
- All creds in [location] (e.g., `.env` file at project root)

### Quick Commands
```bash
[Any SSH, run, or test commands that will be needed]
```
```

## Rules

1. **Be compact** - This replaces reading 1000+ lines of docs. Every line must earn its place.
2. **Be specific** - "Install SiYuan" not "Continue with infrastructure"
3. **Include state, not history** - What IS, not what WAS
4. **Infrastructure as table** - Scannable at a glance
5. **One next action** - Don't list 5 things, list THE thing
6. **No credentials in output** - Point to where they live
7. **Include quick commands** - SSH commands, run scripts, etc. that will be needed immediately

## Example Output

```markdown
## Continue: Clawdbot Second Brain - Phase 2

### Context
Building AI-powered second brain. Phase 1 (infrastructure) complete. Now implementing classification pipeline skills.

### Current State
| CTID | Service | IP | Status |
|------|---------|-----|--------|
| 200 | postgres + pgvector | <DB_IP> | ✅ Running |
| 203 | siyuan | <YOUR_IP> | ❌ Needs install |
| 204 | clawdbot | <LITELLM_IP> | ✅ Gateway running |

### Completed This Session
- Verified all infrastructure state
- Created task list for Phase 2

### Next Action
Install SiYuan on LXC 203 (<YOUR_IP>) - prerequisite for store-siyuan skill

### Key Files
- `specs/CLAWDBOT-SECOND-BRAIN-SPEC.md` - Full architecture
- `.env` - All credentials
- `clawdbot/skills/` - Skill pattern examples

### Credentials
- All in `.env` at project root

### Quick Commands
```bash
ssh root@<YOUR_IP>  # siyuan LXC
ssh root@<LITELLM_IP>  # clawdbot gateway
```
```

## After Generating

1. **Output to terminal FIRST (MANDATORY):** Print the full checkpoint block directly in the conversation. This is the primary deliverable — the user needs to see it and copy-paste it.
2. **Save to file (backup):** Save to the centralized reports location: `Development/.reports/<project-name>/checkpoint.md`. Derive project name from CWD relative to Development root. Read the file first before writing (tool requirement).
3. **Confirm**: Tell the user:
   > Checkpoint saved to `Development/.reports/<project-name>/checkpoint.md`
   >
   > Next session, paste the above as your first message or run:
   > ```bash
   > cat <DEV_DIR>/.reports/<project-name>/checkpoint.md | pbcopy
   > ```

**Note:** If the checkpoint file already exists, read it first then overwrite.

**CRITICAL:** Never only write to file without also displaying in the conversation. The terminal output IS the deliverable.
