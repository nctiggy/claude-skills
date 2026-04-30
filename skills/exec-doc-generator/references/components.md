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
      <!-- Official knockout white logo from assets/spectrocloud-logo-horizontal-knockout-white.svg -->
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 501 192" fill="#fff" fill-rule="evenodd" style="height: 18px; width: auto;">
        <g><path d="M206.61,69.3h9.65c0,4.14,4.39,7.18,9.42,7.18,5.81,0,9.34-3.11,9.34-6.88,0-4.96-3.06-6.14-10.36-8.21-6.75-1.92-16.48-4.37-16.48-15.4,0-8.59,8.24-15.47,18.6-15.47s18.36,6.88,18.36,15.54h-9.73c0-4.15-3.69-6.96-8.71-6.96-5.41,0-8.79,2.74-8.79,6.22s2.2,5.25,9.34,7.33c7.14,2,17.5,4.37,17.5,16.5,0,9.18-8.55,16.06-19.15,16.06s-18.99-7.14-18.99-15.91Z"/><path d="M254.78,43.21h9.08v8.27h.3c2.51-5.69,8.86-9.38,15.88-9.38,11.08,0,19.64,9.6,19.64,21.56s-8.57,21.56-19.64,21.56c-6.72,0-12.11-2.88-15.65-9.01h-.3v14.94l-9.3,7.12v-55.07ZM290.15,63.67c0-7.83-5.69-12.85-12.55-12.85s-12.41,5.02-12.41,12.85,5.61,12.85,12.41,12.85,12.55-5.02,12.55-12.85Z"/><path d="M305.17,63.44c0-11.96,9.75-21.34,22.23-21.34s22.23,9.38,22.23,21.64c0,.66-.07,1.85-.3,2.95h-34.26c1.03,5.61,6.28,9.82,12.48,9.82,4.87,0,8.93-2.29,10.85-6.43h10.19c-2.88,8.79-11,15.06-21.19,15.06-12.48,0-22.23-9.75-22.23-21.71ZM339.36,59.68c-.81-4.87-5.61-8.93-12.11-8.93s-11.37,3.76-12.03,8.93h24.14Z"/><path d="M355.74,63.44c0-11.96,9.75-21.64,21.78-21.64,6.2,0,11.89,2.66,15.8,6.79l-5.98,6.13c-2.29-2.58-5.69-4.21-9.82-4.21-6.94,0-12.48,5.61-12.48,12.92s5.54,13,12.48,13c3.91,0,7.02-1.4,9.3-3.69l5.98,6.05c-3.91,3.99-9.3,6.35-15.29,6.35-12.04,0-21.78-9.67-21.78-21.71Z"/><path d="M400.99,38.97l9.23-7.29v11.53h9.95v8.64h-9.95v23.55h9.73v8.64h-18.96v-45.08Z"/><path d="M429.33,43.21h24.59v8.64h-15.29v32.19h-9.3v-40.83Z"/><path d="M457.08,63.67c0-12.04,9.75-21.49,21.71-21.49s21.71,9.45,21.71,21.49-9.75,21.49-21.71,21.49-21.71-9.75-21.71-21.49ZM491.34,63.67c0-7.9-5.61-12.77-12.55-12.77s-12.4,4.87-12.4,12.77,5.54,12.77,12.4,12.77,12.55-5.17,12.55-12.77Z"/><path d="M272.81,140.4c0-11.89,9.67-21.34,21.56-21.34s21.56,9.45,21.56,21.34-9.67,21.34-21.56,21.34-21.56-9.67-21.56-21.34ZM310.1,140.4c0-9.23-7.09-15.8-15.73-15.8s-15.8,6.57-15.8,15.8,7.09,15.8,15.8,15.8,15.73-6.87,15.73-15.8Z"/><path d="M323.65,145.06v-25.03h5.83v25.33c0,7.09,4.8,10.85,11.04,10.85s11.15-3.84,11.15-10.85v-25.33h5.76v25.03c0,10.34-7.31,16.69-16.91,16.69s-16.91-6.35-16.91-16.69Z"/><path d="M365.39,140.33c0-11.96,8.94-21.41,20.45-21.41,8.2,0,14.47,4.65,17.35,11.15h.3v-21.49h5.76v51.98h-5.69v-10.04h-.22c-3.32,7.46-9.97,11.22-17.5,11.22-11.52,0-20.45-9.67-20.45-21.41ZM402.68,140.33c0-9.01-6.72-15.95-15.58-15.95s-15.73,6.94-15.73,15.95,6.72,15.88,15.73,15.88,15.58-7.02,15.58-15.88Z"/><polygon points="260.82 155.1 260.82 105.78 255.06 110.33 255.06 160.64 267.83 160.64 267.83 155.1 260.82 155.1"/><path d="M228.42,156.13c-11.81,0-21.12-9.3-21.12-21.71s9.3-21.34,21.12-21.34c6.13,0,11.42,2.28,15.37,5.96l3.52-3.73c-4.85-4.81-11.62-7.84-18.89-7.84-15.06,0-27.17,11.89-27.17,26.95s12.11,27.32,27.17,27.32c7.31,0,14.03-3.03,18.9-7.9l-3.62-3.84c-3.84,3.77-9.16,6.13-15.29,6.13Z"/></g>
        <g><path d="M85.84,137.46c-6.21,0-12.32-2.13-17.19-5.98l-37.96-29.97L3.26,123.22c-3.69,2.92-3.69,8.52,0,11.43l69.48,54.85c1.89,1.49,4.17,2.24,6.45,2.24s4.56-.75,6.45-2.24l65.84-51.97-65.64-.06Z"/><path d="M84.41,67.46c-3.38-2.66-7.55-4.12-11.86-4.12l-65.78-.11c-1.5-.09-4.23-.27-5.83-2.54-.47,1.37-.5,2.39-.38,3.45.13,1.1.6,2.38,1.32,3.35.39.52.87,1.03,1.49,1.52,0,0,0,0,0,0l68.82,54.33s0,0,0,0c0,0,1.64,1.41,3.17,2.4,1.76,1.14,3.68,2,5.69,2.52.03,0,.06.01.1.02,1.52.39,3.1.59,4.7.59h1.87c-1.02-1.18-2.4-4.5.51-7.14l32.47-25.63-36.3-28.62Z"/><path d="M155.13,57.49L85.66,2.51c-1.89-1.5-4.18-2.25-6.46-2.25s-4.57.75-6.46,2.25L7.07,54.47l.11.16,65.39.11c6.2.01,12.29,2.13,17.16,5.97l36.3,28.62,1.61,1.27,27.48-21.69c3.69-2.91,3.69-8.51,0-11.43Z"/><path d="M155.02,123.14s0,0-.01,0l-27.36-21.58-1.61,1.27-27.1,21.39c-1.94,1.53-.86,4.64,1.61,4.65l52.07.05c2.79.03,4.08,1,4.83,2.52.33-.9.45-1.76.45-2.43,0-1.34-.33-3.86-2.88-5.87Z"/></g>
      </svg>
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
