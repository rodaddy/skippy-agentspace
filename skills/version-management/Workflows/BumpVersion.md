# BumpVersion Workflow

Bump VERSION file, update CHANGELOG.md, create git tag. Enforces dual-source version management (VERSION file + git tag).

## When to Use

- User says "bump version", "update version", "version bump"
- Blocked by `check-version-on-pr.ts` hook when trying to create PR
- Before merging feature branch to development/main
- After completing a feature or bug fix

## Process

### 1. Verify Prerequisites

```bash
# Check if this is a git repo
git rev-parse --git-dir

# Check if VERSION file exists
test -f VERSION
```

- If not a git repo → Exit with error
- If no VERSION file → Offer to run InitVersioning workflow
- If VERSION exists → Continue

### 2. Determine Current Version

```bash
# Read current version from VERSION file
current_version=$(cat VERSION)
echo "Current version: $current_version"

# Verify git tag exists (optional - might not match if manually edited)
git describe --tags --abbrev=0 2>/dev/null || echo "No git tags yet"
```

### 3. Ask User: Version Bump Type

**Default: PATCH** (most common - bug fixes, minor changes)

**Prompt:**
```
Current version: 1.2.3

What type of bump?
1. PATCH (1.2.3 → 1.2.4) - Bug fixes, docs, minor changes [DEFAULT]
2. MINOR (1.2.3 → 1.3.0) - New features, non-breaking improvements
3. MAJOR (1.2.3 → 2.0.0) - Breaking changes, major refactors

Enter choice (1/2/3) or press Enter for PATCH:
```

**Auto-suggestion logic** (analyze commits since last tag):
- Check for `BREAKING CHANGE:` or `!:` in commits → Suggest MAJOR
- Check for `feat:` commits → Suggest MINOR
- Otherwise → Suggest PATCH

```bash
# Get commits since last tag/version
git log v${current_version}..HEAD --oneline 2>/dev/null || git log --oneline -10

# Analyze for conventional commit keywords
has_breaking=$(git log v${current_version}..HEAD --grep="BREAKING CHANGE" --grep="!:" --oneline)
has_feat=$(git log v${current_version}..HEAD --grep="^feat" --oneline)

if [ -n "$has_breaking" ]; then
  echo "💡 Suggestion: MAJOR (breaking changes detected)"
elif [ -n "$has_feat" ]; then
  echo "💡 Suggestion: MINOR (new features detected)"
else
  echo "💡 Suggestion: PATCH (fixes/docs only)"
fi
```

### 4. Calculate New Version

```bash
# Parse current version
IFS='.' read -r major minor patch <<< "$current_version"

# Bump based on type
case $bump_type in
  major)
    new_version="$((major + 1)).0.0"
    ;;
  minor)
    new_version="${major}.$((minor + 1)).0"
    ;;
  patch)
    new_version="${major}.${minor}.$((patch + 1))"
    ;;
esac

echo "New version: $new_version"
```

### 5. Analyze Commits for Changelog

```bash
# Get commits since last version
git log v${current_version}..HEAD --format="%h|%s|%b" > /tmp/commits.txt

# Extract JIRA tickets (PROJ-XXXXX pattern)
jira_tickets=$(grep -oE "PROJ-[0-9]+" /tmp/commits.txt | sort -u)

# Group by conventional commit type
feat_commits=$(grep "^[a-f0-9]*|feat" /tmp/commits.txt || true)
fix_commits=$(grep "^[a-f0-9]*|fix" /tmp/commits.txt || true)
docs_commits=$(grep "^[a-f0-9]*|docs" /tmp/commits.txt || true)
infra_commits=$(grep "^[a-f0-9]*|chore\|^[a-f0-9]*|ci\|^[a-f0-9]*|build" /tmp/commits.txt || true)
```

### 6. Prompt for Changelog Entry

**Show context:**
```
📝 Changelog Entry for v${new_version}

Recent commits:
${commit_summary}

JIRA tickets found: ${jira_tickets}

Enter changelog description (what changed in this version):
```

**User provides:** "Added Slack thread timer management with 30min conversation windows"

**Generate changelog entry:**
```markdown
## [${new_version}] - $(date +%Y-%m-%d)

### Added
- Slack thread timer management with 30min conversation windows

### Related
- PROJ-12345: Slack Thread Timer Management
- PROJ-12346: Slack Message Posting

### Commits
- feat: add slack timer service (abc1234)
- fix: handle timer race conditions (def5678)
```

### 7. Update VERSION File

```bash
echo "$new_version" > VERSION
echo "✅ Updated VERSION: $current_version → $new_version"
```

