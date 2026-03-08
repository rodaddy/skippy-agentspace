# Checkpoints -- Human-in-the-Loop Protocol

Checkpoint protocol for human-in-the-loop verification during plan execution. Plans execute autonomously by default -- checkpoints formalize the rare interaction points where human verification, decisions, or manual actions are genuinely needed.

## Golden Rule

**If Claude can run it via CLI or API, Claude runs it.** Checkpoints verify AFTER automation, not replace it.

Users never run CLI commands. Users never start servers. Users never create files. Users only do things that require human judgment: visit URLs, evaluate visuals, provide secrets, make decisions.

## Checkpoint Types

| Type | Usage | Frequency |
|------|-------|-----------|
| `checkpoint:human-verify` | Confirm automated work is correct | ~90% of checkpoints |
| `checkpoint:decision` | Human makes implementation choice | ~9% of checkpoints |
| `checkpoint:human-action` | Truly unavoidable manual step (no CLI/API exists) | ~1% of checkpoints |

### human-verify (90%)

Claude completed automated work. Human confirms it works correctly.

**Use for:** Visual UI checks, interactive flow testing, functional verification, accessibility testing, animation smoothness.

**Pattern:** Claude builds and deploys, starts dev server, then asks user to visit URL and confirm.

### decision (9%)

Human must choose between implementation options that affect direction.

**Use for:** Technology selection, architecture decisions, design choices, feature prioritization, data model decisions.

**Pattern:** Present 2-3 options with pros/cons. User selects. Claude implements the choice.

### human-action (1%)

An action with NO CLI/API that truly requires human interaction, or an authentication gate Claude hit during automation.

**Use for:** Email verification links, SMS 2FA codes, manual account approvals, OAuth browser flows, credit card 3D Secure.

**Do NOT use for:** Deploying (use CLI), creating webhooks (use API), running builds (use Bash), creating files (use Write tool). If a CLI exists, it is not a human-action.

## Execution Protocol

When encountering a checkpoint task:

1. **Stop** -- do not proceed to the next task
2. **Display** -- show checkpoint details clearly with progress count
3. **Wait** -- do not hallucinate completion or assume approval
4. **Verify** -- after user responds, run any verification checks specified
5. **Resume** -- continue to next task only after confirmation

**Checkpoint display format:**
```
Progress: 5/8 tasks complete
Task: [checkpoint name]

[What was built / What decision is needed / What action is required]

[Specific verification steps or options]

YOUR ACTION: [what user needs to do]
```

## Authentication Gates

Auth gates are NOT pre-planned checkpoints. They are created dynamically when Claude tries CLI automation and gets an authentication error.

**Pattern:**
```
1. TRY:   Claude runs CLI command (e.g., vercel --yes)
2. FAIL:  Auth error returned ("Not authenticated")
3. GATE:  Claude creates checkpoint:human-action dynamically
4. AUTH:  User authenticates (e.g., vercel login)
5. RETRY: Claude retries the original command
6. DONE:  Continue normally
```

**Key distinction:**
- Pre-planned manual work: "Deploy via the dashboard UI" -- WRONG (CLI exists)
- Auth gate: "I tried to deploy but need credentials" -- CORRECT (unblocks automation)

Auth gates are documented in summaries as normal flow, not as deviations.

## Anti-Patterns

### 1. Asking user to do automatable work

```
BAD:  "Run: npm run dev, then visit localhost:3000"
GOOD: Claude runs npm run dev in background, then asks user
      to visit localhost:3000 and verify the layout
```

If it has a CLI, Claude runs it. Period.

### 2. Too many checkpoints (verification fatigue)

```
BAD:  Checkpoint after every task (schema, API, UI -- 3 checkpoints)
GOOD: One checkpoint at the end after all related work completes
```

Combine related verification into a single checkpoint at the end of a logical unit of work.

### 3. Checkpoint before automation completes

```
BAD:  Ask user to verify dashboard when server isn't running
GOOD: Start dev server, verify it responds, THEN ask user to
      check the dashboard at the running URL
```

Never present a checkpoint with a broken verification environment. Fix first, then checkpoint.

## Placement Rules

- **After automation completes** -- not before Claude does the work
- **After UI buildout** -- before declaring the plan complete
- **Before dependent work** -- decisions before implementation that depends on them
- **At integration points** -- after configuring external services
- **One checkpoint per logical unit** -- not after every task

## Auto-Mode Behavior

When auto-mode is active (user preference or chain flag):

| Checkpoint Type | Behavior |
|----------------|----------|
| human-verify | Auto-approved, logged, continue |
| decision | Auto-select first option, logged, continue |
| human-action | STOP normally -- auth gates cannot be automated |

## Integration Points

- **Deviation Rule 1:** See plan-structure.md -- architectural changes create decision checkpoints
- **Verification after checkpoint:** See verification-loops.md for cycling protocol
- **Phase execution:** See phased-execution.md for checkpoint handling between waves
- **Task format:** Checkpoint type is specified in the task's `type` field (see plan-structure.md)

## When to Apply

- Planning any phase with UI/visual components (human-verify needed)
- Planning phases with technology choices (decision needed)
- When CLI/API automation fails with auth errors (auth gate created dynamically)
- NOT for work that can be verified programmatically (tests, builds, typechecks)
- NOT for file operations or command execution (Claude handles those)

---
*Source: Adapted from GSD execute-plan.md checkpoint protocol and GSD checkpoints reference*
*Last reviewed: 2026-03-08*
