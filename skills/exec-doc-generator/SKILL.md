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

### Color Scheme Strategy

**Always merge customer brand colors with Spectro Cloud teal.** Extract 2-3 primary colors from the customer's website/brand:

| Role | Purpose | Example (banking customer) |
|------|---------|---------------------------|
| `--primary` | Headers, stat numbers, borders | Deep navy `#0A1628` |
| `--primary-mid` | Secondary elements, badges | Mid navy `#162D50` |
| `--accent` | Highlights, decorative accents | Gold `#C5963A` |
| `--teal` | Spectro Cloud identity (always present) | `#0D7377` |
| `--green` | Success/positive indicators | `#1A7A4C` |
| `--ink` | Body text | Near-black |
| `--paper` | Page background | Light gray `#F5F6F8` |
| `--surface` | Card backgrounds | White |
| `--border` | Card/table borders | Light gray `#D0D5DD` |
| `--text-dim` | Secondary text | Muted gray `#4A5568` |

Also define glow variants for subtle backgrounds:
- `--accent-glow: rgba(accent, 0.10)`
- `--primary-glow: rgba(primary, 0.06)`

**How to pick customer colors:**
- Visit the customer's website, note their primary brand color and a secondary/accent
- Dark colors → use for `--primary` (headers, stats)
- Bright/accent colors → use for `--accent` (highlights, decorative elements)
- When in doubt, use deep blues/grays as primary — they're universally professional

### Typography

- **Font:** Plus Jakarta Sans (Google Fonts) — always include the import
- **Hierarchy:** 800 weight for h1/stats, 700 for section titles, 600 for labels, 400 for body
- **Sizes:** h1: 24px, section titles: 10px uppercase, body: 10-11px, labels: 9px, fine print: 8px

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

```html
<div class="page-footer">
  <div class="footer-left">Confidential — Prepared for [Customer] Leadership</div>
  <div class="footer-right">
    <div class="footer-page">Page N of 2</div>
    <img src="https://cdn.prod.website-files.com/64105dfa8da6a9f617932c6c/675aeef4ffab12597b98eb85_SpectroCloud_Horizontal_light-bkgd_RGB.png" alt="Spectro Cloud">
  </div>
</div>
```

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
  border-top: 2px solid var(--primary-mid);
}
```

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
