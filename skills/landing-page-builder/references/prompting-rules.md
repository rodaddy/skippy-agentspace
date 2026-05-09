# Image Prompting Rules

Rules for writing effective prompts for Gemini 3 image generation via LiteLLM.
Derived from iteration testing -- each rule addresses a specific failure mode.

## The 13 Rules

1. **No dimensions or aspect ratios** -- The model generates square images regardless. Never include "1200x630", "16:9", "wide", "tall" in prompts. Crop after generation.

2. **Always include "no text"** -- Unless you specifically want text rendered in the image. AI-rendered text is almost always garbled.

3. **One subject per prompt** -- Don't ask for "a laptop AND a coffee cup AND a notebook." Focus on the primary subject; secondary elements as context only.

4. **Specify art style explicitly** -- Don't assume the model knows what you want. Always include one of: "professional editorial photograph", "flat vector illustration", "3D render", "watercolor painting", "minimalist line art", "isometric design".

5. **Include lighting direction** -- "morning sunlight from left", "soft diffused overhead light", "dramatic side lighting". Without this, lighting is inconsistent across a batch.

6. **Specify background** -- "white background", "dark gradient background", "blurred office environment". Never leave background unspecified.

7. **Include negative descriptions** -- Say what you DON'T want: "no people", "no text", "no watermarks", "not photorealistic" (for illustrations).

8. **Color palette hints** -- "using purple and blue tones", "warm orange and cream palette", "monochromatic blue". This ensures visual consistency across multiple images.

9. **Composition keywords** -- "centered subject", "rule of thirds", "close-up", "wide shot", "bird's eye view". These dramatically affect output quality.

10. **Mood/atmosphere words** -- "professional", "playful", "serene", "energetic", "luxurious". One mood word per prompt keeps it focused.

11. **Keep prompts under 100 words** -- Longer prompts confuse the model. Be precise, not verbose.

12. **Don't reference other images** -- "like the hero image but different" doesn't work. Each prompt must be self-contained.

13. **Test with one before batching** -- Generate a single image first to validate the prompt style, then generate remaining images in that style.

## Prompt Template

```
[art style] of [subject] [doing action/in state], [lighting], [background],
[color palette], [composition], [mood], no text, no watermarks
```

## Example Prompts

### Hero Image (Developer Tool)
```
professional editorial photograph of a developer workspace with dual monitors
showing code, soft morning sunlight from the left, shallow depth of field with
blurred office background, blue and purple tones, centered composition,
professional and focused mood, no text, no people
```

### Feature Icon (Abstract)
```
flat vector illustration of a shield with a checkmark, soft diffused light,
clean white background, using green and blue tones, centered subject,
professional and trustworthy mood, no text, no gradients
```

### Testimonial Background
```
minimalist watercolor painting of abstract flowing shapes, soft overhead
lighting, light cream background, warm pastel tones, wide composition with
negative space on right side, serene and calming mood, no text
```
