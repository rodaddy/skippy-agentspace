# Phase 3: Command Validation - Research

**Researched:** 2026-03-07
**Domain:** Shell scripting, GSD .planning/ structure parsing, git operations, file management
**Confidence:** HIGH

## Summary

Phase 3 validates and hardens three commands: `/skippy:reconcile` (a Claude Code command file that instructs the agent to parse GSD `.planning/` artifacts), `/skippy:update` (a bash script that clones upstream repos and tracks versions), and `/skippy:cleanup` (a bash script that quarantines or nukes ephemeral files). All three exist and run but have concrete bugs and gaps that need fixing before they can be called "validated."

The reconcile command is purely a markdown prompt file -- it tells the agent what to do but has never been tested against a real completed phase. The update script has two critical bugs: it uses `source` to load `.versions` (arbitrary code execution risk) and stores short SHA hashes (ambiguous, break on fetch prune). The cleanup script's default quarantine path uses `$TMPDIR` which on macOS resolves to a per-session `/var/folders/` path that gets cleaned on reboot, defeating the purpose of quarantine-before-delete.

**Primary recommendation:** Fix the three concrete bugs in the shell scripts first (source, short SHA, TMPDIR), then validate reconcile against this project's own completed Phase 1 and Phase 2 as real test fixtures.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CMD-01 | `/skippy:reconcile` works end-to-end against a real `.planning/` project with completed GSD phases -- reads PLAN.md, compares to execution output, reports deviations | GSD structure analysis (Section: GSD .planning/ Structure), reconciliation template (Section: Reconcile Command Analysis), this project's own phases 1-2 as test fixtures |
| CMD-02 | `/skippy:update` hardened -- clones to `~/.cache/` (not `/tmp/`), parses `.versions` safely (no `source`), uses full SHA hashes, survives macOS reboot | Three specific bugs identified (Section: Update Script Analysis), fix patterns documented |
| CMD-03 | `/skippy:cleanup` validated -- quarantine and nuke modes both work correctly, space reporting accurate, empty dirs recreated after cleanup | TMPDIR bug identified (Section: Cleanup Script Analysis), edge cases catalogued |
</phase_requirements>

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | 3.2+ (macOS default) | Script runtime | Project constraint: `#!/usr/bin/env bash`, no external deps |
| git | 2.39+ | Upstream clone, diff, log, rev-parse | Required for update script and reconcile git history analysis |
| du/awk/sed | macOS built-in | File size calculation, text processing | Used by cleanup for space reporting |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| Claude Code command files (.md) | Define reconcile behavior as agent instructions | reconcile.md is a prompt, not a script |
| `${CLAUDE_SKILL_DIR}` | Portable path resolution at runtime | All script invocations in SKILL.md body |
| Environment variables | Override defaults (SKIPPY_CACHE_DIR, SKIPPY_QUARANTINE_DIR) | User customization without editing scripts |

### Not Applicable

This phase does not add any new libraries or dependencies. All three commands use bash + standard Unix tools. The project constraint explicitly prohibits TypeScript/Node dependencies.

## Architecture Patterns

### GSD .planning/ Structure (What Reconcile Must Parse)

Based on analysis of this project's completed phases 1 and 2:

```
.planning/
  PROJECT.md              # Project-level context, key decisions
  REQUIREMENTS.md         # Requirement IDs (SPEC-01, CMD-01, etc.)
  ROADMAP.md              # Phase list with [x] completion markers, success criteria
  STATE.md                # YAML frontmatter with current_phase, status, progress
  config.json             # GSD config (mode, workflow toggles)
  phases/
    01-spec-compliance/
      CONTEXT.md           # User decisions (optional, from /gsd:discuss-phase)
      01-RESEARCH.md       # Phase research
      01-VALIDATION.md     # Validation strategy
      01-VERIFICATION.md   # Post-execution verification
      01-01-PLAN.md        # Plan with YAML frontmatter + <tasks> XML
      01-01-SUMMARY.md     # Execution summary with YAML frontmatter
    02-plugin-packaging/
      02-RESEARCH.md
      02-VERIFICATION.md
      02-01-PLAN.md        # Multiple plans per phase
      02-01-SUMMARY.md
      02-02-PLAN.md
      02-02-SUMMARY.md
      02-03-PLAN.md
      02-03-SUMMARY.md
```

