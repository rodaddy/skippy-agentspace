---
name: nano-banana
description: REQUIRED for all image generation requests. Generate and edit images via LiteLLM proxy (Gemini 3 image model on Vertex AI). Uses JSON-structured prompting for professional-quality output. Handles blog featured images, YouTube thumbnails, icons, diagrams, patterns, illustrations, photos, visual assets, graphics, artwork, pictures, memes. Use this skill whenever the user asks to create, generate, make, draw, design, or edit any image or visual content.
allowed-tools: Bash(generate-image:*),Bash(curl:*),Bash(open:*),Bash(file:*),Bash(ls:*),Bash(mkdir:*)
---

# Nano Banana Image Generation

Generate images via LiteLLM proxy using the `image` model alias (routes to `vertex_ai/gemini-3-pro-image-preview`).

## When to Use This Skill

ALWAYS use this skill when the user:
- Asks for any image, graphic, illustration, or visual
- Wants a thumbnail, featured image, or banner
- Requests icons, diagrams, or patterns
- Asks to edit, modify, or restore a photo
- Wants memes (classic templates or original)
- Uses words like: generate, create, make, draw, design, visualize

Do NOT attempt to generate images through any other method.

## How It Works

Images are generated via LiteLLM proxy -> Vertex AI -> Gemini 3 Pro Image model.

- **LiteLLM proxy:** `http://<LITELLM_IP>:4000`
- **Model alias:** `image` (resolves to `vertex_ai/gemini-3-pro-image-preview`)
- **Auth:** Master key from vaultwarden (`LiteLLM` secret) or `LITELLM_API_KEY` env var
- **Response format:** Images returned in `.choices[0].message.images[0].image_url.url` as `data:image/png;base64,<data>`
- **Output:** Square-ish by default (model decides dimensions). Crop after if needed.

## JSON-Structured Prompting (CRITICAL)

**ALWAYS convert user requests into JSON-structured prompts before sending to the API.** This is not optional. JSON prompts produce dramatically better results than plain text -- better composition, lighting, constraint adherence, and photorealistic quality.

### JSON Prompt Schema

Build a JSON object with these categories. Only `core`, `style`, and `quality_keywords` are required -- everything else is optional enrichment.

```json
{
  "core": {
    "subject": "main subject description (required, min 3 chars)",
    "scene": "environment/setting description",
    "objects": ["object1", "object2"],
    "actions": ["action1", "action2"],
    "constraints": ["no text in image", "no logos", "LinkedIn-appropriate"]
  },
  "style": {
    "primary_style": "photorealistic|cinematic|documentary|studio|editorial|illustrative",
    "render_quality": "hyperrealistic|detailed|high-resolution|professional-quality",
    "lighting": "natural|studio|dramatic|soft-ambient|golden-hour|overcast",
    "color_profile": "neutral|rich|muted|monochrome"
  },
  "technical": {
    "camera": {
      "focal_length_mm": 50,
      "depth_of_field": "shallow|medium|deep",
      "aperture_effects": "optional description"
    }
  },
  "materials": {
    "skin_textures": "pores|natural_imperfections",
    "fabric_details": "thread_patterns|realistic_drape|wear_indicators",
    "surfaces": ["scratches", "patina", "authentic_oxidation", "natural_irregularities"]
  },
  "environment": {
    "atmosphere": ["distance_haze", "weather_effects", "humidity"],
    "time_season": ["golden_hour", "autumn", "night", "summer"],
    "particles": ["dust", "moisture", "mist", "rain"]
  },
  "composition": {
    "perspective": "natural_human_vision|wide|telephoto|low-angle|overhead",
    "framing": "rule_of_thirds|golden_ratio|centered|professional_positioning",
    "subject_placement": "balanced|asymmetric|tight-crop|environmental"
  },
  "quality_keywords": {
    "include": ["photographic quality", "natural lighting", "authentic textures"],
    "avoid": ["digital artifacts", "oversaturated colors", "blurry", "overprocessed"]
  }
}
```

### Focal Length Guide (High Impact)

| Use Case | Focal Length | Effect |
|----------|-------------|--------|
| Landscape/architecture | 16-24mm | Wide, expansive |
| Street/documentary | 35mm | Natural perspective |
| General/portrait | 50mm | Standard human vision |
| Portrait/product | 85mm | Compression, bokeh |
| Macro/detail | 100mm | Close-up isolation |
| Wildlife/sports | 200mm+ | Telephoto compression |

