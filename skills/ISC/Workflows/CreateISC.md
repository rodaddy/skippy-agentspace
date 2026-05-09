---
name: CreateISC
description: Extract testable success criteria from a user request
---

# CreateISC Workflow

## Purpose

Convert vague requests into binary-testable success criteria before starting work.

## Input

Any request for work: "Build X", "Fix Y", "Implement Z"

## Output

ISC tracker with:
- 5-10 success criteria (8 words each)
- 3-5 anti-criteria (what must NOT happen)
- All in PENDING state

## Steps

### 1. Parse the Request

**Extract:**
- What user wants to achieve (positive requirements)
- What user wants to avoid (negative requirements → anti-criteria)
- Implicit requirements (error handling, performance, security)

### 2. Convert to Criteria

**Each criterion must be:**
- **Granular:** One thing only
- **Binary:** YES/NO testable
- **8 words max:** Forces precision
- **Verifiable:** Can collect evidence

### 3. Add Anti-Criteria

**Look for:**
- Security risks ("don't expose credentials")
- Breaking changes ("don't break existing API")
- Data loss risks ("don't corrupt database")
- Performance degradation ("don't slow down response")

### 4. Present for Review

```
🎯 ISC TRACKER ════════════════════════════════════════════════════
│ # │ Criterion (8 words max)           │ Status      │ Evidence │
├───┼───────────────────────────────────┼─────────────┼──────────┤
│ 1 │ [derived from request]            │ ⬜ PENDING  │          │
│ 2 │ [derived from request]            │ ⬜ PENDING  │          │
...
├───┴───────────────────────────────────┴─────────────┴──────────┤
│ ⚠️ ANTI-CRITERIA                                               │
├───┬───────────────────────────────────┬────────────────────────┤
│ ! │ [must NOT happen]                 │ 👀 WATCHING            │
└───┴───────────────────────────────────┴────────────────────────┘

Does this capture what "done" means?
```

### 5. Refine with User

Ask:
- "Any criteria missing?"
- "Any criteria too vague?"
- "Any anti-criteria we should watch?"

## Example

**User Request:** "Build user authentication"

**CreateISC Output:**

```
🎯 AUTHENTICATION ISC ═════════════════════════════════════════════
│ # │ Criterion                              │ Status    │ Evidence │
├───┼────────────────────────────────────────┼───────────┼──────────┤
│ 1 │ Login endpoint accepts email password  │ ⬜ PENDING │          │
│ 2 │ JWT token generated on successful login│ ⬜ PENDING │          │
│ 3 │ Protected routes reject invalid tokens │ ⬜ PENDING │          │
│ 4 │ Token refresh mechanism works correctly│ ⬜ PENDING │          │
│ 5 │ Logout invalidates token server side   │ ⬜ PENDING │          │
│ 6 │ Password reset email sent successfully │ ⬜ PENDING │          │
├───┴────────────────────────────────────────┴───────────┴──────────┤
│ ⚠️ ANTI-CRITERIA                                                  │
├───┬────────────────────────────────────────┬──────────────────────┤
│ ! │ No passwords stored in plain text      │ 👀 WATCHING          │
│ ! │ No tokens exposed in client logs       │ 👀 WATCHING          │
│ ! │ No authentication bypass vulnerabilities│ 👀 WATCHING          │
│ ! │ No session fixation attacks possible   │ 👀 WATCHING          │
└───┴────────────────────────────────────────┴──────────────────────┘

SCORE: 0/6 verified | STATUS: Ready to start
```

## Storage

**For small tasks:** Keep ISC in conversation context

**For projects:** Save to `specs/[project]-ISC-spec.md`

## Next Step

After ISC is approved → Start implementation with criteria in mind
