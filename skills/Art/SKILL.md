---
name: art
description: Complete visual content system. FOURTEEN workflows - (1) VISUALIZE (adaptive multi-modal orchestrator), (2) MERMAID (Excalidraw-style technical diagrams), (3) Editorial illustrations, (4) Technical diagrams, (5) Visual taxonomies, (6) Timelines, (7) Frameworks, (8) Comparisons, (9) Annotated screenshots, (10) Recipe cards, (11) Aphorisms, (12) Conceptual maps, (13) Stats, (14) Comics. USE WHEN user requests any visual content: 'visualize', 'mermaid', 'flowchart', 'sequence diagram', 'state diagram', 'infographic', 'art', 'illustration', 'diagram', 'taxonomy', 'timeline', 'framework', 'comparison', 'screenshot', 'recipe', 'aphorism', 'quote card', 'map', 'stat card', 'comic'. Note: Blogging skill auto-routes header images here.
---

# Art - Complete Visual Content System

Creates editorial-quality visuals for ALL content types using the brand color scheme.

**Fourteen Workflows:**
1. **Visualize** — Adaptive orchestrator combining optimal approaches
2. **Mermaid** — Excalidraw-style technical diagrams (flowcharts, sequences, states) (NEW)
3. **Editorial Illustrations** — Abstract metaphors for blog posts
4. **Technical Diagrams** — Hand-drawn architecture/system diagrams
5. **Visual Taxonomies** — Classification grids and periodic tables
6. **Timelines** — Illustrated chronological progressions
7. **Frameworks** — Mental models and 2x2 matrices
8. **Comparisons** — Side-by-side X vs Y illustrations
9. **Annotated Screenshots** — Real images with editorial overlays
10. **Recipe Cards** — Step-by-step process visuals
11. **Aphorisms** — Typography-dominant quote cards
12. **Conceptual Maps** — Idea territory landscapes
13. **Stats** — Illustrated data point cards
14. **Comics** — Sequential panel narratives

---

## 🎨 STYLE PREFERENCE LEARNING SYSTEM

**CRITICAL: Before generating ANY image, follow this workflow:**

### Step 1: Check User's Style Preferences

Run this command to get ranked styles:
```bash
bun ~/.config/pai/Skills/Art/tools/select-style.ts --json
```

This returns styles ranked by user's ratings (highest first).

### Step 2: Present Style Options Using AskUserQuestion

Use the `AskUserQuestion` tool to present ranked options:

**Example:**
```
User: "Create an infographic about hybrid RAG"

You: [Run select-style.ts to get rankings]

You: [Use AskUserQuestion]
```

**Present top 3-4 styles** with star ratings:
- Option 1: "isometric-3d (★★★★★ 5.0/5) - Recommended" ← Make this option 1 if rating >= 4.0
- Option 2: "glassmorphism (★★★★☆ 4.0/5)"
- Option 3: "blueprint (★★★☆☆ 3.0/5)"
- Option 4: "Try something new..."

**Set multiSelect: false** - User picks ONE style

### Step 3: Handle User's Choice

**If user says "go" or picks option 1:** Use the top-rated style (recommended)

**If user picks specific style:** Use that style

**If user picks "Try something new":** Present unrated styles or ask which they want to try

### Step 4: Generate Image with Selected Style

**Map style to prompt modifications:**

```typescript
const STYLE_PROMPTS = {
  'isometric-3d': 'Isometric 3D illustration, depth and perspective, professional corporate aesthetic like Slack or Notion, clean modern design',
  'glassmorphism': 'Glassmorphism design, frosted glass panels, soft blur effects, vibrant gradient backgrounds, translucent layers, premium iOS-style',
  'blueprint': 'Blueprint technical drawing style, white/cyan lines on deep blue background, engineering schematic, architectural drawing aesthetic, grid paper background',
  'minimalist-flat': 'Minimalist flat design, clean geometric shapes, solid colors, limited color palette, Dribbble-style illustration, sharp professional',
  'dark-tech-original': 'Dark background with electric blue/purple accents, high-tech futuristic aesthetic, modern tech editorial style',
  'cyberpunk': 'Cyberpunk style, neon colors, dark background, Blade Runner aesthetic, futuristic tech, high contrast',
  'retro-synthwave': 'Retro synthwave style, 80s gradients, grid patterns, vaporwave aesthetic, nostalgic tech vibes',
  'hand-drawn': 'Hand-drawn whiteboard marker style, sketch aesthetic, informal and approachable, casual illustration',
  'neumorphism': 'Neumorphism design, soft shadows, embossed look, subtle depth, minimalist modern aesthetic'
};
```

