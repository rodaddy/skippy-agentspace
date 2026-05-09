---
name: landing-page-builder
description: |
  Build landing pages and web UIs with AI-generated images via LiteLLM (Gemini 3 image model).
  Coordinates design planning, image generation, validation, and frontend implementation.
  USE WHEN: "build a landing page", "create a site", "make a website", "design a page",
  "landing page with images", "web UI with generated images", "build me a homepage".
  DO NOT USE FOR: standalone image generation (use nano-banana), simple bug fixes,
  API-only backends, database work, non-visual tasks, editing existing sites without
  image generation needs.
allowed-tools: Bash(curl:*), Bash(jq:*), Bash(base64:*), Bash(file:*), Bash(sips:*)
---

# Landing Page Builder

Build production-quality landing pages with AI-generated images, routed through LiteLLM's Gemini 3 image model.

## Critical Section

- **Image generation:** LiteLLM proxy at `http://<LITELLM_IP>:4000` -- model alias `image`
- **Auth:** Auto-resolved -- script fetches key from vaultwarden-secrets MCP via `mcp-cli` (no manual setup needed)
- **Images are square by default** -- never request specific dimensions from the model
- **Crop AFTER generation** if non-square layouts are needed (use `scripts/crop-image.sh`)
- **All generated images** go in `public/images/` relative to project root
- **Validation is mandatory** -- never build UI around unverified images

## Workflow

### Phase 1: Design Planning

1. Ask the user what the landing page is for (product, service, portfolio, etc.)
2. **Choose a Design Identity** (CRITICAL -- load `references/frontend-aesthetics.md` Section "Design Identity System"):
   - Present the 6 identity options from the aesthetics reference
   - Let the user pick one or describe their own
   - ALL subsequent design decisions flow from this choice
3. Ask whether they want AI-generated images or stock/existing images
4. If no AI images needed, skip to Phase 4 using only frontend references
5. Create a design plan:
   - Page sections (hero, features, testimonials, CTA, footer)
   - Image requirements per section (subject, mood, style)
   - Color palette and typography from the chosen design identity
6. Present the plan for user approval before proceeding

### Phase 2: Image Generation

Load `references/prompting-rules.md` before writing any prompts.

1. Write image prompts following the prompting rules
2. Assign descriptive filenames (e.g., `hero-developer-workspace.png`)
3. Generate images using the script:
   ```bash
   ./scripts/generate-image.sh --prompt "your prompt here" --output public/images/filename.png
   ```
4. For multiple images, generate them sequentially (API rate limits)

---
### GATE: Structural Validation
Run validation before proceeding:
```bash
./scripts/validate-images.sh --dir public/images/
```
- [ ] All planned images exist in `public/images/`
- [ ] No corrupt or zero-byte files
- [ ] All files are valid image formats (PNG/JPEG/WebP)
**Do not proceed until all structural checks pass.**
---

### Phase 3: Visual Review

For EACH generated image:
1. Read/view the image file to inspect it visually
2. Evaluate against these criteria:
   - Does it match the design plan's intent for this section?
   - Is the quality acceptable (no artifacts, distortion, weird text)?
   - Will it work in the planned layout?
   - Does the color palette fit the overall design?
3. Mark each image as PASS or FAIL
4. For FAILED images:
   - Delete the failed image
   - Write a corrected prompt explaining what went wrong
   - Regenerate and re-validate

---
### GATE: Visual Review Complete
- [ ] Every planned image has passed visual review
- [ ] All images are aesthetically consistent with each other
- [ ] Color palettes complement the planned design
**Do not proceed until all images pass visual review.**
---

### Phase 4: Crop & Resize (if needed)

If any images need non-square dimensions for the layout:
```bash
./scripts/crop-image.sh --input public/images/hero.png --width 1200 --height 630 --preview
```
Always use `--preview` first, then run without it to apply.

### Phase 5: Build UI

Load `references/design-patterns.md` and `references/frontend-aesthetics.md` before building.

1. Detect existing project framework (Next.js, Astro, plain HTML, etc.)
2. If no framework, scaffold with the user's preferred stack
3. Build the page section by section, referencing the design plan
4. Apply typography and spacing rules from the aesthetics reference
5. Add subtle animations where appropriate (not overdone)
6. Ensure responsive design (mobile-first)

---
### GATE: Final Review
- [ ] All sections from the design plan are implemented
- [ ] Images are properly referenced and displayed
- [ ] Page is responsive (check at 375px, 768px, 1440px widths)
- [ ] No broken image references
- [ ] Typography and spacing follow the aesthetics reference
**Present the completed page to the user for review.**
---

## References (Level 3 -- load only when needed)

| Reference | Load When |
|-----------|-----------|
| `references/prompting-rules.md` | Phase 2 -- before writing image prompts |
| `references/design-patterns.md` | Phase 5 -- before building UI |
| `references/frontend-aesthetics.md` | Phase 5 -- for typography, spacing, animation |

## Scripts

| Script | Purpose | Key Flags |
|--------|---------|-----------|
| `scripts/generate-image.sh` | Generate image via LiteLLM | `--prompt`, `--output`, `--model` |
| `scripts/validate-images.sh` | Check images are valid | `--dir`, `--file`, `--verbose` |
| `scripts/crop-image.sh` | Resize/crop images | `--input`, `--width`, `--height`, `--preview` |

## Error Handling

### API Connection Failed
- **Cause:** LiteLLM proxy unreachable or auth failure
- **Fix:** Key is auto-fetched from vaultwarden-secrets MCP. If that fails, check proxy at `curl http://<LITELLM_IP>:4000/health`

### Image Generation Returns Text Only
- **Cause:** Model doesn't support image output or wrong model alias
- **Fix:** Ensure using model `image` (alias for `gemini-3-image`). Check LiteLLM config.

### Square Images Don't Fit Layout
- **Cause:** Gemini generates square by default
- **Fix:** Never request dimensions in prompts. Use `crop-image.sh` post-generation.

### Corrupt/Zero-Byte Images
- **Cause:** API timeout or partial response
- **Fix:** Delete and regenerate. Check LiteLLM logs if persistent.

### Font/Typography Looks Generic
- **Cause:** Claude defaults to safe system fonts
- **Fix:** Load `references/frontend-aesthetics.md` and apply its typography rules.
