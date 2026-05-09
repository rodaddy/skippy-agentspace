# Humanizer Eval Results

- **Date:** 2026-03-13
- **Score:** 16/16
- **Iterations:** 1
- **Pass threshold:** 1.0 (100%)

## Assertion Results

| ID | Category | Result | Notes |
|----|----------|--------|-------|
| 1 | transition-words | PASS | No "Additionally"/"Furthermore"/"Moreover" as sentence starters |
| 2 | ai-vocabulary | PASS | No "delve"/"landscape"/"navigate"/"leverage" in rewritten text |
| 3 | ai-vocabulary | PASS | No "tapestry"/"multifaceted"/"holistic"/"paradigm shift" in rewritten text |
| 4 | ai-vocabulary | PASS | No "ecosystem"/"stakeholders"/"catalyst" in rewritten text |
| 5 | hedging | PASS | No "It's worth noting"/"It is important to note" |
| 6 | hedging | PASS | No "arguably" |
| 7 | copilot-phrases | PASS | No "serves as"/"stands as"/"marks a" -- direct verbs used |
| 8 | copilot-phrases | PASS | No "cutting-edge"/"game-changing"/"groundbreaking" |
| 9 | soul-injection | PASS | Added: retailer example, 40% cost cut, 18-month delay, unbudgeted hires |
| 10 | soul-injection | PASS | "oversold", "I keep coming back to", "a lot of noise" -- clear POV |
| 11 | structure | PASS | "There's also a lot of noise." (6 words) + "A mid-size retailer..." (32 words) |
| 12 | structure | PASS | Rewritten text is prose paragraphs, no parallel lists |
| 13 | formatting | PASS | Used "--" (double hyphens), no em dashes |
| 14 | tone | PASS | Maintains cloud/AI technology topic throughout |
| 15 | pattern-report | PASS | Detailed list of detected patterns and changes for each |
| 16 | overcorrection | PASS | 6+ natural gerunds preserved: moving, hoping, using, forecasting, migrating, trying |

## Changes Made

None. The skill passed all 16 assertions on the first iteration without modifications.

## Robustness Notes

The SKILL.md's explicit word lists don't cover every word the assertions test for. The following words are caught by general principles rather than explicit listing:

- **Not in Pattern 7 (AI vocabulary):** navigate, leverage, multifaceted, holistic, paradigm shift, ecosystem, stakeholders, catalyst
- **Not in Pattern 4 (promotional):** cutting-edge, game-changing
- **Not in Pattern 22 (filler):** "It's worth noting"
- **Not in Pattern 23 (hedging):** arguably

A capable model generalizes beyond the explicit lists, but adding these words would make the skill more robust for less capable models. No changes were made since the eval passed cleanly.
