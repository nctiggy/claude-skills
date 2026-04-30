---
name: exec-doc-generator
description: Generate polished 2-page executive PDF documents (HTML+Puppeteer). Merges customer brand colors with Spectro Cloud branding. Pinned footers, stat cards, timelines, and professional layouts.
---

# Executive Document Generator

Build polished, executive-grade 2-page PDF documents as HTML files rendered via Puppeteer. Used for customer-facing POC overviews, solution summaries, architecture briefs, and similar deliverables.

## When to Use

- User asks for an executive summary, POC overview, or customer-facing doc
- User wants a "nice looking" or "PDF" document for a customer
- Building deliverables for customer leadership or stakeholders

## Design System

### Page Layout Rules

**CRITICAL — these are non-negotiable:**

1. **Exactly 2 pages** — content must fit cleanly, no spill
2. **Pinned footers** on every page — footer sticks to page bottom regardless of content height
3. **Page structure** uses flex column with `min-height: 100vh` and footer with `margin-top: auto`
4. **Letter size** with tight margins: `@page { size: letter; margin: 12px 22px; }`
5. **Print-safe colors** — always set `-webkit-print-color-adjust: exact`

### Spectro Cloud Brand

READ the `spectrocloud-brand` skill for the complete 2025 brand palette, design principles, logos, icons, and messaging. Key values for quick reference:

| Token | Hex | Role |
|-------|-----|------|
| Tranquil Teal | `#1F7A78` | SC identity, `--teal` |
| Paper | `#F7F1ED` | Brand background, `--paper` |
| Ink | `#012121` | Brand text, `--ink` |
| Gold Leaf | `#F0BE65` | Warm accent |
| Tea Green | `#9EB277` | Soft accent |

### Color Scheme Strategy

**Always merge customer brand colors with Spectro Cloud teal.** Extract 2-3 primary colors from the customer's website/brand:

| Role | Purpose | Example (banking customer) |
|------|---------|---------------------------|
| `--primary` | Headers, stat numbers, borders | Deep navy `#0A1628` |
| `--primary-mid` | Secondary elements, badges | Mid navy `#162D50` |
| `--accent` | Highlights, decorative accents | Gold `#C5963A` |
| `--teal` | Spectro Cloud identity (always present) | `#1F7A78` |
| `--green` | Success/positive indicators | `#1A7A4C` |
| `--ink` | Body text | `#012121` |
| `--paper` | Page background | Warm cream `#F7F1ED` |
| `--surface` | Card backgrounds | White |
| `--border` | Card/table borders | Light gray `#D0D5DD` |
| `--text-dim` | Secondary text | Muted gray `#4A5568` |

Also define glow variants for subtle backgrounds:
- `--accent-glow: rgba(accent, 0.10)`
- `--primary-glow: rgba(primary, 0.06)`

**For SC-only docs (no customer co-branding):**
Use the SC palette directly: `--primary: #043736`, `--accent: #F0BE65`, `--teal: #1F7A78`. Use Tea Green or Gold Leaf for highlights. Keep Paper `#F7F1ED` as background.

**How to pick customer colors:**
- Visit the customer's website, note their primary brand color and a secondary/accent
- Dark colors → use for `--primary` (headers, stats)
- Bright/accent colors → use for `--accent` (highlights, decorative elements)
- When in doubt, use deep blues/grays as primary — they're universally professional
- The `--teal` and `--paper` values should always reflect Spectro Cloud branding

### Typography

- **Font:** Plus Jakarta Sans (Google Fonts) — always include the import. Fallback: Trebuchet MS
- **Brand weight hierarchy:** ExtraLight (200) for display headlines, Medium (500) for subheads, Regular (400) for body, Light (300) for quotes
- **Exec doc weight hierarchy** (compact 2-page format needs heavier weights for legibility at small sizes): 800 for h1/stats, 700 for section titles, 600 for labels, 400 for body
- **Sizes:** h1: 24px, section titles: 10px uppercase, body: 10-11px, labels: 9px, fine print: 8px
- **Import:** Include weights 200-800: `wght@200;300;400;500;600;700;800`

### Component Library

READ the `references/components.md` file for the full HTML/CSS component patterns. Key components:

1. **Header** — Gradient banner with logo row, badge, h1, and executive summary paragraph
2. **Stat Cards** — 4-column grid with large numbers, labels, and detail text
3. **Data Strip** — Horizontal segmented bar (e.g., data centers, phases)
4. **Hardware/Stack Table** — Compact table with themed header row
5. **Scope Banner** — Dark gradient callout with pill tags
6. **Track Cards** — Side-by-side cards with icon headers and bullet lists
7. **Stack Strip** — Horizontal component strip with icons and labels
8. **Integration Pills** — Inline pill badges with colored dots
9. **Success Box** — 2-column criteria grid with checkmark header
10. **Timeline** — Horizontal timeline with dots and gradient connector
11. **Callout** — Bordered text box for next steps or key info
12. **Verdict Cards** — Icon + text cards for key decisions