### Style Combinations That Work Well

| Look | primary_style | lighting | color_profile |
|------|--------------|----------|---------------|
| Magazine editorial | editorial | studio | rich |
| Moody cinematic | cinematic | dramatic | muted |
| Clean product shot | studio | studio | neutral |
| Street photography | documentary | natural | neutral |
| Golden hour portrait | photorealistic | golden-hour | rich |

### Meme Generation

Gemini can generate classic meme templates with text overlays. Use `constraints` to specify text placement.

```json
{
  "core": {
    "subject": "Distracted Boyfriend meme template recreation",
    "scene": "man walking with girlfriend turns to look at another woman",
    "objects": ["man in blue shirt", "girlfriend looking annoyed", "other woman in red"],
    "actions": ["man turning head", "girlfriend disapproving"],
    "constraints": [
      "text on woman in red: Your text here",
      "text on man: Label here",
      "text on girlfriend: Another label",
      "white Impact font with black outline",
      "text must be clearly readable",
      "classic meme format"
    ]
  },
  "style": {
    "primary_style": "photorealistic",
    "render_quality": "detailed",
    "lighting": "natural",
    "color_profile": "rich"
  },
  "quality_keywords": {
    "include": ["photographic quality", "natural lighting"],
    "avoid": ["blurry", "digital artifacts"]
  }
}
```

**Meme Template Reference** -- use these scene descriptions in `subject` + `scene` fields:

| Template | Labels | Scene Description | Style |
|----------|--------|-------------------|-------|
| **Distracted Boyfriend** | 3 | Man walking with girlfriend turns to stare at another woman. Girlfriend looks betrayed. Street setting. Labels on each person. | photorealistic |
| **Drake Hotline Bling** | 2 | Two-panel vertical. Top: man in orange puffer jacket grimacing, hand up rejecting. Bottom: same man smiling, pointing approvingly. Text on right side of each panel. | illustrative |
| **This Is Fine** | 1-2 | Dog sitting calmly at table drinking coffee while room is engulfed in flames around him. Dog says "This is fine." | illustrative |
| **Two Buttons** | 2 | Sweating person agonizing over which of two large red buttons to press. Each button has a label. Close-up on face showing stress. | illustrative |
| **Expanding Brain** | 4 | Four panels stacked vertically, each showing a brain with increasing levels of glow/expansion. Small brain at top, galaxy brain at bottom. Text beside each panel. | illustrative |
| **Change My Mind** | 1 | Person sitting at folding table outdoors with a sign/banner. Sign has the main text. Person looks smugly confident. | photorealistic |
| **Is This A Pigeon** | 3 | Anime-style character in suit gesturing at a butterfly, asking "Is this a [label]?" Labels on person, butterfly, and subtitle question. | illustrative |
| **Always Has Been** | 2 | Two astronauts in space looking at Earth. First astronaut realizes something, second astronaut behind him points a gun. "Wait, it's all X?" "Always has been." | cinematic |
| **Woman Yelling at Cat** | 2 | Two-panel horizontal. Left: angry woman pointing and yelling at dinner table. Right: confused white cat sitting at dinner table with plate of salad. | photorealistic |
| **Boardroom Suggestion** | 4 | Four panels. Boss asks question in boardroom. Two employees give expected answers. Third employee gives honest/unexpected answer. Boss throws third employee out window. | illustrative |
| **Left Exit 12** | 3 | Car on highway swerving dramatically across lane dividers to take an exit ramp at last second. Labels on the car, the highway, and the exit sign. | photorealistic |
| **Bike Fall** | 3 | Three panels. Person riding bike happily. Person puts stick into own front wheel spokes. Person on ground with crashed bike looking upset. | illustrative |
| **Gru's Plan** | 4 | Four panels from animated villain presentation. First 3: character presents plan steps on whiteboard confidently. Panel 4: realizes the flaw, looks shocked at own whiteboard. | illustrative |
| **Trade Offer** | 3 | Person in tracksuit presenting a "trade offer" with two columns: "I receive" and "You receive." Confident expression. | photorealistic |
| **They're the Same Picture** | 2 | Office worker holding two pictures side by side. Someone asks to find the difference. "They're the same picture." | photorealistic |
| **Tuxedo Winnie the Pooh** | 2 | Two-panel vertical. Top: regular casual Winnie the Pooh with basic label. Bottom: Pooh in fancy tuxedo with sophisticated version of same label. | illustrative |
| **Batman Slapping Robin** | 2 | Batman slapping Robin across the face mid-sentence. Robin's speech bubble is the bad take, Batman's slap represents the correction. | illustrative |
| **Surprised Pikachu** | 1 | Yellow electric mouse character with wide open mouth and shocked expression. The obvious consequence happened and everyone is surprised. | illustrative |
| **Roll Safe / Thinking** | 1 | Man tapping temple/forehead with a knowing smirk. "Can't have X problem if you Y." | photorealistic |
| **Stonks** | 1 | Surreal 3D-rendered businessman in suit standing in front of a stock chart going up. "Stonks" text. Intentionally low-poly/absurd. | illustrative |
| **UNO Draw 25** | 2 | Person holding massive hand of UNO cards. Card on table says "do X or draw 25." Person chose to draw 25 rather than do the thing. | photorealistic |
| **Running Away Balloon** | 5 | Person chasing a balloon floating away while still holding the string of a different balloon. Multiple labels on person, balloons, and ground. | illustrative |
| **Success Kid** | 1 | Toddler on beach with fist clenched in victory/determination. Sandy face, triumphant expression. | photorealistic |
| **Disaster Girl** | 1 | Young girl smiling mischievously at the camera while a house burns in the background. | photorealistic |
| **One Does Not Simply** | 1 | Medieval fantasy character making a hand gesture while delivering wisdom. "One does not simply [do thing]." | cinematic |
| **Waiting Skeleton** | 1 | Skeleton sitting on a park bench, clearly having been waiting so long they died. Cobwebs optional. | photorealistic |

