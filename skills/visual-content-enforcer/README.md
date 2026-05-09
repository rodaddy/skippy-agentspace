# Visual Content Enforcer Skill

**Purpose**: Prevent AI from creating wrong output format when user requests visual content.

## What This Fixes

**Problem**: User asks for "infographic" → AI creates 3000 lines of markdown text with Mermaid code blocks

**Solution**: Force AI to:
1. Ask user to clarify format (images vs markdown)
2. Use correct tools (Fabric + Art skill for images)
3. Output actual files in requested format

## How It Works

### Trigger Words
Skill auto-activates when user says:
- "infographic"
- "visual"
- "diagram"
- "slides"
- "presentation"
- "show [person]"
- "create graphics"

### Enforcement Mechanism

1. **Hook**: `~/.claude/hooks/pre-visual-content.sh`
   - Blocks execution
   - Reminds AI to ask clarification

2. **Skill**: Forces workflow:
   ```
   Ambiguous request detected
   → Use AskUserQuestion to clarify format
   → Route to correct workflow (Image vs Markdown)
   → Validate output matches request
   ```

3. **Workflows**:
   - **Image workflow**: Fabric → Art skill → Nano Banana Pro → PNG/JPG
   - **Markdown workflow**: Fabric patterns → Structured docs → Mermaid OK

## Usage

### Auto-Invoked
Skill triggers automatically on visual content requests.

### Manual Invocation
```bash
/skill visual-content-enforcer
```

## Example Flow

```
User: "Create infographic about X"

AI: [Skill triggers]
AI: [Uses AskUserQuestion]
    "What format do you want?
     A) Image files (PNG/JPG)
     B) Markdown documentation
     C) Both"

User: "Image files"

AI: [Follows Image workflow]
    1. Extract key points with Fabric
    2. Invoke Art skill (visualize.md)
    3. Generate PNG with Nano Banana Pro
    4. Save to ~/Desktop/forX/

AI: "Created infographic.png at [path]"
```

## Files

```
visual-content-enforcer/
├── SKILL.md              # Main skill definition
├── README.md             # This file
└── (future: tools/)      # Helper scripts if needed
```

## Integration

Works with:
- `~/.claude/hooks/pre-visual-content.sh` - Pre-execution blocker
- Art skill workflows - Actual image generation
- Fabric patterns - Content structuring

## Validation Checklist

Before completing visual content task:

**If user wanted images:**
- [ ] Used Fabric patterns?
- [ ] Invoked Art skill?
- [ ] Generated actual PNG/JPG?
- [ ] Files saved to accessible location?

**If user wanted markdown:**
- [ ] Used Fabric to structure?
- [ ] Kept concise (< 1000 lines/file)?
- [ ] Mermaid diagrams properly formatted?

## Why This Matters

**Core Principle**: Questions are quick, redoing work is a pain in the ass.

Always clarify ambiguous requests before proceeding.

---

**Created**: 2026-01-02
**Lesson**: Don't assume format - ask user first
