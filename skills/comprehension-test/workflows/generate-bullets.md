# Generate Master Bullets

**Purpose:** Convert a comprehension test artifact into resume-ready bullets compatible with the master-bullets.md format used by career-ops.

**When to Use:**
- After generating an explanation artifact
- User says "generate bullets", "add to master bullets", "resume bullets from this"

---

## Master Bullets Format

Bullets live in `<DEV_DIR>/resumeUpdate/Resumes/master-bullets.md`.

Format per role section:
```markdown
## Company | Location
**Title** | Dates

### Category Label (context for when to include)

- Achievement-based bullet with quantified result.
- Another bullet leading with outcome, not duty.
```

---

## Bullet Generation Rules

### Source Material
- Pull ONLY from the explanation artifact and interview answers
- Every bullet must have a metric or concrete result
- Lead with outcomes, not descriptions of what was built

### Style (from resumeUpdate CLAUDE.md)
- Achievement-based, not duty-based
- Quantify where possible (%, time saved, scale)
- No buzzwords without concrete backing
- No longevity signals ("years of experience")
- Use contractions naturally
- Mix sentence lengths

### Categories
Generate bullets in labeled categories that match master-bullets.md patterns:
- `### Core Bullets (always include)` -- the strongest 2-3
- `### AI & Automation Bullets (include when AI/automation emphasis)` -- if applicable
- `### Infrastructure Bullets (include when ops emphasis)` -- if applicable
- `### Comprehension-Tested` -- special tag indicating these came from a pressure-tested interview, not self-reported

### Quality Gate
Before presenting bullets, verify each one:
- [ ] Leads with outcome or metric, not a description of what was built
- [ ] Contains at least one specific (number, tool name, concrete result)
- [ ] Sounds human, not AI-generated (run mental humanizer check)
- [ ] Maps to something the user actually said in the interview -- no fabrication

---

## Output

Present generated bullets with:
1. The bullets themselves, formatted for copy-paste into master-bullets.md
2. Which section of master-bullets.md they belong in (existing role or new section)
3. Any existing bullets they might replace or complement

Ask: "Want me to append these to master-bullets.md, or just copy them to clipboard?"

If append: edit the file directly under the appropriate role section.
If clipboard: `pbcopy` the formatted bullets.

---

**Last Updated:** 2026-04-20
