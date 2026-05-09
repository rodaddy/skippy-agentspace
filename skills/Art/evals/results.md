# Art Skill Eval Results

**Date:** 2026-03-13
**Score:** 15/15 (perfect)
**Iterations:** 2
**Model:** claude-opus-4-6

## Assertion Results

| # | Category | Assertion | Result |
|---|----------|-----------|--------|
| 1 | pre-generation | Reads workflow.md BEFORE generation | PASS |
| 2 | pre-generation | Reads aesthetic.md BEFORE generation | PASS |
| 3 | story-explanation | 24-item story explanation MANDATORY | PASS |
| 4 | style-selection | Runs select-style.ts --json | PASS |
| 5 | style-selection | Top 3-4 styles, AskUserQuestion, multiSelect: false | PASS |
| 6 | aspect-ratio | 1:1 square, NOT 16:9 | PASS |
| 7 | model | nano-banana-pro default | PASS |
| 8 | composition | Full-bleed, 100% frame fill | PASS |
| 9 | color | Purple #4A148C visible/noticeable | PASS |
| 10 | color | NO gradients | PASS |
| 11 | background | White bg → remove.bg transparency | PASS |
| 12 | signature | Kai signature charcoal bottom right | PASS |
| 13 | post-generation | AskUserQuestion for style rating | PASS |
| 14 | language | No copilot phrases | PASS |
| 15 | output | ~/Downloads/pai-generated-${timestamp}.png | PASS |

## Changes Made

### Iteration 1: FAILED #6 (14/15)

**File:** `SKILL.md` (line 90-98)
**Problem:** The Style Preference Learning System example command hardcoded `--aspect-ratio 16:9`, directly contradicting Core Visual Rules which specify `1:1` for editorial illustrations. An executor copy-pasting the style section's example would use the wrong aspect ratio.
**Fix:** Changed example to `--aspect-ratio 1:1` and added bold warning: "Editorial illustrations MUST use 1:1 (square). Other workflows may vary."
**Commit:** `eval: fix assertion #6 -- aspect ratio 16:9 contradiction in style example`

### Iteration 2: PASSED (15/15)

No further changes needed. All assertions pass with the 16:9 → 1:1 fix in place.

## Notes

- Previous eval run (same date) claimed 15/15 on iteration 1 without catching the 16:9 contradiction -- that was a false pass
- The --remove-bg flag is mentioned in text (workflow.md line 222) but omitted from example commands in both SKILL.md and workflow.md -- not a failure but a latent risk
