# SummarizeChanges Workflow

Summarize git changes in plain English (commits, diffs, history).

## When to Use

- User asks "what changed", "summarize changes", "what's new"
- Reviewing commit history
- Understanding changes in a branch or commit range

## Process

1. **Identify Scope**
   - Last N commits: `git log -N`
   - Commit range: `git log A..B`
   - Current branch vs main: `git log main..HEAD`
   - Specific file: `git log -- path/to/file`

2. **Get Changes**
   ```bash
   # For commits
   git log --oneline -10

   # For diffs
   git diff main...HEAD

   # For specific commit
   git show <commit-hash>
   ```

3. **Summarize with Fabric**
   ```bash
   # Summarize commit messages
   git log --oneline -10 | fabric --pattern summarize

   # Summarize actual changes
   git diff main...HEAD | fabric --pattern summarize_git_changes
   ```

4. **Present Results**
   - Plain English summary
   - Key changes highlighted
   - Files affected
   - Impact assessment

## Use Cases

### Last N Commits
```bash
# What happened in last 10 commits?
git log --oneline -10 --no-decorate | fabric --pattern summarize
```

### Branch vs Main
```bash
# What's different in this branch?
git log main..HEAD --oneline | fabric --pattern summarize
git diff main...HEAD | fabric --pattern summarize_git_changes
```

### Specific File History
```bash
# What changed in this file?
git log -p -- path/to/file | fabric --pattern summarize
```

### Between Tags
```bash
# Changes between releases
git log v1.0.0..v2.0.0 --oneline | fabric --pattern summarize
```

## Output Format

```
SUMMARY:
[One-line overview of changes]

CHANGES:
- Feature: description
- Fix: description
- Refactor: description

FILES AFFECTED:
- file1.ts (modified)
- file2.ts (new)
- file3.ts (deleted)

IMPACT:
[Assessment of change scope and risk]
```

## Example

```bash
# User: "What changed in the last week?"
git log --since="1 week ago" --oneline | fabric --pattern summarize

# Output:
# "Added user authentication, fixed 3 bugs in payment flow,
# refactored database connection pooling"
```

## Advanced Options

**Include stats:**
```bash
git diff --stat main...HEAD
```

**Show authors:**
```bash
git shortlog main..HEAD
```

**With dates:**
```bash
git log --since="2025-01-01" --until="2025-01-31" --oneline
```
