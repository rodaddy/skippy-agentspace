---
name: review-swarm
description: Multi-perspective code review swarm with fix-and-repeat loop. USE WHEN code is ready for review, before committing, or after fixing review findings.
triggers:
  - /review-swarm
  - /swarm
  - review this code from every angle
  - run the review swarm
  - hit this from every direction
  - swarm it
user-invocable: true
---

# Review Swarm

Main context orchestrates parallel review rounds directly -- no lead agent. Spawn 5 reviewers, aggregate findings, fix, repeat until clean.

## Quick Reference

- Main context runs the loop (full Agent tool access for spawning reviewers)
- 5 reviewer agents per round: correctness, adversarial, quality, security, domain
- All reviewers are `general-purpose` with `run_in_background: true`
- Fix ALL CRITICAL/HIGH/MEDIUM findings per round, then re-review
- Max 5 rounds. Fix everything, never defer to "later"

## Workflow

### Step 1: Determine Scope and Domain

Check what's being reviewed:
- `git diff HEAD --stat` for uncommitted changes
- `git diff main...HEAD --stat` for full branch diff

Detect the project domain from CLAUDE.md or the codebase (trading, infra, web app, etc.).

If the user passes `domain:<type>`, use that. Otherwise auto-detect:
- Trading/simulator code -> `quant` (financial modeling, PnL, market assumptions)
- Infrastructure/deploy code -> `infra` (containers, networking, security)
- Frontend/UI code -> `frontend` (accessibility, UX, rendering, state management)
- API/backend code -> `backend` (REST conventions, auth, data validation)
- Default -> `general` (software engineering best practices)

### Step 2: Run the Review Loop

```
DIFF_CMD = "git diff HEAD" or "git diff main...HEAD"
ROUND = 1
while ROUND <= 5:
  1. Capture the current diff: run DIFF_CMD and save output
  2. Spawn 5 reviewer agents in PARALLEL (run_in_background: true)
     - Each gets the diff + their focus prompt from references/reviewer-prompts.md
     - Each gets coding standards path if it exists
  3. Wait for all 5 to complete
  4. Aggregate findings into severity table
  5. If zero CRITICAL/HIGH/MEDIUM -> EXIT with summary
  6. Spawn a fixer agent (general-purpose, bypassPermissions) with all findings
     - Fixer reads files, makes minimal edits, runs tests + typecheck
  7. VERIFY: run `bunx tsc --noEmit` and `bun test` yourself (never trust agent claims)
  8. If verify fails, fix in another agent pass
  9. ROUND += 1
```

**Critical:** After the fixer agent returns, ALWAYS run typecheck and tests independently. Never trust the agent's claim of "clean."

### Step 3: Present Results

When the loop exits clean, present:
- Total rounds run
- Findings fixed per round with severity breakdown
- Remaining LOW/INFO items (not blocking)
- Test/typecheck/build verification status

### Spawning Reviewers

Read `references/reviewer-prompts.md` for the 5 agent prompts. Each reviewer gets:

**Common preamble:**
```
Working directory: {CWD}
Branch: {BRANCH}

Here is the diff to review:
<diff>
{DIFF_CONTENT}
</diff>

Also read {CODING_STANDARDS} for project conventions.

Return findings as a structured list:
- SEVERITY (CRITICAL/HIGH/MEDIUM/LOW/INFO)
- FILE:LINE
- ONE-LINE DESCRIPTION
- SUGGESTED FIX (2-3 lines max)

If no issues found, return "CLEAN -- no issues found."
```

**Important:** Paste the diff content directly into each reviewer's prompt. Do NOT tell them to run `git diff` themselves -- they may get stale or different results.

### Spawning the Fixer

The fixer agent gets:
- All aggregated CRITICAL/HIGH/MEDIUM findings
- Instructions to read each affected file, make minimal changes
- Reminder to NOT create new files unless truly necessary
- File size limit (750 lines)
- Project coding standards path

## Arguments

- No args: review uncommitted changes
- `branch`: review full branch diff
- `files <path>`: review specific files
- `domain:<type>`: override domain specialist (quant, infra, frontend, backend, general)

## Nocache Model Routing

Start swarm sessions with `claude --model opus-nocache` to get fresh, uncached reviewer
perspectives. Cached responses can return the same analysis patterns across reviewers,
reducing the value of multi-perspective review. Cannot switch mid-session.

## Gotchas

- Reviewers are read-only agents -- they analyze, they don't edit
- Fixer agent gets `bypassPermissions` -- it edits freely
- Always verify after fixer completes (memory: feedback_verify_agent_claims.md)
- Domain specialist prompt should match the actual code being reviewed
- All agents are `general-purpose` -- not omc/gsd wrappers (those lose tool access)
- If diff is very large (>500 lines), consider splitting into logical chunks per reviewer
- For best results, start the session with `--model opus-nocache` -- can't switch mid-session
