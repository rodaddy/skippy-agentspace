---
name: ISC
description: Create and track Ideal State Criteria (ISC) for tasks. USE WHEN starting complex work, defining success conditions, or verifying completion. Auto-loads verification best practices from PAI v2.4.
---

# ISC - Ideal State Criteria Skill

**Purpose:** Define testable success criteria BEFORE starting work, verify with evidence AFTER completing work.

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **CreateISC** | "define success", "what does done mean", "create ISC" | `Workflows/CreateISC.md` |
| **VerifyISC** | "verify ISC", "check criteria", "is this done" | `Workflows/VerifyISC.md` |

## When to Use This Skill

**Auto-invoke when:**
- User asks "what does done/complete/finished mean"
- Starting complex implementation (3+ components)
- Building production systems
- Need proof something works

**Example triggers:**
- "Help me build a classification pipeline" → CreateISC first
- "Is the authentication done?" → VerifyISC
- "Define success criteria for this project" → CreateISC

## Quick Reference

### The ISC Format

```
🎯 ISC TRACKER ═════════════════════════════════════════════════
│ # │ Criterion (8 words max)    │ Status      │ Evidence    │
├───┼────────────────────────────┼─────────────┼─────────────┤
│ 1 │ [binary-testable condition]│ ⬜ PENDING  │             │
├───┴────────────────────────────┴─────────────┴─────────────┤
│ ⚠️ ANTI-CRITERIA (Must NOT Happen)                        │
├───┬────────────────────────────┬───────────────────────────┤
│ ! │ [failure mode to avoid]    │ 👀 WATCHING               │
└───┴────────────────────────────┴───────────────────────────┘
```

### Status Symbols

- ⬜ **PENDING** - Not started
- 🔄 **IN_PROGRESS** - Working on it
- ✅ **VERIFIED** - Completed with evidence
- ❌ **FAILED** - Didn't meet criterion
- 👀 **WATCHING** - Anti-criterion being monitored
- ✅ **AVOIDED** - Anti-criterion successfully prevented

### The 8-Word Rule

**Why 8 words?** Forces precision. Can't be vague in 8 words.

**Examples:**

❌ "The system should handle errors properly and gracefully"
✅ "Error handler catches exceptions and returns user friendly message"

❌ "Implement authentication securely"
✅ "JWT token validates successfully on all protected routes"

### Evidence Requirements

**Each VERIFIED criterion needs proof:**
- **Code:** "Function exists at file.ts:47"
- **Tests:** "npm test passes: 12/12 green"
- **API:** "Endpoint returns 200 with valid JSON"
- **Logs:** "No errors in production logs (24h)"
- **Screenshots:** "UI shows expected behavior"

## Integration with Your Workflow

### Before Starting Work

```bash
# User says: "Build a feature to classify messages"

# You invoke: CreateISC workflow
# Result: 5-10 testable criteria defined
# Then: Build with criteria in mind
```

### After Completing Work

```bash
# User says: "Is the classification pipeline done?"

# You invoke: VerifyISC workflow
# Result: Check all criteria, collect evidence
# Only say "done" if all VERIFIED
```

## Anti-Criteria

**Track what must NOT happen:**

```
⚠️ ANTI-CRITERIA
│ ! │ No credentials exposed in logs        │ 👀 WATCHING │
│ ! │ No database corruption on crash       │ 👀 WATCHING │
│ ! │ No breaking changes to existing API   │ 👀 WATCHING │
```

**These prevent:**
- "Fixed one thing, broke another"
- Security vulnerabilities
- Regression bugs

## PAI Integration

**This skill works with:**
- **Verification Agent** (`~/.config/pai/Skills/CORE/agents/verification-agent.md`)
- **Task tracking** (use ISC to define task acceptance criteria)
- **Project specs** (store ISC in `specs/` directory)

## Examples

### Example 1: Quick Task

**User:** "Fix the login bug"

**CreateISC:**
```
│ 1 │ Login form submits without JavaScript errors   │ ⬜ PENDING │
│ 2 │ Valid credentials return JWT token             │ ⬜ PENDING │
│ 3 │ Invalid credentials show error message         │ ⬜ PENDING │
```

**After fix, VerifyISC:**
```
│ 1 │ Login form submits without JavaScript errors   │ ✅ VERIFIED │ Console: no errors │
│ 2 │ Valid credentials return JWT token             │ ✅ VERIFIED │ Token in response  │
│ 3 │ Invalid credentials show error message         │ ✅ VERIFIED │ "Invalid login"    │
```

### Example 2: Complex Project

**User:** "Build classification pipeline"

**CreateISC** (see `specs/classification-pipeline-ISC-spec.md`):
- 10 success criteria
- 5 anti-criteria
- Tracked throughout implementation
- All must VERIFY before deployment

## Best Practices

**Do:**
- Define ISC BEFORE starting implementation
- Make each criterion binary (YES/NO)
- Collect evidence for every VERIFIED status
- Update ISC as you learn during implementation

**Don't:**
- Accept vague criteria ("works well", "is good")
- Mark VERIFIED without evidence
- Skip anti-criteria (what must NOT happen)
- Create too many criteria (5-10 is ideal)

---

**Bottom line:** ISC transforms "I think it's done" into "Here's proof it's done."

**Adapted from:** PAI v2.4.0 Algorithm (danielmiessler/Personal_AI_Infrastructure)
