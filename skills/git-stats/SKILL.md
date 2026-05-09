---
name: git-stats
description: |
  Analyze git repository statistics including commit history, author contributions, file churn,
  and code velocity. Uses executable tools for deterministic analysis.

  USE WHEN user says "git stats", "analyze repo", "commit statistics", "who contributed most",
  "most changed files", "repository analysis", or any request for git repository metrics.
---

## Workflow Routing (SYSTEM PROMPT)

**When user requests commit statistics by author:**
Examples: "who committed most", "commits by author", "contributor stats", "show me commit counts", "who's been working on this"
→ **READ:** ~/.config/pai/Skills/git-stats/workflows/commits-by-author.md
→ **EXECUTE:** Analyze commit counts per contributor using commits-by-author.ts tool

**When user requests file change analysis:**
Examples: "most changed files", "file churn", "what files change most", "hotspot files", "frequently modified files"
→ **READ:** ~/.config/pai/Skills/git-stats/workflows/file-churn.md
→ **EXECUTE:** Find most frequently modified files using file-churn.ts tool

**When user requests repository summary:**
Examples: "repo summary", "repository stats", "git statistics", "overall repo analysis", "project metrics"
→ **READ:** ~/.config/pai/Skills/git-stats/workflows/repo-summary.md
→ **EXECUTE:** Generate comprehensive repository statistics using repo-summary.ts tool

---

## When to Activate This Skill

### Direct Git Statistics Requests
- "git stats", "git statistics", "analyze git", "analyze repository"
- "run git stats", "do git analysis", "perform repo analysis"
- "quick git stats", "comprehensive repo analysis", "detailed commit analysis"
- "git stats for [repo]", "analyze [repo]", "stats on [repo]"

### Commit & Contribution Analysis
- "commits by author", "who committed most", "contributor statistics"
- "who's been working on this", "team contributions", "author breakdown"
- "commit counts", "contribution metrics", "developer activity"

### File & Code Analysis
- "most changed files", "file churn", "hotspot files", "code churn"
- "frequently modified files", "what files change most", "unstable files"
- "find problem files", "which files need refactoring"

### Repository Overview
- "repo summary", "repository overview", "project statistics"
- "how big is this repo", "repository metrics", "codebase analysis"
- "project health", "development activity"

---

## Core Capabilities

**What this skill provides:**
- **Author Statistics:** Commit counts and contributions per developer
- **File Churn Analysis:** Identify frequently changed files (potential hotspots)
- **Repository Metrics:** Overall stats including commit count, age, activity

**Tools-First Implementation:**
All analysis performed by executable TypeScript tools in `tools/` directory.
AI invokes tools and interprets results - deterministic work handled by code.

---

## Workflow Overview

**Contributor Analysis:**
- **commits-by-author.md** - Analyze commits per contributor, ranked by count

**File Analysis:**
- **file-churn.md** - Find most frequently modified files over time

**Repository Overview:**
- **repo-summary.md** - Comprehensive repository statistics and metrics

---

## Tools Reference

All workflows use deterministic tools (following TOOLS-FIRST.md philosophy):

**commits-by-author.ts**
- Parses git log for author information
- Counts commits per contributor
- Formats output as ranked table
- Usage: `bun commits-by-author.ts [--repo PATH] [--limit N]`

**file-churn.ts**
- Analyzes file modification frequency
- Identifies hotspot files
- Formats output with change counts
- Usage: `bun file-churn.ts [--repo PATH] [--limit N] [--since DATE]`

**repo-summary.ts**
- Aggregates multiple git statistics
- Provides overall repository health metrics
- Formats comprehensive summary
- Usage: `bun repo-summary.ts [--repo PATH]`

---

## Examples

**Example 1: Find Top Contributors**

User: "Who committed the most to this repo?"

Skill Response:
1. Routes to commits-by-author.md
2. Executes: `bun ~/.config/pai/Skills/git-stats/tools/commits-by-author.ts --repo . --limit 10`
3. Presents formatted table of top 10 contributors

**Example 2: Identify Problem Files**

User: "What files change the most? Might need refactoring."

Skill Response:
1. Routes to file-churn.md
2. Executes: `bun ~/.config/pai/Skills/git-stats/tools/file-churn.ts --repo . --limit 20`
3. Shows files with highest change frequency

**Example 3: Repository Health Check**

User: "Give me an overview of this repository."

Skill Response:
1. Routes to repo-summary.md
2. Executes: `bun ~/.config/pai/Skills/git-stats/tools/repo-summary.ts --repo .`
3. Displays comprehensive metrics (commits, authors, age, activity)

---

## Related Documentation

- **TOOLS-FIRST.md** - Philosophy behind executable tools approach
- **HistoryQuery skill** - Reference implementation of tools-first pattern

**Last Updated:** 2025-12-29
