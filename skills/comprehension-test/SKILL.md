---
name: comprehension-test
description: |
  Interview loop that pressure-tests whether you actually understand something you built.
  Four-phase structured interview with pushback on vague answers. Outputs explanation
  artifact, resume-ready master bullets, and comprehension ledger entry.

  USE WHEN user says "comprehension test", "test my understanding", "explanation artifact",
  "prove I understand", "do I actually understand this", "comprehension check",
  "interview me about", "pressure test my knowledge", or wants to articulate what they
  know about a project they built.
---

## Workflow Routing (SYSTEM PROMPT)

**When user wants to run a comprehension test on a project:**
Examples: "comprehension test on PAI", "test my understanding of MyProject", "prove I understand the audiobook pipeline", "interview me about sample-app"
-> **READ:** ~/.config/pai/Skills/comprehension-test/workflows/interview-loop.md
-> **EXECUTE:** Run the four-phase interview one question at a time, then route to artifact generation

**When user wants to generate an explanation artifact from existing notes:**
Examples: "generate artifact from these notes", "turn this into an explanation artifact", "format my answers as an artifact"
-> **READ:** ~/.config/pai/Skills/comprehension-test/workflows/generate-artifact.md
-> **EXECUTE:** Assemble polished explanation artifact from interview answers

**When user wants resume bullets from a comprehension test:**
Examples: "generate bullets from this", "add to master bullets", "create resume bullets from artifact"
-> **READ:** ~/.config/pai/Skills/comprehension-test/workflows/generate-bullets.md
-> **EXECUTE:** Convert artifact into master-bullets.md format entries

**When user wants to check their comprehension ledger:**
Examples: "show my comprehension scores", "which projects have I tested", "what are my weak spots", "comprehension ledger"
-> **EXECUTE:** `bun ~/.config/pai/Skills/comprehension-test/tools/ledger.ts list`

**When user wants to update or record comprehension results:**
Examples: "update ledger", "record comprehension results"
-> **READ:** ~/.config/pai/Skills/comprehension-test/workflows/update-ledger.md
-> **EXECUTE:** Record interview results in comprehension ledger

---

## When to Activate This Skill

### Direct Comprehension Test Requests (Categories 1-4)
- "comprehension test", "comprehension check", "understanding check"
- "run comprehension test", "do comprehension test", "start comprehension test"
- "quick comprehension test", "deep comprehension test", "full comprehension test"
- "comprehension test on [project]", "comprehension test for [project]"

### Understanding & Knowledge Verification (Categories 5-7)
- "do I actually understand this", "prove I understand", "test my knowledge"
- "interview me about [project]", "grill me on [project]"
- "explanation artifact", "generate artifact", "comprehension artifact"
- "can I explain what I built", "pressure test my knowledge"

### Portfolio & Career Integration (Category 8)
- "comprehension ledger", "show my scores", "what are my weak spots"
- "which projects have I tested", "comprehension gaps"
- "generate bullets from test", "add comprehension bullets to resume"

---

## Core Capabilities

1. **Four-Phase Interview** -- Structured pushback interview (What Is This, Why This Approach, What Would Break, What I Learned)
2. **Explanation Artifact** -- Polished, honest, portfolio-ready artifact in your voice
3. **Master Bullets** -- Resume-ready bullets that feed into career-ops pipeline
4. **Comprehension Ledger** -- Per-project, per-section confidence tracking with weak spot identification

---

## Workflow Overview

- **interview-loop.md** -- Core four-phase interview with follow-ups and pushback
- **generate-artifact.md** -- Assemble the explanation artifact from interview answers
- **generate-bullets.md** -- Convert artifact into master-bullets.md compatible entries
- **update-ledger.md** -- Record results in comprehension ledger

## Tools

- **tools/ledger.ts** -- CRUD for comprehension-ledger.json (add, list, update, gaps)

---

## Integration Points

- **career-ops** -- Bullets generated here feed into `master-bullets.md` at `<DEV_DIR>/resumeUpdate/Resumes/master-bullets.md`
- **career-ops interview-prep** -- Ledger weak spots become drill questions for specific projects
- **Known projects** -- Can pre-load context from any project with a CLAUDE.md or architecture docs in the workspace

---

## The Interview Philosophy

This is NOT a friendly self-assessment. The interview:
- Pushes back on marketing-speak, hand-waving, and "it just works"
- Names comprehension gaps honestly rather than papering over them
- Treats Phase 3 (What Would Break) as the hardest section -- this is where the real understanding lives
- Records how many follow-up pushbacks each section required (more pushbacks = lower confidence)
- Produces an artifact that's honest, not flattering

The per-section confidence scoring is the killer feature. After testing a project, the ledger shows exactly where your understanding is strong vs. where you'd stumble in an interview. Career-ops interview-prep can then generate drill questions targeting your weakest sections.

---

**Related Skills:**
- `career-ops` -- Resume tailoring and job application pipeline
- `brain` -- Knowledge base queries for project context

**Last Updated:** 2026-04-20
