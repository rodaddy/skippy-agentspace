# Commits By Author

**Purpose:** Analyze commit counts per contributor to identify top contributors

**When to Use:**
- User wants to see who committed the most
- Need contributor statistics
- Analyzing team contributions

**Prerequisites:**
- Git repository (current directory or specified path)

---

## Workflow Steps

### Step 1: Execute Analysis Tool

**Run:**
```bash
bun ~/.config/pai/Skills/git-stats/tools/commits-by-author.ts --repo . --limit 10
```

**What it does:**
- Parses git log for all commit authors
- Counts commits per contributor
- Sorts by commit count (descending)
- Formats as ranked table

**Expected output:**
```
## 📊 Commits By Author

**Repository:** /path/to/repo
**Total commits:** 1,234

Rank  Author              Commits    %
────────────────────────────────────────
1     Alice Developer     456        37.0%
2     Bob Engineer        321        26.0%
3     Carol Contributor   234        19.0%
...
```

---

## Options

**--repo PATH**
- Specify repository path (default: current directory)
- Example: `--repo /path/to/repo`

**--limit N**
- Show top N contributors (default: 10)
- Example: `--limit 20`

**--all**
- Show all contributors (no limit)

---

## Outputs

**What this workflow produces:**
- Ranked list of contributors by commit count
- Percentage breakdown of contributions
- Total commit count

---

## Related Workflows

- **file-churn.md** - See what files these contributors changed most
- **repo-summary.md** - Get overall repository statistics

---

**Last Updated:** 2025-12-29