**Prepend the style prompt** to the user's content prompt:

**⚠️ ASPECT RATIO:** Editorial illustrations MUST use `1:1` (square). Other workflows may vary. See Core Visual Rules.

```bash
bun ~/.config/pai/Skills/Art/tools/generate-ulart-image.ts \
  --model nano-banana-pro \
  --prompt "STYLE: ${STYLE_PROMPTS[selectedStyle]}. CONTENT: ${userContentPrompt}" \
  --size 2K \
  --aspect-ratio 1:1 \
  --output ~/Downloads/pai-generated-${timestamp}.png
```

### Step 5: After Generation - Ask for Rating

**Immediately after showing the image**, use `AskUserQuestion` again:

**Ask:** "Rate this [style-name] style?"

**Options:**
- "Love it! (5/5)" → rating: 5
- "Like it (4/5)" → rating: 4
- "It's okay (3/5)" → rating: 3
- "Not great (2/5)" → rating: 2
- "Dislike (1/5)" → rating: 1

**Set multiSelect: false**

### Step 6: Save Rating

When user provides rating, update preferences:

```bash
# This happens automatically via gallery server
# OR you can update JSON directly if needed
```

The gallery server at `http://localhost:9001` provides UI for rating images by clicking emoji buttons. Ratings save automatically to `~/.config/pai/preferences/image-styles.json`.

---

## 🔀 ROUTING: Which Workflow to Use?

### **🎯 Visualize (ADAPTIVE ORCHESTRATOR)** → `workflows/visualize.md`
**When to use:**
- User says 'visualize this', 'create visualization', 'what's the best way to show this'
- Content has multiple dimensions (data + narrative + concepts)
- User says 'infographic', 'dashboard', 'data viz', 'mixed media'
- You're not sure which single workflow fits (let Visualize analyze and choose)
- Need to combine approaches (data + metaphor, charts + illustrations)
- Want optimal visualization strategy, not predetermined format

**Key:** Intelligent analysis → strategic combination → professional infographics/dashboards

**🚨 CRITICAL: Visualize is the META-WORKFLOW. It analyzes content and orchestrates the optimal combination of the 13 specialized workflows below. Use when content doesn't fit neatly into one category or needs sophisticated multi-modal visualization.**

---

### **Mermaid Diagrams** → `workflows/mermaid.md`
**When to use:**
- User says 'mermaid', 'flowchart', 'sequence diagram', 'state diagram'
- User says 'draw a flowchart', 'show the sequence', 'state machine'
- Content describes process flows, decision logic, state transitions
- Need structured diagram types (not freeform architecture)
- Want Excalidraw whiteboard sketch aesthetic
- Deriving diagram structure from content via /cse

**Key:** Mermaid structure (flowchart/sequence/state/class/ER) + Excalidraw sketchy hand-drawn aesthetic + brand colors

**Diagram types supported:** Flowcharts, Sequence diagrams, State diagrams, Class diagrams, ER diagrams, Gantt charts, Git graphs

---

### **Editorial Illustrations** → `workflows/workflow.md`
**When to use:**
- Blog header images (auto-routed from blogging skill)
- User says 'art', 'illustration', 'editorial image', 'blog header'
- Need abstract visual metaphor for narrative content
- Physical objects representing concepts (scissors, hands, mountains)

**Key:** Abstract metaphor, NO text labels, full illustration

---

### **Technical Diagrams** → `workflows/technical-diagrams.md`
**When to use:**
- User says 'technical diagram', 'architecture diagram', 'system diagram'
- User says 'draw diagram', 'process flow', 'show the architecture'
- Explaining systems, components, relationships with labels
- Need boxes, arrows, text labels showing structure

**Key:** Shows actual structure with text labels and connections

---

### **Visual Taxonomies** → `workflows/taxonomies.md`
**When to use:**
- User says 'taxonomy', 'classification', 'periodic table', 'categorize'
- User says 'organize into categories', 'framework grid', 'capability matrix'
- Need organized classification system with categories
- "The Periodic Table of X" style visuals

**Key:** Grid structure organizing concepts into categories

---

### **Timelines** → `workflows/timelines.md`
**When to use:**
- User says 'timeline', 'evolution', 'history', 'progression over time'
- User says 'show how X changed', 'before and after', 'trend analysis'
- Need chronological progression with milestones
- "The Evolution of X" style visuals

**Key:** Temporal flow with illustrated milestones

---

