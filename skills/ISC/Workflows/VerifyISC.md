---
name: VerifyISC
description: Verify that all ISC criteria are met with documented evidence
---

# VerifyISC Workflow

## Purpose

Check if work is actually complete by verifying all ISC criteria with evidence.

## Input

- ISC tracker (from CreateISC workflow)
- Completed implementation

## Output

- Updated ISC tracker with VERIFIED/FAILED status
- Evidence documented for each criterion
- Final determination: COMPLETE or INCOMPLETE

## Steps

### 1. Review All Criteria

For each criterion in the ISC tracker:

**Ask:**
- Can I test this with YES/NO?
- What evidence would prove it?
- How do I collect that evidence?

### 2. Run Verification Tests

**For each criterion, execute verification:**

```
Criterion: "Login endpoint accepts email password"

Test:
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

Expected: 200 OK with JWT token
Actual: 200 OK, token present
Evidence: Response body contains "token": "eyJ..."

Status: ✅ VERIFIED
```

### 3. Collect Evidence

**Types of evidence:**
- **Code:** "Function implemented at src/auth.ts:47"
- **Tests:** "npm test passes: 12/12 ✅"
- **API responses:** "curl returns 200 with valid JSON"
- **Screenshots:** "UI renders correctly (screenshot attached)"
- **Logs:** "No errors in last 24h of logs"
- **Metrics:** "Response time <100ms (average 73ms)"

### 4. Check Anti-Criteria

**For each anti-criterion, verify it was AVOIDED:**

```
Anti-Criterion: "No passwords stored in plain text"

Test:
SELECT password FROM users LIMIT 1;

Expected: Hashed value (bcrypt/argon2)
Actual: $2b$10$... (bcrypt hash)
Evidence: Database query shows hashed passwords

Status: ✅ AVOIDED
```

### 5. Update ISC Tracker

```
🎯 FINAL ISC STATE ════════════════════════════════════════════════
│ # │ Criterion                    │ Status      │ Evidence        │
├───┼──────────────────────────────┼─────────────┼─────────────────┤
│ 1 │ Login endpoint works         │ ✅ VERIFIED │ curl: 200 OK    │
│ 2 │ JWT token generated          │ ✅ VERIFIED │ Token in resp   │
│ 3 │ Protected routes secured     │ ✅ VERIFIED │ 401 unauthorized│
│ 4 │ Token refresh works          │ ❌ FAILED   │ Returns 500     │
│ 5 │ Logout invalidates token     │ ⬜ PENDING  │ Not implemented │
├───┴──────────────────────────────┴─────────────┴─────────────────┤
│ ⚠️ ANTI-CRITERIA                                                 │
├───┬──────────────────────────────┬───────────────────────────────┤
│ ! │ No plain text passwords      │ ✅ AVOIDED  │ Bcrypt used    │
│ ! │ No tokens in client logs     │ ✅ AVOIDED  │ No console.log │
│ ! │ No auth bypass               │ ❌ TRIGGERED│ Admin endpoint │
└───┴──────────────────────────────┴───────────────────────────────┘

SCORE: 3/5 verified | 2/3 anti-criteria avoided | STATUS: INCOMPLETE
```

### 6. Determine Completion Status

**COMPLETE if:**
- All criteria ✅ VERIFIED
- All anti-criteria ✅ AVOIDED
- All evidence documented

**INCOMPLETE if:**
- Any criterion ❌ FAILED or ⬜ PENDING
- Any anti-criterion ❌ TRIGGERED

## Example Output

### Success Case

```
✅ VERIFICATION COMPLETE

All 6 criteria VERIFIED with evidence.
All 4 anti-criteria AVOIDED.

This implementation is ready for deployment.

Evidence summary:
- API tests: 12/12 passing
- Security scan: No vulnerabilities
- Performance: <100ms average
- Integration test: End-to-end flow works

SCORE: 6/6 verified | 4/4 avoided | STATUS: COMPLETE
```

### Failure Case

```
❌ VERIFICATION INCOMPLETE

2 criteria FAILED:
- C4: Token refresh returns 500 error
- C5: Logout not implemented yet

1 anti-criterion TRIGGERED:
- A3: Admin endpoint bypasses authentication

Remaining work:
1. Fix token refresh endpoint (returns 500)
2. Implement logout functionality
3. Secure admin endpoint with auth check

SCORE: 3/5 verified | 2/3 avoided | STATUS: INCOMPLETE
```

## When to Run

**Run VerifyISC:**
- After claiming work is "done"
- Before deployment to production
- After major changes to existing features
- As part of PR review process

## Integration

**Works with:**
- **CI/CD:** Run verification tests in pipeline
- **PR reviews:** Include ISC status in PR description
- **Documentation:** Verification evidence → test documentation
