# Landing Page Design Patterns

Reference for common landing page layouts and component patterns.
Load this during Phase 5 (UI Build).

## Section Patterns

### Hero Section
- **Split hero:** Image on one side, text + CTA on the other. Works for products.
- **Full-bleed hero:** Background image with overlay text. Works for portfolios/agencies.
- **Centered hero:** Centered headline + subtext, image below. Works for SaaS.
- Always include: headline (5-8 words), subtext (1-2 sentences), primary CTA button.
- Hero image should be the highest-quality generated image.

### Features Section
- **Icon grid:** 3-4 features in a row with icons above text. Clean and scannable.
- **Alternating rows:** Image left/text right, then swap. Good for detailed features.
- **Card grid:** Features in cards with subtle shadows. Works for 6+ features.
- Keep feature descriptions to 2-3 sentences max.

### Social Proof / Testimonials
- **Quote cards:** Simple cards with quote, name, role.
- **Logo bar:** Row of client/partner logos. No generated images needed.
- **Stats row:** 3-4 key metrics in large type (e.g., "10K+ users").

### CTA Section
- **Simple CTA:** Headline + single button on contrasting background.
- **CTA with image:** Split layout with motivating image.
- Always use a contrasting color for CTA buttons.

### Footer
- Keep it simple: links, copyright, social icons.
- Don't over-design the footer -- it should fade, not compete.

## Layout Rules

1. **Max content width:** 1200px for text, images can bleed wider.
2. **Section spacing:** Consistent vertical rhythm -- 80px-120px between sections.
3. **Never center-align body text** -- Left-align paragraphs, center only headlines.
4. **One CTA per viewport** -- Don't overwhelm with multiple actions.
5. **Image sizing:** Hero images full-width or 50% in split layouts. Feature icons 48-64px. Don't stretch generated images.

## Responsive Breakpoints

| Breakpoint | Width | Layout Change |
|------------|-------|--------------|
| Mobile | < 640px | Single column, stack everything |
| Tablet | 640-1024px | 2-column grids become 1-2 columns |
| Desktop | > 1024px | Full layout with sidebars and grids |

## Component Patterns

### Buttons
- Primary: solid background, white text, 12-16px padding, rounded corners (6-8px)
- Secondary: outline/ghost, same border radius
- Hover: subtle scale (1.02) or color shift, not both

### Cards
- Subtle shadow (0 2px 8px rgba(0,0,0,0.08))
- 24-32px internal padding
- Rounded corners matching buttons (6-8px)
- Don't put cards inside cards

### Images
- Always include `alt` text describing the image
- Use `loading="lazy"` for below-the-fold images
- Provide width/height to prevent layout shift
- Use `object-fit: cover` for fixed-dimension containers
