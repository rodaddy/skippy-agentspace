# Art Skill - Image Generation with Style Learning

Generate images using various AI models with **style preference learning**.

## Quick Start

**Just ask naturally:**
- "Create a diagram showing..."
- "Generate an illustration of..."
- "Make an infographic about..."

The skill will:
1. ✅ Check your style preferences
2. ✅ Suggest your favorite style (or let you pick)
3. ✅ Generate the image
4. ✅ Ask you to rate it (learning for next time)

## How Style Learning Works

### First Time Using a Style
**You:** "Create an infographic about hybrid RAG"

**PAI responds:**
```
📊 Which style for this infographic?

[isometric-3d] ★★★★★ (5.0/5) - You LOVE this (Recommended)
[glassmorphism] ★★★★☆ (4.0/5) - You like it
[dark-tech-original] ★★★☆☆ (3.3/5) - It's okay
[blueprint] ★★★☆☆ (3.0/5) - Meh
[minimalist-flat] ★★★☆☆ (2.5/5) - Not your favorite

Say "go" for recommended, or pick a style:
```

**You:** "go" (or "isometric-3d" or pick any other)

**PAI generates the image, then asks:**
```
Rate this isometric-3d style?
❤️ Love it (5) | 👍 Like it (4) | 😐 Okay (3) | 👎 Dislike (2) | 🗑️ Hate it (1)
```

### After You've Rated Styles
**You:** "Create an infographic about..."

**PAI:** Automatically uses **isometric-3d** (your 5-star favorite) unless you specify otherwise.

---

## Models Available

- **nano-banana-pro** (Default) - Gemini 3 Pro, high quality, fast
- **flux** - Flux 1.1 Pro via Replicate
- **nano-banana** - Gemini 2 Flash
- **gpt-image-1** - OpenAI DALL-E

## Available Styles

### Rated Styles (Your Preferences)
1. **isometric-3d** - ★★★★★ - Depth, perspective, Slack/Notion aesthetic
2. **glassmorphism** - ★★★★☆ - Frosted glass, iOS-style premium
3. **dark-tech-original** - ★★★☆☆ - Dark with blue/purple accents
4. **blueprint** - ★★★☆☆ - Technical engineering schematics
5. **minimalist-flat** - ★★★☆☆ - Clean geometric shapes

### Available But Not Rated Yet
- **cyberpunk** - Neon, Blade Runner aesthetic
- **retro-synthwave** - 80s gradients, vaporwave
- **hand-drawn** - Whiteboard sketch style
- **neumorphism** - Soft shadows, embossed look

## Setup

### API Keys

The tool uses `GEMINI_API_KEY` from your `~/.zshrc` for Nano Banana Pro.

**Already configured:** ✅ `GEMINI_API_KEY` is set in `~/.zshrc`

For other models, add to `~/.claude/.env`:
```bash
REPLICATE_API_KEY=your_key_here  # For Flux models
OPENAI_API_KEY=your_key_here     # For GPT-image-1
```

### Dependencies

Already installed in `~/.config/pai/Skills/Art/tools/`:
```bash
bun add replicate openai @google/genai
```

## Usage

### Natural Language (Preferred)

```
You: "Create an infographic showing the key points of [topic]"

PAI: [Suggests your favorite style: isometric-3d]
     Generate in isometric-3d (your favorite ★★★★★)?

You: "go"

PAI: [Generates image]
     Rate this style? ❤️ 👍 😐 👎 🗑️
```

### Override Default Style

```
You: "Create an infographic in blueprint style"

PAI: [Uses blueprint style explicitly]
     [After generation] Rate this blueprint style?
```

### Rate Existing Images

1. Gallery running at `http://localhost:9001` (when started)
2. Click rating buttons under each image (❤️ 👍 😐 👎 🗑️)
3. Preferences saved to `~/.config/pai/preferences/image-styles.json`

### View Your Style Rankings

```bash
bun ~/.config/pai/Skills/Art/tools/select-style.ts
```

Shows ranked list with star ratings.

## Gallery Server

### Start Gallery
```bash
bun ~/.config/pai/Tools/image-gallery-server.ts --port 9001
```

### Features
- ✅ Manual refresh (no annoying auto-refresh)
- ✅ Rating buttons for each image
- ✅ Automatic style detection from filenames
- ✅ Saves preferences as you rate

### Stop Gallery
```bash
kill $(cat /tmp/pai-gallery-server.pid)
```

## How It Works

### Preference Storage
Location: `~/.config/pai/preferences/image-styles.json`