### **Frameworks** → `workflows/frameworks.md`
**When to use:**
- User says 'framework', '2x2 matrix', 'mental model', 'Venn diagram'
- User says 'quadrant model', 'conceptual model', 'thinking framework'
- Need structured mental model or decision framework
- "The Daniel Miessler Framework for X" style visuals

**Key:** Structured conceptual diagrams (matrices, Venns, pyramids)

---

### **Comparisons** → `workflows/comparisons.md`
**When to use:**
- User says 'X vs Y', 'compare', 'before vs after', 'this vs that'
- User says 'side by side', 'contrast', 'difference between'
- Need split composition showing two contrasting concepts
- "Junior vs Senior" or "Old Way vs New Way" visuals

**Key:** Split screen showing contrasts

---

### **Annotated Screenshots** → `workflows/annotated-screenshots.md`
**When to use:**
- User says 'annotate screenshot', 'mark up this image', 'add notes to screenshot'
- User says 'point out', 'highlight this', 'show the problem in UI'
- Need real screenshot/code with editorial commentary overlay
- Product reviews, tutorials, UX critiques

**Key:** Real image + hand-drawn annotations

---

### **Recipe Cards** → `workflows/recipe-cards.md`
**When to use:**
- User says 'recipe', 'step-by-step', 'process card', 'how-to guide'
- User says 'methodology', 'playbook', '5-step X', 'workflow'
- Need numbered steps with icons for each action
- Consulting deliverables, process documentation

**Key:** Numbered steps with simple illustrated icons

---

### **Aphorisms** → `workflows/aphorisms.md`
**When to use:**
- User says 'aphorism', 'quote card', 'visual quote', 'make this a card'
- User says 'social media quote', 'typography card', 'statement'
- Need Daniel's quote as shareable visual
- Newsletter pull quotes, social media content

**Key:** Massive typography with minimal accent illustration

---

### **Conceptual Maps** → `workflows/maps.md`
**When to use:**
- User says 'map', 'landscape', 'territory', 'domain map', 'field overview'
- User says 'map of X', 'landscape of Y', 'conceptual geography'
- Need illustrated map showing idea territories and relationships
- "The Landscape of AI Safety" style visuals

**Key:** Cartographic metaphor for conceptual domains

---

### **Stats** → `workflows/stats.md`
**When to use:**
- User says 'stat card', 'number', 'statistic', 'by the numbers', 'data point'
- User says 'illustrate this stat', '78% of', 'visualize this number'
- Need single striking statistic as visual
- Newsletter data sections, social media facts

**Key:** Dominant number with tiny illustration

---

### **Comics** → `workflows/comics.md`
**When to use:**
- User says 'comic', 'comic strip', 'panels', 'sequential', 'storyboard'
- User says 'illustrate this scenario', 'show this story', '3-panel', '4-panel'
- Need sequential panels telling a story or explaining concept
- Narrative explanations, thought experiments

**Key:** 3-4 panels with editorial sophistication (NOT cartoonish)

---

## Quick Decision Tree

```
What does user need?

├─ Unsure which approach? Complex multi-dimensional content? → VISUALIZE (analyzes & orchestrates)
├─ Infographic/dashboard/data viz with multiple elements? → VISUALIZE
├─ Flowchart/sequence/state diagram with Excalidraw sketchy feel? → MERMAID
├─ Abstract metaphor for article? → Editorial Illustration
├─ System/architecture with labels? → Technical Diagram
├─ Categories organized in grid? → Taxonomy
├─ Change over time? → Timeline
├─ 2x2 matrix or mental model? → Framework
├─ Side-by-side contrast? → Comparison
├─ Markup existing screenshot? → Annotated Screenshot
├─ Step-by-step process? → Recipe Card
├─ Quote as social visual? → Aphorism
├─ Idea territories as map? → Conceptual Map
├─ Single striking number? → Stat Card
└─ Multi-panel story? → Comic

NOTE: Visualize is the ORCHESTRATOR - it can choose and combine any of the 13 specialized workflows
NOTE: Mermaid = structured diagram types (flowchart, sequence, state, etc.) + Excalidraw whiteboard aesthetic
```

---

## 🚨 MANDATORY WORKFLOW — EDITORIAL ILLUSTRATIONS

**This section describes the EDITORIAL ILLUSTRATION workflow. For TECHNICAL DIAGRAMS, see `workflows/technical-diagrams.md`**

**CRITICAL: These steps are MANDATORY and must be executed IN ORDER. Do NOT skip steps. Do NOT make up your own process.**

