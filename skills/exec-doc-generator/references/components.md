# Component Reference — Executive Document Generator

Full HTML/CSS patterns for building 2-page executive documents. All CSS goes inline in a `<style>` block. Colors use CSS custom properties defined in `:root`.

## Base Boilerplate

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[Customer] + Spectro Cloud — [Doc Title]</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@200;300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  @page { size: letter; margin: 12px 22px; }

  :root {
    /* Customer colors — REPLACE THESE per customer */
    --primary: #0A1628;
    --primary-mid: #162D50;
    --primary-light: #1E3A5F;
    --accent: #C5963A;
    --accent-light: #D4AA5C;
    --accent-dim: #A67C2E;
    /* Standard colors — Spectro Cloud 2025 brand */
    --ink: #012121;
    --paper: #F7F1ED;
    --surface: #FFFFFF;
    --border: #D0D5DD;
    --text-dim: #4A5568;
    --accent-glow: rgba(197, 150, 58, 0.10);
    --accent-glow-strong: rgba(197, 150, 58, 0.18);
    --primary-glow: rgba(10, 22, 40, 0.06);
    --teal: #1F7A78;
    --teal-glow: rgba(31, 122, 120, 0.08);
    --green: #1A7A4C;
    --green-glow: rgba(26, 122, 76, 0.08);
    --red: #B83230;
    --radius: 10px;
    --radius-sm: 7px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: var(--paper);
    color: var(--ink);
    line-height: 1.55;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  /* PAGE STRUCTURE */
  .page {
    min-height: calc(100vh - 24px);
    display: flex;
    flex-direction: column;
  }
  .page > .container, .page > .header { flex-shrink: 0; }
  .page > .page-footer { margin-top: auto; }

  .container {
    max-width: 1040px;
    margin: 0 auto;
    padding: 12px 34px;
  }

  .page-break { break-before: page; page-break-before: always; }

  @media print {
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .stat-card, .track-card, .verdict, .scope-banner, .dc-strip, .stack-strip, .success-box {
      break-inside: avoid;
      page-break-inside: avoid;
    }
    .section-title { break-after: avoid; page-break-after: avoid; }
  }

  /* ...component styles below... */
</style>
</head>
<body>

<div class="page">
  <div class="header">...</div>
  <div class="container">...</div>
  <div class="page-footer">...</div>
</div>

<div class="page page-break">
  <div class="container">...</div>
  <div class="page-footer">...</div>
</div>

</body>
</html>
```

---

## 1. Header

Gradient banner at top of page 1. Contains logo row, badge, title, and summary paragraph.

```css
.header {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-mid) 45%, var(--primary-light) 100%);
  color: #fff;
  padding: 20px 36px 16px;
  position: relative;
  overflow: hidden;
}
.header::before {
  content: '';
  position: absolute;
  top: -50%; right: -8%;
  width: 400px; height: 400px;
  background: radial-gradient(circle, rgba(var(--accent-rgb, 197, 150, 58), 0.15) 0%, transparent 65%);
  pointer-events: none;
}
.header-inner {
  position: relative; z-index: 1;
  max-width: 1040px; margin: 0 auto;
}
.logo-row {
  display: flex; align-items: center; gap: 14px; margin-bottom: 18px;
}
.logo-text {
  font-size: 14px; font-weight: 700; letter-spacing: 0.02em; color: rgba(255,255,255,0.9);
}
.logo-divider { width: 1px; height: 22px; background: rgba(255,255,255,0.25); }
.header .badge {
  display: inline-flex;
  background: rgba(var(--accent-rgb, 197, 150, 58), 0.2);
  border: 1px solid rgba(var(--accent-rgb, 197, 150, 58), 0.4);
  color: var(--accent-light);
  font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
  text-transform: uppercase; padding: 3px 12px; border-radius: 100px; margin-bottom: 12px;
}
.header h1 {
  font-size: 24px; font-weight: 800; letter-spacing: -0.025em; margin-bottom: 6px; line-height: 1.15;
}
.header h1 span { color: var(--accent); }
.header p {
  color: rgba(255,255,255,0.6); font-size: 11px; max-width: 620px; line-height: 1.45;
}
```

```html
<div class="header">
  <div class="header-inner">
    <div class="logo-row">
      <div class="logo-text">[Customer Name]</div>
      <div class="logo-divider"></div>
      <!-- Use inline SVG from assets/spectrocloud-logo-horizontal.svg with style="color: #fff; height: 18px;" -->
    </div>
    <div class="badge">[Badge Text] &mdash; [Quarter/Year]</div>
    <h1>[Title Line 1]<br>[Title Line 2] <span>[Accent Word]</span></h1>
    <p>[Executive summary paragraph — 2-3 sentences max]</p>
  </div>
