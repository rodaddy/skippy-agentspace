# n8n Workflow Wiring Patterns

## Chaining Workflows (Webhook-to-Webhook)

**Pattern:** Independent workflows trigger each other via webhook calls. Each workflow stays small, testable, and deployable independently.

### To connect Workflow A -> Workflow B:

Add **1 HTTP Request node** at the end of Workflow A:
- method: POST
- url: `https://n8n.your-domain.example/webhook/<workflow-b-path>`
- body: minimal payload (e.g., `{ "id": {{ $json.id }} }`)
- continueOnFail: true (downstream failure shouldn't break upstream)
- timeout: match expected runtime of Workflow B

That's it. One node. Don't restructure either workflow.

### Why this pattern:

- Each workflow has its own webhook trigger already -- use it
- Workflows are services, not functions -- call the API, don't merge the code
- Independent testing: trigger any workflow directly via curl
- Independent deployment: update one without touching others
- Failure isolation: if B fails, A still completes its own work

### Anti-patterns:

| Don't | Do Instead |
|-------|------------|
| Merge workflows into one big flow | Chain via webhooks |
| Add 4+ nodes to "wire" workflows | Add 1 HTTP Request node |
| Edit JSON files to rewire connections | Use n8n MCP `update_workflow` |
| Bundle unrelated fixes into wiring changes | Separate PRs/commits |

### Example: Discord Handler -> Post Generator -> Visual Generator

```
Discord Handler (8blbFOMmwoWquc1j)
  !approve -> DB update -> POST /webhook/generate-post -> Discord confirm

Post Generator (NYSfP7NRODTv7uDq)
  webhook -> generate -> store -> POST /webhook/generate-visuals -> respond

Visual Generator (1utW51dZYIKgb3hr)
  webhook -> generate images -> Discord review msg -> respond
```

Each workflow adds exactly 1 outbound HTTP Request node. Total changes: 3 nodes across 3 workflows.
