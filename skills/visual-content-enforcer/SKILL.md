---
name: visual-content-enforcer
description: ENFORCES correct workflow for visual content requests. AUTO-TRIGGERS when user asks for infographics, diagrams, slides, visuals, or presentations. BLOCKS execution until AI clarifies format and follows Fabric → Art skill workflow. USE WHEN user says "infographic", "visual", "diagram", "slides", "presentation", "show [person]", "create graphics".
---

# Visual Content Enforcer

**CRITICAL: This skill AUTO-TRIGGERS to prevent AI from creating wrong format.**

## Trigger Detection

**Activate when user request contains:**
- "infographic"
- "visual" + (explanation/content/guide)
- "diagram" (except when explicitly "mermaid code")
- "slides"
- "presentation"
- "graphics"
- "create [visual thing] for [person]"
- "show [person]"
- "image" + (explanation/comparison/overview)

## Enforcement Protocol

### Step 1: BLOCK and Ask Format Clarification (MANDATORY)

**AI MUST use AskUserQuestion tool immediately:**

```
Question: "What format do you want for this visual content?"
Header: "Format"
Options:
  1. "Image files (PNG/JPG) - I can share these"
     Description: "Actual visual graphics generated with Nano Banana Pro"
  2. "Markdown docs with diagrams - For reading/reference"
     Description: "Text documentation with Mermaid code blocks"
  3. "Both - Images AND markdown documentation"
     Description: "Visual assets plus detailed written explanation"
```

**DO NOT PROCEED without user answer.**

---

### Step 2: Route Based on Answer

#### If User Chooses: "Image files (PNG/JPG)"

**REQUIRED WORKFLOW:**

```
1. Research & Extract
   ├─ Gather information about topic
   ├─ Create outline of key points
   └─ Run Fabric pattern to condense:
       cat outline.md | fabric --pattern extract_key_points > key_points.md

2. Structure for Visual
   ├─ Determine visualization type (comparison, workflow, overview, etc.)
   ├─ Use Fabric for structure:
       fabric --pattern create_mermaid_visualization  (for structure ideas)
       fabric --pattern summarize  (to condense complex content)
   └─ Identify 3-5 key elements to visualize

3. Invoke Art Skill (MANDATORY)
   ├─ Read Art skill's workflows:
       - workflows/visualize.md (for infographics/complex visuals)
       - workflows/technical-diagrams.md (for system diagrams)
       - workflows/comparisons.md (for X vs Y visuals)
       - workflows/frameworks.md (for 2x2 matrices, models)
   ├─ Follow chosen workflow EXACTLY
   └─ Generate with Nano Banana Pro

4. Output Actual Image Files
   ├─ Save to ~/Desktop/forHarrison/ (or appropriate location)
   ├─ PNG or JPG format
   └─ Tell user where files are saved
```

**FORBIDDEN ACTIONS:**
- ❌ Creating Mermaid code blocks and calling them "infographics"
- ❌ Writing markdown text instead of generating images
- ❌ Skipping Fabric patterns (they help structure content)
- ❌ Skipping Art skill workflows (they ensure quality)

---

#### If User Chooses: "Markdown docs with diagrams"

**ALLOWED WORKFLOW:**

```
1. Use Fabric to Structure
   ├─ fabric --pattern summarize (condense complex topics)
   ├─ fabric --pattern create_mermaid_visualization (diagram ideas)
   └─ fabric --pattern extract_key_points (bullet lists)

2. Create Markdown Documentation
   ├─ Keep concise (avoid 3000+ line docs)
   ├─ Mermaid diagrams are acceptable
   ├─ Use tables and structured formatting
   └─ Include ASCII art for simple visuals

3. Validation
   ├─ Is it readable/scannable?
   ├─ Is it under 1000 lines? (if not, split into multiple files)
   └─ Did you use Fabric to help structure?
```

---

#### If User Chooses: "Both"

**REQUIRED WORKFLOW:**

```
1. Generate Images FIRST (follow Image workflow above)
2. Create Markdown Documentation (follow Markdown workflow above)
3. Cross-reference in markdown:
   "See visual diagram: path/to/image.png"
```

---

## Ambiguity Handling

**IF REQUEST IS AMBIGUOUS (common cases):**

### "Create infographic about X"
**AMBIGUOUS** → Could mean image OR structured markdown
**ACTION**: Ask format clarification (use Step 1)

### "Explain X to Harrison" / "Show Harrison how Y works"
**AMBIGUOUS** → "Show" implies visual, but format unclear
**ACTION**: Ask format clarification (use Step 1)

