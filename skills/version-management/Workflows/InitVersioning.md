# InitVersioning Workflow

Initialize VERSION file and CHANGELOG.md for projects that don't have versioning yet.

## When to Use

- User says "init version", "initialize versioning", "create VERSION file"
- BumpVersion workflow encounters missing VERSION file
- Starting a new project that needs version tracking
- Adding versioning to existing project

## Process

### 1. Verify Prerequisites

```bash
# Check if this is a git repo
git rev-parse --git-dir

# Check if VERSION already exists
test -f VERSION
```

- If not a git repo → Error (must be git repo to use versioning)
- If VERSION exists → Error (already initialized - use BumpVersion instead)
- Otherwise → Continue

### 2. Ask User: Is This Your Project?

**Prompt:**
```
Initialize versioning for this project?

Project: $(basename $(pwd))
Path: $(pwd)

Is this a project you own/maintain? (Y/n):
```

- **If no:** Exit (don't initialize versioning for projects you don't own)
- **If yes:** Continue

### 3. Determine Starting Version

**Ask:**
```
What starting version should we use?

1. 0.1.0 - Early development, pre-release [DEFAULT]
2. 1.0.0 - Production-ready, stable
3. Custom - Enter your own version

Enter choice (1/2/3) or press Enter for 0.1.0:
```

**Logic:**
- Default: `0.1.0` (most new projects)
- Production: `1.0.0` (if project is already deployed/stable)
- Custom: Validate format is `X.Y.Z`

```bash
# Validate semver format
if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "❌ Invalid version format. Must be X.Y.Z (e.g., 1.2.3)"
  exit 1
fi
```

### 4. Check for Existing Changelog

```bash
# Check if CHANGELOG.md exists
if [ -f CHANGELOG.md ]; then
  echo "⚠️  CHANGELOG.md already exists"
  echo ""
  echo "Options:"
  echo "1. Keep existing and add version entry"
  echo "2. Backup and create new"
  echo "3. Abort"

  # Get user choice
  # If keep: Prepend version entry
  # If backup: mv CHANGELOG.md CHANGELOG.md.backup
  # If abort: exit
fi
```

### 5. Create VERSION File

```bash
echo "$version" > VERSION
echo "✅ Created VERSION file: $version"
```

**VERSION file format:**
```
1.0.0
```

- No `v` prefix
- Just the semver number
- Single line, no trailing newline

### 6. Create/Update CHANGELOG.md

**If creating new:**

```bash
cat > CHANGELOG.md <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [$version] - $(date +%Y-%m-%d)

### Added
- Initial version
- Versioning infrastructure (VERSION file + CHANGELOG.md)

EOF

echo "✅ Created CHANGELOG.md"
```

**If updating existing:**

```bash
# Insert new version entry at the top of version history
# Find line that starts with "## [" and insert before it

awk -v version="$version" -v date="$(date +%Y-%m-%d)" '
  /^## \[/ && !inserted {
    print "## [" version "] - " date
    print ""
    print "### Added"
    print "- Initial version"
    print "- Versioning infrastructure (VERSION file + CHANGELOG.md)"
    print ""
    inserted=1
  }
  { print }
' CHANGELOG.md > CHANGELOG.md.tmp

mv CHANGELOG.md.tmp CHANGELOG.md

echo "✅ Updated CHANGELOG.md"
```

### 7. Preview Files

```
📄 Files to be created/updated:

VERSION:
  + $version

CHANGELOG.md:
  + # Changelog
  +
  + All notable changes to this project will be documented in this file.
  +
  + ## [$version] - $(date +%Y-%m-%d)
  +
  + ### Added
  + - Initial version
  + - Versioning infrastructure
  ...

Proceed with commit? (Y/n):
```

### 8. Commit VERSION + CHANGELOG