### 8. Update CHANGELOG.md

```bash
# Read current CHANGELOG
changelog_content=$(cat CHANGELOG.md)

# Find insertion point (after header, before first version)
# Insert new entry at the top of version history

# Use awk/sed to insert new entry
awk -v entry="$changelog_entry" '
  /^## \[/ && !inserted {
    print entry
    print ""
    inserted=1
  }
  { print }
' CHANGELOG.md > CHANGELOG.md.tmp

mv CHANGELOG.md.tmp CHANGELOG.md

echo "✅ Updated CHANGELOG.md"
```

### 9. Preview Changes

```
📄 Preview of changes:

VERSION:
  - $current_version
  + $new_version

CHANGELOG.md:
  + ## [$new_version] - $(date +%Y-%m-%d)
  + ### Added
  + - [User's description]
  ...

Proceed with commit and tag? (Y/n):
```

### 10. Commit VERSION + CHANGELOG

```bash
git add VERSION CHANGELOG.md

git commit -m "$(cat <<'EOF'
Bump version to ${new_version}

Updated VERSION file and CHANGELOG.md for ${new_version} release.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

echo "✅ Committed version bump"
```

### 11. Create Git Tag

```bash
# Create annotated tag with build timestamp
tag_message="Release v${new_version}

Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Commit: $(git rev-parse --short HEAD)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

git tag -a "v${new_version}" -m "$tag_message"

echo "✅ Created git tag: v${new_version}"
```

### 12. Optionally Push Tag

**Ask:**
```
Push tag v${new_version} to remote? (y/N):
```

If yes:
```bash
git push origin "v${new_version}"
echo "✅ Pushed tag to remote"
```

### 13. Clear Hook Override Flag

```bash
# If SKIP_VERSION_CHECK_ONCE was set, clear it
unset SKIP_VERSION_CHECK_ONCE
```

### 14. Summary

```
✅ Version Bump Complete

  Version: $current_version → $new_version
  Files:   VERSION, CHANGELOG.md
  Tag:     v${new_version}
  Pushed:  [Yes/No]

You can now:
  - Create PR: gh pr create --title "..." --body "..."
  - Continue development
  - Merge to main/development
```

## Safety Checks

- Verify VERSION file contains valid semver (X.Y.Z)
- Check CHANGELOG.md exists and is well-formed
- Confirm git working directory is clean (or only VERSION/CHANGELOG modified)
- Validate tag doesn't already exist
- Allow user to preview all changes before committing
- Provide option to abort at any step

## Example Run

```bash
User: "bump version"

→ Current version: 1.2.3
→ Analyzing commits...
→ 💡 Suggestion: MINOR (new features detected)
→
→ What type of bump? (1=PATCH, 2=MINOR, 3=MAJOR) [1]: 2
→ New version: 1.3.0
→
→ Enter changelog description: Added Slack thread timer management
→
→ Preview:
→   VERSION: 1.2.3 → 1.3.0
→   CHANGELOG: Added new entry for 1.3.0
→
→ Proceed? (Y/n): y
→ ✅ Committed version bump
→ ✅ Created git tag: v1.3.0
→
→ Push tag to remote? (y/N): y
→ ✅ Pushed tag
→
→ ✅ Version bump complete! You can now create your PR.
```

## Integration with Existing PAI Infrastructure

**Reuses:**
- PAI's `Tools/release.ts` commit parsing logic
- Git commit analysis patterns
- Conventional commit format detection

**Coordinates with:**
- `check-version-on-pr.ts` hook (clears blocking flag)
- `track-git-changes.ts` (tracks VERSION/CHANGELOG modifications)
- `Git/CreatePR` workflow (unblocked after version bump)

## Error Handling

**Not a git repo:**
```
❌ Error: Not a git repository
   Run: git init
```

**No VERSION file:**
```
❌ Error: VERSION file not found

Would you like to initialize versioning? (Y/n)
→ If yes: Run InitVersioning workflow
```

**VERSION file malformed:**
```
❌ Error: VERSION file contains invalid semver: "v1.2.3.4"
   Expected format: "1.2.3" (no 'v' prefix, exactly 3 components)
```

**Tag already exists:**
```
❌ Error: Git tag v1.3.0 already exists

Options:
  1. Delete existing tag: git tag -d v1.3.0
  2. Choose different version
  3. Abort
```

**Uncommitted changes:**
```
⚠️  Warning: Uncommitted changes detected

Modified files:
  - src/handlers.py
  - src/config.py

Options:
  1. Commit changes first
  2. Stash changes
  3. Continue anyway (will commit with VERSION/CHANGELOG)
  4. Abort
```
