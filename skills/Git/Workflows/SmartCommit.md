# SmartCommit Workflow

Generate AI-powered commit messages from staged changes.

## When to Use

- User asks to "create a commit", "write commit message", "commit these changes"
- Need professional, conventional commit format
- Want detailed commit descriptions

## Process

1. **Check Staged Changes**
   ```bash
   git diff --cached --stat
   ```
   - If nothing staged, inform user
   - Show summary of what will be committed

2. **Analyze Changes**
   ```bash
   git diff --cached | fabric --pattern create_git_diff_commit
   ```
   - Use fabric to generate commit message
   - Alternatively use `summarize_git_diff` for detailed analysis

3. **Format Commit Message**
   - Follow conventional commits format
   - Include type (feat, fix, docs, etc.)
   - Add scope if applicable
   - List detailed changes
   - Note breaking changes if any
   - Reference issues (#123)

4. **Present to User**
   - Show generated commit message
   - Ask for confirmation or edits
   - Explain what will be committed

5. **Execute Commit**
   ```bash
   git commit -m "$(cat <<'EOF'
   [Generated commit message]
   EOF
   )"
   ```

## Commit Message Format

```
type(scope): brief description

- Detailed change 1
- Detailed change 2
- Breaking: description (if applicable)

Refs: #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semi-colons, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

## Example

```bash
# Check staged changes
git diff --cached --stat

# Generate commit message
git diff --cached | fabric --pattern create_git_diff_commit

# Review and commit
git commit -m "feat(api): add user authentication endpoint

- Implement JWT token generation
- Add login/logout routes
- Include password hashing with bcrypt
- Add rate limiting to auth endpoints

Refs: #234"
```

## Safety Checks

- Verify staged changes before committing
- Confirm with user before executing
- Show full commit message preview
- Allow user to edit before final commit
