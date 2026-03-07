# LAW 8: Never Work on Main

**Enforcement:** `pre-bash-protected-branch-commit.ts` (PreBash hook)
**Severity:** MANDATORY

## Rule

All development on feature/wip branches. Never commit directly to protected branches: main, master, develop, production, staging, release/*.

## Why

Direct commits to main bypass code review, break CI assumptions, and make rollbacks painful. Branch-based development enables parallel work, clean history, and safe experimentation.

## Enforcement Details

- Pre-commit hook checks current branch name against protected branch list
- Blocks `git commit` on: main, master, develop, production, staging, release/*
- Also blocks `git push` directly to protected branches

## Workflow

1. Create branch: `feat/description`, `fix/description`, `wip/description`
2. Make changes and commit
3. Push branch: `git push -u origin feat/description`
4. Create PR: `gh pr create --base main --head feat/description`

## Examples

**Correct:** `git checkout -b feat/add-auth && git commit -m "feat: add auth"`
**Incorrect:** `git checkout main && git commit -m "added stuff"`

## Exceptions

- Hotfixes only with explicit user approval
- Session merge: `git merge session/*` into main is allowed for session-wrap workflow. This is the ONLY automated merge to main.