### Page Footer Pattern

Use the inline SVG logo (from `assets/spectrocloud-logo-horizontal.svg`). The SVG uses `currentcolor` for the wordmark text, so set `color` on the container to control text color. The Strata mark uses the actual brand teals (#1F7A78, #043736, #005B5B).

```html
<div class="page-footer">
  <div class="footer-left">Confidential — Prepared for [Customer] Leadership</div>
  <div class="footer-right">
    <div class="footer-page">Page N of 2</div>
    <svg xmlns="http://www.w3.org/2000/svg" width="74" height="28" viewBox="0 0 148 57" fill="none" fill-rule="evenodd" style="color: var(--ink);">
      <!-- Strata mark (brand teals) -->
      <path d="M21.4869 56.089L0.948352 39.9029C-0.142452 39.0427-0.142452 37.3902 0.948352 36.53L21.4869 20.3058C22.6074 19.4202 24.1863 19.4202 25.3068 20.3058L45.8453 36.53C46.9361 37.3902 46.9361 39.0427 45.8453 39.9029L25.3068 56.089C24.1905 56.9703 22.6116 56.9703 21.4911 56.089H21.4869Z" fill="#1F7A78"/>
      <path d="M45.8029 36.5088L24.9333 20.0812C23.9358 19.2931 22.7007 18.8651 21.4274 18.8651L1.74201 18.8312C0.880403 18.8312 0.447477 18.6744 0.260725 18.0854C0.163104 18.3524 0.12915 18.6066 0.12915 18.8015C0.12915 19.1956 0.226771 19.9371 0.978025 20.5346L21.8476 36.9791C22.8493 37.7673 24.0844 38.1952 25.3577 38.1995L45.094 38.2164C45.9175 38.2249 46.3419 38.3859 46.5202 38.9579C46.6178 38.691 46.6517 38.4367 46.6517 38.2418C46.6517 37.8435 46.5541 37.102 45.8029 36.5088Z" fill="#043736"/>
      <path d="M45.8368 17.1321L25.3025 0.907834C24.182 0.0222584 22.6031 0.0222584 21.4826 0.907834L0.94408 17.1321C-0.146724 17.9922-0.146724 19.6448 0.94408 20.5049L21.3213 36.5639C21.3425 36.5936 21.3723 36.619 21.4104 36.6529C22.5607 37.5766 23.1506 37.8012 23.9189 38.013C24.6914 38.2249 25.3535 38.1995 25.6251 38.1995H26.6523C25.9647 38.1063 25.6676 37.691 25.5699 37.3563C25.4426 36.9241 25.6548 36.4622 26.058 36.0936L45.8283 20.5134C46.9191 19.6532 46.9191 18.0007 45.8283 17.1406L45.8368 17.1321Z" fill="#1F7A78"/>
      <path d="M26.0666 36.0851L35.6631 28.5217L24.9333 20.0727C23.9359 19.2846 22.7008 18.8566 21.4275 18.8566L1.74205 18.8227C0.88044 18.8227 0.443271 18.6617 0.260762 18.0728C0.120698 18.4753 0.112208 18.7761 0.150408 19.0897C0.188607 19.4117 0.328671 19.7888 0.540889 20.077C0.655488 20.2295 0.799797 20.382 0.982305 20.5261L21.3256 36.5597C21.3256 36.5597 21.8094 36.9749 22.2594 37.2673C22.7814 37.602 23.3459 37.8563 23.9444 38.0088C23.9529 38.0088 23.9613 38.013 23.9741 38.0173C24.424 38.1317 24.8909 38.191 25.362 38.191H26.6608C25.9732 38.102 25.6761 37.6825 25.5785 37.3478C25.4511 36.9156 25.6633 36.4537 26.0666 36.0851Z" fill="#005B5B"/>
      <!-- Wordmark (uses currentcolor) -->
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
</div>
```

The SVG wordmark uses `currentcolor`, so set `color` on the parent to control the text portion. The full SVG source is in `assets/spectrocloud-logo-horizontal.svg`.

**Two logo SVG variants (both in `assets/`):**
- **Footer (light background):** `spectrocloud-logo-horizontal.svg` — Strata mark in brand teals, wordmark in `currentcolor` (set `color: var(--ink)`)
- **Header (dark background):** `spectrocloud-logo-horizontal-knockout-white.svg` — Official knockout white, all paths `fill="#fff"`. This is the approved asset from the Spectro Brand 2025 Google Drive.

See `references/components.md` for the full inline SVG in both header and footer patterns.

### Easter Egg (REQUIRED)

Every generated document MUST include these meta tags in the HTML `<head>`. They appear only in PDF document properties (File > Properties), not visually on any page:

```html
<meta name="author" content="Craig Smith">
<meta name="creator" content="Yes, I made this. You're welcome.">
```

Also include an HTML comment before `</body>`:
```html
<!-- You're welcome. — CS -->
```

Always include these — no exceptions.

### Page Wrapper Pattern

Each page MUST be wrapped:

```html
<div class="page">
  <!-- header (page 1 only) -->
  <div class="header">...</div>
  <!-- content -->
  <div class="container">...</div>
  <!-- footer OUTSIDE container, INSIDE page -->
  <div class="page-footer">...</div>
</div>

<div class="page page-break">
  <div class="container">...</div>
  <div class="page-footer">...</div>
</div>
```

### CSS for Pinned Footer

```css
.page {
  min-height: calc(100vh - 24px);
  display: flex;
  flex-direction: column;
}
.page > .container, .page > .header { flex-shrink: 0; }
.page > .page-footer { margin-top: auto; }

.page-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 34px 0;
  border-top: 2px solid var(--teal);
}
```

## Puppeteer Rendering Gotchas

### Emoji Centering

Emojis have inconsistent vertical metrics across fonts/platforms in Puppeteer. When using emojis as icons (e.g., in track card headers, verdict cards, stack strips), wrap them in a flex container with explicit sizing:

```css
.icon-wrap {
  width: 28px; height: 28px;
  display: flex; align-items: center; justify-content: center;
  font-size: 16px; line-height: 1;
  flex-shrink: 0;
}
```

Do NOT rely on `vertical-align` or bare emoji text for alignment. Always use a flex centering wrapper. For circular icon backgrounds, add `border-radius: 50%; background: var(--accent-glow);` to the wrapper.

### SVG Letter Counters (fill-rule)

Letters with enclosed counters (p, o, e, d, b, a, g, etc.) have separate outer and inner paths both filled with `currentcolor`. In Puppeteer/Chrome, both paths render as solid fill, making the "holes" disappear (e.g., the hole in "o" fills solid).

**Fix:** Add `fill-rule="evenodd"` to the parent `<svg>` element. This tells the renderer to use even-odd winding, which correctly cuts out the inner paths as holes.

```html
<!-- WRONG — letters render as solid blobs -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 148 57" fill="none">

<!-- CORRECT — letter counters render properly -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 148 57" fill="none" fill-rule="evenodd">
```

This applies to the Spectro Cloud logo SVG and any other inline SVGs with text paths.

## PDF Generation

Always create a `generate-pdf.mjs` alongside the HTML:

```javascript
import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const htmlPath = path.join(__dirname, 'OUTPUT_NAME.html');
const pdfPath = path.join(__dirname, 'OUTPUT_NAME.pdf');

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();
await page.goto(`file://${htmlPath}`, { waitUntil: 'networkidle0', timeout: 30000 });
await page.pdf({
  path: pdfPath,
  format: 'letter',
  printBackground: true,
  margin: { top: '20px', right: '28px', bottom: '20px', left: '28px' },
});
await browser.close();
console.log(`PDF generated: ${pdfPath}`);
```

Ensure `package.json` has `puppeteer` as a dependency. Run `npm install` before generating.

## Workflow

1. **Identify customer brand colors** — check their website or existing materials
2. **Pick a page 1 / page 2 structure** from the templates (READ `references/components.md`)
3. **Write the HTML** with all CSS inline in a `<style>` block (no external stylesheets)
4. **Test fit** — if content spills past 2 pages, tighten padding/margins/font sizes
5. **Generate PDF** via puppeteer
6. **Iterate** — common fixes: reduce `margin-bottom`, shrink font sizes, tighten `padding`

## Typical Page 1 / Page 2 Layouts

**POC Overview:**
- P1: Header → Stat Cards → DC/Environment Strip → Infrastructure Table → Scope Banner
- P2: Approach Cards → Track Cards → Stack Strip → Integration Pills → Success Criteria → Timeline → Next Steps

**Solution Brief:**
- P1: Header → Problem Statement → Current State Cards → Challenges Grid
- P2: Solution Architecture → Benefits Cards → Comparison Table → Next Steps → Timeline

**Architecture Summary:**
- P1: Header → Architecture Diagram Description → Component Table → Integration Points
- P2: Deployment Model → Security Model → Operational Model → Timeline → Contacts

## Spacing Cheat Sheet (for fitting on 2 pages)

If content overflows, reduce in this order:
1. `@page margin` — go as low as `10px 20px`
2. `.container padding` — go as low as `10px 30px`
3. `.header padding` — reduce vertical padding
4. `margin-bottom` on components — go from 14px → 10px → 8px
5. Font sizes — reduce by 1-2px
6. Card padding — reduce by 2-4px
7. Table cell padding — reduce by 2-3px
8. As last resort, remove or combine sections
