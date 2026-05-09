# Architecture: {FEATURE_NAME}

---

## Current Architecture

### How It Works Today

**Components:**
- Component 1: Current implementation
- Component 2: How it integrates
- Component 3: Dependencies

**Data Flow:**
```
Input → Processing → Output
  ↓         ↓          ↓
 {step}   {step}    {step}
```

**Data Structures:**
```typescript
// Current data model
interface CurrentModel {
  field1: type;
  field2: type;
}
```

**Operations:**
- Operation 1: How it's done today
- Operation 2: Current approach
- Operation 3: Existing flow

**Bottlenecks:**
- Bottleneck 1: Why it's slow/problematic
- Bottleneck 2: Scale limitations
- Bottleneck 3: Technical debt

---

## Proposed Architecture

### Option A: {Approach Name} ⭐ RECOMMENDED

**Overview:**
[High-level description of this approach]

**Pros:**
- ✅ Benefit 1 (with concrete impact)
- ✅ Benefit 2 (with measurable gain)
- ✅ Benefit 3 (with technical advantage)

**Cons:**
- ❌ Drawback 1 (with real limitation)
- ❌ Drawback 2 (with trade-off cost)

**Why Recommended:**
[Context-specific reasoning for this choice]

### Option B: {Alternative Approach}

**Overview:**
[High-level description]

**Pros:**
- ✅ ...

**Cons:**
- ❌ ...

**Why Not Recommended:**
[Reasoning against this approach]

### Option C: {Another Alternative}

[Similar structure]

---

## Chosen Approach: Option A

### Data Model

**New Schema:**
```typescript
// Proposed data model
interface NewModel {
  field1: type;  // Purpose
  field2: type;  // Purpose
  field3?: type; // Optional, for {reason}
}
```

**Storage:**
- Where data lives (database, cache, file, etc.)
- Access patterns (read-heavy, write-heavy, mixed)
- Indexing strategy (for query performance)

### Component Design

**Component 1:**
```typescript
// High-level structure (NOT full implementation)
class ComponentName {
  constructor(dependencies) {
    // Injection pattern
  }

  async mainOperation(input: Type): Promise<Result> {
    // Core logic flow
  }
}
```

**Component 2:**
[Similar structure]

### Data Flow

```
New Flow:
Input → Validation → Processing → Storage → Output
  ↓         ↓            ↓          ↓         ↓
{step}    {step}      {step}     {step}   {step}
```

**Key Changes from Current:**
- Change 1: What's different and why
- Change 2: New step added
- Change 3: Removed complexity

### API Changes

**New Endpoints/Methods:**
```typescript
// Example API signature (NOT full code)
async function newOperation(
  param1: Type,
  param2: Type
): Promise<Result> {
  // High-level approach
}
```

**Breaking Changes:**
- Change 1: What breaks and migration path
- Change 2: Deprecation timeline

**Backward Compatibility:**
- How we maintain compatibility (if applicable)
- Migration support period

---

## Migration Strategy

### Phase 1: {Name} ({Duration estimate})

**Goal:** {What we achieve in this phase}

**Steps:**
1. Step 1 - Technical action
2. Step 2 - Technical action
3. Validation - How we verify

**Deliverables:**
- Deliverable 1
- Deliverable 2

### Phase 2: {Name} ({Duration estimate})

[Similar structure]

### Phase 3: {Name} ({Duration estimate})

[Similar structure]

### Rollback Plan

**If migration fails:**
1. Rollback step 1
2. Rollback step 2
3. Recovery validation

**Data Safety:**
- Backup strategy before migration
- Validation checksums
- Point-in-time recovery capability

---

## Operational Changes

### Deployment

**New Requirements:**
- Infrastructure: VMs, containers, services needed
- Configuration: New environment variables, secrets
- Dependencies: External services, packages

**Deployment Steps:**
1. Pre-deployment: Backups, validation
2. Deployment: Blue-green, canary, rolling update
3. Post-deployment: Health checks, smoke tests

### Monitoring

**New Metrics:**
- Metric 1: What to track (latency, errors, throughput)
- Metric 2: Alert thresholds
- Metric 3: SLO targets

**Dashboards:**
- Dashboard 1: Key metrics for {purpose}
- Dashboard 2: Debug view for troubleshooting

**Alerts:**
- Alert 1: Condition → Action
- Alert 2: Threshold → Escalation

### Backup & Recovery

**Backup Strategy:**
- What: Data, state, configuration
- When: Frequency (hourly, daily, etc.)
- Where: Storage location (GCS, S3, etc.)
- Retention: {X} days

**Recovery:**
- RTO: Recovery Time Objective ({X} minutes)
- RPO: Recovery Point Objective (max {X} data loss)
- Procedure: Step-by-step recovery process

---

## Performance Analysis

### Current Performance

| Operation | Latency | Throughput | Bottleneck |
|-----------|---------|------------|------------|
| {Op1} | {current} | {current} | {why slow} |
| {Op2} | {current} | {current} | {why slow} |

### Expected Performance

| Operation | Current | Target | Improvement | Method |
|-----------|---------|--------|-------------|--------|
| {Op1} | {value} | < {target} | {X}x faster | {how} |
| {Op2} | {value} | < {target} | {improvement} | {how} |

**Benchmarking Plan:**
- Load test: {X} concurrent operations
- Measure: P50, P95, P99 latencies
- Compare: Before vs After side-by-side

---

## Trade-Off Analysis

### Chosen Approach (Option A) vs Alternatives

| Factor | Option A ⭐ | Option B | Option C |
|--------|-----------|----------|----------|
| Complexity | {rating} | {rating} | {rating} |
| Performance | {rating} | {rating} | {rating} |
| Maintainability | {rating} | {rating} | {rating} |
| Cost | {estimate} | {estimate} | {estimate} |
| Risk | {level} | {level} | {level} |

**Decision Factors:**
1. Factor 1: Why Option A wins
2. Factor 2: Acceptable trade-off
3. Factor 3: Long-term benefit

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| {Risk 1} | High/Med/Low | High/Med/Low | {How we address} |
| {Risk 2} | ... | ... | ... |

---

## Implementation Checklist

**Pre-Implementation:**
- [ ] Design review completed
- [ ] Dependencies identified and available
- [ ] Test environment prepared
- [ ] Backup strategy validated

**Implementation:**
- [ ] Core functionality implemented
- [ ] Unit tests written (> {X}% coverage)
- [ ] Integration tests passing
- [ ] Performance benchmarks met

**Pre-Deployment:**
- [ ] Code review approved
- [ ] Security scan passed
- [ ] Load testing completed
- [ ] Documentation updated

**Post-Deployment:**
- [ ] Monitoring dashboards created
- [ ] Alerts configured
- [ ] Runbook documented
- [ ] Team trained on new system

---

## Files Changed

**New Files:**
- `path/to/new/file.ext` - Purpose

**Modified Files:**
- `path/to/existing/file.ext` - Changes made

**Deleted Files:**
- `path/to/deprecated/file.ext` - Reason for removal

**Estimated LOC:** +{additions} / -{deletions} = {net change}

---

**Last Updated:** {DATE}
**Author:** {NAME}
**Status:** Draft | Under Review | Approved