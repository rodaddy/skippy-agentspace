# GSD Dependency Map

What skippy-dev reads from GSD's `.planning/` directory, what format it expects, and what breaks if GSD changes upstream.

**Purpose:** Maintain compatibility when GSD updates its file formats. Check this document before absorbing upstream changes via `/skippy:update`.

## Integration Points Overview

| File Pattern | Read By | Risk | Key Dependencies |
|-------------|---------|------|-----------------|
| `.planning/ROADMAP.md` | reconcile, state-consistency | HIGH | `[x]` phase markers, phase headers, progress table |
| `.planning/STATE.md` | reconcile, state-consistency | HIGH | YAML frontmatter (`progress.*`), Current Position section |
| `.planning/phases/NN-*/NN-*-PLAN.md` | reconcile | HIGH | YAML frontmatter + XML `<task>` blocks |
| `.planning/phases/NN-*/NN-*-SUMMARY.md` | reconcile | HIGH | YAML frontmatter (`key-files`), markdown sections |
| `.planning/phases/` (directory structure) | reconcile | MEDIUM | `NN-name/` naming convention for glob discovery |
| `.planning/PROJECT.md` | state-consistency | LOW | Project name, milestone, informational only |

## Which Commands Depend on GSD

| Command | GSD Dependency Level | Notes |
|---------|---------------------|-------|
| `/skippy:reconcile` | **Heavy** -- reads PLAN.md, SUMMARY.md, STATE.md, ROADMAP.md | Core function is comparing GSD artifacts |
| `/skippy:update` | **None** -- only reads `upstreams/*/upstream.json` and upstream repos | Independent of `.planning/` |
| `/skippy:cleanup` | **None** -- operates on ephemeral files only | Independent of `.planning/` |
| `state-consistency.md` (reference) | **Heavy** -- defines cross-file alignment checks | Referenced by reconcile |

---

## PLAN.md Structure

**Path pattern:** `.planning/phases/NN-*/NN-*-PLAN.md`

Reconcile discovers plans via glob: `.planning/phases/<NN>-*/<NN>-*-PLAN.md`

### YAML Frontmatter

```yaml
---
phase: 01-spec-compliance    # Phase identifier
plan: 01                      # Plan number within phase
type: execute                 # Plan type
wave: 1                       # Execution wave
depends_on: []                # Plan dependencies
files_modified:               # <-- RECONCILE READS THIS
  - path/to/file.ts           # Expected file changes (compared against SUMMARY key-files)
  - path/to/other.ts
autonomous: true              # Execution mode
requirements:                 # Requirement IDs (e.g., SPEC-01)
  - REQ-ID

must_haves:                   # <-- RECONCILE READS THIS
  truths:                     # Acceptance criteria -- each is verified PASS/FAIL/UNTESTED
    - "Statement that must be true after execution"
  artifacts:                  # Expected output files
    - path: "path/to/file"
      provides: "description"
      contains: "expected content"
  key_links:                  # Expected cross-file references
    - from: "source"
      to: "target"
      via: "mechanism"
      pattern: "regex"
---
```

**Fields reconcile depends on:**

| Field | Used For | If Missing |
|-------|----------|------------|
| `files_modified` | Compare planned vs actual file changes | Skip file change comparison |
| `must_haves.truths` | Acceptance criteria verification (PASS/FAIL/UNTESTED) | Skip AC section of report |
| `must_haves.artifacts` | Verify expected output files exist | Skip artifact checks |

**If GSD changes this:** Renaming `files_modified` or `must_haves` breaks reconcile's plan-vs-actual comparison. The YAML frontmatter parser is standard -- adding new fields is safe, removing or renaming existing ones is breaking.

### XML Task Blocks

```xml
<tasks>
<task type="auto">
  <name>Task 1: Description here</name>
  <files>path/to/file.ts, path/to/other.ts</files>
  <action>What the task does...</action>
  <verify><automated>verification command</automated></verify>
  <done>Observable completion criteria</done>
</task>
</tasks>
```

**Elements reconcile depends on:**

| Element | Used For | If Missing |
|---------|----------|------------|
| `<task>` wrapper | Task discovery and counting | No tasks found -- empty report |
| `<name>` | Task identification in report table | Task listed as "unnamed" |
| `<files>` | Expected file touchpoints per task | Skip per-task file comparison |
| `<done>` | Completion criteria for DONE/MODIFIED/SKIPPED classification | Cannot assess task completion |

**If GSD changes this:** The XML structure is the highest-risk dependency. If GSD switches from XML to a different task format (YAML blocks, markdown checkboxes, etc.), the entire task extraction logic in reconcile breaks. The `<task type="...">` attribute is read but only for reporting -- reconcile doesn't filter on it.

### Breakage Risk: HIGH

