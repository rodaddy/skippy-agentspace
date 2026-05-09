# CompareOptions Workflow

Side-by-side comparison of technologies, tools, or approaches with recommendation.

## When to Use

- User asks "compare X vs Y", "which should I use", "what's better"
- Evaluating technology choices
- Need decision matrix with trade-offs

## Process

1. **Identify Options**
   - List all options to compare (usually 2-4)
   - Ensure apples-to-apples comparison
   - Define comparison criteria

2. **Research Each Option**
   - Official documentation
   - Community sentiment
   - Real-world usage examples
   - Performance benchmarks
   - Ecosystem maturity

3. **Define Comparison Criteria**
   Common criteria:
   - Performance/Speed
   - Developer Experience
   - Ecosystem/Community
   - Learning Curve
   - Maturity/Stability
   - License/Cost
   - Use Case Fit

4. **Build Comparison Matrix**
   ```markdown
   ## Feature Comparison

   | Feature | Option A | Option B | Option C |
   |---------|----------|----------|----------|
   | Speed | Fast | Very Fast | Moderate |
   | DX | Excellent | Good | Fair |
   | Ecosystem | Large | Growing | Small |
   | Learning Curve | Easy | Moderate | Steep |
   ```

5. **Analyze Trade-offs**
   - What you gain with each option
   - What you sacrifice
   - Deal-breakers for each use case

6. **Provide Recommendation**
   ```markdown
   ## Recommendation

   **For your use case ([context]):**

   Choose [Option A] if:
   - Requirement 1
   - Requirement 2

   Choose [Option B] if:
   - Requirement 1
   - Requirement 2

   **Winner:** [Option X]
   **Reason:** [Justification based on user's specific needs]
   ```

## Output Format

```markdown
# Comparison: [Option A] vs [Option B] vs [Option C]

## Quick Summary
[One sentence per option describing its main value prop]

## Detailed Comparison

### Performance
[Analysis]

### Developer Experience
[Analysis]

### Ecosystem
[Analysis]

## Comparison Matrix

| Criteria | Option A | Option B | Option C | Winner |
|----------|----------|----------|----------|--------|
| Speed | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | A |
| DX | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | B |
[...]

## Pros & Cons

### Option A
**Pros:**
- Pro 1
- Pro 2

**Cons:**
- Con 1
- Con 2

## Recommendation

**For [your specific use case]:**

**Choose Option A if:**
- You prioritize X
- You need Y
- You can accept Z trade-off

**Choose Option B if:**
- You prioritize different things

**Winner:** Option A
**Reasoning:** [Clear justification]

## Sources
[Links to documentation, benchmarks, comparisons]
```

## Example: "Compare Redis vs Memcached"

1. Research both caching solutions
2. Define criteria (speed, features, persistence, etc.)
3. Build comparison matrix
4. Analyze use cases
5. Recommend based on user's context

**Output includes:**
- Feature comparison table
- Performance benchmarks
- Use case analysis
- Clear recommendation with reasoning

## Tips

- **Be objective** - Present facts, not opinions
- **Context matters** - Best choice depends on use case
- **Show trade-offs** - There's no perfect solution
- **Include benchmarks** - When available and relevant
- **Date your research** - Technologies evolve
