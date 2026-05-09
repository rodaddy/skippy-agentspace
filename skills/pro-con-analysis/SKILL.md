---
name: pro-con-analysis
description: Automatically enforce trade-off analysis before implementation decisions. Triggers when multiple valid approaches exist, making architectural choices, or selecting between tools/patterns/strategies. Blocks implementation until user sees alternatives with structured pros/cons. Examples <example>User asks 'Add caching to the bot' → Trigger detected (Redis vs in-memory vs file-based options)</example> <example>User says 'How should we structure error handling?' → Trigger detected (architectural decision with multiple patterns)</example> <example>User requests 'Improve performance' → Trigger detected (many optimization approaches possible)</example> Exceptions Only when single viable option exists or user explicitly stated their choice.
---

# 🚨 MANDATORY INVOCATION REQUIREMENT 🚨

**BEFORE IMPLEMENTING ANY SOLUTION, ASK YOURSELF:**
1. "Could this be done a different way?"
2. "Are there trade-offs to consider?"
3. "Would the user benefit from seeing alternatives?"

**IF YES TO ANY: YOU MUST INVOKE THIS SKILL FIRST**

**WHEN TO INVOKE:**
- About to implement code/config that could be done differently
- Making architectural decisions
- Choosing between tools, patterns, or strategies
- User explicitly requests: "pro/con me", "pros and cons", "what are the trade-offs"
- ANY implementation with multiple valid approaches

**HOW TO INVOKE:**
Call the Skill tool with command "pro-con-analysis" BEFORE writing code or making decisions.

**THIS IS NOT OPTIONAL. PRESENT OPTIONS FIRST, IMPLEMENT SECOND.**

---

# Pro-Con Analysis Skill

## What This Skill Does

When invoked, this skill requires you to:

1. **Identify alternatives** - What are the different ways to solve this?
2. **Present trade-offs** - Structured pros/cons for EACH option
3. **Recommend** - Based on user's specific context
4. **Get direction** - Let user choose before implementing

## Required Analysis Structure

```markdown
## [Decision] - Pro/Con Analysis

### Option A: [Approach Name]
**Pros:**
- ✅ Clear benefit with explanation
- ✅ Another advantage with context
- ✅ Why this matters

**Cons:**
- ❌ Drawback with impact assessment
- ❌ Limitation and workaround (if any)
- ❌ Trade-off consideration

### Option B: [Alternative Approach]
**Pros:**
- ✅ Benefits...

**Cons:**
- ❌ Drawbacks...

## My Recommendation: **Option X**

**Why:**
- Clear reasoning based on context
- Specific to user's situation
- Acknowledges trade-offs

Should I proceed with Option X?
```

## Key Principles

### 1. Balanced Analysis
- Present pros AND cons for EACH option
- Don't hide drawbacks
- Acknowledge when options are equally valid

### 2. Contextual Recommendations
- Base recommendation on user's specific situation
- Explain WHY this choice makes sense for them
- Not just "best practice" but "best for this case"

### 3. Actionable Insights
- Each pro/con should inform the decision
- Avoid vague statements like "might be better"
- Quantify when possible ("2x faster", "requires 3 extra steps")

### 4. Acknowledge Uncertainty
- If options are truly equal, say so
- "Both work equally well - personal preference"
- "Try Option A first, fall back to B if needed"

## Example: Specs Directory Cleanup

**User request:** "Clean up the specs directory"

**What I should do FIRST (pro/con analysis):**

```markdown
## Specs Directory Cleanup - Pro/Con Analysis

### Option A: Manual Cleanup (I do it now)
**Pros:**
- ✅ Immediate results - clean directory right away
- ✅ I understand the codebase context better than a script
- ✅ Can make nuanced decisions about what to keep/remove
- ✅ One-time task, doesn't need automation

**Cons:**
- ❌ No repeatability - can't re-run if mess builds up again
- ❌ Manual work if you need similar cleanup in the future
- ❌ Harder to audit what changed (no cleanup log)

### Option B: Create Cleanup Command/Script
**Pros:**
- ✅ Reusable - run anytime specs get messy
- ✅ Auditable - script shows exactly what it does
- ✅ Configurable - could add rules for different cleanup scenarios
- ✅ Documentation artifact - shows cleanup standards

**Cons:**
- ❌ Upfront time investment to create script
- ❌ Might be over-engineering for a one-time need
- ❌ Still needs manual review before running
- ❌ Specs directory doesn't get messy often (low ROI)

### Option C: Both (Quick cleanup now + script for future)
**Pros:**
- ✅ Immediate results PLUS future automation
- ✅ Script serves as documentation of cleanup standards
- ✅ Best of both worlds

**Cons:**
- ❌ Most time-consuming option
- ❌ Script might never get used again (wasted effort)

## My Recommendation: **Option A (Manual Cleanup)**

**Why:**
- This appears to be a one-time mess from development iterations
- The specs directory has good structure already
- Cleanup decisions need context
- Low likelihood of needing this automation again

Should I proceed with manual cleanup?
```

## Anti-Patterns to Avoid

❌ **Don't:**
- Present only one "good" option and make others look bad
- Hide significant drawbacks
- Use vague pros/cons ("might be better", "could work")
- Forget to give a recommendation
- Give recommendation without explaining why
- Rush to implementation without presenting options

✅ **Do:**
- Present all options fairly
- Be specific about trade-offs
- Recommend based on user's context
- Acknowledge when multiple options are valid
- Explain your reasoning clearly
- Wait for user direction before implementing

## When NOT to Use

This skill should NOT activate for:

- Simple yes/no questions with obvious answers
- Questions with only ONE technically viable option (genuinely no alternatives)
- User explicitly stated their choice already AND the choice is reasonable
- Trivial decisions (naming a variable, formatting choices)
- Continuing an already-approved approach

**Skip the analysis if:**
- User says "just do X" AND you've already discussed alternatives
- Only one approach is technically feasible (rare - think harder first!)
- The decision is trivial (naming, minor formatting)
- You're executing a previously-approved plan

**Don't skip just because:**
- ❌ "It seems obvious" - might not be obvious to user
- ❌ "I think this is best" - user deserves to see alternatives
- ❌ "The other way is worse" - let user decide based on trade-offs

## Benefits

1. **Better decisions** - User sees all options before committing
2. **Avoids regret** - User won't wonder "what if we did it differently"
3. **Builds trust** - Shows you're thinking through alternatives
4. **Saves time** - Prevents wrong direction that needs rework later
5. **Informed choices** - User understands trade-offs upfront

## Customization

User can customize analysis format by:
- Requesting specific comparison criteria
- Asking for quantitative vs qualitative analysis
- Specifying decision factors that matter most

**Examples:**
- "Pro/con me, focusing on performance"
- "What are the trade-offs in terms of maintainability?"
- "Compare these approaches for team collaboration"

## Why This Matters

This skill enforces Constitutional Law #2 from the global CLAUDE.md configuration. The law exists because:

1. User deserves to see alternatives before implementation
2. Multiple valid approaches usually exist - don't assume
3. User might have constraints you don't know about
4. Presenting options shows respect for user's decision-making

**Remember: Present options BEFORE implementing. User gets to choose the approach.**
