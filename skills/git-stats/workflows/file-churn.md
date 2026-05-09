# File Churn Analysis

**Purpose:** Identify most frequently modified files to find potential hotspots or refactoring candidates

**When to Use:**
- User wants to find "problem files" that change often
- Analyzing code stability
- Identifying refactoring candidates
- Understanding which parts of codebase are most active

**Prerequisites:**
- Git repository (current directory or specified path)

---

## Workflow Steps

### Step 1: Execute Analysis Tool

**Run:**
```bash
bun ~/.config/pai/Skills/git-stats/tools/file-churn.ts --repo . --limit 20 --since "6 months ago"
```

**What it does:**
- Parses git log for file modification events
- Counts modifications per file
- Sorts by change frequency (descending)
- Formats as ranked list with change counts

**Expected output:**
```
## 🔥 File Churn Analysis

**Repository:** /path/to/repo
**Period:** Last 6 months
**Total files modified:** 342

Rank  Changes  File Path
────────────────────────────────────────────
1     127      src/services/api.ts
2     98       src/components/Dashboard.tsx
3     76       src/utils/helpers.ts
...
```

---

## Options

**--repo PATH**
- Specify repository path (default: current directory)

**--limit N**
- Show top N files (default: 20)

**--since DATE**
- Analyze changes since date (default: all history)
- Example: `--since "3 months ago"`, `--since "2025-01-01"`

---

## Related Workflows

- **commits-by-author.md** - See who's making these changes
- **repo-summary.md** - Get overall activity metrics

---

**Last Updated:** 2025-12-29
