---
name: spectrocloud-web-ui
description: Spectro Cloud brand theming for web frontends. CSS custom properties, component patterns, dark mode, responsive layouts, and accessibility guidance. References spectrocloud-brand for colors and typography.
---

# Spectro Cloud Web UI Theming

Brand-aligned web UI patterns for dashboards, internal tools, customer portals, and demo apps. READ the `spectrocloud-brand` skill for full color definitions, logo rules, and messaging guidelines -- this skill focuses on web implementation.

## When to Use

- Building web dashboards or admin panels with SC branding
- Creating demo apps (e.g., hello-universe style demos)
- Internal tools that need brand-consistent styling
- Customer-facing portals or landing pages
- Any HTML/CSS project requiring SC visual identity

## CSS Custom Properties

Import the full palette. These mirror the definitions in `spectrocloud-brand/references/colors.md`.

```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@200;300;400;500;600;700;800&display=swap');

:root {
  /* Primary */
  --sc-teal: #1F7A78;
  --sc-teal-dark: #005B5B;
  --sc-teal-darker: #004244;
  --sc-teal-darkest: #043736;
  --sc-green: #9EB277;
  --sc-green-dark: #5D823C;
  --sc-gold: #F0BE65;
  --sc-gold-dark: #DE8D2A;
  --sc-orange: #B94B01;
  --sc-orange-dark: #851A01;
  --sc-lilac: #7E5C8E;
  --sc-lilac-dark: #441647;

  /* Neutrals */
  --sc-paper: #F7F1ED;
  --sc-neutral-1: #E0DCD7;
  --sc-neutral-2: #BEB9B6;
  --sc-neutral-3: #9E9C9C;
  --sc-neutral-4: #3C4949;
  --sc-neutral-5: #1E3332;
  --sc-ink: #012121;

  /* Semantic aliases */
  --sc-bg: var(--sc-paper);
  --sc-text: var(--sc-ink);
  --sc-text-muted: var(--sc-neutral-4);
  --sc-border: var(--sc-neutral-2);
  --sc-border-light: var(--sc-neutral-1);
  --sc-primary: var(--sc-teal);
  --sc-primary-dark: var(--sc-teal-dark);
  --sc-accent: var(--sc-gold);
  --sc-success: var(--sc-green);
  --sc-warning: var(--sc-gold-dark);
  --sc-danger: var(--sc-orange);

  /* Typography */
  --sc-font: 'Plus Jakarta Sans', 'Trebuchet MS', sans-serif;
  --sc-font-size-base: 16px;
  --sc-line-height: 1.6;

  /* Spacing scale */
  --sc-space-xs: 4px;
  --sc-space-sm: 8px;
  --sc-space-md: 16px;
  --sc-space-lg: 24px;
  --sc-space-xl: 32px;
  --sc-space-2xl: 48px;

  /* Border radius */
  --sc-radius-sm: 4px;
  --sc-radius-md: 8px;
  --sc-radius-lg: 12px;
}
```

## Typography Setup

Weight hierarchy for web (from spectrocloud-brand):

| Element | Weight | CSS |
|---------|--------|-----|
| Display / hero headings | 200 ExtraLight | `font-weight: 200` |
| Section headings (h2-h3) | 500 Medium | `font-weight: 500` |
| Body text | 400 Regular | `font-weight: 400` |
| Blockquotes | 300 Light | `font-weight: 300` |
| Labels, badges, nav items | 600 SemiBold | `font-weight: 600` |
| Small-text emphasis | 700 Bold | `font-weight: 700` |

## Base Styles