Gemini isn't limited to these -- you can describe ANY meme format and it will attempt it.

**Meme tips:**
- Specify `"white Impact font with black outline"` in constraints for all text
- Keep text SHORT (under 40 chars per label)
- For multi-panel memes, describe the layout explicitly (e.g., "four panels stacked vertically")
- Use the `style` column above as the `primary_style` value
- Gemini recreates scenes with original faces/compositions -- won't be the exact stock photo everyone's seen, which actually stands out more on LinkedIn

## Sending the Prompt

Wrap the JSON in a message that tells the model what to do:

```
Generate an image based on these specifications. Return ONLY the image, no text.

{...your JSON here...}
```

### Using the generate-image.sh script (preferred)

```bash
~/.claude/skills/landing-page-builder/scripts/generate-image.sh \
  --prompt "Generate an image based on these specifications. Return ONLY the image, no text. $(cat prompt.json)" \
  --output path/to/output.png
```

### Direct curl

```bash
curl -s -X POST "http://<LITELLM_IP>:4000/v1/chat/completions" \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "image",
    "messages": [{"role": "user", "content": "Generate an image based on these specifications. Return ONLY the image, no text.\n\n{...JSON...}"}],
    "max_tokens": 4096
  }' -o /tmp/img-response.json

# Extract and decode the image
jq -r '.choices[0].message.images[0].image_url.url' /tmp/img-response.json \
  | sed 's|data:image/png;base64,||' \
  | base64 -d > output.png
```

## Output Location

Save generated images to `public/images/` relative to the project root, or wherever the user specifies. Use descriptive filenames (e.g., `hero-beer-can.png`, `feature-infrastructure.png`).

## Presenting Results

After generation completes:
1. Open the image with `open <path>` so the user can see it
2. Read the image file to visually inspect it yourself
3. Offer to regenerate with variations if needed

## Cropping / Resizing

If non-square layouts are needed, crop after generation:

```bash
~/.claude/skills/landing-page-builder/scripts/crop-image.sh \
  --input public/images/hero.png \
  --width 1200 --height 630 \
  --preview  # dry run first, then remove --preview to apply
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| 403 / route not allowed | The virtual key is restricted. Use the master key instead. |
| No image data in response | Check `.choices[0].message.images` array -- LiteLLM puts images there, NOT in `.content` |
| Empty response | Check LiteLLM logs: `ssh root@<LITELLM_IP> "journalctl -u litellm -n 20"` |
| LiteLLM proxy unreachable | Check: `curl http://<LITELLM_IP>:4000/v1/chat/completions` (needs auth header) |
| Text in image garbled | Keep text short (<40 chars), use `constraints` to specify exact text and font style |
| Contradictory output | Don't mix conflicting style cues (e.g., "low-light" + "bright exposure") |
| Flat/clipart output | You forgot JSON prompting. Never send plain text prompts. |