</div>
```

---

## 2. Section Title

Uppercase label with gold accent bar. Used before every content section.

```css
.section-title {
  font-size: 10px; font-weight: 700; letter-spacing: 0.1em;
  text-transform: uppercase; color: var(--primary-mid);
  margin-bottom: 8px; display: flex; align-items: center; gap: 7px;
}
.section-title::before {
  content: ''; width: 3px; height: 12px;
  background: var(--accent); border-radius: 2px;
}
```

---

## 3. Stat Cards

4-column grid with large numbers. Good for KPIs, environment summary.

```css
.stat-grid {
  display: grid; grid-template-columns: repeat(4, 1fr);
  gap: 8px; margin-bottom: 10px;
}
.stat-card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 8px 12px;
  text-align: center; position: relative; overflow: hidden;
}
.stat-card::before {
  content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px;
  background: linear-gradient(90deg, var(--primary-mid), var(--accent));
}
.stat-card .stat-number { font-size: 22px; font-weight: 800; color: var(--primary-mid); letter-spacing: -0.03em; line-height: 1.1; }
.stat-card .stat-label { font-size: 10px; font-weight: 600; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.05em; margin-top: 2px; }
.stat-card .stat-detail { font-size: 9px; color: var(--accent-dim); margin-top: 4px; line-height: 1.4; }
```

```html
<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-number">56</div>
    <div class="stat-label">ESXi Hosts</div>
    <div class="stat-detail">Cisco UCS B200 blades</div>
  </div>
  <!-- repeat for each stat -->