### PLAN.md Structure (What Reconcile Reads)

Plans have two key sections to parse:

**1. YAML frontmatter** with structured metadata:
```yaml
---
phase: 01-spec-compliance
plan: 01
type: execute
wave: 1
files_modified:
  - skills/skippy-dev/SKILL.md
  - skills/skippy-dev/commands/reconcile.md
requirements:
  - SPEC-01
  - SPEC-02
must_haves:
  truths:
    - "No hardcoded absolute paths exist in any skill file under skills/"
  artifacts:
    - path: "skills/skippy-dev/SKILL.md"
      provides: "Spec-compliant skill entry point"
      contains: "metadata:"
---
```

**2. XML task blocks** in the body:
```xml
<tasks>
<task type="auto">
  <name>Task 1: Fix hardcoded paths</name>
  <files>skills/skippy-dev/SKILL.md, skills/skippy-dev/commands/reconcile.md</files>
  <action>...</action>
  <verify><automated>command here</automated></verify>
  <done>Observable completion signal</done>
</task>
</tasks>
```

### SUMMARY.md Structure (What Reconcile Compares Against)

Summaries have:

**1. YAML frontmatter** with execution metadata:
```yaml
---
phase: 01-spec-compliance
plan: 01
requirements-completed: [SPEC-01, SPEC-02, SPEC-03, STRU-01]
duration: 3min
completed: 2026-03-07
key-files:
  created: []
  modified:
    - skills/skippy-dev/SKILL.md
key-decisions:
  - "Relative @../ paths for command file context refs"
---
```

**2. Markdown body** with sections:
- `## Accomplishments` -- what was done
- `## Task Commits` -- commit hashes per task
- `## Files Created/Modified` -- actual file changes
- `## Decisions Made` -- runtime decisions
- `## Deviations from Plan` -- critical for reconciliation
- `## Issues Encountered`

### Pattern: Reconcile is a Prompt, Not a Script

The `/skippy:reconcile` command is a Claude Code command file (markdown). It does NOT execute a bash script. Instead, it instructs the agent to:
1. Read `.planning/` files
2. Compare plan vs summary
3. Check state consistency
4. Output a reconciliation report

This means reconcile's "validation" is about ensuring the prompt produces correct, useful output when run against real data -- not about fixing bash bugs. The command file needs to give the agent enough structure to parse the GSD artifacts correctly.

### Pattern: Update and Cleanup ARE Scripts

Both `/skippy:update` and `/skippy:cleanup` delegate to bash scripts. The command files (.md) just instruct the agent to run the script and interpret the output.

## Reconcile Command Analysis

### Current State

The reconcile.md command file references:
- `@../SKILL.md` -- loads skill context
- `@../references/reconciliation.md` -- loads reconciliation template
- `@../references/state-consistency.md` -- loads state checks

The process section says "Follow the `/skippy:reconcile` workflow in the SKILL.md" which has 7 steps.

### What's Missing / Needs Validation

**1. No guidance on finding "most recently completed phase"**
The command says "Find the most recently completed phase (check STATE.md or scan phases/ dirs)" but doesn't specify HOW. The agent needs to:
- Read STATE.md YAML frontmatter for `progress.completed_phases`
- Read ROADMAP.md and find the last `[x]` phase
- Scan `phases/` directories for the highest-numbered dir with SUMMARY.md files
- These should agree (state consistency check)

**2. No guidance on parsing PLAN.md task structure**
Plans use XML `<task>` blocks with `<name>`, `<files>`, `<action>`, `<verify>`, `<done>` children. The reconciliation template in `references/reconciliation.md` expects a task-by-task comparison but doesn't mention the XML format. The agent needs to know to extract tasks from `<tasks>` blocks.