```json
{
  "styles": {
    "isometric-3d": {
      "rating": 5.0,
      "count": 2,
      "last_used": "2025-12-30T13:57:07.854Z",
      "description": "Depth and perspective...",
      "tags": ["depth", "corporate", "professional"]
    }
  }
}
```

### Weighted Average Ratings
- First rating: Sets initial score
- Additional ratings: Averaged with previous scores
- Example: 5-star + 4-star = 4.5 average

### Style Detection (Gallery)
- `style1-*.png` → minimalist-flat
- `style2-*.png` → isometric-3d
- `style3-*.png` → blueprint
- `style4-*.png` → glassmorphism
- `pai-*.png` → dark-tech-original
- Filename keywords (cyberpunk, neon, sketch, etc.)

## Workflow

```
┌─────────────────────────────────────┐
│ User: "Create infographic..."      │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Load preferences from JSON          │
│ ~/.config/pai/preferences/          │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Present ranked style options        │
│ (Top-rated first)                   │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ User picks or says "go"             │
│ ("go" = use recommended/top-rated)  │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Generate image in selected style    │
│ (Nano Banana Pro default)           │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Show image + ask for rating         │
│ ❤️ 👍 😐 👎 🗑️                        │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Save rating → Update preferences    │
│ (Weighted average)                  │
└─────────────────────────────────────┘
```

## Examples

### Example 1: First Image
```
You: "Create a technical diagram of a RAG pipeline"

PAI: 📊 Which style for this diagram?

     [isometric-3d] ★★★★★ (5.0/5) - You LOVE this (Recommended)
     [glassmorphism] ★★★★☆ (4.0/5)
     [blueprint] ★★★☆☆ (3.0/5)
     [Try something new...]

You: "go"

PAI: [Generates in isometric-3d style]
     🎨 Generated: ~/Downloads/pai-generated-rag-pipeline.png

     Rate this isometric-3d style?
     ❤️ Love it (5) | 👍 Like it (4) | 😐 Okay (3) | 👎 Dislike (2) | 🗑️ Hate it (1)

You: "❤️"

PAI: ✅ Rated isometric-3d: 5/5 ⭐
     Your preferences updated!
```

### Example 2: Override Style
```
You: "Create the same thing but in blueprint style"

PAI: [Generates in blueprint style]
     Rate this blueprint style?

You: "😐"

PAI: ✅ Rated blueprint: 3/5
     (isometric-3d is still your top choice at 5/5)
```

## Troubleshooting

### "Missing environment variable: GOOGLE_API_KEY or GEMINI_API_KEY"

**Fixed:** Tool checks both variables. Your `GEMINI_API_KEY` from `~/.zshrc` is automatically used.

### "Cannot find package 'replicate'"

Run from the tools directory:
```bash
cd ~/.config/pai/Skills/Art/tools
bun add replicate openai @google/genai
```

### Gallery not showing rating buttons

Make sure filename matches detection pattern:
- `pai-*` files → dark-tech-original
- `style1-*` → minimalist-flat
- `style2-*` → isometric-3d
- etc.

Or update `~/.config/pai/Tools/image-gallery-server.ts` detection logic.

### Want to reset preferences

Delete or edit:
```bash
rm ~/.config/pai/preferences/image-styles.json
# Or edit manually to reset specific style ratings
```

## Advanced: Manual Tool Usage

```bash
# Generate with specific style
bun ~/.config/pai/Skills/Art/tools/generate-ulart-image.ts \
  --model nano-banana-pro \
  --prompt "Isometric 3D illustration: RAG pipeline with servers..." \
  --size 2K \
  --aspect-ratio 16:9 \
  --output ~/Downloads/custom-image.png

# View ranked styles
bun ~/.config/pai/Skills/Art/tools/select-style.ts

# Get JSON output (for scripts)
bun ~/.config/pai/Skills/Art/tools/select-style.ts --json
```

## Files

```
~/.config/pai/Skills/Art/
├── SKILL.md                                    # Skill metadata
├── README.md                                   # This file
└── tools/
    ├── generate-ulart-image.ts                 # Core generation tool
    └── select-style.ts                         # Style preference helper

~/.config/pai/preferences/
└── image-styles.json                           # Your learned preferences

~/.config/pai/Tools/
└── image-gallery-server.ts                     # Gallery with rating UI

~/Downloads/
├── pai-generated-*.png                         # Generated images
└── style*.png                                  # Style test variations
```

## What's Next

The system learns your aesthetic preferences over time. As you rate more images:
- Recommendations get smarter
- Your favorite styles bubble to the top
- New images default to what you love
- No more guessing what style you want

This is **personalization that actually works** — PAI learns what you like and just does it.

---

*Last updated: 2025-12-30*
*Style learning system v1.0*
