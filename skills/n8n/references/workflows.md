<!-- Extracted from SKILL.md -- load on demand -->
# n8n Workflow Inventory

## Active Workflows

| ID | Name | Trigger | Status |
|----|------|---------|--------|
| `<WORKFLOW_ID_1>` | Infra Daily Report - Webhook | POST /webhook/infra-daily | Active |
| `<WORKFLOW_ID_2>` | LinkedIn Post Approval - Telegram | Telegram trigger | Active, published |
| `<WORKFLOW_ID_3>` | LinkedIn Posting Pipeline | Schedule (daily 8am CT) | Active |
| `<WORKFLOW_ID_4>` | LinkedIn OAuth Token Monitor | Schedule (daily 9am CT) | Active |
| `<WORKFLOW_ID_5>` | Infra Health Check - Weekly | Schedule | Active |
| `<WORKFLOW_ID_6>` | RSS Content Sourcing Pipeline | Schedule | Active |
| `<WORKFLOW_ID_7>` | Thought Leadership Post Generator | Schedule | Active |
| `<WORKFLOW_ID_8>` | AI Article Commentary Generator | Webhook (Phase 4a) | Active |
| `<WORKFLOW_ID_9>` | Article Queue Consumer | After RSS/YT sourcing | Active |
| `<WORKFLOW_ID_10>` | Second Brain - Daily Digest | Schedule | Active |
| `<WORKFLOW_ID_11>` | Second Brain - Weekly Review | Schedule | Active |
| `<WORKFLOW_ID_12>` | Second Brain - Recall Webhook | Webhook | Active |
| `<WORKFLOW_ID_13>` | Skippy - Dashboard API | Webhook | Active |
| `<WORKFLOW_ID_14>` | Skippy - Discord Classification | Webhook | Active |
| `<WORKFLOW_ID_15>` | Universal Capture v2 | -- | Active |
| `<WORKFLOW_ID_16>` | Universal Capture v3 | -- | Active |
| `<WORKFLOW_ID_17>` | YouTube Content Sourcing | Schedule (8am + 8pm UTC) | Active |

## LinkedIn Pipeline Workflows

```
Phase 3a: RSS Content Sourcing (<WORKFLOW_ID_6>) -- 7am + 7pm UTC
Phase 3b: YouTube Content Sourcing (<WORKFLOW_ID_17>) -- 8am + 8pm UTC
    Both write to -> /home/n8n/.n8n/curated-articles.json (consumed: false)
    -> Queue Consumer (<WORKFLOW_ID_9>) -- picks unconsumed articles
        -> Phase 4a: AI Article Commentary (<WORKFLOW_ID_8>) -- 3-model battle + opus judge
        -> Phase 4b: Thought Leadership (<WORKFLOW_ID_7>)
            -> Phase 5: Telegram Approval (<WORKFLOW_ID_2>)
                -> /data/approved-posts/ queue
                    -> Phase 6: LinkedIn Posting (<WORKFLOW_ID_3>)

Token Monitor (<WORKFLOW_ID_4>) -- independent, checks OAuth health daily
```

### File Locations on the n8n Container

```
/data/approved-posts/          -- Queue of approved posts (JSON files)
/data/pending-approvals/       -- Posts awaiting Telegram approval
/data/post-history.json        -- Append-only log of posted content
/data/linkedin-token-meta.json -- OAuth token tracking
/data/classification-prompt.md -- Second Brain classification prompt
/home/n8n/.n8n/curated-articles.json -- Article queue (RSS + YouTube)
/home/n8n/.n8n/yt-processed.json   -- YouTube video dedup history
```

### LinkedIn Posting Schedule

- Runs daily 8am CT (13:00 UTC), Mon-Fri
- Picks 3 random days per week
- Random time window: 7-9am ET, 11am-1pm ET, or 4-6pm ET
- Rate limit: 100 API calls/user/day (we do ~3/week)

## Webhook Paths

| Workflow | Path | Method |
|----------|------|--------|
| Infra Daily Report | `/webhook/infra-daily` | POST |
| Telegram Approval | `/webhook/telegram-approval` | POST |
| Post Now (LinkedIn) | `/webhook/post-now` | POST |
| Second Brain Recall | `/webhook/second-brain-recall` | POST |
| Skippy Dashboard | `/webhook/skippy-dashboard` | POST |
| Skippy Discord | `/webhook/skippy-discord` | POST |

## Telegram appendAttribution Audit (2026-02-28)

All 13 Telegram nodes across 5 workflows verified `appendAttribution: false`. No issues found. Workflows without Telegram nodes: Second Brain (Daily/Weekly), RSS, YouTube, AI Commentary, Queue Consumer, Thought Leadership.

## Archived Workflows

Inactive workflows use `old_YYYY-MM-DD_name` naming convention to avoid fuzzy-match collisions with `n8n-wf`. These are archived in the DB but NOT deleted.

## Local Workflow JSON Files

Project-specific workflow JSONs live in `resumeUpdate/Workflows/`:
- `linkedin-posting-pipeline.json` -- Phase 6
- `telegram-approval.json` -- Phase 5 (original)
- `telegram-approval-v2.json` -- Phase 5 (updated)
- `tg-approval-v2-fixed.json` -- Phase 5 (fixed for n8n 2.x)
- `ai-content-generation.json` -- Phase 4
- `thought-leadership-generation.json` -- Phase 4b
- `oauth-token-monitor.json` -- Token lifecycle