### Step 0: Read Required Files (MANDATORY)
1. **Read workflow:** `workflows/workflow.md` (editorial) OR `workflows/technical-diagrams.md` (technical)
2. **Read aesthetic:** `~/.claude/skills/CORE/aesthetic.md`

### Step 1: Run 24-Item Story Explanation on Content (MANDATORY)
**You MUST use the story-explanation skill with 24-item length. Do NOT skip this step. Do NOT derive concepts yourself without the 24-item story explanation.**

```
Use story-explanation skill with 24-item length for [content or URL]
```

The 24-item output gives you the FULL narrative arc: setup, tension, transformation, resolution.

### Step 2: Derive Visual Metaphor from FULL NARRATIVE ARC (MANDATORY)
Only AFTER running 24-item story explanation, derive ONE visual metaphor that captures the JOURNEY/TRANSFORMATION/PROCESS using ALL 24 items (not just the final item).

### Step 3-6: Continue with workflow.md
Follow the remaining steps in `workflows/workflow.md` exactly.

---

### Aesthetic Source (REQUIRED READING)

**Always read first:** `~/.claude/skills/CORE/aesthetic.md`

This defines the Anthropic editorial style:
- Flat solid colors (NO gradients)
- Hand-drawn black linework (imperfect, gestural)
- Muted earth-tone backgrounds (cream, terracotta, sage, peach)
- Abstract conceptual metaphors
- 30-40% negative space

---

## Color System

### Background
- **WHITE #FFFFFF** for generation → **remove.bg** creates TRANSPARENCY
- Final images have transparent background (blog CSS applies sepia)

### Primary: Black Linework
- **Pure Black #000000** — DOMINANT, carries the entire composition

### Accent Colors (MUST BE VISIBLE - not primary fills)
| Color | Hex | Usage |
|-------|-----|-------|
| Deep Purple | #4A148C | Brand accent - REQUIRED and MUST BE NOTICEABLE |
| Deep Teal | #00796B | Secondary accent option |
| Charcoal | #2D2D2D | Kai signature, subtle details |

