# Sealed Eval -- Tamper-Proof Benchmark Pattern

Lock evaluation criteria before an improvement loop starts so the agent can modify implementation but not the metrics it is measured against. Prevents self-improvement loops from gaming their own benchmarks.

**Source:** OMC v4.10 (self-improve skill)
**Cherry-picked:** 2026-04-06

## The Problem

When an agent can modify both code AND its evaluation, it optimizes for passing tests rather than actual quality. Common failure modes:

- **Weakened assertions:** Agent relaxes pass/fail thresholds to make scores improve
- **Narrowed scope:** Agent removes test cases that are hard to pass
- **Metric substitution:** Agent redefines the metric to one it already satisfies
- **Eval-aware implementation:** Agent writes code that detects the eval harness and branches

The result: metrics improve while actual quality stays flat or degrades. The improvement loop reports success but nothing meaningful changed.

## The Pattern

```
1. DEFINE: Write evaluation criteria (validate.sh, assertions, benchmarks)
2. SEAL: Hash-lock the eval artifacts. Record checksums.
3. IMPROVE: Agent iterates on implementation (code, prompts, config)
   - Agent CAN modify: source code, prompts, configuration, documentation
   - Agent CANNOT modify: eval scripts, assertion files, benchmark data
4. VERIFY: Run sealed eval against improved implementation
5. COMPARE: Pre-improvement score vs post-improvement score
6. ACCEPT/REJECT: Only accept if scores improve without seal violation
```

## Implementation

### Hash-Lock the Eval

Before the improvement loop starts:

```bash
# Compute checksums for all eval artifacts
sha256sum evals/**/*.sh evals/**/*.json > .eval-seal.sha256

# At each iteration, verify seal integrity
sha256sum --check .eval-seal.sha256 || echo "SEAL BROKEN -- reject this iteration"
```

### Isolated Execution

Run the eval in a context where the agent cannot modify it:

- Eval scripts run from a read-only copy or a separate worktree
- Agent's tool permissions exclude eval directories during improvement phases
- Results are written to a location the agent cannot retroactively edit

### Score Comparison

```
Pre-improvement:  67/103 assertions pass (65.0%)
Post-improvement: 89/103 assertions pass (86.4%)
Seal intact:      YES (all checksums match)
Verdict:          ACCEPT (+21.4% genuine improvement)
```

## When to Apply

- Any autonomous improvement loop where the agent modifies its own artifacts
- `/skippy:eval` pipeline -- eval assertions must be sealed before skill iteration
- Self-modifying agent patterns (agents that edit their own prompts or tools)
- Benchmark-driven development where the benchmark must remain stable
- NOT needed for human-supervised iteration (human is the seal)

## What to Seal

| Seal | Do Not Seal |
|------|-------------|
| Assertion scripts and expected outputs | Implementation source code |
| Benchmark data and test fixtures | Configuration and parameters |
| Scoring logic and thresholds | Documentation and comments |
| Pass/fail criteria | Build scripts and tooling |

## Integration Points

- **verification-loops.md** -- Sealed eval protects the integrity of verification criteria during cycling. Without it, an improvement loop can silently weaken its own verification.
- **audit-swarm.md** -- Review agents should verify seal integrity as part of their review. A broken seal is an automatic rejection.
- **skill-improver-loop.md** -- The skill improvement cycle should seal its eval before iterating on skill content.

---
*Sources: OMC v4.10 self-improve skill. Pattern generalized for any eval-driven iteration.*
*Last reviewed: 2026-04-06*
