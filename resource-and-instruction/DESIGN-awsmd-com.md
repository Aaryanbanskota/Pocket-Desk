# Design System Inspired by Creative Design and Development Agency

> Auto-extracted from `https://awsmd.com/?utm_source=Pinterest&utm_medium=organic` on 2026-07-23

## 1. Visual Theme & Atmosphere

Friendly, approachable design with rounded shapes and generous whitespace.

The hero section leads with "We create".

**Key Characteristics:**
- Freigeist Con as the heading font (custom web font loaded via @font-face)
- Times New Roman as the body font for all running text
- Heading weight 400
- Light/white background (#ffffff) as the primary canvas
- Primary accent `#5f8cfe` used for CTAs and brand highlights
- 1 shadow level(s) detected — standard shadows
- Rounded corners (44px+) creating a friendly, approachable feel
- Tags: light, rounded, accented, bold-typography, sans-serif

## 2. Color Palette & Roles

### Primary
- **Primary Accent** (`#5f8cfe`) · `--color-primary`: Brand color, CTA backgrounds, link text, interactive highlights.
- **Secondary Accent** (`#4858e4`) · `--color-secondary`: Secondary brand, hover states, complementary highlights.
- **Background** (`#ffffff`) · `--color-bg`: Page background, primary canvas.
- **Background Secondary** (`#4858e4`) · `--color-bg-secondary`: Cards, surfaces, alternating sections.

### Text
- **Text Primary** (`#000000`) · `--color-text`: Headings and body text.
- **Text Secondary** (`#404040`) · `--color-text-secondary`: Muted text, captions, placeholders.

### Borders & Surfaces
- **Border** (`#f4f4f4`) · `--color-border`: Dividers, outlines, input borders.

### Full Extracted Palette

| # | Hex | CSS Variable | Role | Area | Contrast |
|---|---|---|---|---|---|
| 1 | `#5f8cfe` | `--palette-1` | section | large | text-dark |
| 2 | `#4858e4` | `--palette-2` | section | large | text-light |
| 3 | `#ffffff` | `--palette-3` | button | large | text-dark |
| 4 | `#f4f4f4` | `--palette-4` | section | large | text-dark |
| 5 | `#e4e3df` | `--palette-5` | section | large | text-dark |
| 6 | `#f1ae86` | `--palette-6` | section | large | text-dark |
| 7 | `#90a6d0` | `--palette-7` | section | large | text-dark |
| 8 | `#d9d9d9` | `--palette-8` | button | medium | text-dark |
| 9 | `#404040` | `--palette-9` | button | small | text-light |

## 3. Typography Rules

- **Heading Font:** `Freigeist Con` (web font)
- **Body Font:** `Times New Roman`, sans-serif

### Type Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing |
|---|---|---|---|---|---|
| H1 | Freigeist Con | 162px | 400 | 145.8px | normal |
| H2 | Plus Jakarta Sans | 48px | 500 | 57.6px | -0.48px |
| H3 | Inter | 18px | 500 | 18.9px | normal |
| Body | Freigeist Con | 162px | 700 | 145.8px | -6.48px |

### Type Scale

| Token | Size | Suggested Usage |
|---|---|---|
| Display | `231px` | headings |
| H1 | `211px` | headings |
| H2 | `173px` | headings |
| H3 | `162px` | headings |
| H4 | `145.8px` | headings |
| Body L | `108px` | body / supporting text |
| Body | `87px` | body / supporting text |
| Small | `70px` | body / supporting text |
| XS | `60px` | body / supporting text |
| Caption | `58px` | body / supporting text |

## 4. Component Stylings

### Primary Button

```css
.btn-primary {
  background: #f1f1f1;
  color: #000000;
  border-radius: 21px;
  padding: 12px 17px;
  font-size: 16px;
  font-weight: 400;
  border: none;
  cursor: pointer;
}
```

### Outline Button

```css
.btn-outline {
  background: transparent;
  color: #ffffff;
  border-radius: 16px;
  padding: 12.5px 17.5px;
  font-size: 16px;
  font-weight: 400;
  border: 1px solid rgba(255, 255, 255, 0.4);
  cursor: pointer;
}
```

### Filled Button

```css
.btn-filled {
  background: #ffffff;
  color: #000000;
  border-radius: 50px;
  padding: 0px 0px;
  font-size: 13.3333px;
  font-weight: 400;
  border: none;
  cursor: pointer;
}
```

### Ghost Button

```css
.btn-ghost {
  background: transparent;
  color: #000000;
  border-radius: 0px;
  padding: 0px 0px;
  font-size: 13.3333px;
  font-weight: 400;
  border: none;
  cursor: pointer;
}
```

### Ghost Button 2

```css
.btn-ghost-2 {
  background: transparent;
  color: #2e2f30;
  border-radius: 0px;
  padding: 18px 20px;
  font-size: 15px;
  font-weight: 600;
  border: none;
  cursor: pointer;
}
```

### Filled Button 2

```css
.btn-filled-2 {
  background: #f1f1f1;
  color: #242424;
  border-radius: 21px;
  padding: 12px 29px;
  font-size: 16px;
  font-weight: 500;
  border: none;
  cursor: pointer;
}
```

### Card

```css
.card {
  background: #f2f0f0;
  border-radius: 30px;
  padding: 12px;
}
```

## 5. Layout Principles

- **Base spacing unit:** `2px` — use multiples (4px, 6px, 8px, etc.)

### Spacing Scale (extracted from real elements)

| Token | Value | Role |
|---|---|---|
| spacing-1 | `2px` | element |
| spacing-2 | `12px` | element |
| spacing-3 | `5px` | element |
| spacing-4 | `19px` | element |
| spacing-5 | `20px` | element |
| spacing-6 | `4.5px` | element |
| spacing-7 | `18px` | element |
| spacing-8 | `25px` | card |

### Border Radius Scale

| Token | Value | Element |
|---|---|---|
| radius-card | `44px` | card |
| radius-card | `50px` | card |
| radius-card | `25px` | card |
| radius-card | `40px` | card |
| radius-card | `33px` | card |
| radius-card | `30px` | card |

## 6. Depth & Elevation

| Level | Shadow | Usage |
|---|---|---|
| Low | `rgb(36, 36, 36) 0px 0px 0px 1px inset` | Cards, subtle elevation |


## 7. Do's and Don'ts

### Do
- Use `#ffffff` as the primary background color
- Use `Freigeist Con` for all headings and `Times New Roman` for body text
- Use `#5f8cfe` as the single dominant accent/CTA color
- Maintain `2px` as the base spacing unit — all gaps should be multiples
- Use rounded corners (`44px`+) consistently for all interactive elements
- Make headlines large and bold — typography is the hero element
- Apply the shadow system for elevation — use the extracted shadow values
- Use weight 400 for headings to match the brand's typographic voice

### Don't
- Don't use colors outside the extracted palette without justification
- Don't substitute Freigeist Con/Times New Roman with generic alternatives
- Don't use irregular spacing — stick to 2px grid
- Don't use dark/black backgrounds — this is a light-themed design
- Don't use sharp corners — they feel hostile in this rounded design language
- Don't use pure black (#000000) for text — use `#000000` instead
- Don't add decorative elements not present in the original design — no badges, ribbons, banners, or ornaments unless the source site uses them
- Don't invent UI patterns the source site doesn't have — if the original has no NEW badge, don't add one just because a red is in the palette

## 8. Responsive Behavior

| Breakpoint | Width | Notes |
|---|---|---|
| Mobile | < 640px | Single column, stack sections, reduce font sizes ~80% |
| Tablet | 640–1024px | 2-column where appropriate, maintain spacing ratios |
| Desktop | 1024–1440px | Full layout as designed |
| Wide | > 1440px | Max-width container, center content |

- Touch targets: minimum 44×44px on mobile
- Maintain 2px base unit across breakpoints — only scale multipliers

## 9. Agent Prompt Guide

### Quick Color Reference

```
Background:  #ffffff
Text:        #000000
Accent:      #5f8cfe
Secondary:   #4858e4
Border:      #f4f4f4
```

### Example Prompts

1. "Build a hero section with a `#ffffff` background, `Freigeist Con` heading in `#000000`, and a `#5f8cfe` CTA button with 21px radius."
2. "Create a pricing card using background `#4858e4`, border `#f4f4f4`, `Times New Roman` for text, and 6px padding."
3. "Design a navigation bar — `#ffffff` background, `#000000` links, `#5f8cfe` for active state."
4. "Build a feature grid with 3 columns, 6px gap, each card using the card component style."
5. "Create a footer with `#000000` background, `#ffffff` text, and 4px padding."

### Iteration Guide

1. Start with layout structure (sections, grid, spacing)
2. Apply colors from the palette — background first, then text, then accents
3. Set typography — font families, sizes from the type scale, weights
4. Add components — buttons, cards, inputs using the specs above
5. Apply border-radius consistently across all elements
6. Add shadows for depth — use the extracted shadow values, not defaults
7. Check responsive behavior — test mobile and tablet layouts
8. Final pass — verify all colors match, spacing is consistent, fonts are correct

## 10. CSS Custom Properties

> 23 custom properties extracted from `:root` / `html` stylesheets.

### Color Variables

| Variable | Value |
|---|---|
| `--swiper-theme-color` | `#007aff` |
| `--f-spinner-color-1` | `rgba(0,0,0,0.1)` |
| `--f-spinner-color-2` | `rgba(17,24,28,0.8)` |
| `--f-button-color` | `#374151` |
| `--f-button-bg` | `#f8f8f8` |
| `--f-button-hover-bg` | `#e0e0e0` |
| `--f-button-active-bg` | `#d0d0d0` |

### Spacing Variables

| Variable | Value |
|---|---|
| `--f-spinner-width` | `36px` |
| `--f-spinner-height` | `36px` |
| `--f-spinner-stroke` | `2.75` |
| `--f-button-width` | `40px` |
| `--f-button-height` | `40px` |
| `--f-button-border` | `0` |
| `--f-button-border-radius` | `0` |
| `--f-button-svg-width` | `20px` |
| `--f-button-svg-height` | `20px` |
| `--f-button-svg-stroke-width` | `1.5` |
| `--f-button-svg-disabled-opacity` | `0.65` |

### Other Variables

| Variable | Value |
|---|---|
| `--f-button-shadow` | `none` |
| `--f-button-transition` | `all 0.15s ease` |
| `--f-button-transform` | `none` |
| `--f-button-svg-fill` | `none` |
| `--f-button-svg-filter` | `none` |
