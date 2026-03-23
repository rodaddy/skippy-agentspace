# PRD Schema (v2.1.0)

Machine-readable PRD format written to `.prd/prd.json`.

## Top-Level Structure

```json
{
  "version": "2.1.0",
  "project": "<name>",
  "branch": "<feat|fix|wip/branch-name>",
  "description": "<what and why, max 500 chars>",
  "tier": "quick | standard | full",

  "stack": {
    "language": "python | typescript | swift | go | rust | bash | multi",
    "test_runner": "<exact command, e.g. 'uv run pytest', 'bun test'>",
    "type_checker": "<exact command or null>",
    "working_directory": "<project root, absolute path>"
  },

  "limits": {
    "max_retries_per_story": 5,
    "max_total_cycles": 20,
    "current_cycle": 0
  },

  "pre_flight": {
    "commands": [
      {
        "name": "<what this checks>",
        "command": "<shell command>",
        "expect_exit_0": true
      }
    ],
    "known_issues": [
      {
        "description": "<what's already broken>",
        "affects_stories": ["US-001"],
        "resolution": "out_of_scope | will_fix | blocker"
      }
    ]
  },

  "stories": [
    {
      "id": "US-001",
      "title": "<imperative, max 80 chars, no 'and'>",
      "description": "As a <role>, I want <action> so that <benefit>.",
      "depends_on": [],
      "priority": 1,
      "status": "pending",
      "retries": 0,

      "acceptance_criteria": [
        "<specific, verifiable criterion -- max 7 items>"
      ],

      "verify": {
        "commands": [
          {
            "name": "<what this proves>",
            "command": "<shell command, exit 0 = pass>",
            "timeout_ms": 30000,
            "expect_pattern": "<regex stdout must match>",
            "expect_not_pattern": "<regex stdout must NOT match, e.g. 'FAIL|ERROR'>",
            "retry_on_fail": false
          }
        ],
        "manual_checks": []
      }
    }
  ],

  "review_protocol": {
    "mode": "pipelined",
    "reviewers": ["quality", "antagonist"],
    "blocking_severities": ["CRITICAL", "HIGH"],
    "integration_check": true
  },

  "amendment_history": [],
  "completed_at": null
}
```

## Story Status State Machine

```
pending --> in_progress --> awaiting_verify --> passed
                |                   |
                |                   |-> failed (retry < max) --> pending
                |                   |
                |                   '-> failed (retry >= max) --> STOP
                |
                '-> blocked (dependency failed or known_issue blocker)
```

- `pending` -- not started
- `in_progress` -- executor agent is working on it
- `awaiting_verify` -- executor done, waiting for verifier agent
- `passed` -- ALL verify commands exit 0, ALL patterns match, NO not-patterns match
- `failed` -- at least one command failed. Retry if under limit.
- `blocked` -- dependency in `depends_on` is failed/blocked, OR known_issue is a blocker

## Evidence Structure (per-story, in `.prd/evidence/US-NNN.json`)

```json
{
  "story_id": "US-001",
  "verified_at": "2026-02-21T23:19:26-08:00",
  "verified_by": "verifier-agent (not executor)",
  "git_commit": "<commit hash at verification time>",
  "cycle": 3,
  "command_results": [
    {
      "command": "uv run pytest tests/ -x -q",
      "exit_code": 0,
      "passed": true,
      "stdout_excerpt": "324 passed in 0.60s",
      "stderr_excerpt": "",
      "duration_ms": 1200,
      "pattern_matched": true,
      "not_pattern_clean": true
    }
  ],
  "summary": {
    "total": 3,
    "passed": 3,
    "failed": 0
  },
  "regressions_checked": ["US-001", "US-002"],
  "regressions_clean": true
}
```

Evidence is NEVER inlined in `prd.json`. Separate files keep the main PRD small.
