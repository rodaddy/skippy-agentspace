---
name: prd-to-issues
description: Break a PRD into independently-grabbable GitHub issues with vertical slicing, HITL/AFK classification, and dependency links. USE WHEN user says "prd-to-issues", "create issues from prd", "break this into tickets", or has a completed PRD that needs team-visible tracking via GitHub Issues.
allowed-tools: "Read,Write,Edit,Bash,Grep,Glob,Agent"
metadata:
  version: 0.1.0
  author: Rico
  category: workflow
---

# PRD to Issues -- Vertical Slice Issue Generator

Convert a completed PRD into tracked GitHub issues that agents or humans can grab independently.
Each issue is a vertical tracer bullet -- cuts through ALL layers end-to-end (schema + API + UI + tests), not horizontal slices.

## Trigger

- `/prd-to-issues` -- reads local `.prd/prd.json`
- `/prd-to-issues <issue-number>` -- reads PRD from GitHub issue
- `/prd-to-issues --dry-run` -- show planned issues without creating them

## When to Use

After `/prd` creates a PRD and user picks the GH Issues path (team visibility).
NOT for solo local work -- use `/drive` for that.

## Core Principles

1. **Vertical slices only** -- each issue cuts end-to-end through all integration layers. Never "build the API" then "build the UI" separately.
2. **HITL/AFK classification** -- every issue is tagged. AFK = agent can ship without human review. HITL = needs architectural decision or design sign-off.
3. **No file paths in issues** -- describe behaviors and contracts, not implementation details. File paths go stale. "A good issue reads like a spec; a bad one reads like a diff."
4. **Dependency chains** -- issues link via "Blocked by #N". No circular deps. Independent issues can run in parallel.
5. **Q&A collocation** -- interview decisions captured as Q/A pairs in the parent PRD for future context.

## Classification Guide

| Classification | Meaning | Examples |
|---------------|---------|----------|
| **AFK** | Agent can implement and merge without human interaction | CRUD endpoint, test coverage, migration, config change |
| **HITL** | Requires human review before merge -- architectural decision, UX judgment, external integration | Auth flow design, payment integration, schema that affects other services |

**Default to AFK.** Only mark HITL when genuine human judgment is needed, not just "this is complex." Complex != needs human. Uncertain design direction == needs human.

## Workflow

### Phase 1: Ingest PRD

**From local `.prd/prd.json`:**
```bash
# Read the PRD
cat .prd/prd.json | jq '.stories[] | {id, title, description, acceptance_criteria, depends_on}'
```

**From GitHub issue:**
```bash
gh issue view <number> --json title,body
```

Extract: project name, story list, acceptance criteria, dependencies, stack info.

### Phase 2: Explore Current State

Spawn an explore agent to understand:
- Current codebase structure relevant to the PRD
- Existing patterns the implementation should follow
- Integration points between stories

This informs how to slice -- you can't cut vertically without knowing the layers.

### Phase 3: Slice into Tracer Bullets

For each story (or group of related stories), create a vertical slice:

**Good slice (vertical):**
> "Add commodity price alert: schema for alert rules, API endpoint to create/list/trigger alerts, UI toggle on commodity detail page, test that alert fires on threshold cross."

**Bad slice (horizontal):**
> "Add alert database tables" then "Add alert API" then "Add alert UI"

**Slicing rules:**
- Each slice MUST be demoable on its own -- it produces a visible, testable result
- Each slice MUST include its own tests
- Merge too-small slices -- don't spin up an agent for a 10-line change
- Split too-large slices -- if it touches more than 3 modules, it's probably compound
- Max ~8 issues per PRD. If you need more, the PRD scope is too broad.

### Phase 4: Classify and Interview

Present the proposed slices to the user via AskUserQuestion:

```
I've sliced the PRD into N issues. Review and adjust:

1. [AFK] Add commodity alert rules (schema + API + basic UI)
2. [HITL] Design alert notification delivery (email vs push vs in-app)
3. [AFK] Alert trigger engine (background job + threshold check + tests)
4. [AFK] Alert management UI (list, edit, delete alerts)
5. [HITL] Alert rate limiting and abuse prevention

Adjust classifications? Merge/split any issues? Change ordering?
```

Interview questions to ask:
- **Granularity:** "Are issues 1 and 4 too small to be separate? Should they merge?"
- **Classification:** "I marked #2 as HITL because the notification channel is a design decision. Agree?"
- **Dependencies:** "Issue 3 depends on 1 (needs schema). Any other blocking relationships?"
- **Priority:** "Which slice should ship first to unblock the most work?"

Capture all Q&A in collocated format (see Phase 6).

### Phase 5: Create GitHub Issues

Create issues in dependency order using `gh issue create`.

**Issue template:**

```bash
gh issue create --title "[AFK] Add commodity alert rules" --body "$(cat <<'EOF'
## Parent PRD
Closes requirement from #<prd-issue-number> (or references .prd/prd.json)

## What to Build
<End-to-end behavior description. NO file paths, NO function names.
Describe what the user/system should be able to do when this is done.>

## Acceptance Criteria
- [ ] Alert rules can be created with commodity, threshold, and direction
- [ ] Alert rules are listed on the commodity detail view
- [ ] Creating a duplicate rule returns a clear error
- [ ] Unit and integration tests cover create, list, and duplicate scenarios

## Classification
**AFK** -- agent can implement and merge without human review.

## Blocked By
- #<issue-number> (if any)

## User Stories Addressed
- US-001, US-003 (from PRD)

---
Generated by `/prd-to-issues`
EOF
)"
```

**After creating all issues**, add a comment to the parent PRD issue (if it exists) linking to all created issues:

```bash
gh issue comment <prd-number> --body "$(cat <<'EOF'
## Issues Created

| # | Title | Classification | Blocked By |
|---|-------|---------------|------------|
| #10 | Add commodity alert rules | AFK | -- |
| #11 | Design alert notification delivery | HITL | -- |
| #12 | Alert trigger engine | AFK | #10 |
| #13 | Alert management UI | AFK | #10 |
| #14 | Alert rate limiting | HITL | #12 |

AFK issues are ready for agent execution via `/drive`.
HITL issues need human review before implementation.
EOF
)"
```

### Phase 6: Capture Q&A (Collocated Format)

All interview decisions from Phase 4 go into the parent PRD issue as a comment, or into `.prd/progress.md` if local:

```markdown
## Design Decisions (Q&A)

**Q: Should alert rules support multiple thresholds per commodity?**
A: No -- one rule per commodity/direction pair. Multiple thresholds = multiple rules. Simpler model, easier to test.

**Q: Email vs push vs in-app for notifications?**
A: In-app only for v1. Email is Phase 2. Push requires mobile work we're not ready for.

**Q: Should we rate-limit alert creation or alert firing?**
A: Both. Creation: max 50 rules per user. Firing: deduplicate within 5min window.
```

This preserves the reasoning behind decisions. When an agent picks up an issue 3 weeks later, the Q&A context is right there.

## Output

- GitHub issues with labels, dependency links, and acceptance criteria
- Parent PRD issue updated with issue index table
- Q&A decisions captured in collocated format
- Summary printed to terminal with issue numbers and URLs

## What This Skill Does NOT Do

1. **Execute the issues** -- use `/drive` for AFK batch execution or assign HITL issues to humans
2. **Replace `/prd`** -- this skill consumes PRD output, it doesn't create PRDs
3. **Manage sprints/milestones** -- it creates issues, you organize them however you want
4. **Auto-close the PRD** -- the parent PRD stays open until all child issues are done
