# Repository Summary

**Purpose:** Generate comprehensive statistics about a git repository

**When to Use:**
- User wants overall repository metrics
- Need project health overview
- Analyzing repository age and activity

**Prerequisites:**
- Git repository (current directory or specified path)

---

## Workflow Steps

### Step 1: Execute Analysis Tool

**Run:**
```bash
bun ~/.config/pai/Skills/git-stats/tools/repo-summary.ts --repo .
```

**What it does:**
- Aggregates multiple git statistics
- Counts total commits, authors, files
- Calculates repository age
- Analyzes recent activity
- Formats comprehensive summary

**Expected output:**
```
## 📊 Repository Summary

**Path:** /path/to/repo

### Overview
- Total commits: 1,234
- Contributors: 15
- Files tracked: 342
- Branches: 8

### History
- First commit: 2023-06-15
- Latest commit: 2025-12-29
- Age: 563 days
- Average commits/day: 2.2

### Recent Activity (Last 30 Days)
- Commits: 67
- Active contributors: 5
- Files changed: 89
```

---

## Options

**--repo PATH**
- Specify repository path (default: current directory)

---

## Outputs

**What this workflow produces:**
- Comprehensive repository metrics
- Historical analysis
- Activity trends
- Health indicators

---

## Related Workflows

- **commits-by-author.md** - See detailed contributor breakdown
- **file-churn.md** - Analyze file modification patterns

---

**Last Updated:** 2025-12-29
