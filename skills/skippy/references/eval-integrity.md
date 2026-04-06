# Eval Integrity -- LLM-as-Judge Bias Mitigation

When using LLM agents to evaluate other LLM outputs (as in `/skippy:eval` or `/skippy:review`), 5 known biases affect judgment quality.

## Known Biases

| Bias | Description | Mitigation |
|------|-------------|------------|
| **Position bias** | First/last items in a list get disproportionate attention | Randomize presentation order, evaluate items independently |
| **Self-enhancement bias** | LLMs rate their own outputs higher | Use a different model for evaluation than generation |
| **Length bias** | Longer outputs rated as higher quality regardless of content | Normalize for length, set explicit length expectations |
| **Verbosity bias** | More detailed explanations rated as better even when wrong | Score correctness separately from completeness |
| **Authority bias** | Outputs that cite sources or use technical language rated higher | Verify claims independently, don't reward citation count |

## When to Apply

- Any `/skippy:eval` pipeline run (v2.0 curation engine)
- Review swarm synthesis (audit-swarm.md) -- cross-reviewer aggregation
- Self-improvement loops (sealed-eval.md) -- evaluation quality

## Integration Points

- **sealed-eval.md** -- model separation mitigates self-enhancement bias
- **audit-swarm.md** -- multi-reviewer aggregation should be position-bias-aware
- **verification-loops.md** -- cycling eval should vary presentation order

---
*Source: Agent-Skills-for-Context-Engineering (muratcankoylan). LLM-as-judge research.*
*Last reviewed: 2026-04-06*
