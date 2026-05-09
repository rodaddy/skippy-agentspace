# Update Comprehension Ledger

**Purpose:** Record comprehension test results in the ledger for tracking and interview prep.

**When to Use:**
- After completing a comprehension test interview
- User says "update ledger", "record results", "save comprehension scores"

---

## Ledger Location

`~/.config/pai-private/memory/comprehension-ledger.json`

---

## Recording Results

After an interview, use the ledger tool to record:

```bash
bun ~/.config/pai/Skills/comprehension-test/tools/ledger.ts add \
  --project "Project Name" \
  --what-is-this 4 \
  --why-this-approach 3 \
  --what-would-break 2 \
  --what-i-learned 4 \
  --weak-spots "failure mode enumeration, dependency mapping" \
  --bullets-generated 3 \
  --notes "Struggled with Phase 3 edge cases around API dependencies"
```

Confidence scores (1-5) come from the pushback count during the interview:
- 0 pushbacks = 5 (nailed it)
- 1 pushback = 4 (good, minor clarification)
- 2 pushbacks = 3 (adequate, gaps visible)
- 3 pushbacks = 2 (significant gaps)
- 4+ pushbacks = 1 (doesn't understand well)

---

## Viewing Results

```bash
# List all tested projects
bun ~/.config/pai/Skills/comprehension-test/tools/ledger.ts list

# Show gaps across all projects
bun ~/.config/pai/Skills/comprehension-test/tools/ledger.ts gaps
```

---

## Career-Ops Integration

The ledger feeds into interview prep:
- Projects with overall score 4+ -> lead with these in interviews
- Projects with overall score 3 -> mention but don't deep-dive unless asked
- Projects with overall score < 3 -> either retest after studying or omit from portfolio
- Weak spots per project -> career-ops can generate targeted drill questions

---

**Last Updated:** 2026-04-20