```css
*, *::before, *::after { box-sizing: border-box; }

body {
  font-family: var(--sc-font);
  font-size: var(--sc-font-size-base);
  line-height: var(--sc-line-height);
  color: var(--sc-text);
  background: var(--sc-bg);
  margin: 0;
}

h1 { font-weight: 200; font-size: 2.5rem; color: var(--sc-teal-darkest); }
h2 { font-weight: 500; font-size: 1.75rem; color: var(--sc-teal-dark); }
h3 { font-weight: 500; font-size: 1.25rem; color: var(--sc-ink); }
h4 { font-weight: 600; font-size: 1rem; color: var(--sc-ink); }

a { color: var(--sc-teal); text-decoration: underline; }
a:hover { color: var(--sc-teal-dark); }

code {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  background: var(--sc-neutral-1);
  padding: 2px 6px;
  border-radius: var(--sc-radius-sm);
  font-size: 0.9em;
}

pre code {
  display: block;
  padding: var(--sc-space-md);
  overflow-x: auto;
  border-left: 3px solid var(--sc-teal);
}
```

## Component Patterns

### Navigation Bar

```html
<nav class="sc-navbar">
  <div class="sc-navbar-brand">
    <!-- Use knockout-white SVG on teal background -->
    <img src="spectrocloud-logo-horizontal-knockout-white.svg" alt="Spectro Cloud" height="28">
  </div>
  <div class="sc-navbar-links">
    <a href="#" class="sc-navbar-link active">Dashboard</a>
    <a href="#" class="sc-navbar-link">Clusters</a>
    <a href="#" class="sc-navbar-link">Profiles</a>
  </div>
</nav>
```

```css
.sc-navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--sc-teal);
  padding: var(--sc-space-sm) var(--sc-space-xl);
  color: #fff;
}
.sc-navbar-links { display: flex; gap: var(--sc-space-lg); }
.sc-navbar-link {
  color: rgba(255,255,255,0.8);
  text-decoration: none;
  font-weight: 600;
  font-size: 0.875rem;
  padding: var(--sc-space-xs) 0;
  border-bottom: 2px solid transparent;
}
.sc-navbar-link:hover,
.sc-navbar-link.active {
  color: #fff;
  border-bottom-color: var(--sc-gold);
}
```

### Side Navigation

```css
.sc-sidenav {
  width: 240px;
  background: var(--sc-ink);
  color: var(--sc-neutral-2);
  padding: var(--sc-space-lg) 0;
  min-height: 100vh;
}
.sc-sidenav-section { padding: var(--sc-space-sm) var(--sc-space-lg); font-weight: 600; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--sc-neutral-3); }
.sc-sidenav-link {
  display: block;
  padding: var(--sc-space-sm) var(--sc-space-lg);
  color: var(--sc-neutral-2);
  text-decoration: none;
  font-size: 0.875rem;
  border-left: 3px solid transparent;
}
.sc-sidenav-link:hover { background: rgba(255,255,255,0.05); color: #fff; }
.sc-sidenav-link.active {
  color: var(--sc-gold);
  border-left-color: var(--sc-gold);
  background: rgba(255,255,255,0.05);
}
```

### Cards

```css
.sc-card {
  background: #fff;
  border: 1px solid var(--sc-border-light);
  border-radius: var(--sc-radius-md);
  padding: var(--sc-space-lg);
  border-top: 3px solid var(--sc-teal);
}
.sc-card-title { font-weight: 600; font-size: 1.1rem; margin: 0 0 var(--sc-space-sm); }
.sc-card-body { color: var(--sc-text-muted); font-size: 0.9rem; }
```

Variants: add `border-top-color` overrides for `.sc-card--gold` (`var(--sc-gold)`), `.sc-card--lilac` (`var(--sc-lilac)`), `.sc-card--orange` (`var(--sc-orange)`).

### Stat Cards / KPI Displays

```html
<div class="sc-stat-card">
  <div class="sc-stat-label">Active Clusters</div>
  <div class="sc-stat-value">127</div>
  <div class="sc-stat-change positive">+12% from last month</div>
</div>
```

