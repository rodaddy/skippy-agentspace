# LAW 15: No LiteLLM Self-Surgery

**Enforcement:** `pre-litellm-self-surgery.ts` (PreBash hook)
**Severity:** MANDATORY

## Rule

Never modify LiteLLM infrastructure while the session is routed through LiteLLM.

## Why

If Claude Code is using LiteLLM as its API proxy and breaks it (restart, user remap, config change), the session dies and there's no AI available to fix the damage. It's the equivalent of sawing off the branch you're sitting on.

## Enforcement Details

- Pre-Bash hook checks `ANTHROPIC_BASE_URL` for LiteLLM indicators
- Detection: URL contains LiteLLM host or "litellm" keyword = routed through LiteLLM (BLOCKED)
- `CLAUDE_CODE_USE_VERTEX=1` with no LiteLLM base URL = direct API (SAFE)

**Blocked commands (when routed through LiteLLM):**
- SSH to the LiteLLM host
- Ansible playbooks targeting LiteLLM hosts
- systemctl operations on litellm.service
- Config file edits in LiteLLM directories

## Workaround

1. Start a direct API session (e.g., `CLAUDE_CODE_USE_VERTEX=1 claude`)
2. Make LiteLLM changes from that session
3. Verify LiteLLM is healthy before switching back

## Exceptions

- Read-only operations (checking status, viewing logs) are allowed
- Sessions confirmed to be using direct API access (not routed through LiteLLM)