```bash
git add VERSION CHANGELOG.md

git commit -m "$(cat <<'EOF'
Initialize versioning infrastructure

Added VERSION file (${version}) and CHANGELOG.md.

From this point forward:
- All changes must bump VERSION (minimum PATCH)
- All changes must update CHANGELOG.md
- Git tags mirror VERSION file

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

echo "✅ Committed versioning files"
```

### 9. Create Initial Git Tag

```bash
# Create annotated tag for initial version
tag_message="Initial version v${version}

Initialized versioning infrastructure.

Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Commit: $(git rev-parse --short HEAD)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

git tag -a "v${version}" -m "$tag_message"

echo "✅ Created git tag: v${version}"
```

### 10. Optionally Push

**Ask:**
```
Push initial version to remote? (y/N):
```

If yes:
```bash
git push origin main  # or current branch
git push origin "v${version}"
echo "✅ Pushed to remote"
```

### 11. Summary

```
✅ Versioning Initialized

  Version: $version
  Files:   VERSION, CHANGELOG.md
  Tag:     v$version
  Pushed:  [Yes/No]

Next steps:
  1. Make changes to your project
  2. Before creating PR: "bump version"
  3. VERSION file + git tags will track all releases

Version bump policy:
  - PATCH (X.Y.Z): Bug fixes, docs, minor changes
  - MINOR (X.Y.0): New features, non-breaking improvements
  - MAJOR (X.0.0): Breaking changes, major refactors
```

## Safety Checks

- Verify git repo exists
- Confirm VERSION doesn't already exist
- Validate semver format for starting version
- Check for existing CHANGELOG.md (offer to keep/backup)
- Preview all changes before committing
- Allow user to abort at any step

## Example Run

```bash
User: "initialize versioning"

→ Is this your project? (Y/n): y
→
→ Starting version?
→   1. 0.1.0 [DEFAULT]
→   2. 1.0.0
→   3. Custom
→ [1]:
→
→ Using version: 0.1.0
→
→ Preview:
→   Creating VERSION (0.1.0)
→   Creating CHANGELOG.md
→
→ Proceed? (Y/n): y
→ ✅ Created VERSION
→ ✅ Created CHANGELOG.md
→ ✅ Committed versioning files
→ ✅ Created git tag: v0.1.0
→
→ Push to remote? (y/N): y
→ ✅ Pushed to remote
→
→ ✅ Versioning initialized!
```

## Integration with PAI

**Works with:**
- `check-version-on-pr.ts` hook (will start enforcing after initialization)
- `BumpVersion` workflow (can now be used)
- PAI's `Tools/release.ts` (compatible changelog format)

**Triggers:**
- Auto-offered when BumpVersion finds no VERSION file
- Manual invocation via skill

## Error Handling

**Not a git repo:**
```
❌ Error: Not a git repository

Versioning requires git. Initialize git first:
  git init
  git add .
  git commit -m "Initial commit"

Then try again: "initialize versioning"
```

**VERSION already exists:**
```
❌ Error: VERSION file already exists (1.2.3)

This project already has versioning initialized.

To bump version: "bump version"
To view current version: cat VERSION
```

**Invalid starting version:**
```
❌ Error: Invalid version format: "v1.0"

Expected: X.Y.Z (e.g., 1.0.0)
No 'v' prefix, exactly 3 numeric components separated by dots.
```

**Git working directory dirty:**
```
⚠️  Warning: Uncommitted changes detected

Modified files:
  - src/main.py
  - README.md

Options:
  1. Commit changes first
  2. Stash changes
  3. Continue anyway (will commit with VERSION/CHANGELOG)
  4. Abort

Choose option (1/2/3/4):
```

## Special Cases

**Existing project with git history:**
- Offer to analyze git history for appropriate starting version
- Suggest version based on number of commits (many commits → 1.0.0, few → 0.1.0)

**Project already deployed:**
- Suggest starting at 1.0.0 instead of 0.1.0
- Warn that version bumps will be enforced going forward

**Multiple remotes:**
- Ask which remote to push to (origin, upstream, etc.)
- Default to 'origin'