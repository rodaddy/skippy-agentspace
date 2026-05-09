<!-- Extracted from SKILL.md -- load on demand -->

# State File Formats

## `.autoresearch/state.json`

```json
{
  "best_score": -1,
  "best_validation_score": -1,
  "run_number": 0,
  "target": "chosen optimization target",
  "scope": "chosen scope, if provided",
  "context": "chosen context, if provided",
  "max_score": 40,
  "criteria_count": 4,
  "batch_size": 10,
  "validation_items": [
    "path/to/item1",
    "path/to/item2",
    "path/to/item3"
  ],
  "sampled_items": [],
  "item_failures": {},
  "plateau_counter": 0
}
```

### Field Descriptions

| Field | Type | Purpose |
|-------|------|---------|
| `best_score` | number | Highest total score achieved |
| `best_validation_score` | number | Highest validation-set-only score (primary comparison metric) |
| `run_number` | number | Current run counter |
| `target` | string | What's being optimized |
| `scope` | string | Narrowed focus area |
| `context` | string | Constraints or conventions |
| `max_score` | number | batch_size x criteria_count |
| `criteria_count` | number | Number of eval criteria |
| `batch_size` | number | Items per cycle (validation + rotating) |
| `validation_items` | string[] | Fixed items that appear every cycle |
| `sampled_items` | string[] | All items ever sampled (for coverage tracking) |
| `item_failures` | object | `"path:criterion" -> count` for tracking persistent failures |
| `plateau_counter` | number | Consecutive DISCARD cycles (triggers rewrite at 5) |

## `.autoresearch/results.jsonl`

One JSON line per cycle:

```json
{
  "run": 1,
  "timestamp": "2026-04-08T10:30:00Z",
  "score": 24,
  "validation_score": 12,
  "max": 40,
  "criteria": {
    "has_docstring": 8,
    "passes_lint": 6,
    "has_error_handling": 5,
    "has_return_type": 5
  },
  "status": "keep",
  "mutation_operator": "add_constraint",
  "prompt_len": 245,
  "prompt_text": "full text of the prompt used this run",
  "failures": [
    "item3: missing docstring on nested function",
    "item5: bare except clause"
  ],
  "items_flagged": [],
  "flaky_commands": []
}
```

### Field Descriptions

| Field | Type | Purpose |
|-------|------|---------|
| `run` | number | Cycle number |
| `timestamp` | string | ISO 8601 |
| `score` | number | Total score this cycle |
| `validation_score` | number | Score on fixed validation items only |
| `max` | number | Maximum possible score |
| `criteria` | object | Per-criterion pass counts |
| `status` | string | "keep" or "discard" |
| `mutation_operator` | string | Which operator was applied for the next cycle |
| `prompt_len` | number | Word count of the prompt |
| `prompt_text` | string | Full prompt text (for reproducibility) |
| `failures` | string[] | Brief descriptions of why items failed |
| `items_flagged` | string[] | Item+criterion pairs flagged as item-level issues |
| `flaky_commands` | string[] | Commands that passed only on retry |

## `.autoresearch/prompt.txt`

Plain text file containing the current cycle's prompt. Reverts to `best_prompt.txt` content when a cycle is discarded.

## `.autoresearch/best_prompt.txt`

Plain text file containing the highest-scoring prompt. Only updated when a cycle scores higher than the previous best (by the confidence margin). This is the final deliverable.

## Confidence Margins

| Batch Size | Required Improvement |
|------------|---------------------|
| 5-7 items | 2+ points on validation set |
| 8-10 items | 1+ point on validation set |

These margins prevent noise from being mistaken for progress.
