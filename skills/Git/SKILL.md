---
name: Git
description: Smart git operations and automation. USE WHEN create commit, write commit message, create PR, PR description, branch management, summarize changes, git diff analysis, or manage git workflow. Generates professional commits and PR descriptions using AI.
triggers:
  - /git
  - create commit
  - commit these changes
  - create PR
  - push changes
  - summarize changes
  - branch management
user-invocable: true
---

# Git -- Smart Version Control

AI-powered git operations using fabric patterns for commit messages, PR descriptions, and change analysis.

## Workflow Routing

| Trigger | Workflow |
|---------|----------|
| "commit", "commit message" | SmartCommit (below) |
| "PR", "pull request" | CreatePR (below) |
| "summarize", "what changed" | SummarizeChanges (below) |
| "branch", "create branch", "cleanup" | See `Workflows/BranchManagement.md` |

---

## SmartCommit

1. **Check staged changes:** `git diff --cached --stat` -- abort if nothing staged
2. **Generate message:** Pipe diff through fabric:
   ```bash
   git diff --cached | fabric --pattern create_git_diff_commit
   ```
3. **Format** as conventional commit: `type(scope): description` + bullet details + `Refs: #N`
4. **Present to user** for confirmation/edits -- NEVER commit without showing the message first
5. **Execute** via HEREDOC:
   ```bash
   git commit -m "$(cat <<'EOF'
   type(scope): description

   - Detail 1
   - Detail 2

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

**Types:** feat, fix, docs, style, refactor, test, chore

---

## CreatePR

1. **Verify state:**
   ```bash
   git status                              # clean working tree?
   git log origin/main..HEAD --oneline     # what commits are in scope?
   git push -u origin HEAD                 # ensure branch is pushed
   ```
2. **Analyze changes:** Full diff through fabric:
   ```bash
   git diff origin/main...HEAD | fabric --pattern summarize_git_changes
   ```
3. **Generate PR body** with structure: Summary / Changes / Test Plan / Related Issues
4. **Present to user** for edits -- NEVER create PR without confirmation
5. **Create PR** via gh CLI with HEREDOC body:
   ```bash
   gh pr create --title "short title" --body "$(cat <<'EOF'
   ## Summary
   [what and why]

   ## Changes
   - Change 1
   - Change 2

   ## Test Plan
   - [ ] Test case 1
   - [ ] Test case 2

   Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"
   ```
6. **Return the PR URL** to the user

---

## SummarizeChanges

1. **Identify scope:** last N commits, range, branch vs main, or specific file
2. **Pull data** with the correct git command:
   - Commits: `git log main..HEAD` (TWO dots)
   - Diffs: `git diff main...HEAD` (THREE dots -- the dot count matters)
   - Time-based: `git log --since="3 days ago"`
   - Author: `git shortlog -sn`
3. **Analyze** through fabric:
   - For commit summaries: `fabric --pattern summarize`
   - For diff analysis: `fabric --pattern summarize_git_changes`
4. **Output** structured block: SUMMARY / CHANGES / FILES AFFECTED / IMPACT

---

## Critical Rules

1. **Never commit to main** -- LAW #8, hook-enforced. Use feat/fix/wip/ branches.
2. **Always confirm before committing or creating PR** -- present the message, wait for approval
3. **Use HEREDOC for commit/PR bodies** -- avoids shell quoting issues
4. **fabric is the generation engine** -- pipe diffs through fabric patterns, don't generate inline
5. **Two dots vs three dots** -- `..` for log ranges, `...` for diff ranges. Getting this wrong gives wrong results.

## Detailed Reference

For branch management (create, switch, cleanup, naming conventions): see `Workflows/BranchManagement.md`
