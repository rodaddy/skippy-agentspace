# CreatePR Workflow

Generate comprehensive PR descriptions and create pull requests.

## When to Use

- User asks to "create a PR", "make a pull request", "PR description"
- Ready to merge feature branch
- Need professional PR documentation

## Process

1. **Verify Git State**
   ```bash
   git status
   git log origin/main..HEAD --oneline
   ```
   - Check current branch
   - Verify commits to include
   - Ensure branch is pushed to remote

2. **Analyze Changes**
   ```bash
   git diff origin/main...HEAD | fabric --pattern summarize_git_changes
   ```
   - Get all changes since branch diverged
   - Analyze commit messages
   - Identify patterns and scope

3. **Generate PR Description**

   **Title:**
   - Concise, descriptive
   - Include type prefix if appropriate

   **Body:**
   - Summary section (what this PR does)
   - Changes section (bullet list)
   - Test plan (how to verify)
   - Related issues/tickets
   - Breaking changes (if any)

4. **Present to User**
   - Show generated title and description
   - Allow edits before creation
   - Confirm PR details

5. **Create PR**
   ```bash
   gh pr create --title "..." --body "$(cat <<'EOF'
   [Generated PR description]
   EOF
   )"
   ```
   - Use gh CLI to create PR
   - Return PR URL
   - Optionally set labels, reviewers

## PR Description Format

```markdown
## Summary
[1-2 sentences describing what this PR does and why]

## Changes
- Change 1: description
- Change 2: description
- Change 3: description

## Test Plan
- [ ] Test case 1
- [ ] Test case 2
- [ ] Verify no regressions

## Related Issues
Closes #123
Relates to #456

## Breaking Changes
[If any, describe migration path]

---
🤖 Generated with PAI
```

## Example

```bash
# Check commits
git log origin/main..HEAD --oneline

# Analyze all changes
git diff origin/main...HEAD | fabric --pattern summarize_git_changes

# Create PR
gh pr create \
  --title "feat: add user authentication system" \
  --body "$(cat <<'EOF'
## Summary
Implements complete user authentication using JWT tokens with secure password hashing and rate limiting.

## Changes
- Add JWT token generation and validation
- Implement login/logout endpoints
- Add bcrypt password hashing
- Include rate limiting middleware
- Add auth middleware for protected routes

## Test Plan
- [ ] Test user registration flow
- [ ] Test login with valid credentials
- [ ] Test login with invalid credentials
- [ ] Verify rate limiting works
- [ ] Test protected route access

## Related Issues
Closes #234

🤖 Generated with PAI
EOF
)"
```

## Safety Checks

- Verify branch is pushed to remote
- Confirm base branch (main/master/develop)
- Review all commits to be included
- Allow user to edit description before creation
- Return PR URL for review