### "Make slides about X"
**CLEAR** → Slides = images
**ACTION**: Use Image workflow (no clarification needed)

### "Diagram the architecture"
**AMBIGUOUS** → Could mean Mermaid code OR image
**ACTION**: Ask format clarification (use Step 1)

### "Visual guide to X"
**AMBIGUOUS** → Visual could mean formatted markdown OR images
**ACTION**: Ask format clarification (use Step 1)

**PRINCIPLE: When in doubt, ask. Questions are fast, redoing work sucks.**

---

## Validation Checklist

Before declaring task complete:

### If User Wanted Images:
- [ ] Did I use Fabric patterns to extract/structure content?
- [ ] Did I invoke the Art skill?
- [ ] Did I follow a specific Art workflow (visualize, technical-diagrams, etc.)?
- [ ] Did I generate actual PNG/JPG files?
- [ ] Can user immediately share these files?
- [ ] Are files saved to accessible location?

### If User Wanted Markdown:
- [ ] Did I use Fabric to help structure?
- [ ] Is document concise (< 1000 lines per file)?
- [ ] Are Mermaid diagrams properly formatted?
- [ ] Is content scannable/readable?

### Common Failure Modes to Check:
- [ ] Did I create Mermaid code and claim it's an infographic? ❌
- [ ] Did I write 3000+ lines of text instead of visuals? ❌
- [ ] Did I skip asking for clarification on ambiguous request? ❌
- [ ] Did I skip using Fabric entirely? ❌
- [ ] Did I skip the Art skill for image requests? ❌

---

## Integration with Hooks

This skill works with:
- `~/.claude/hooks/pre-visual-content.sh` - Blocks execution until clarification

When hook triggers, invoke this skill to handle the workflow.

---

## Examples

### Example 1: Correct Flow - Image Request

```
User: "Create infographic explaining PAI system"

AI: [Invokes visual-content-enforcer skill]
AI: [Uses AskUserQuestion for format clarification]

User: "Image files"

AI: [Follows Image workflow]
    1. Researches PAI architecture
    2. Creates outline
    3. Runs: cat outline.md | fabric --pattern extract_key_points
    4. Invokes Art skill → workflows/visualize.md
    5. Generates PNG with Nano Banana Pro
    6. Saves to ~/Desktop/forHarrison/pai-system-infographic.png

AI: "Created infographic: ~/Desktop/forHarrison/pai-system-infographic.png"
```

### Example 2: Correct Flow - Ambiguous Request

```
User: "Explain PAI to Harrison"

AI: [Invokes visual-content-enforcer skill]
AI: [Detects ambiguity - "explain" + "to [person]" could mean visual OR text]
AI: [Uses AskUserQuestion for format clarification]

User: "Markdown docs, he'll read them"

AI: [Follows Markdown workflow]
    1. Uses fabric --pattern summarize for sections
    2. Creates concise markdown (< 1000 lines)
    3. Includes Mermaid diagrams

AI: "Created documentation: ~/Desktop/forHarrison/PAI-Overview.md"
```

### Example 3: Failure Mode - What NOT to Do

```
User: "Create infographic for Harrison"

❌ WRONG AI RESPONSE:
AI: [Immediately creates 3000 lines of markdown with Mermaid code]
AI: "Here's your infographic!" [Shows markdown file]

✅ CORRECT AI RESPONSE:
AI: [Invokes visual-content-enforcer skill]
AI: [Uses AskUserQuestion]
AI: "For this infographic, do you want actual image files (PNG) or markdown documentation?"
```

---

## Why This Exists

**Problem**: AI defaults to text/markdown for everything, even when user wants actual visual images.

**Root causes**:
1. Text generation is AI's comfort zone
2. Misunderstanding "infographic" as "structured information" not "graphic image"
3. Skipping available tools (Fabric, Art skill)
4. Assuming format instead of asking

**Solution**: This skill enforces:
1. Always clarify ambiguous requests
2. Use correct tools for format (Fabric → Art skill for images)
3. Validate output matches user intent

---

## Skill Invocation

This skill is AUTO-INVOKED when trigger words detected.

Manual invocation:
```
/skill visual-content-enforcer
```

Or natural language:
```
"Enforce visual content workflow"
"Check if I should use Art skill"
```

---

**Last Updated**: 2026-01-02
**Purpose**: Prevent AI from creating wrong format for visual content requests
**Enforcement**: Pre-hook + Skill + Validation checklist
