# BranchManagement Workflow

Smart branch operations (create, switch, clean up, strategy).

## When to Use

- User asks to "create a branch", "switch branch", "clean up branches"
- Managing feature/fix branches
- Branch hygiene and organization

## Process

### Create Branch

1. **Determine Branch Name**
   - Follow naming convention
   - Include type prefix (feature/, fix/, etc.)
   - Use descriptive name

2. **Create and Switch**
   ```bash
   git checkout -b <branch-name>
   ```

3. **Push to Remote**
   ```bash
   git push -u origin <branch-name>
   ```

### Switch Branch

1. **Check for Uncommitted Changes**
   ```bash
   git status
   ```
   - Stash if needed
   - Commit if ready

2. **Switch**
   ```bash
   git checkout <branch-name>
   # or
   git switch <branch-name>
   ```

### Clean Up Branches

1. **List Merged Branches**
   ```bash
   git branch --merged main
   ```

2. **Delete Local Branches**
   ```bash
   git branch -d <branch-name>
   ```

3. **Delete Remote Branches**
   ```bash
   git push origin --delete <branch-name>
   ```

4. **Prune Remote References**
   ```bash
   git fetch --prune
   ```

## Branch Naming Convention

```
<type>/<short-description>

Examples:
- feature/user-authentication
- fix/payment-validation-bug
- refactor/database-layer
- docs/api-documentation
- chore/upgrade-dependencies
```

**Types:**
- `feature/` - New features
- `fix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation changes
- `chore/` - Maintenance tasks
- `test/` - Test-related changes

## Common Operations

### Create Feature Branch
```bash
# From main
git checkout main
git pull
git checkout -b feature/new-feature
git push -u origin feature/new-feature
```

### Clean Up After PR Merge
```bash
# Switch back to main
git checkout main
git pull

# Delete local branch
git branch -d feature/completed-feature

# Delete remote (if not auto-deleted)
git push origin --delete feature/completed-feature
```

### List All Branches
```bash
# Local branches
git branch

# Remote branches
git branch -r

# All branches
git branch -a

# With last commit
git branch -v
```

### Rename Branch
```bash
# Rename current branch
git branch -m new-name

# Rename other branch
git branch -m old-name new-name

# Update remote
git push origin -u new-name
git push origin --delete old-name
```

## Branch Strategy

**Main Branches:**
- `main` / `master` - Production code
- `develop` - Integration branch (if using Git Flow)

**Supporting Branches:**
- `feature/*` - New features
- `fix/*` - Bug fixes
- `hotfix/*` - Emergency fixes
- `release/*` - Release preparation

**Rules:**
- Never commit directly to main
- Feature branches off main (or develop)
- Delete after merge
- Keep branches short-lived
- Sync with main regularly

## Safety Checks

- Verify no uncommitted changes before switching
- Confirm branch is merged before deleting
- Check remote refs before force operations
- Always pull main before creating new branch
