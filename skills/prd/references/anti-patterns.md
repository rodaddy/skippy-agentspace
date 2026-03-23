# PRD Anti-Patterns

Common mistakes that undermine PRD effectiveness. Check your PRD against this list before finalizing.

| Anti-Pattern | Why It Kills PRDs | Prevention |
|---|---|---|
| Narrative evidence ("Report confirms...") | Self-certification, not proof | Evidence is command output in separate files |
| Same agent writes and verifies | Fox guarding henhouse | Executor sets `awaiting_verify`, different agent runs `--close` |
| `passes: true` without commands | Agent wishful thinking | Status only changes via verify step with captured output |
| Pre-existing issues discovered post-hoc | Surprise blockers | Pre-flight catches them upfront |
| 15-criterion mega-stories | Never fully complete | 7-criteria limit, no exceptions |
| Missing e2e story | Unit tests pass but feature doesn't work in practice | E2E story is mandatory |
| No cycle limits | Agent loops forever | max 5 retries/story, 20 total cycles |
| Optional expect_pattern | Exit 0 with garbage output = false positive | expect_pattern is REQUIRED |
| Full ceremony for bug fixes | Over-engineering kills momentum | Complexity tiers (Quick/Standard/Full) |
| Prose masquerading as commands | "Run pytest" as acceptance criteria text | Verify commands are separate executable fields |
| Evidence inline in prd.json | Context window blowout on 15+ stories | Evidence in `.prd/evidence/` per-story files |