**3. No guidance on handling multi-plan phases**
Phase 2 had 3 plans (02-01, 02-02, 02-03). Reconciliation needs to handle all plans in a phase, not just one. The current prompt says "Read the phase's PLAN.md" (singular) but phases can have multiple plans.

**4. No guidance on git diff for unplanned file changes**
The reconciliation template says "Files changed that weren't in the plan? Flag them." This requires knowing the plan's commit range (from SUMMARY.md `## Task Commits` section) and running `git diff --name-only` to compare planned vs actual file lists.

**5. SUMMARY.md "Deviations from Plan" section is the key input**
Both Phase 1 and Phase 2 summaries have explicit `## Deviations from Plan` sections. The reconcile command should be told to look for this section as primary evidence of drift.

### What Reconcile Should Output

Per `references/reconciliation.md`, the report template includes:
- Task Results table (DONE/MODIFIED/SKIPPED/ADDED)
- Acceptance Criteria table (PASS/FAIL/UNTESTED)
- Deviations section (unplanned changes, scope drift)
- State Consistency section (STATE.md, ROADMAP.md, PROJECT.md alignment)
- Verdict (CLEAN/MINOR_DRIFT/MAJOR_DRIFT/BLOCKED)

### Test Fixture: This Project's Own Phases

Phase 1 (1 plan, 3 tasks, 1 deviation) and Phase 2 (3 plans, 4+ tasks, 0 deviations) are ideal test fixtures. Phase 1 has an explicit deviation (shell scripts had hardcoded paths not listed in the plan), making it a non-trivial reconciliation case.

## Update Script Analysis

### Bug 1: `source "$VERSIONS_FILE"` (CRITICAL)

**Line 24:** `source "$VERSIONS_FILE"` executes `.versions` as bash code. The file contains:
```
gsd_hash=none
paul_hash=none
last_check=never
```

This works today but is a security risk -- any content in `.versions` gets executed. If the file gets corrupted or contains shell metacharacters, arbitrary commands run.

**Fix:** Replace `source` with safe key=value parsing:
```bash
gsd_hash=$(grep '^gsd_hash=' "$VERSIONS_FILE" | cut -d= -f2)
paul_hash=$(grep '^paul_hash=' "$VERSIONS_FILE" | cut -d= -f2)
last_check=$(grep '^last_check=' "$VERSIONS_FILE" | cut -d= -f2)
```

Or use a while-read loop:
```bash
while IFS='=' read -r key value; do
    case "$key" in
        gsd_hash) gsd_hash="$value" ;;
        paul_hash) paul_hash="$value" ;;
        last_check) last_check="$value" ;;
    esac
done < "$VERSIONS_FILE"
```

### Bug 2: `--short` SHA Hashes (MEDIUM)

**Lines 41, 75:** `git rev-parse --short HEAD` produces 7-character hashes. Short hashes:
- Can become ambiguous as the repo grows
- Break `git diff old..new` comparisons when fetched objects change the minimum unique prefix
- Don't match between different clones

**Fix:** Remove `--short` flag to get full 40-character SHA:
```bash
GSD_CURRENT=$(git rev-parse HEAD)
PAUL_CURRENT=$(git rev-parse HEAD)
```

Display can still truncate for readability, but store the full hash.

### Bug 3: Stale `/tmp/skippy-upstream/` Reference in update.md

**update.md line 22** still says: "read the relevant files from `/tmp/skippy-upstream/`"

The script itself was fixed in Phase 1 to use `~/.cache/skippy-upstream` (via `SKIPPY_CACHE_DIR`), but the command file prompt text still references `/tmp/`. This means the agent gets wrong instructions about where to find cloned repos.

**Fix:** Update line 22 to reference `~/.cache/skippy-upstream` (or `$SKIPPY_CACHE_DIR`).

### Bug 4: `git reset --hard origin/main` Assumes Branch Name (LOW)