```css
.sc-stat-card {
  background: #fff;
  border: 1px solid var(--sc-border-light);
  border-radius: var(--sc-radius-md);
  padding: var(--sc-space-lg);
  text-align: center;
}
.sc-stat-label { font-size: 0.8rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--sc-text-muted); }
.sc-stat-value { font-size: 2.5rem; font-weight: 200; color: var(--sc-teal); margin: var(--sc-space-xs) 0; }
.sc-stat-change { font-size: 0.8rem; color: var(--sc-text-muted); }
.sc-stat-change.positive { color: var(--sc-green-dark); }
.sc-stat-change.negative { color: var(--sc-orange); }
```

### Tables

```css
.sc-table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
.sc-table th {
  background: var(--sc-teal-darkest);
  color: #fff;
  font-weight: 600;
  text-align: left;
  padding: var(--sc-space-sm) var(--sc-space-md);
}
.sc-table td {
  padding: var(--sc-space-sm) var(--sc-space-md);
  border-bottom: 1px solid var(--sc-border-light);
}
.sc-table tr:hover td { background: rgba(31,122,120,0.04); }
```

### Buttons

```css
.sc-btn {
  font-family: var(--sc-font);
  font-weight: 600;
  font-size: 0.875rem;
  padding: var(--sc-space-sm) var(--sc-space-lg);
  border-radius: var(--sc-radius-sm);
  border: 2px solid transparent;
  cursor: pointer;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
}
.sc-btn-primary {
  background: var(--sc-teal);
  color: #fff;
  border-color: var(--sc-teal);
}
.sc-btn-primary:hover { background: var(--sc-teal-dark); border-color: var(--sc-teal-dark); }

.sc-btn-secondary {
  background: transparent;
  color: var(--sc-teal);
  border-color: var(--sc-teal);
}
.sc-btn-secondary:hover { background: var(--sc-teal); color: #fff; }

.sc-btn-accent {
  background: var(--sc-gold);
  color: var(--sc-ink);
  border-color: var(--sc-gold);
}
.sc-btn-accent:hover { background: var(--sc-gold-dark); border-color: var(--sc-gold-dark); }
```

### Badges / Pills

```css
.sc-badge {
  display: inline-block;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 2px 10px;
  border-radius: 999px;
  background: var(--sc-neutral-1);
  color: var(--sc-ink);
}
.sc-badge--teal { background: rgba(31,122,120,0.12); color: var(--sc-teal-dark); }
.sc-badge--green { background: rgba(158,178,119,0.2); color: var(--sc-green-dark); }
.sc-badge--gold { background: rgba(240,190,101,0.2); color: var(--sc-gold-dark); }
.sc-badge--orange { background: rgba(185,75,1,0.12); color: var(--sc-orange-dark); }
.sc-badge--lilac { background: rgba(126,92,142,0.12); color: var(--sc-lilac-dark); }
```

### Alerts / Notifications

```css
.sc-alert {
  padding: var(--sc-space-md) var(--sc-space-lg);
  border-radius: var(--sc-radius-md);
  border-left: 4px solid var(--sc-teal);
  background: rgba(31,122,120,0.06);
  font-size: 0.9rem;
}
.sc-alert--success { border-left-color: var(--sc-green-dark); background: rgba(158,178,119,0.1); }
.sc-alert--warning { border-left-color: var(--sc-gold-dark); background: rgba(240,190,101,0.1); }
.sc-alert--error { border-left-color: var(--sc-orange); background: rgba(185,75,1,0.08); }
```

### Form Inputs

```css
.sc-input {
  font-family: var(--sc-font);
  font-size: 0.9rem;
  padding: var(--sc-space-sm) var(--sc-space-md);
  border: 1px solid var(--sc-border);
  border-radius: var(--sc-radius-sm);
  background: #fff;
  color: var(--sc-text);
  width: 100%;
  transition: border-color 0.15s;
}
.sc-input:focus { outline: none; border-color: var(--sc-teal); box-shadow: 0 0 0 3px rgba(31,122,120,0.15); }
.sc-input::placeholder { color: var(--sc-neutral-3); }

.sc-label {
  display: block;
  font-weight: 600;
  font-size: 0.85rem;
  margin-bottom: var(--sc-space-xs);
  color: var(--sc-ink);
}
```

