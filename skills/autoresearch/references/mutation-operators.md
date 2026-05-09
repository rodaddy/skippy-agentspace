<!-- Extracted from SKILL.md -- load on demand -->

# Mutation Operators Reference

Six structured operators for prompt mutation. Rotate through them across cycles. Always mutate FROM `best_prompt.txt`, never from a failed attempt.

## 1. Add Constraint

For the weakest criterion, add an explicit rule or prohibition addressing the most common failure pattern.

**When:** A specific criterion consistently fails for the same reason.

**Example:**
```
BEFORE: "Include error handling in the function."
AFTER:  "Every async function MUST have a try/catch block. The catch block MUST log the error with context (function name + input params) before re-throwing."
```

## 2. Add Negative Example

Insert a "DO NOT do X" with a concrete example of a common failure.

**When:** Outputs keep making the same mistake.

**Example:**
```
ADDED: "DO NOT use generic alt text like 'image', 'screenshot', or 'figure'. Bad: alt='screenshot'. Good: alt='Authentication flow showing JWT token exchange between client and server'."
```

## 3. Restructure

Reorder the prompt's instructions. Move the most-failed criterion's rules to the top (primacy bias). Group related rules together.

**When:** The prompt has good rules but they're buried or scattered.

**Example:** Move "MUST have exactly one H1" from line 15 to line 2 if that criterion keeps failing.

## 4. Tighten Language

Replace vague words with imperatives. Make fuzzy instructions concrete.

**When:** Outputs are inconsistent -- sometimes passing, sometimes not.

**Replacements:**
| Vague | Tight |
|-------|-------|
| "try to" | "MUST" |
| "consider" | "ALWAYS" |
| "should" | "REQUIRED" |
| "avoid" | "NEVER" |
| "can include" | "MUST include" |
| "ideally" | "REQUIRED" |

## 5. Remove Bloat

Delete a redundant or low-impact line. Shorter prompts at equal scores are better.

**When:** Prompt exceeds 300 words, or a rule hasn't contributed to any score improvement.

**Flag:** If prompt exceeds 500 words, log `"prompt_warning": "length"`.

## 6. Add Counterexample

For a frequently failed criterion, add a before/after example showing what passing vs failing looks like.

**When:** The criterion is clear but the model keeps producing failing outputs anyway.

**Example:**
```
ADDED:
BAD:  description: "This page covers authentication"  (too short, 42 chars)
GOOD: description: "Configure OAuth 2.0 authentication for your API integration with step-by-step setup, token management, and troubleshooting"  (138 chars)
```

---

## Operator Selection Strategy

- Rotate through operators so each gets tried at least once in the first 6 cycles
- After cycle 6, bias toward operators with higher KEEP rates
- Log which operator was used in every `results.jsonl` entry
- In the final summary, rank operators by KEEP rate (KEEPs / times used)

## Plateau Break (Special)

Not a regular operator. Triggered after 5 consecutive DISCARD cycles.

- Ignore current best prompt entirely
- Re-read last 10 `results.jsonl` entries
- Write a completely new prompt from scratch using ONLY:
  - The target description
  - The eval criteria
  - Accumulated failure patterns
- Log as `"mutation_operator": "plateau_break"`
- Reset `plateau_counter` to 0
