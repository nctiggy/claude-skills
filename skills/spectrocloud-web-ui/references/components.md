# Spectro Cloud Web UI Component Library

Copy-paste CSS/HTML for the `sc-*` component classes. All rules use the `--sc-*` custom properties defined in SKILL.md — include that `:root` block first.

## Navigation Bar

```html
<nav class="sc-navbar">
  <div class="sc-navbar-brand">
    <!-- Use knockout-white SVG on teal background (source: spectrocloud-brand/assets/) -->
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

## Side Navigation

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

## Cards

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

## Stat Cards / KPI Displays

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

## Tables

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

## Buttons

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

## Badges / Pills

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

## Alerts / Notifications

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

## Form Inputs

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

## Footer

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

## Dark Mode Overrides

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

## Animation

```css
.sc-fade-in {
  animation: scFadeIn 0.3s ease-out;
}
@keyframes scFadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
```
