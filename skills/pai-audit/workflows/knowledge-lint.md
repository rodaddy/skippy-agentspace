# Knowledge Lint

**Purpose:** Scan memory/knowledge files for staleness, broken references, contradictions, and topic overlap. The deterministic scanner handles file checks; the AI reviews results for semantic issues.

**When to Use:**
- During a full pai-audit run (as one of the audit sections)
- User says "lint the knowledge base", "check my memory files", "knowledge audit"
- Monthly maintenance alongside other pai-audit checks

---

## Workflow Steps

### Step 1: Run the Scanner

**Execute:**
```bash
bun ~/.config/pai/Skills/pai-audit/tools/knowledge-lint.ts scan
```

This scans all memory directories and reports:
- Stale entries (60+ days without modification)
- Broken file references (paths mentioned in entries that no longer exist)
- Orphaned files (memory files not referenced in MEMORY.md)
- Topic clusters (multiple files covering the same topic -- potential overlap)

For machine-readable output (useful for large result sets):
```bash
bun ~/.config/pai/Skills/pai-audit/tools/knowledge-lint.ts scan --json
```

### Step 2: AI Review -- Contradiction Detection

The scanner can't detect semantic contradictions. After reviewing the scan output, the AI should:

1. **Read topic clusters** with 3+ overlapping files
2. For each cluster, read the actual file contents
3. Check for:
   - Contradictory advice (one file says X, another says not-X)
   - Superseded entries (newer entry replaces older one but both exist)
   - Redundant entries (two files saying the same thing differently)

**Present contradictions as:**
```
CONTRADICTION: [topic]
  File A: [filename] says "[claim]"
  File B: [filename] says "[conflicting claim]"
  Recommendation: [keep A / keep B / merge / ask user]
```

### Step 3: AI Review -- Knowledge Gaps

Scan for topics that are *referenced* across entries but never get their own dedicated entry:
- Terms that appear in 3+ files but have no dedicated memory file
- Projects mentioned repeatedly with no project memory
- Decisions referenced but not documented

**Present gaps as:**
```
GAP: [topic] mentioned in [N] files but has no dedicated entry
  Referenced in: [file1], [file2], [file3]
  Recommendation: create [suggested-filename].md
```

### Step 4: Present Findings

Compile all results into a single report:

```markdown
## Knowledge Lint Results

**Scanned:** N files across 2 directories

### Deterministic Findings (from scanner)
- Stale: N entries
- Broken refs: N paths
- Orphaned: N files

### AI Findings
- Contradictions: N found
- Superseded entries: N found
- Knowledge gaps: N identified

### Recommended Actions
1. [action 1]
2. [action 2]
...
```

### Step 5: Act on Findings (with user approval)

For each finding category, offer to fix:
- **Stale entries:** Review and either update or remove
- **Broken refs:** Update paths or remove dead references
- **Orphaned files:** Add to MEMORY.md or remove
- **Contradictions:** Merge, update, or ask user to resolve
- **Gaps:** Create new memory entries

**Never auto-fix contradictions without user approval.** The user's judgment determines which version is correct.

---

## Subcommands (for targeted checks)

```bash
# Just stale entries
bun ~/.config/pai/Skills/pai-audit/tools/knowledge-lint.ts stale

# Just broken file references
bun ~/.config/pai/Skills/pai-audit/tools/knowledge-lint.ts broken-refs

# Topic overlap analysis
bun ~/.config/pai/Skills/pai-audit/tools/knowledge-lint.ts topics

# Files missing from MEMORY.md
bun ~/.config/pai/Skills/pai-audit/tools/knowledge-lint.ts orphans
```

---

## Integration with pai-audit

This workflow runs as **Section 8** of the full pai-audit checklist. When running a complete audit, spawn this as one of the parallel agents alongside the other 7 sections.

---

**Last Updated:** 2026-04-20
