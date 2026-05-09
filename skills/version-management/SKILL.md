---
name: version-management
description: Universal version and changelog management for all projects. Enforces VERSION file + git tag synchronization. AUTO-INVOKES when creating PRs without version bump. USE WHEN bump version, update changelog, initialize versioning, or user asks about version management.
---

# version-management - Universal Version Discipline

**Enforces professional version management across all your projects.**

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **BumpVersion** | "bump version", "update version", "version bump", blocked by PR hook | `Workflows/BumpVersion.md` |
| **InitVersioning** | "init version", "initialize versioning", "create VERSION file" | `Workflows/InitVersioning.md` |

## Core Principles

**Dual-Source Version Management:**
- VERSION file (1.2.3) = Source of truth for builds/CI/CD
- Git tag (v1.2.3) = Mirrors VERSION, used for releases
- Always kept in sync automatically

**Version Bump Policy:**
- Every PR MUST bump version (minimum PATCH)
- PATCH: Bug fixes, docs, minor changes
- MINOR: New features, non-breaking improvements
- MAJOR: Breaking changes, major refactors

**Enforcement:**
- PreBash hook blocks `gh pr create` if VERSION unchanged
- Can override with "skip version check" (discouraged)
- Assumes project is yours unless told otherwise

## Examples

**Example 1: Bump version before PR**
```
User: "create a PR"
→ Hook blocks: VERSION unchanged
→ User: "bump version"
→ Invokes BumpVersion workflow
→ Ask: PATCH/MINOR/MAJOR? (default: PATCH)
→ Updates VERSION: 1.2.3 → 1.2.4
→ Updates CHANGELOG.md with entry
→ Commits both files
→ Creates git tag: v1.2.4
→ User can now create PR
```

**Example 2: Initialize new project**
```
User: "initialize versioning"
→ Invokes InitVersioning workflow
→ Creates VERSION (0.1.0)
→ Creates CHANGELOG.md template
→ Commits both
→ Creates git tag: v0.1.0
```

**Example 3: Docs-only change override**
```
User: edits README.md
User: "create PR"
→ Hook: "Only docs changed - still bump version?"
→ User: "skip version check"
→ Sets SKIP_VERSION_CHECK_ONCE=1
→ Allows PR creation
```

## Features

**Automatic Version Detection:**
- Analyzes git commits since last version
- Extracts JIRA tickets (PROJ-XXXXX) from commit messages
- Suggests PATCH/MINOR/MAJOR based on conventional commits
- Auto-generates changelog entries

**Dual-Source Synchronization:**
- Updates VERSION file
- Commits VERSION + CHANGELOG.md
- Creates matching git tag (v1.2.4)
- Optionally pushes tag to remote

**Smart Changelog Generation:**
- Groups commits by type (Features/Fixes/Infrastructure)
- Includes JIRA ticket references
- Follows Keep a Changelog format
- Preserves manual entries

## Integration

**Works with existing PAI infrastructure:**
- Reuses `Tools/release.ts` commit parsing logic
- Integrates with `track-git-changes.ts` session tracking
- Enhances `Git/CreatePR` workflow
- Coordinates with `check-version-on-pr.ts` hook

**Works with JIRA workflows:**
- Extracts PROJ-XXXXX tickets from commits
- Supports JIRA-first development
- Aligns with CI/CD requirements (GitHub Actions, Cloud Run)
- Professional version tracking for production services

## Project Detection

**Determines if project uses versioning:**
1. Check for VERSION file in repo root
2. If exists → Enforce version bumps
3. If doesn't exist → Offer to initialize (only if CHANGELOG.md pattern exists)

**Project ownership detection:**
1. Ask: "Is this your project?" (default: yes)
2. If yes → Enforce version bumps
3. If no → Set SKIP_VERSION_CHECK_ONCE, allow PR

## Safety Checks

- Verify git repo exists
- Confirm VERSION file format (semantic version)
- Validate CHANGELOG.md structure
- Preview changes before committing
- Allow user to edit changelog entry
- Option to skip tag creation (advanced)

---

**Last Updated:** 2025-12-31
**Enforcement:** MANDATORY for projects with VERSION file
