# Spectro Cloud 2025 Color Palette

Complete color reference with HEX, RGB, CMYK, and Pantone values.

## Primary Palette

Color proportions below represent the recommended proportion when creating materials.

| Name | Hex | RGB | CMYK | Pantone |
|------|-----|-----|------|---------|
| **Tranquil Teal** | `#1F7A78` | 31, 122, 120 | 85, 34, 51, 11 | PMS 7718 |
| Teal (dark) | `#005B5B` | 0, 91, 91 | 92, 45, 57, 30 | PMS 7721 |
| Teal (darker) | `#004244` | 0, 66, 68 | 92, 57, 61, 46 | PMS 316 |
| Teal (darkest) | `#043736` | 4, 55, 54 | 92, 56, 65, 59 | PMS 2217 |
| **Tea Green** | `#9EB277` | 158, 178, 119 | 42, 16, 68, 0 | PMS 577 |
| Tea Green (dark) | `#5D823C` | 93, 130, 60 | 67, 30, 100, 14 | PMS 575 |
| **Gold Leaf** | `#F0BE65` | 240, 190, 101 | 5, 27, 73, 0 | PMS 141 |
| Gold Leaf (dark) | `#DE8D2A` | 222, 141, 42 | 11, 50, 100, 0 | PMS 7569 |
| **Sunset Orange** | `#B94B01` | 185, 75, 1 | 12, 78, 100, 16 | PMS 718 |
| Orange (dark) | `#851A01` | 133, 26, 1 | 27, 96, 100, 35 | PMS 7628 |
| **Soft Lilac** | `#7E5C8E` | 126, 92, 142 | 58, 73, 18, 0 | PMS 2081 |
| Lilac (dark) | `#441647` | 68, 22, 71 | 75, 100, 38, 42 | PMS 2627 |

## Overlap Palette

Colors created where two primary colors meet in folded graphics. Use ONLY to represent mixing of neighboring primary colors, never as standalone colors.

| Name | Hex | RGB | CMYK | Pantone |
|------|-----|-----|------|---------|
| Teal + Lilac | `#0C2A44` | 12, 42, 68 | 98, 80, 40, 48 | PMS 2767 |
| Teal + Orange | `#062305` | 6, 35, 5 | 80, 56, 82, 75 | PMS 546 |
| Teal + Green | `#1E5434` | 30, 84, 52 | 87, 40, 88, 40 | PMS 357 |
| Teal + Gold | `#175B17` | 23, 91, 23 | 76, 25, 100, 46 | PMS 2427 |
| Orange + Gold | `#AD3805` | 173, 56, 5 | 5, 82, 100, 28 | PMS 1675 |
| Orange + Lilac | `#591708` | 89, 23, 8 | 40, 90, 91, 56 | PMS 2449 |
| Orange + Green | `#733400` | 115, 52, 0 | 30, 78, 100, 42 | PMS 168 |
| Green + Gold | `#798E36` | 121, 142, 54 | 56, 28, 100, 6 | PMS 377 |
| Lilac + Green | `#4C383D` | 76, 56, 61 | 60, 70, 57, 48 | PMS 5185 |
| Lilac + Gold | `#754234` | 117, 66, 52 | 40, 72, 74, 36 | PMS 499 |

## Neutral Palette

Used for backgrounds and text. Creates rest for the eye.

| Name | Hex | RGB | CMYK |
|------|-----|-----|------|
| **Paper** | `#F7F1ED` | 247, 241, 237 | 2, 5, 7, 0 |
| Neutral 1 | `#E0DCD7` | 248, 221, 215 | 9, 10, 12, 0 |
| Neutral 2 | `#BEB9B6` | 190, 185, 182 | 26, 22, 24, 0 |
| Neutral 3 | `#9E9C9C` | 158, 156, 156 | 41, 34, 34, 0 |
| Neutral 4 | `#3C4949` | 60, 73, 73 | 73, 56, 58, 40 |
| Neutral 5 | `#1E3332` | 30, 51, 50 | 81, 59, 64, 60 |
| **Ink** | `#012121` | 1, 33, 33 | 85, 62, 65, 75 |

## Accessibility Contrast Grid (WCAG 2.0)

### On Paper (#F7F1ED) backgrounds

| Color | Contrast | Level |
|-------|----------|-------|
| Dark Lilac `#441647` | 12.92:1 | AAA all |
| Dark Teal `#043736` | 11.69:1 | AAA all |
| Dark Orange `#851A01` | 8.74:1 | AAA all |
| Green `#9EB277` | 7.32:1 | AAA all |
| Dark Gold `#DE8D2A` | 6.41:1 | AAA all |
| Lilac `#7E5C8E` | 4.93:1 | AA normal + large, AAA large |
| Orange `#B94B01` | 4.61:1 | AA normal + large, AAA large |
| Teal `#1F7A78` | 4.93:1 | AA normal + large, AAA large |

### On Ink (#012121) backgrounds

| Color | Contrast | Level |
|-------|----------|-------|
| Gold `#F0BE65` | 9.88:1 | AAA all |
| Green `#9EB277` | 7.32:1 | AAA all |
| Dark Gold `#DE8D2A` | 6.41:1 | AAA all |
| Teal `#1F7A78` | 3.32:1 | AA large + non-text |
| Orange `#B94B01` | 3.28:1 | AA large + non-text |
| Lilac `#7E5C8E` | 3.07:1 | AA large + non-text |

## CSS Custom Properties (for web/HTML use)

```css
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
}
```