</div>
```

---

## 4. Data Strip

Horizontal segmented bar — good for data centers, phases, or category breakdowns.

```css
.dc-strip {
  display: flex; gap: 0; margin-bottom: 10px;
  border-radius: var(--radius); overflow: hidden; border: 1px solid var(--border);
}
.dc-strip-item {
  flex: 1; text-align: center; padding: 8px 8px;
  background: var(--surface); border-right: 1px solid var(--border);
}
.dc-strip-item:last-child { border-right: none; }
.dc-strip-item .dc-name { font-size: 10px; font-weight: 700; color: var(--ink); margin-bottom: 2px; }
.dc-strip-item .dc-hosts { font-size: 16px; font-weight: 800; color: var(--primary-mid); }
.dc-strip-item .dc-label { font-size: 9px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.05em; }
.dc-strip-item .dc-vms { font-size: 10px; color: var(--accent-dim); font-weight: 600; margin-top: 3px; }
.dc-badge { display: inline-block; font-size: 7px; font-weight: 700; padding: 1px 6px; border-radius: 3px; margin-top: 3px; text-transform: uppercase; letter-spacing: 0.05em; }
.dc-badge-active { background: var(--green-glow); color: var(--green); }
.dc-badge-migrate { background: rgba(184, 50, 48, 0.08); color: var(--red); }
```

---

## 5. Hardware / Stack Table

Compact table with themed header.

```css
.hw-table {
  width: 100%; border-collapse: collapse; margin-bottom: 10px;
  font-size: 10px; border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden;
}
.hw-table th {
  background: var(--primary); color: rgba(255,255,255,0.85);
  font-weight: 700; font-size: 9px; text-transform: uppercase;
  letter-spacing: 0.08em; padding: 5px 10px; text-align: left;
}
.hw-table td {
  padding: 4px 10px; border-bottom: 1px solid var(--border);
  color: var(--text-dim); background: var(--surface);
}
.hw-table tr:last-child td { border-bottom: none; }
.hw-table td:first-child { font-weight: 600; color: var(--ink); }
```

---

## 6. Scope Banner

Dark gradient callout with pill tags. Good for POC scope or key messages.

```css
.scope-banner {
  background: linear-gradient(135deg, var(--primary), var(--primary-mid));
  border-radius: var(--radius); padding: 14px 18px; margin-bottom: 10px;
  color: #fff; position: relative; overflow: hidden;
}
.scope-banner h2 { font-size: 15px; font-weight: 800; margin-bottom: 5px; }
.scope-banner h2 span { color: var(--accent); }
.scope-banner p { font-size: 11px; color: rgba(255,255,255,0.65); line-height: 1.55; max-width: 620px; }
.scope-pills { display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap; }
.scope-pill {
  background: rgba(255,255,255,0.10); border: 1px solid rgba(255,255,255,0.18);
  border-radius: 100px; padding: 3px 12px; font-size: 9px; font-weight: 600; color: rgba(255,255,255,0.8);
}
```

---

## 7. Track Cards

Side-by-side cards with icon headers and bullet lists.

```css
.track-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 14px; }
.track-card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden; }
.track-card-header { padding: 10px 14px; border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 8px; }
.track-card-header h4 { font-size: 12px; font-weight: 700; color: var(--ink); }
.track-card-body { padding: 12px 14px; }
.track-card-body ul { list-style: none; }
.track-card-body li { font-size: 10px; color: var(--text-dim); padding: 2px 0; display: flex; align-items: baseline; gap: 6px; line-height: 1.45; }
.track-card-body li::before { content: ''; width: 4px; height: 4px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
.dot-navy li::before { background: var(--primary-mid); }
.dot-accent li::before { background: var(--accent); }
.dot-teal li::before { background: var(--teal); }
```

---

## 8. Stack Strip

Horizontal component strip with icons and labels. Good for technology stacks.

```css
.stack-strip {
  display: flex; gap: 0; margin-bottom: 12px;
  border-radius: var(--radius); overflow: hidden; border: 1px solid var(--border);
}
.stack-strip-item {
  flex: 1; text-align: center; padding: 10px 6px;
  background: var(--surface); border-right: 1px solid var(--border);
}
.stack-strip-item:last-child { border-right: none; }
.stack-strip-item .stack-icon { font-size: 16px; margin-bottom: 2px; }
.stack-strip-item .stack-label { font-size: 9px; font-weight: 700; color: var(--ink); line-height: 1.3; }
.stack-strip-item .stack-desc { font-size: 8px; color: var(--text-dim); }
```

---

## 9. Integration Pills

Inline badges with colored dots.

```css
.integration-row { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px; }
.int-pill {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 100px; padding: 5px 14px; font-size: 10px;
  font-weight: 600; color: var(--primary-mid); display: flex; align-items: center; gap: 5px;
}
.int-pill .int-dot { width: 6px; height: 6px; border-radius: 50%; }
```

---

## 10. Success Box

2-column criteria grid with icon header.

```css
.success-box {
  background: linear-gradient(135deg, rgba(var(--accent-rgb, 197, 150, 58), 0.06), rgba(var(--primary-rgb, 22, 45, 80), 0.04));
  border: 1px solid rgba(var(--accent-rgb, 197, 150, 58), 0.25);
  border-radius: var(--radius); padding: 14px 18px; margin-bottom: 12px;
}
.success-box h4 { font-size: 11px; font-weight: 700; color: var(--primary-mid); margin-bottom: 8px; display: flex; align-items: center; gap: 6px; }
.success-box ul { list-style: none; display: grid; grid-template-columns: 1fr 1fr; gap: 3px 16px; }
.success-box li { font-size: 10px; color: var(--text-dim); display: flex; align-items: baseline; gap: 6px; line-height: 1.45; }
.success-box li::before { content: ''; width: 5px; height: 5px; border-radius: 50%; background: var(--accent); flex-shrink: 0; margin-top: 4px; }
```

---

## 11. Timeline

Horizontal timeline with gradient connector and dots.

```css
.timeline { display: flex; gap: 0; margin-bottom: 12px; position: relative; }
.timeline::before {
  content: ''; position: absolute; top: 14px; left: 0; right: 0; height: 3px;
  background: linear-gradient(90deg, var(--primary), var(--accent), var(--green));
  border-radius: 2px; z-index: 0;
}
.timeline-step { flex: 1; text-align: center; position: relative; z-index: 1; }
.timeline-step .tl-dot {
  width: 10px; height: 10px; border-radius: 50%;
  background: var(--primary-mid); border: 2px solid var(--surface);
  margin: 9px auto 6px; box-shadow: 0 0 0 2px var(--primary-mid);
}
.timeline-step .tl-label { font-size: 9px; font-weight: 700; color: var(--ink); margin-bottom: 1px; }
.timeline-step .tl-desc { font-size: 8px; color: var(--text-dim); line-height: 1.35; padding: 0 4px; }
```

---

## 12. Verdict Cards

Icon + text cards for key decisions or approach summaries.

```css
.verdict {
  background: linear-gradient(135deg, rgba(var(--primary-rgb, 22, 45, 80), 0.05), rgba(var(--accent-rgb, 197, 150, 58), 0.04));
  border: 1px solid rgba(var(--primary-rgb, 22, 45, 80), 0.18);
  border-radius: var(--radius); padding: 14px 18px; display: flex; align-items: flex-start; gap: 12px;
}
.verdict-icon {
  width: 30px; height: 30px; border-radius: 50%;
  background: var(--accent-glow-strong);
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.verdict h4 { font-size: 12px; font-weight: 700; color: var(--ink); margin-bottom: 2px; }
.verdict p { font-size: 10px; color: var(--text-dim); line-height: 1.5; }
```

---

## 13. Callout

Bordered text box for next steps or important notes.

```css
.callout {
  font-size: 10px; color: var(--text-dim);
  padding: 8px 12px; background: var(--paper);
  border-radius: var(--radius-sm); border: 1px solid var(--border); line-height: 1.45;
}
.callout strong { color: var(--ink); }
```

---

## 14. Page Footer

Use the inline SVG logo from `assets/spectrocloud-logo-horizontal.svg`. The SVG uses `currentcolor` for the wordmark — set `color` on the footer SVG to control it (e.g., `color: var(--ink)`). The Strata mark always renders in brand teals.

```css
.page-footer {
  display: flex; align-items: center; justify-content: space-between;
  padding: 8px 34px 0; border-top: 2px solid var(--teal); margin-top: auto;
}
.page-footer .footer-left { font-size: 9px; color: var(--text-dim); }
.page-footer .footer-right { display: flex; align-items: center; gap: 10px; }
.page-footer .footer-page { font-size: 8px; font-weight: 700; color: var(--primary-mid); letter-spacing: 0.05em; text-transform: uppercase; }
.page-footer svg { height: 14px; opacity: 0.6; color: var(--ink); }
```

## Customer Brand Color Examples

| Customer | Primary | Accent | Notes |
|----------|---------|--------|-------|
| **SC-only** | `#043736` dark teal | `#F0BE65` gold leaf | Use for SC-branded docs without customer co-branding |
| Bank OZK | `#0A1628` navy | `#C5963A` gold | Banking = conservative, professional |
| GlobalFoundries | `#43007A` purple | `#FF6012` orange | Semiconductor = bold, technical |
| Toyota | `#CC0000` red | `#1A1A1A` black | Automotive = strong, confident |
| Taco Bell | `#702082` purple | `#E4002B` magenta | QSR = vibrant, energetic |
| PayPal | `#003087` blue | `#009CDE` light blue | Fintech = trustworthy, modern |
| Blue Yonder | `#0033A0` blue | `#00B0F0` cyan | Supply chain = clean, precise |

## Spectro Cloud 2025 Brand Palette Reference

Primary palette (use for SC elements):
- Tranquil Teal: `#1F7A78` / Dark: `#005B5B` / Darkest: `#043736`
- Tea Green: `#9EB277` / Dark: `#5D823C`
- Gold Leaf: `#F0BE65` / Dark: `#DE8D2A` / Darkest: `#851A01`
- Sunset Orange: `#B94B01`
- Soft Lilac: `#7E5C8E` / Dark: `#441647`

Overlap palette (where brand colors meet in folded graphics):
- Teal + Gold: `#175B17`
- Teal + Orange: `#062305`
- Orange + Gold: `#AD3805`
- Teal + Green: `#1E5434`

Neutrals: Paper `#F7F1ED` → `#E0DCD7` → `#BEB9B6` → `#9E9C9C` → `#3C4949` → `#1E3332` → Ink `#012121`
