---
name: pai-audit
description: Audit PAI configuration for drift, contradictions, dead weight, and plugin overlap. Tracks metrics over time. USE WHEN user says "audit", "config drift", "clean up rules", "review setup", or monthly on schedule.
---

# PAI Configuration Audit

Systematic audit of the entire PAI config hierarchy. Run monthly or when things feel off.

## Workflow Routing

**When user requests knowledge lint / memory audit:**
Examples: "lint the knowledge base", "check my memory files", "knowledge audit", "are my memories stale", "broken references in memory"
-> **READ:** ~/.config/pai/Skills/pai-audit/workflows/knowledge-lint.md
-> **EXECUTE:** Run knowledge-lint scanner, then AI review for contradictions and gaps

**When user requests a full audit:**
Examples: "audit PAI", "full config audit", "run pai-audit", "monthly audit"
-> **EXECUTE:** Run all sections below (1-8) as parallel agents, including knowledge-lint as section 8

---

## Audit Checklist

Run each section as a parallel agent. Collect results, then present findings.

### 1. Contradiction Scanner

Spawn a sonnet explore agent to check for contradictions across all config files:

```
Files to cross-reference:
- ~/.claude/CLAUDE.md
- <DEV_DIR>/CLAUDE.md (or current project CLAUDE.md)
- ~/.claude/docs/*.md (all 6 deep docs)
- ~/.config/pai/Skills/CORE/SKILL.md
- ~/.config/pai-private/rules/style/communication-style.md
- ~/.config/pai-private/memory/decisions.md
- ~/.claude/projects/-Volumes-ThunderBolt-Development/memory/MEMORY.md

Check for:
- Same rule stated differently in 2+ files (which is canonical?)
- Banned things still referenced (e.g., banned model tiers still in docs)
- Superseded decisions not marked superseded
- Dead references (files that don't exist)
- Default persona disagreements
```

### 2. Plugin Value Audit (OMC + GSD + Others)

For EACH installed plugin (`~/.claude/settings.json` plugins section):

```
Questions to answer:
- How many skills does it register? List them.
- Which skills have we ACTUALLY invoked? (check session logs, .reports/)
- How many agent types does it register?
- Which agents have we ACTUALLY spawned?
- What context cost per session? (token estimate for skill list entries)
- What has CC added natively since we installed this? (check CC release notes)
- Should any plugin features be replaced with CC-native equivalents?
- Should any plugin features be replaced with PAI-native skills?
```

### 3. Permission Consolidation Check

```
Scan:
- ~/.claude/settings.json permissions.allow (global)
- All project .claude/settings.local.json files

Check for:
- Permissions duplicated between global and project (should be global-only)
- Hardcoded credentials in permission strings (SECURITY ISSUE)
- Read-only operations not in global (should be)
- Overly broad permissions that should be tightened
```

### 4. Hook Health Check

```
For each hook in settings.json:
- Does the hook file exist?
- Does it compile/run without errors? (bun run --dry-run)
- Is it referenced but not registered? Or registered but file missing?
- What's the execution time? (check timeout vs actual)
- Any hooks that fire on EVERY operation but rarely do anything?
```

### 5. MEMORY.md Hygiene

```
Check:
- Line count (should be < 120 lines, warn at 150+)
- Content that duplicates CLAUDE.md or deep docs (should reference, not repeat)
- Entries older than 60 days that haven't been validated
- Project-specific knowledge that belongs in project files, not global memory
```

### 6. Skill Coverage Gap Analysis

```
Compare:
- Skills registered in system reminder (full list)
- Intent router patterns (intent-skill-router.ts)
- Skill enforcer triggers (enforce-skill-usage.ts / skill-index.json)

Find:
- Skills with no intent-router pattern (won't get auto-suggested)
- Skills with no enforcer trigger (won't get enforced)
- Skills that overlap with each other (confusing routing)
- Skills that overlap with CC-native features (candidates for removal)
```

### 6b. Skill QA Validation

```
Run /skill-qa to validate the enforcement layer:
- Hook enforcement: do hooks actually block violations?
- Skill triggers: does intent-skill-router match natural language?
- Skill quality: are skills good enough to prefer over manual?

Compare to previous .skill-qa/gaps.json for delta:
- Gaps fixed since last audit
- New gaps introduced
- Regression trend

If no previous gap report exists, this run becomes the baseline.
Output: .skill-qa/gaps.json + .skill-qa/report.md
```

### 7. CC Native Feature Check

```
Check what Claude Code provides natively vs. what plugins provide:
- Agent tool subagent_type list (what's built-in vs. plugin-added?)
- TaskCreate/TaskUpdate/TaskList (does this replace GSD todos?)
- TeamCreate/SendMessage (does this replace OMC swarm?)
- EnterPlanMode (does this replace OMC plan/ralplan?)
- EnterWorktree (does this replace OMC parallel isolation?)
- Skill tool (what skills are CC-native vs. plugin?)

Flag anything where a plugin feature is now redundant with CC-native.
```

## Metrics to Track

After each audit, append to `~/.config/pai/reports/audit-metrics.jsonl`:

```json
{
  "date": "YYYY-MM-DD",
  "config_files": 14,
  "total_config_lines": 2300,
  "contradictions_found": 4,
  "contradictions_fixed": 4,
  "plugins_installed": 3,
  "plugin_skills_total": 63,
  "plugin_skills_used": 7,
  "plugin_skills_unused_pct": 89,
  "global_permissions": 167,
  "project_settings_files": 28,
  "duplicate_permissions": 45,
  "memory_md_lines": 161,
  "intent_router_rules": 28,
  "intent_router_patterns": 95,
  "hooks_total": 30,
  "hooks_healthy": 30,
  "cc_native_overlaps": 3
}
```

## Output

Write audit report to `~/.config/pai/reports/audit-latest.md` with:
1. Summary table (pass/warn/fail per section)
2. Contradictions found + fixes applied
3. Plugin assessment (keep/trim/replace)
4. Permission changes made
5. Metrics delta from last audit
6. Next audit recommended date

## Schedule

Monthly reminder. Check `~/.config/pai/reports/audit-metrics.jsonl` for last audit date.
If > 30 days since last audit, suggest running at session start.