### Footer

```css
.sc-footer {
  background: var(--sc-ink);
  color: var(--sc-neutral-2);
  padding: var(--sc-space-2xl) var(--sc-space-xl);
  font-size: 0.85rem;
}
.sc-footer a { color: var(--sc-gold); text-decoration: none; }
.sc-footer a:hover { text-decoration: underline; }
.sc-footer-copyright { margin-top: var(--sc-space-lg); color: var(--sc-neutral-3); font-size: 0.75rem; }
/* Logo in footer: use horizontal SVG with color: var(--sc-neutral-2) and opacity: 0.6 */
```

## Dark Mode

Apply via `[data-theme="dark"]` or `@media (prefers-color-scheme: dark)`.

```css
[data-theme="dark"] {
  --sc-bg: var(--sc-ink);
  --sc-text: var(--sc-paper);
  --sc-text-muted: var(--sc-neutral-2);
  --sc-border: var(--sc-neutral-5);
  --sc-border-light: var(--sc-neutral-4);
}

[data-theme="dark"] .sc-card,
[data-theme="dark"] .sc-stat-card,
[data-theme="dark"] .sc-input {
  background: var(--sc-neutral-5);
}

[data-theme="dark"] .sc-table th {
  background: var(--sc-teal-dark);
}

[data-theme="dark"] .sc-navbar {
  background: var(--sc-teal-darkest);
}
```

On Ink backgrounds, use Gold (#F0BE65, 9.88:1) or Green (#9EB277, 7.32:1) for high-contrast text. Teal, Orange, and Lilac are only AA-large on dark -- use for decorative accents, not body text.

## Responsive Breakpoints

```css
/* Mobile first */
--sc-bp-sm: 576px;   /* Small devices */
--sc-bp-md: 768px;   /* Tablets */
--sc-bp-lg: 1024px;  /* Desktops */
--sc-bp-xl: 1280px;  /* Large screens */

@media (max-width: 768px) {
  .sc-navbar { flex-direction: column; gap: var(--sc-space-sm); }
  .sc-sidenav { width: 100%; min-height: auto; }
  .sc-stat-value { font-size: 2rem; }
  h1 { font-size: 1.75rem; }
}
```

## Animation Guidelines

Follow the spectrocloud-brand animation principles:

- **Transitions**: 150-300ms ease-out for UI interactions (hovers, focus, toggles)
- **Page transitions**: 300-500ms ease-in-out for route changes or panel slides
- **Folding motifs**: Use subtle `transform: rotateY()` or skew effects to suggest origami folds -- keep it tactile and gentle, never bouncy or playful
- **No character-by-character text animation** -- fade or slide entire blocks
- **Product demos**: Keep the UI feature front and center, minimize surrounding motion

```css
.sc-fade-in {
  animation: scFadeIn 0.3s ease-out;
}
@keyframes scFadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
```

## Accessibility

WCAG contrast ratios from the brand guide (see spectrocloud-brand for full grid):

**On Paper backgrounds (#F7F1ED):** Dark Lilac (12.92:1), Dark Teal (11.69:1), Dark Orange (8.74:1) all pass AAA. Teal and Lilac (4.93:1) pass AA for normal text.

**On Ink backgrounds (#012121):** Gold (9.88:1) and Green (7.32:1) pass AAA. Orange, Teal, and Lilac only pass AA-large (~3.3:1).

Rules:
- Use `--sc-teal-darkest` or `--sc-ink` for body text on light backgrounds
- Use `--sc-gold` or `--sc-green` for body text on dark backgrounds
- Interactive elements need visible `:focus` styles (the `box-shadow` on `.sc-input:focus` is a pattern to follow)
- Minimum touch target: 44x44px for mobile
- Always provide `alt` text on logo images
