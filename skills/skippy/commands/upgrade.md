---
name: skippy:upgrade
description: Upgrade skippy-agentspace to latest version preserving customizations
---

<objective>
Pull the latest skippy-agentspace changes, re-install all skills and hooks, verify the result, and report what changed. Detect and surface any conflicts between upstream changes and local customizations.

Handles the full upgrade lifecycle so the user does not need to run individual commands.
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>

## 1. Pre-Upgrade Snapshot

Capture current state before making any changes:

- Run `bash tools/install.sh` (no args) and capture the status table output
- Count hooks in `~/.claude/settings.json` (count entries in the hooks arrays)
- Run `git status` to detect any locally modified tracked files
- Record the current HEAD commit: `git rev-parse HEAD`

Store all snapshot data for comparison in step 4.

## 2. Pull Latest

From the repo root:

```bash
git pull origin main
```

Or pull from the current branch if not on main. After pull:

- Report the number of new commits: `git log --oneline <old-HEAD>..HEAD`
- If the pull fails due to conflicts, report the conflicting files and stop -- do not force-resolve

## 3. Re-Install

Run both install steps:

```bash
bash tools/install.sh --all
bash skills/core/hooks/install-hooks.sh
```

Both are idempotent. Capture their output for the upgrade report.

## 4. Verify

Run the health check:

```bash
bash tools/verify.sh
```

Compare post-upgrade state to the pre-upgrade snapshot:

- List any new skills that appeared (in repo but not in pre-upgrade snapshot)
- List any skills that were removed upstream
- List any hook changes (count difference)
- Report verify.sh results -- all PASS is clean, any FAIL needs attention

**Open Brain integration check:**
- Verify OB hooks still registered in settings.json (3/3)
- Verify `OPEN_BRAIN_AGENT_TOKEN` still set
- Verify PAI Skills symlinks (session-wrap, capture-session, brain, session-start) point to SAS, not stale copies
- If `install.sh --all` replaced symlinks with copies, fix them back to symlinks
- Report OB integration status in the upgrade summary

## 5. Handle Customizations

Check `git status` after the pull for modified tracked files:

- If no modifications: report clean upgrade
- If modifications exist: list the files, show `git diff` for each, and suggest resolution options:
  - **Keep upstream:** `git checkout -- <file>` (discard local changes)
  - **Keep local:** `git stash` before pull, `git stash pop` after (reapply local changes)
  - **Manual merge:** review the diff and edit manually

Do not auto-resolve conflicts. Present the options and let the user decide.

</process>
