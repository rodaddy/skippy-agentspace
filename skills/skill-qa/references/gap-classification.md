<!-- Extracted from SKILL.md -- load on demand -->

# Gap Classification Guide

## Gap Types

### trigger-miss (Severity: HIGH)

**What:** A skill exists for the task but its trigger description doesn't match the user's natural language request.

**Root cause:** Trigger descriptions are too narrow, use jargon the user doesn't use, or miss common phrasings.

**Fix via autoresearch:** Optimize the `description` field in SKILL.md frontmatter. The autoresearch eval criterion is: "Does skill X trigger for request Y?"

**Example:**
- User says: "I need the Discord API key"
- vaultwarden skill trigger has: "API key", "credentials", "password"
- But intent-skill-router.ts regex doesn't match "Discord API key" to vaultwarden
- Gap: trigger-miss on vaultwarden for credential requests with service-specific context

### trigger-false-positive (Severity: MEDIUM)

**What:** A skill triggers for a request it shouldn't handle.

**Root cause:** Trigger descriptions are too broad, or overlap with other skills.

**Fix:** Narrow the trigger description, add exclusion patterns.

**Example:**
- User says: "debug the network timeout"
- unifi skill triggers on "network"
- But user meant application-level debugging, not UniFi network management

### hook-miss (Severity: HIGH)

**What:** A hook should have blocked a violation but allowed it through.

**Root cause:** Pattern matching too narrow, missing edge cases, incorrect exit codes.

**Fix:** Modify hook source code to handle the missed pattern.

**Example:**
- User runs `python3 -m json.tool < file.json`
- pre-python3-blocker.ts should block but the `-m` pattern isn't in its regex

### hook-false-positive (Severity: MEDIUM)

**What:** A hook blocked a legitimate operation.

**Root cause:** Pattern matching too aggressive, missing allowlist patterns.

**Fix:** Add allowlist entries or refine the blocking pattern.

### hook-broken (Severity: CRITICAL)

**What:** A hook has a code-level bug that prevents it from working at all.

**Root cause:** Wrong input format, missing dependencies, unhandled errors, stale references.

**Fix:** Fix the hook code.

**Known instance:** pre-lsp-first.ts reads `tool`/`params`/`toolHistory` but CC hooks provide `toolName`/`toolInput`/`recentMessages`.

### quality-gap (Severity: MEDIUM)

**What:** A skill triggers correctly but its content is poor enough that manual work is easier.

**Root cause:** Incomplete steps, stale references, missing common use cases, too verbose.

**Fix via autoresearch:** Optimize the SKILL.md content. Eval criterion: "Would an agent prefer this skill over manual work?"

### overlap (Severity: LOW)

**What:** Multiple skills or hooks fire for the same scenario with potentially conflicting guidance.

**Root cause:** Skills evolved independently, no dedup review.

**Fix:** Consolidate or add priority ordering.

**Known instance:** pre-skill-enforcer.ts (regex) vs enforce-skill-usage.ts (fuzzy keywords) -- both enforce "use skills first" with different approaches.

### bypass (Severity: HIGH)

**What:** An enforcement mechanism can be circumvented by subagents, pattern tricks, or input manipulation.

**Root cause:** Universal subagent bypass (`CLAUDE_CODE_AGENT` check), overly specific pattern matching.

**Fix:** Remove or gate the bypass, broaden pattern matching.

**Known instance:** Almost all hooks check `process.env.CLAUDE_CODE_AGENT !== undefined` and pass through. Subagents can violate any LAW except destructive git and catastrophic deletion.

---

## Severity Prioritization

| Severity | Fix When | Impact |
|----------|----------|--------|
| CRITICAL | Immediately | System is broken, enforcement doesn't exist |
| HIGH | This session | Violations get through, skills get skipped |
| MEDIUM | Next session | Annoying but not dangerous |
| LOW | Backlog | Minor friction, cosmetic |

## Autoresearch Mapping

| Gap Type | Autoresearch Target | Eval Type |
|----------|-------------------|-----------|
| trigger-miss | Skill description field | command (regex match test) |
| trigger-false-positive | Skill description field | command (inverse match test) |
| hook-miss | Hook source code (manual fix, not autoresearch) | command (hook exit code) |
| hook-false-positive | Hook source code (manual fix) | command (hook exit code) |
| hook-broken | Hook source code (manual fix) | command (hook exit code) |
| quality-gap | Skill SKILL.md content | agent-judge |
| overlap | Consolidation (manual) | agent-judge |
| bypass | Hook source code (manual fix) | command (subagent simulation) |

Note: hook-miss, hook-broken, and bypass gaps need code fixes, not prompt optimization. The autoresearch loop is most effective for trigger-miss and quality-gap types.