**Lines 34, 68:** The script assumes the upstream default branch is `main`. Both GSD and PAUL currently use `main`, but if either switches to a different default branch, the script silently breaks.

**Fix:** Use `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'` to detect the default branch, or at minimum document the assumption.

### Edge Cases for Update

| Case | Current Behavior | Expected Behavior |
|------|-----------------|-------------------|
| No network | `git clone` fails, `set -e` exits script | Should print informative error, continue to next repo |
| Partial clone (GSD works, PAUL fails) | Script exits on PAUL failure | Should report GSD results, note PAUL failure |
| `.versions` file missing | Creates new one with `none` values | Correct (already handled) |
| First run (no cached repos) | Clones both repos | Correct (already handled) |
| Upstream force-pushed (old hash gone) | `git diff old..new` fails, fallback message shown | Correct (already handled with `|| echo` fallback) |

## Cleanup Script Analysis

### Bug 1: TMPDIR Quarantine Path (MEDIUM)

**Line 10:** `QUARANTINE_BASE="${SKIPPY_QUARANTINE_DIR:-${TMPDIR:-/tmp}/skippy-cleanup}"`

On macOS, `$TMPDIR` resolves to something like `/var/folders/xx/xxxxxxxxxx/T/` which:
- Is per-user and per-session
- Gets cleaned by macOS's periodic maintenance
- Defeats the purpose of "quarantine for later review"

The env var override (`SKIPPY_QUARANTINE_DIR`) was added in Phase 1, but the default is still bad.

**Fix:** Change the default fallback chain:
```bash
QUARANTINE_BASE="${SKIPPY_QUARANTINE_DIR:-${HOME}/.cache/skippy-quarantine}"
```

Using `~/.cache/` follows XDG convention and survives reboots.

### Functional Verification Needed

