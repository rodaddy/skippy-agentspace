# Frontend Aesthetics Reference

Typography, spacing, color, and animation guidelines for landing pages.
Load this during Phase 5 (UI Build).

## Typography

### Font Pairing Strategy
Don't use system defaults. Pick ONE of these proven pairings:

| Headlines | Body | Vibe |
|-----------|------|------|
| Inter | Inter | Clean, modern SaaS |
| Plus Jakarta Sans | Inter | Friendly, approachable |
| Instrument Serif | Inter | Premium, editorial |
| Space Grotesk | DM Sans | Tech-forward |
| Sora | Source Sans 3 | Geometric, contemporary |
| Fraunces | Outfit | Creative, distinctive |

### Type Scale
Use a consistent scale -- don't eyeball sizes:

| Element | Desktop | Mobile | Weight |
|---------|---------|--------|--------|
| H1 (hero) | 48-64px | 32-40px | 700-800 |
| H2 (section) | 36-40px | 28-32px | 600-700 |
| H3 (card title) | 24-28px | 20-24px | 600 |
| Body | 16-18px | 16px | 400 |
| Caption/meta | 14px | 13px | 400 |

### Line Height
- Headlines: 1.1-1.2
- Body text: 1.5-1.7
- Never go below 1.1 or above 1.8

### Letter Spacing
- Large headlines (48px+): -0.02em to -0.03em (tighter)
- Body text: 0 (default)
- Uppercase labels: 0.05em to 0.1em (wider)

## Color

### Building a Palette
1. Pick ONE primary color (brand)
2. Pick ONE accent color (CTAs, highlights)
3. Use neutrals for everything else (grays, not pure black/white)
4. Background: off-white (#FAFAFA or #F8F9FA), not pure white
5. Text: dark gray (#1A1A2E or #111827), not pure black

### Contrast Rules
- Body text: minimum 4.5:1 contrast ratio (WCAG AA)
- Large text (24px+): minimum 3:1
- Interactive elements: visible focus states

### Dark Sections
- Use a dark section to break up the page (e.g., testimonials or CTA)
- Dark background: #111827 or #0F172A
- Light text on dark: #F1F5F9, not pure white

## Spacing

### The 8px Grid
All spacing should be multiples of 8px:
- 8, 16, 24, 32, 40, 48, 64, 80, 96, 120

### Component Spacing
| Context | Spacing |
|---------|---------|
| Between sections | 80-120px |
| Section title to content | 40-48px |
| Between cards | 24-32px |
| Card internal padding | 24-32px |
| Between paragraphs | 16-24px |
| Button padding | 12-16px vertical, 24-32px horizontal |

## Animation

### Principles
- **Subtle only** -- animations should enhance, not distract
- **Fast** -- 200-300ms for micro-interactions, 400-600ms for reveals
- **Ease-out** -- use `cubic-bezier(0.16, 1, 0.3, 1)` for smooth deceleration

### Safe Animations
- **Fade-in on scroll:** opacity 0 to 1, translateY 20px to 0. Stagger cards by 100ms.
- **Button hover:** scale(1.02) or background color shift. Pick one, not both.
- **Image hover:** subtle scale(1.03) with overflow hidden on container.

### Avoid
- Parallax scrolling (performance, accessibility issues)
- Auto-playing carousels (nobody likes them)
- Bouncing/pulsing elements (looks cheap)
- Animations longer than 600ms
- Animation on mobile (reduce motion preference)

## Design Identity System (CRITICAL -- Read This First)

Every landing page MUST have a distinct visual identity. The #1 problem with AI-generated pages
is they all look identical -- dark background, purple/blue neon gradients, glowing orbs,
the "Tokyo Nights" aesthetic. This section exists to prevent that.

### Step 1: Ask About Brand/Vibe

Before writing ANY CSS, ask the user which design direction fits their project.
Present these options (or let them describe their own):

| Identity | Colors | Feel | Example Sites |
|----------|--------|------|---------------|
| **Warm Earthy** | Terracotta, cream, forest green, warm gray | Craft, artisan, organic | Notion, Linear blog |
| **Clean Corporate** | Navy, white, light blue accents, slate | Professional, trustworthy | Stripe, Plaid |
| **Playful Bold** | Bright primary colors, yellow/coral/teal | Fun, approachable, startup | Figma, Notion |
| **Minimal Mono** | Black, white, one accent color only | Elegant, editorial, luxury | Apple, Rauno |
| **Soft Pastel** | Lavender, mint, peach, light gray | Gentle, wellness, creative | Calm, Headspace |
| **Dark Professional** | Charcoal (NOT black), muted gold/green, warm gray | Premium, fintech, serious | Linear, Vercel |

### Step 2: Commit to the Identity

Once chosen, EVERY design decision flows from it:
- Colors come from the identity palette, not your defaults
- Typography pairing should match the vibe (serif for editorial, geometric sans for tech)
- Image prompts should specify the identity's color palette
- Button styles, shadows, borders -- all consistent with the identity

### Step 3: Differentiation Checklist

Before presenting the final page, verify:
- [ ] No purple-to-blue gradients (unless explicitly requested)
- [ ] No glowing/neon effects (unless the identity calls for it)
- [ ] Background is NOT #0F172A or #111827 for the entire page
- [ ] Not using Inter for both headlines AND body (pick a distinctive headline font)
- [ ] At least one section uses a layout OTHER than centered cards
- [ ] Color palette has a warm OR cool tone -- not the default blue/purple
- [ ] The page looks different from the last 3 pages you generated

### Banned Defaults (The "Tokyo Nights" Blacklist)

These are the things Claude reaches for when it has no direction. NEVER use them
unless the user explicitly requests this aesthetic:

- `background: linear-gradient(to right, #6366f1, #8b5cf6)` or any indigo/violet gradient
- Full-page dark backgrounds with neon accent text
- Glowing box-shadows (`box-shadow: 0 0 20px rgba(139, 92, 246, 0.5)`)
- Orb/blob decorative elements with purple/blue gradients
- The combo of dark bg + gradient text + glassmorphism cards
- Background patterns that look like circuit boards or neural networks
- "Futuristic" sans-serif fonts with extreme letter-spacing

## Anti-Patterns (Things Claude Defaults To -- Avoid These)

1. **Generic gradients** -- Don't slap a purple-to-blue gradient on everything
2. **Too many rounded corners** -- Not everything needs border-radius: 50%
3. **Excessive whitespace** -- Some is good, too much looks unfinished
4. **Stock-photo aesthetics** -- The AI images should feel integrated, not pasted on
5. **Rainbow of colors** -- Stick to 2-3 colors max plus neutrals
6. **Overly safe fonts** -- Arial, Helvetica, system-ui defaults look lazy
7. **Card soup** -- Not every section needs to be cards. Mix layouts.
8. **Shadow overload** -- One subtle shadow level, not three different depths
9. **Same page every time** -- If your last page was dark+gradient, this one should be light+solid
10. **Glassmorphism everywhere** -- Frosted glass effects are played out. Use sparingly or not at all.