PLAN.md is the primary input to reconciliation. Any structural change to frontmatter field names or XML task element names requires updating the reconcile command's parsing logic.

---

## SUMMARY.md Structure

**Path pattern:** `.planning/phases/NN-*/NN-*-SUMMARY.md`

Reconcile pairs each PLAN.md with its SUMMARY.md using the same prefix (e.g., `02-01-PLAN.md` pairs with `02-01-SUMMARY.md`). A PLAN.md without a matching SUMMARY.md is flagged as incomplete.

### YAML Frontmatter

```yaml
---
phase: 01-spec-compliance
plan: 01
subsystem: infra
tags: [portability, agent-skills-spec]

requires:
  - phase: none
provides:
  - "Description of what this plan produced"
affects: [downstream-phases]

tech-stack:
  added: []
  patterns:
    - "Pattern established"

key-files:                     # <-- RECONCILE READS THIS
  created:                     # Files that didn't exist before
    - path/to/new/file.md
  modified:                    # Files that were changed
    - path/to/existing/file.md

key-decisions:
  - "Decision description"

duration: 3min
completed: 2026-03-07
---
```

**Fields reconcile depends on:**

| Field | Used For | If Missing |
|-------|----------|------------|
| `key-files.created` | Compare against PLAN's `files_modified` (unplanned change detection) | Skip file comparison |
| `key-files.modified` | Same -- detect unplanned or missed files | Skip file comparison |

**If GSD changes this:** Renaming `key-files` or splitting `created`/`modified` into a different structure breaks reconcile's unplanned-change detection. The rest of the frontmatter is informational and not parsed by reconcile.

### Markdown Sections

```markdown
## Accomplishments
- What was done (bullet list)

## Task Commits
1. **Task 1: Name** - `hash` (type)
2. **Task 2: Name** - `hash` (type)

## Deviations from Plan
### Auto-fixed Issues
**1. [Rule N - Type] Description**
- Found during: Task N
- Issue: ...
- Fix: ...

## Issues Encountered
- Issue description
```

**Sections reconcile depends on:**

| Section | Used For | If Missing |
|---------|----------|------------|
| `## Task Commits` or `## Accomplishments` | Task completion evidence -- classifies tasks as DONE/MODIFIED/SKIPPED/ADDED | Cannot determine what was actually done |
| `## Deviations from Plan` | Primary source of drift evidence | Report shows no deviations (may miss real drift) |
| `## Issues Encountered` | Secondary drift evidence | Minor -- deviations section is primary |

**If GSD changes this:** Renaming `## Task Commits` to something else breaks reconcile's section matching. The heading text is matched literally. GSD's summary template defines these headings -- if the template changes, reconcile must update.

### Breakage Risk: HIGH

SUMMARY.md is the other half of reconciliation. Both frontmatter (`key-files`) and markdown section headers (`## Task Commits`, `## Deviations from Plan`) are structurally depended on.

---

## STATE.md Structure

**Path:** `.planning/STATE.md`

Used by reconcile (verification) and state-consistency checks.

### YAML Frontmatter

```yaml
---
gsd_state_version: 1.0
milestone: v1.0
status: executing
stopped_at: "Completed 03-03-PLAN.md"
last_updated: "2026-03-07T06:32:05.276Z"
progress:
  total_phases: 4
  completed_phases: 3        # <-- RECONCILE READS THIS
  total_plans: 7
  completed_plans: 7          # <-- STATE-CONSISTENCY READS THIS
  percent: 86
---
```

**Fields depended on:**

| Field | Read By | Used For | If Missing |
|-------|---------|----------|------------|
| `progress.completed_phases` | reconcile | Verify against ROADMAP `[x]` count | Skip verification step |
| `progress.completed_plans` | state-consistency | Cross-check against SUMMARY.md file count on disk | Cannot validate progress accuracy |
| `status` | state-consistency | Verify phase status matches reality | Skip status check |

### Markdown Sections

```markdown
## Current Position
Phase: 3 of 4 (Command Validation)
Plan: 3 of 3 in current phase
```

**Sections depended on:**

| Section | Read By | Used For |
|---------|---------|----------|
| `## Current Position` | state-consistency | Verify current phase matches ROADMAP's first incomplete phase |

**If GSD changes this:** The `progress.*` YAML fields are the most critical. If GSD renames these or restructures the progress tracking (e.g., moving to a separate progress file), both reconcile verification and state-consistency checks break. The markdown section is parsed loosely -- format changes within the section are tolerable as long as the heading exists.

### Breakage Risk: HIGH

STATE.md is the central coordination file. Changes to `progress.*` field names cascade through both reconcile and state-consistency.

---

## ROADMAP.md Structure

**Path:** `.planning/ROADMAP.md`