| Test Case | What to Check |
|-----------|--------------|
| Quarantine mode with existing targets | Files move to quarantine, originals replaced with empty dirs |
| Quarantine mode with no targets | Script completes with "SKIP" messages, no errors, 0 KB freed |
| Nuke mode | Files deleted permanently, empty dirs recreated |
| Mixed targets (some exist, some don't) | Existing targets processed, missing ones skipped |
| Space reporting accuracy | Compare `du -sk` output with actual freed space |
| Invalid mode flag | "ERROR: Unknown mode" message, exit 1 |
| Empty target directories | SKIP message (already handled -- checks `size_bytes -eq 0`) |
| Quarantine dir creation | `mkdir -p` creates nested path on first run |

### Edge Case: Target Path Contains Spaces

**Line 46:** The `sed` and `tr` pipeline for quarantine dest path:
```bash
dest="$QUARANTINE_DIR/$(echo "$target" | sed "s|$HOME/||" | tr '/' '_')"
```

This is safe because the TARGETS array uses `$HOME` prefix which doesn't typically contain spaces. But if `$HOME` itself contains spaces (rare on macOS, possible on other systems), the `sed` pattern breaks. LOW risk but worth quoting.

### Edge Case: `du` on Symlinks

If any target directory contains symlinks to large files, `du -sk` counts the actual file size, not the link size. This means:
- Space "freed" by quarantine = moving the symlink, not the target
- Reported space may not match actual disk recovery

LOW risk for the default targets (`~/.claude/debug`, `~/.claude/telemetry`, `~/.config/pai/history`, `~/.config/pai/logs`) which are unlikely to contain symlinks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML frontmatter parsing | Custom regex parser | Agent's built-in markdown understanding | reconcile.md is a prompt -- the agent can read YAML natively |
| XML task extraction | Custom bash XML parser | Agent's built-in text parsing | Same -- reconcile runs as an agent prompt, not a script |
| Key-value file parsing | `source` (bash eval) | `grep + cut` or `while IFS='=' read` | Security: source executes arbitrary code |
| Git default branch detection | Hardcode `main` | `git symbolic-ref refs/remotes/origin/HEAD` | Repos can change default branch names |

**Key insight:** The reconcile command is a Claude Code prompt, not a bash script. The "parsing" is done by the LLM reading files, not by regex. This means the command file's job is to give clear instructions about WHAT to parse and WHERE to find it, not HOW to parse it.

## Common Pitfalls

### Pitfall 1: Treating Reconcile Like a Script

**What goes wrong:** Trying to write bash that parses GSD plan YAML and XML
**Why it happens:** Natural instinct to automate everything in bash
**How to avoid:** Reconcile is and should remain a Claude Code command file (prompt). The agent reads the files and produces the report. The "fix" is improving the prompt instructions, not writing a parser.
**Warning signs:** If anyone starts writing `sed`/`awk` to extract task names from `<task>` XML blocks, stop.

### Pitfall 2: Forgetting Multi-Plan Phases

**What goes wrong:** Reconcile report only covers the first plan in a phase
**Why it happens:** Phase 1 had 1 plan, so the initial implementation works. Phase 2 had 3 plans, which exposes the gap.
**How to avoid:** The reconcile prompt must instruct the agent to glob for `NN-*-PLAN.md` files and process each one.
**Warning signs:** Reconcile report says "1 task" for Phase 2 when there were actually 4+ tasks across 3 plans.

### Pitfall 3: source in Shell Scripts

**What goes wrong:** `.versions` file with unexpected content causes arbitrary command execution
**Why it happens:** `source` is convenient for loading key=value pairs
**How to avoid:** Use `grep + cut` or `while IFS='=' read` for safe key-value parsing
**Warning signs:** Any `source` call on a file that isn't a carefully controlled script.

### Pitfall 4: Short Git Hashes in Stored State

**What goes wrong:** `git diff old..new` fails because short hash is ambiguous or old hash was garbage-collected
**Why it happens:** `--short` is more human-friendly but not stable over time
**How to avoid:** Store full 40-char SHA, display truncated only in output
**Warning signs:** "full diff unavailable -- old hash may be gone" messages.

### Pitfall 5: macOS TMPDIR Impermanence

**What goes wrong:** Quarantined files disappear after reboot
**Why it happens:** macOS sets `$TMPDIR` to a session-specific `/var/folders/` path that gets cleaned
**How to avoid:** Use `~/.cache/` for anything that should survive reboots
**Warning signs:** User quarantines files, reboots, files are gone.

### Pitfall 6: set -e Kills Partial Progress

**What goes wrong:** Update script fails on PAUL clone and never reports GSD results
**Why it happens:** `set -e` exits on first non-zero exit code
**How to avoid:** Use `|| true` or explicit error handling for network operations that can fail independently
**Warning signs:** "Cloning PAUL..." is the last output, no version update for GSD.

## Code Examples

### Safe .versions Parsing (Replaces `source`)

```bash
# Source: project analysis of skippy-update.sh line 24
# Current (unsafe): source "$VERSIONS_FILE"
# Fixed (safe):
gsd_hash="none"
paul_hash="none"
last_check="never"

if [[ -f "$VERSIONS_FILE" ]]; then
    while IFS='=' read -r key value; do
        case "$key" in
            gsd_hash)   gsd_hash="$value" ;;
            paul_hash)  paul_hash="$value" ;;
            last_check) last_check="$value" ;;
        esac
    done < "$VERSIONS_FILE"
fi
```

### Full SHA Storage with Short Display

```bash
# Source: project analysis of skippy-update.sh lines 41, 75
# Current: GSD_CURRENT=$(git rev-parse --short HEAD)
# Fixed:
GSD_CURRENT=$(git rev-parse HEAD)
echo "  Current: ${GSD_CURRENT:0:10}"  # Display first 10 chars
# Store full hash in .versions
```

### Resilient Network Operations

```bash
# Source: project analysis of skippy-update.sh lines 31-38
# Current: set -e causes exit on clone failure
# Fixed: per-repo error handling
fetch_repo() {
    local name="$1" url="$2" dir="$3"
    echo "--- $name ---"
    if [[ -d "$dir/.git" ]]; then
        if ! (cd "$dir" && git fetch origin --quiet 2>/dev/null); then
            echo "  WARNING: fetch failed (network issue?). Using cached version."
            return 1
        fi
        (cd "$dir" && git reset --hard origin/main --quiet 2>/dev/null)
    else
        if ! git clone --quiet "$url" "$dir" 2>/dev/null; then
            echo "  ERROR: clone failed. Check network connection."
            return 1
        fi
    fi
    return 0
}
```

### Persistent Quarantine Default

```bash
# Source: project analysis of skippy-cleanup.sh line 10
# Current: QUARANTINE_BASE="${SKIPPY_QUARANTINE_DIR:-${TMPDIR:-/tmp}/skippy-cleanup}"
# Fixed:
QUARANTINE_BASE="${SKIPPY_QUARANTINE_DIR:-${HOME}/.cache/skippy-quarantine}"
```

### Reconcile Prompt Enhancement (Multi-Plan Awareness)

```markdown
## Process (enhanced)

1. Identify the project's `.planning/` directory
2. Find the most recently completed phase:
   - Read ROADMAP.md, find last phase marked [x]
   - Verify against STATE.md frontmatter
3. Glob for ALL plans in that phase: `phases/<NN>-*/<NN>-*-PLAN.md`
4. For EACH plan, read the matching SUMMARY.md
5. Extract tasks from <task> blocks in each PLAN.md
6. Compare against SUMMARY.md accomplishments and deviations
7. Check for unplanned file changes via git history (SUMMARY commit hashes)
8. Check state consistency (STATE.md, ROADMAP.md, PROJECT.md)
9. Output reconciliation report using template from references/reconciliation.md
10. Optionally save to .planning/phases/<NN>-*/RECONCILIATION.md
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `source` for config loading | `while IFS='=' read` | Security best practice | Prevents arbitrary code execution |
| Short SHA for version tracking | Full SHA storage | Git best practice | Stable references across clone lifetimes |
| `/tmp/` for persistent data | `~/.cache/` (XDG convention) | Phase 1 (update script) | Survives macOS reboots |
| Single plan per phase | Multi-plan phases (up to N plans) | GSD standard | Phase 2 uses 3 plans; reconcile must handle this |

**Important note on `set -e`:** The scripts use `set -euo pipefail` which is generally good practice, but for the update script where independent network operations can fail, the error handling needs to be more granular. Wrapping individual operations in functions with explicit return codes is the standard approach.

## Open Questions

1. **Should reconcile support specifying a phase number?**
   - What we know: Current prompt says "most recent phase" or "user-specified path"
   - What's unclear: The command file doesn't provide a mechanism for the user to pass a phase number
   - Recommendation: Add an optional argument to the process section: "If the user specifies a phase number, use that. Otherwise, find the most recently completed phase."

2. **Should reconcile save output automatically or only when asked?**
   - What we know: Current prompt says "Optionally saved to RECONCILIATION.md"
   - What's unclear: Should it always save and just tell the user, or ask first?
   - Recommendation: Always save to `.planning/phases/<NN>-*/RECONCILIATION.md` (the whole point is creating a persistent record). Print to terminal AND save.

3. **Should cleanup targets be configurable beyond env vars?**
   - What we know: TARGETS array is hardcoded in the script
   - What's unclear: Different users may have different ephemeral directories
   - Recommendation: Keep hardcoded defaults for v1 (the 4 targets are PAI-specific anyway). Configurability is a v2 concern.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual shell script execution + Claude Code command invocation |
| Config file | None -- commands are markdown prompts, scripts are standalone bash |
| Quick run command | `bash skills/skippy-dev/scripts/skippy-update.sh` / `bash skills/skippy-dev/scripts/skippy-cleanup.sh --quarantine` |
| Full suite command | Run all 3 commands and inspect output |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CMD-01 | Reconcile produces correct report for completed phase | manual-only | Invoke `/skippy:reconcile` in Claude Code against this project's Phase 1 | N/A (prompt) |
| CMD-01 | Reconcile handles multi-plan phase | manual-only | Invoke `/skippy:reconcile` for Phase 2 (3 plans) | N/A (prompt) |
| CMD-02 | Update script clones to ~/.cache/ | smoke | `bash -c 'SKIPPY_CACHE_DIR=/tmp/test-skippy-cache bash skills/skippy-dev/scripts/skippy-update.sh && test -d /tmp/test-skippy-cache/gsd/.git && echo PASS'` | Script exists |
| CMD-02 | Update script uses safe .versions parsing | unit | `grep -c "^source " skills/skippy-dev/scripts/skippy-update.sh` -- must be 0 | Script exists |
| CMD-02 | Update script stores full SHA | unit | After running, `grep gsd_hash .versions \| wc -c` -- must be > 45 (key + 40-char hash + newline) | Script exists |
| CMD-03 | Cleanup quarantine moves files and reports space | smoke | Create test dir, run cleanup in quarantine mode, verify files moved | Script exists |
| CMD-03 | Cleanup nuke deletes permanently | smoke | Create test dir, run cleanup in nuke mode, verify files gone | Script exists |
| CMD-03 | Cleanup with no targets exits cleanly | smoke | Run with no matching target dirs -- should output SKIP messages, 0 KB freed | Script exists |

### Sampling Rate

- **Per task commit:** Run the specific script being modified and check output
- **Per wave merge:** Run all three commands/scripts and verify output
- **Phase gate:** All three commands produce correct output against real data

### Wave 0 Gaps

- [ ] No automated test harness exists -- all validation is manual script execution + output inspection
- [ ] Reconcile is manual-only (Claude Code command invocation) -- cannot be automated outside Claude Code
- [ ] Update script needs network access for clone -- tests must handle offline gracefully or use a test override

Note: Given project constraints (shell + markdown only, no TypeScript/Node dependencies), a formal test framework is out of scope. Validation relies on running the scripts and verifying output manually or via verification commands in the plan.

## Sources

### Primary (HIGH confidence)

- **Project files analyzed directly:**
  - `skills/skippy-dev/scripts/skippy-update.sh` -- identified 3 bugs (source, short SHA, /tmp/ reference)
  - `skills/skippy-dev/scripts/skippy-cleanup.sh` -- identified 1 bug (TMPDIR default)
  - `skills/skippy-dev/commands/reconcile.md` -- identified 4 gaps (finding latest phase, multi-plan, XML parsing, git diff)
  - `skills/skippy-dev/commands/update.md` -- identified stale `/tmp/` reference
  - `skills/skippy-dev/references/reconciliation.md` -- analyzed report template structure
  - `skills/skippy-dev/references/state-consistency.md` -- analyzed state check requirements
  - `.planning/phases/01-spec-compliance/01-01-PLAN.md` -- analyzed GSD plan structure (YAML + XML)
  - `.planning/phases/01-spec-compliance/01-01-SUMMARY.md` -- analyzed GSD summary structure
  - `.planning/phases/02-plugin-packaging/02-01-PLAN.md` -- confirmed multi-plan pattern
  - `.planning/phases/02-plugin-packaging/02-01-SUMMARY.md` -- confirmed summary structure consistency
  - `.planning/STATE.md` -- analyzed state tracking format
  - `.planning/ROADMAP.md` -- analyzed phase completion markers

### Secondary (MEDIUM confidence)

- macOS `$TMPDIR` behavior -- verified on local machine (`echo $TMPDIR` returns empty or session-specific path)
- Git `rev-parse --short` ambiguity -- well-known git best practice documented in git-rev-parse man page

### Tertiary (LOW confidence)

- None -- all findings based on direct code analysis of project files

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no external dependencies, all bash + standard Unix tools
- Architecture: HIGH -- analyzed real GSD artifacts from this project's completed phases
- Pitfalls: HIGH -- all bugs identified from direct code reading, not speculation

**Research date:** 2026-03-07
**Valid until:** No expiration -- findings are based on current codebase state, not external library versions
