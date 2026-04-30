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
      <svg xmlns="http://www.w3.org/2000/svg" width="74" height="28" viewBox="0 0 148 57" fill="none" fill-rule="evenodd" style="height: 18px; width: auto; color: #fff;">
        <path d="M21.4869 56.089L0.948352 39.9029C-0.142452 39.0427-0.142452 37.3902 0.948352 36.53L21.4869 20.3058C22.6074 19.4202 24.1863 19.4202 25.3068 20.3058L45.8453 36.53C46.9361 37.3902 46.9361 39.0427 45.8453 39.9029L25.3068 56.089C24.1905 56.9703 22.6116 56.9703 21.4911 56.089H21.4869Z" fill="currentcolor"/>
        <path d="M45.8029 36.5088L24.9333 20.0812C23.9358 19.2931 22.7007 18.8651 21.4274 18.8651L1.74201 18.8312C0.880403 18.8312 0.447477 18.6744 0.260725 18.0854C0.163104 18.3524 0.12915 18.6066 0.12915 18.8015C0.12915 19.1956 0.226771 19.9371 0.978025 20.5346L21.8476 36.9791C22.8493 37.7673 24.0844 38.1952 25.3577 38.1995L45.094 38.2164C45.9175 38.2249 46.3419 38.3859 46.5202 38.9579C46.6178 38.691 46.6517 38.4367 46.6517 38.2418C46.6517 37.8435 46.5541 37.102 45.8029 36.5088Z" fill="currentcolor" opacity="0.6"/>
        <path d="M45.8368 17.1321L25.3025 0.907834C24.182 0.0222584 22.6031 0.0222584 21.4826 0.907834L0.94408 17.1321C-0.146724 17.9922-0.146724 19.6448 0.94408 20.5049L21.3213 36.5639C21.3425 36.5936 21.3723 36.619 21.4104 36.6529C22.5607 37.5766 23.1506 37.8012 23.9189 38.013C24.6914 38.2249 25.3535 38.1995 25.6251 38.1995H26.6523C25.9647 38.1063 25.6676 37.691 25.5699 37.3563C25.4426 36.9241 25.6548 36.4622 26.058 36.0936L45.8283 20.5134C46.9191 19.6532 46.9191 18.0007 45.8283 17.1406L45.8368 17.1321Z" fill="currentcolor"/>
        <path d="M26.0666 36.0851L35.6631 28.5217L24.9333 20.0727C23.9359 19.2846 22.7008 18.8566 21.4275 18.8566L1.74205 18.8227C0.88044 18.8227 0.443271 18.6617 0.260762 18.0728C0.120698 18.4753 0.112208 18.7761 0.150408 19.0897C0.188607 19.4117 0.328671 19.7888 0.540889 20.077C0.655488 20.2295 0.799797 20.382 0.982305 20.5261L21.3256 36.5597C21.3256 36.5597 21.8094 36.9749 22.2594 37.2673C22.7814 37.602 23.3459 37.8563 23.9444 38.0088C23.9529 38.0088 23.9613 38.013 23.9741 38.0173C24.424 38.1317 24.8909 38.191 25.362 38.191H26.6608C25.9732 38.102 25.6761 37.6825 25.5785 37.3478C25.4511 36.9156 25.6633 36.4537 26.0666 36.0851Z" fill="currentcolor" opacity="0.7"/>
        <path d="M60.9893 20.6785H63.8372C63.8372 21.8988 65.136 22.7928 66.6173 22.7928C68.332 22.7928 69.3719 21.8776 69.3719 20.7632C69.3719 19.3014 68.4678 18.9539 66.3159 18.3438C64.3253 17.776 61.4519 17.0557 61.4519 13.81C61.4519 11.2804 63.8839 9.25073 66.9399 9.25073C69.9958 9.25073 72.3599 11.2804 72.3599 13.8311H69.4865C69.4865 12.6108 68.3999 11.7803 66.9144 11.7803C65.3185 11.7803 64.3211 12.5854 64.3211 13.6108C64.3211 14.6362 64.9705 15.1574 67.0757 15.7676C69.1851 16.3565 72.2411 17.0557 72.2411 20.6319C72.2411 23.3352 69.7157 25.3648 66.5918 25.3648C63.468 25.3648 60.9893 23.2505 60.9893 20.6785Z" fill="currentcolor"/>
        <path d="M75.208 12.9923H77.8862V15.4287H77.9753C78.7181 13.755 80.5899 12.666 82.6611 12.666C85.9293 12.666 88.4589 15.4922 88.4589 19.0176C88.4589 22.5429 85.9293 25.3692 82.6611 25.3692C80.679 25.3692 79.0874 24.5217 78.0432 22.7167H77.9541V27.1191L75.208 29.2165V12.9923Z" fill="currentcolor"/>
        <path d="M85.6449 19.0176C85.6449 16.7125 83.9684 15.2338 81.9396 15.2338C79.9108 15.2338 78.2767 16.7125 78.2767 19.0176C78.2767 21.3226 79.932 22.8014 81.9396 22.8014C83.9472 22.8014 85.6449 21.3226 85.6449 19.0176Z" fill="currentcolor"/>
        <path d="M90.0802 18.954C90.0802 15.4287 92.9579 12.666 96.6378 12.666C100.318 12.666 103.195 15.4287 103.195 19.0388C103.195 19.2337 103.174 19.5811 103.106 19.9074H92.9961C93.3017 21.5599 94.8466 22.8014 96.6802 22.8014C98.1191 22.8014 99.316 22.1277 99.8847 20.9074H102.894C102.045 23.4963 99.647 25.3437 96.6378 25.3437C92.9536 25.3437 90.0802 22.4709 90.0802 18.9498V18.954Z" fill="currentcolor"/>
        <path d="M100.169 17.8439C99.9272 16.4075 98.5138 15.2126 96.5953 15.2126C94.6769 15.2126 93.238 16.3227 93.0428 17.8439H100.169Z" fill="currentcolor"/>
        <path d="M105.003 18.9541C105.003 15.4287 107.881 12.5813 111.434 12.5813C113.263 12.5813 114.944 13.3652 116.098 14.5813L114.333 16.3863C113.658 15.6236 112.656 15.1448 111.434 15.1448C109.384 15.1448 107.75 16.7973 107.75 18.9541C107.75 21.1108 109.384 22.7845 111.434 22.7845C112.588 22.7845 113.505 22.3692 114.18 21.6955L115.945 23.4794C114.791 24.6531 113.199 25.3522 111.434 25.3522C107.881 25.3522 105.003 22.5006 105.003 18.9583V18.9541Z" fill="currentcolor"/>
        <path d="M118.356 11.7423L121.081 9.59399V12.9922H124.018V15.5388H121.081V22.4793H123.955V25.0259H118.356V11.7465V11.7423Z" fill="currentcolor"/>
        <path d="M126.718 12.9922H133.976V15.5387H129.464V25.0216H126.718V12.9922Z" fill="currentcolor"/>
        <path d="M134.909 19.0174C134.909 15.4709 137.787 12.687 141.314 12.687C144.841 12.687 147.723 15.4709 147.723 19.0174C147.723 22.5639 144.845 25.3478 141.314 25.3478C137.783 25.3478 134.909 22.475 134.909 19.0174Z" fill="currentcolor"/>
        <path d="M145.019 19.0174C145.019 16.6912 143.364 15.2548 141.314 15.2548C139.264 15.2548 137.655 16.6912 137.655 19.0174C137.655 21.3436 139.289 22.78 141.314 22.78C143.339 22.78 145.019 21.2589 145.019 19.0174Z" fill="currentcolor"/>
        <path d="M80.5304 41.6271C80.5304 38.123 83.3869 35.3391 86.8927 35.3391C90.3986 35.3391 93.255 38.123 93.255 41.6271C93.255 45.1313 90.3986 47.9151 86.8927 47.9151C83.3869 47.9151 80.5304 45.0635 80.5304 41.6271Z" fill="currentcolor"/>
        <path d="M91.5318 41.6271C91.5318 38.9068 89.4393 36.9704 86.8885 36.9704C84.3376 36.9704 82.2239 38.9068 82.2239 41.6271C82.2239 44.3474 84.3164 46.2838 86.8885 46.2838C89.4606 46.2838 91.5318 44.2627 91.5318 41.6271Z" fill="currentcolor"/>
        <path d="M95.5343 42.9958V35.623H97.2575V43.0848C97.2575 45.1737 98.6751 46.2838 100.526 46.2838C102.376 46.2838 103.815 45.1525 103.815 43.0848V35.623H105.513V42.9958C105.513 46.0423 103.357 47.9109 100.521 47.9109C97.6862 47.9109 95.53 46.0381 95.53 42.9958H95.5343Z" fill="currentcolor"/>
        <path d="M107.847 41.6018C107.847 38.0765 110.483 35.2926 113.883 35.2926C116.302 35.2926 118.153 36.6613 119.001 38.5765H119.091V32.2461H120.788V47.5594H119.112V44.6018H119.048C118.068 46.7966 116.107 47.9068 113.883 47.9068C110.483 47.9068 107.847 45.0552 107.847 41.5976V41.6018Z" fill="currentcolor"/>
        <path d="M118.853 41.6018C118.853 38.9494 116.871 36.9028 114.256 36.9028C111.642 36.9028 109.617 38.9494 109.617 41.6018C109.617 44.2543 111.599 46.2797 114.256 46.2797C116.913 46.2797 118.853 44.212 118.853 41.6018Z" fill="currentcolor"/>
        <path d="M76.9906 45.9534V31.4241L75.2886 32.763V47.5848H79.0618V45.9534H76.9906Z" fill="currentcolor"/>
        <path d="M67.428 46.2584C63.9434 46.2584 61.1973 43.5169 61.1973 39.8644C61.1973 36.212 63.9434 33.5764 67.428 33.5764C69.2361 33.5764 70.7981 34.2501 71.961 35.3306L73.0009 34.229C71.5705 32.8137 69.5714 31.9197 67.428 31.9197C62.9842 31.9197 59.4104 35.4238 59.4104 39.8602C59.4104 44.2966 62.9842 47.9109 67.428 47.9109C69.5842 47.9109 71.5705 47.0168 73.0051 45.5847L71.9355 44.4533C70.8023 45.5635 69.2319 46.2584 67.4238 46.2584H67.428Z" fill="currentcolor"/>
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