Used by reconcile (phase detection) and state-consistency (alignment checks).

### Phase Completion Markers

```markdown
- [x] **Phase 1: Spec Compliance** - Description (completed YYYY-MM-DD)
- [x] **Phase 2: Plugin Packaging** - Description (completed YYYY-MM-DD)
- [ ] **Phase 3: Command Validation** - Description
```

**Parsing rules:**
- `[x]` = completed phase
- `[ ]` = incomplete phase
- Reconcile finds the **last** `[x]` row to identify the most recently completed phase
- State-consistency finds the **first** `[ ]` row to identify the current phase

**If GSD changes this:** The `[x]` / `[ ]` checkbox format is standard markdown. If GSD switches to a different completion indicator (e.g., status column in a table, emoji markers, or separate "completed" sections), phase detection breaks entirely.

### Progress Table

```markdown
| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Spec Compliance | 1/1 | Complete | 2026-03-07 |
| 2. Plugin Packaging | 3/3 | Complete | 2026-03-07 |
```

**Used by:** State-consistency checks (verifying plan counts match disk reality).

**If GSD changes this:** The `N/M` format in "Plans Complete" column is parsed for plan counts. Table format changes (column reordering, renaming) break this.

### Phase Detail Sections

```markdown
### Phase 1: Spec Compliance
**Goal**: ...
**Depends on**: ...
**Requirements**: REQ-01, REQ-02
**Success Criteria** (what must be TRUE):
  1. Criterion one
  2. Criterion two
**Plans**: N plans

Plans:
- [ ] 01-01-PLAN.md -- Description
- [x] 01-01-PLAN.md -- Description (if manually checked)
```

**Used by:** Reconcile reads plan lists to discover plan files for a phase (backup to glob discovery).

**If GSD changes this:** The `Plans:` sub-section with plan file names is a secondary discovery path. The primary path (glob) is resilient to this changing. Low risk.

### Breakage Risk: HIGH (completion markers), MEDIUM (progress table), LOW (detail sections)

---

## Directory Structure Dependencies

### Phase Directory Convention

```
.planning/
  phases/
    01-spec-compliance/       # NN-slug format
      01-01-PLAN.md           # NN-PP-PLAN.md
      01-01-SUMMARY.md        # NN-PP-SUMMARY.md
      RECONCILIATION.md       # Output of /skippy:reconcile
      CONTEXT.md              # Optional phase context
    02-plugin-packaging/
      02-01-PLAN.md
      02-01-SUMMARY.md
      02-02-PLAN.md
      02-02-SUMMARY.md
```

**Naming conventions depended on:**

| Convention | Used For | If Changed |
|-----------|----------|------------|
| `NN-slug/` directory naming | Phase discovery via glob | Reconcile can't find phase dirs |
| `NN-PP-PLAN.md` file naming | Plan discovery within a phase | Reconcile can't find plans |
| `NN-PP-SUMMARY.md` file naming | Plan-summary pairing by prefix match | Reconcile can't pair plans with summaries |
| Same `NN-PP` prefix for PLAN/SUMMARY | Pairing logic | Plans appear orphaned |

**If GSD changes this:** The `NN-` numeric prefix convention is fundamental to discovery. If GSD switches to non-numeric phase directories or a different file naming scheme, all glob patterns break. This is the most fragile structural dependency.

### Breakage Risk: MEDIUM

Directory naming changes are unlikely (established convention across many GSD projects) but would require updating all glob patterns in reconcile.

---

## Upstream Monitoring

When `/skippy:update` detects GSD changes, check this document against the changed files:

| GSD File Changed | Check These Sections |
|-----------------|---------------------|
| `templates/plan.md` or plan-related | PLAN.md Structure (frontmatter + XML) |
| `templates/summary.md` | SUMMARY.md Structure (frontmatter + sections) |
| `bin/gsd-tools.cjs` (state commands) | STATE.md Structure (progress fields) |
| `workflows/execute-plan.md` | PLAN.md XML task format, SUMMARY.md sections |
| `workflows/create-plan.md` | PLAN.md YAML frontmatter fields |

---

## Risk Summary

| Risk Level | Count | Items |
|-----------|-------|-------|
| **HIGH** | 4 | PLAN.md structure, SUMMARY.md structure, STATE.md progress fields, ROADMAP.md completion markers |
| **MEDIUM** | 2 | Directory naming convention, ROADMAP.md progress table |
| **LOW** | 2 | PROJECT.md alignment, ROADMAP.md detail sections |

**Most dangerous upstream change:** GSD replacing XML `<task>` blocks with a different format. This would break the core reconciliation logic with no graceful fallback.

**Safest upstream changes:** Adding new YAML frontmatter fields, adding new markdown sections, adding new file types to `.planning/`. These are additive and don't break existing parsing.