**CRITICAL COLOR REQUIREMENT:**
- Purple (#4A148C) MUST be visible and noticeable in every image
- "Accent" means visible color, NOT microscopic hints
- Color should be immediately apparent when viewing the image
- If you can't see the purple/teal without zooming in, it's TOO SUBTLE
- Balance: Not dominant, but definitely present and visible

### Color Hierarchy
1. **BLACK LINEWORK is PRIMARY** — dominates composition
2. **Purple as ACCENT** — hints/details, NOT solid fills, but MUST BE VISIBLE
3. **Secondary accent** — sparingly, but noticeable
4. **No gradients, no shadows**
5. **COLOR VALIDATION** — Must pass visual inspection for color presence

---

## Core Visual Rules

1. **Background:** Single flat muted earth tone
2. **Style:** Hand-drawn, gestural black linework — NOT smooth vectors
3. **Composition:** Full-bleed edge-to-edge, elements fill 100% of frame (NO whitespace or margins)
4. **Aspect Ratio:** Square 1:1 format (NOT 16:9 rectangle)
5. **Elements:** 2-3 abstract elements maximum
6. **Lines:** Variable weight, imperfect, wobbly, brush-like texture
7. **NO TEXT** (except Kai signature)
8. **KAI SIGNATURE:** Small subtle "Kai" in charcoal (#2D2D2D) bottom right
9. **COLOR PRESENCE:** Purple (#4A148C) and/or Teal (#00796B) MUST be visible and noticeable as accents

---

## Style Direction

### Think
- Saul Steinberg (New Yorker)
- Matisse cutouts
- Christoph Niemann (Abstract Sunday)
- Risograph editorial aesthetic

### AVOID
- Gradients or shading
- Glossy/shiny surfaces
- 3D rendering
- Photorealistic elements
- Smooth perfect vector lines
- "AI slop" (too perfect, too shiny)
- Cartoonish or clip-art

---

## Environment Setup

The CLI automatically loads API keys from `~/.claude/.env`. Required keys:
- `REPLICATE_API_TOKEN` - For Flux and Nano Banana models
- `OPENAI_API_KEY` - For GPT-image-1 model
- `GOOGLE_API_KEY` - For Nano Banana Pro (Gemini 3 Pro)
- `REMOVEBG_API_KEY` - For background removal

---

## Default Model

**nano-banana-pro** (Gemini 3 Pro)

```bash
bun run ~/.claude/skills/art/tools/generate-ulart-image.ts \
  --model nano-banana-pro \
  --prompt "[PROMPT]" \
  --size 2K \
  --aspect-ratio 1:1 \
  --output /path/to/output.png
```

### Alternative Models

| Model | When to Use | Command |
|-------|-------------|---------|
| **flux** | Maximum quality | `--model flux --size 1:1` |
| **gpt-image-1** | Different interpretation | `--model gpt-image-1 --size 1536x1024` |

---

## File Structure

```
art/
├── SKILL.md                         # This file (routing + overview)
├── workflows/
│   ├── visualize.md                 # ADAPTIVE orchestrator
│   ├── mermaid.md                   # Mermaid + Excalidraw diagrams (NEW)
│   ├── workflow.md                  # Editorial illustration workflow
│   ├── technical-diagrams.md        # Technical diagram workflow
│   ├── taxonomies.md                # Visual taxonomies workflow
│   ├── timelines.md                 # Timeline workflow
│   ├── frameworks.md                # Mental models workflow
│   ├── comparisons.md               # Side-by-side comparisons workflow
│   ├── annotated-screenshots.md     # Screenshot annotation workflow
│   ├── recipe-cards.md              # Process recipe workflow
│   ├── aphorisms.md                 # Quote cards workflow
│   ├── maps.md                      # Conceptual maps workflow
│   ├── stats.md                     # Illustrated statistics workflow
│   └── comics.md                    # Sequential panels workflow
└── tools/
    └── generate-ulart-image.ts      # CLI tool for generation
```

---

## The Concept Generation Process

**24-ITEM STORY → NARRATIVE ARC → VISUAL JOURNEY → FLAT EDITORIAL PROMPT → GENERATE**

### The 6-Step Workflow

1. **Run 24-item story explanation** on the content to extract FULL narrative arc
2. **Derive visual metaphor** from ALL 24 items — ONE abstract concept showing TRANSFORMATION/JOURNEY, 2-3 elements
3. **Apply aesthetic** — Flat colors, black linework, white background for transparency
4. **Construct prompt** — Specify hand-drawn, gestural, no gradients, Saul Steinberg style, process/movement
5. **Execute generation** via CLI with --remove-bg flag
6. **Validate** — Flat? Hand-drawn quality? No gradients? Shows journey/process?

**For complete workflow instructions, read:** `workflows/workflow.md`

---

## Prompt Template

```
Editorial conceptual illustration in Saul Steinberg / New Yorker style.

BACKGROUND: Solid flat [CREAM #F5E6D3 | TERRACOTTA #C17A5B | SAGE #A8A89A | PEACH #E8C4A8] — NO gradients.

STYLE: Hand-drawn black ink linework. Variable stroke weight. Imperfect wobbly lines.
Gestural brush quality. NOT smooth vectors. NOT photorealistic. Risograph aesthetic.

COMPOSITION (2-3 elements):
[Describe abstract metaphor with 2-3 simple elements]

NEGATIVE SPACE: 30-40% of image is empty background.
Objects occupy 40-60% of frame.

CRITICAL:
- NO gradients anywhere
- NO shadows
- NO 3D effects
- NO glossy/shiny surfaces
- Lines should be imperfect, hand-drawn quality

Sign "Kai" small in charcoal (#2D2D2D) bottom right corner.
NO other text.
```

---

## CONCEPT EXAMPLES

These demonstrate the conceptual translation pattern:

### Example: "Leave the Em Dash Alone"
**Narrative Arc (from 24 items):** AI copies human creativity → people react by abandoning what they love → Daniel refuses to be evicted from his own preferences → standing ground on authentic choices
**Visual Concept:** Robot hand and human hand pulling opposite ends of an em dash (tug-of-war) — shows CONFLICT IN PROGRESS
**Why:** Captures the ongoing struggle/ownership battle, not just endpoint

### Example: "Humans Need Entropy"
**Narrative Arc (from 24 items):** Childhood wonder → adult collapse into repetition → discovery that entropy prevents stagnation → actively seeking novelty → renewal cycle
**Visual Concept:** Human head split vertically — left half: dense packed identical circles (collapse); right half: circles scattering outward (entropy dispersing) — shows STATE TRANSFORMATION
**Why:** Captures the before→after transformation journey, duality of states

### Pattern
| Article Theme | Visual Strategy |
|---------------|-----------------|
| Conflict/Ownership | Two forces pulling one object |
| Loss/Absence | Empty spaces that should be full |
| Duality/States | Split composition showing both |
| Collaboration | Hands working together |

---

**The best concepts are immediately readable without explanation, yet reward deeper looking.**
