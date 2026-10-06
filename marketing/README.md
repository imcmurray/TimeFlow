# TimeFlow marketing and press kit

Logos and artwork for T-shirts, merch, press and social media. Every file is a
PNG generated from the logo SVG (`assets/branding/timeflow-logo.svg`) and the
app's own typeface, Nunito, by:

```bash
swift scripts/generate_marketing_assets.swift
```

Don't edit the PNGs by hand: change the script and run it again.

**Vector logos:** `logo/mark/timeflow-mark.svg` (full colour) and the one-colour
`timeflow-mark-white.svg` / `timeflow-mark-black.svg`, which separate the two
halves of the mark with an outline so it still reads in a single ink. Give
printers these when they ask for vector files. (Sources:
`assets/branding/timeflow-logo*.svg`.)

**The 800, 1000 and 1500 DPI print sets aren't in the repository** (they're
about 32 MB). Download them as
[timeflow-print-high-res.zip](https://github.com/imcmurray/TimeFlow/releases/tag/press-kit-1)
from the *press-kit-1* release, or regenerate them with the script (git
ignores those folders, so regenerating doesn't add them to the repository).

## Which file do I use?

| I need… | Use |
|---|---|
| A T-shirt front (big design) | `print/300dpi/tshirt-front-15x18in-*.png` |
| A small chest logo | `print/<dpi>/tshirt-chest-4x4in-*.png` |
| Text across the back of a shirt | `print/<dpi>/tshirt-back-12x3in-wordmark-*.png` |
| A single-colour screen print (one ink) | the `white`, `black` or `blue` files |
| A logo for an article or website | `logo/wordmark/` (light or dark background) |
| A square logo (avatar, profile picture) | `logo/mark/` or `press/app-icon-*.png` |
| A header image for a press release | `press/banner-1600x900-*.png` |
| A link-preview / social share image | `press/social-1200x630.png` |

### "For light shirts" vs "for dark shirts"

- **for light shirts**: blue mark, blue "TimeFlow", dark-grey tagline.
- **for dark shirts**: blue mark, white text.
- **one-color white / black / blue**: everything in one ink, for one-colour screen printing (cheaper, and works on any colour shirt).

## Print resolutions (DPI)

Print files live in `print/<dpi>dpi/`. Each one comes at the same physical size
in several resolutions, and the DPI is stored in the PNG, so print software
opens it at the right size. Only `300dpi` is in the repository; the others
are in the high-res download above.

| Folder | Use it for |
|---|---|
| `300dpi` | **Most printing.** T-shirts (DTG, DTF, screen print), stickers, posters. Printers ask for 300 DPI. |
| `800dpi` (download) | Fine printing and enlarging a little without softening. |
| `1000dpi` (download) | High-end print, embroidery digitising, large enlargements. |
| `1500dpi` (download) | Maximum detail, archival masters. Very large files. |

The 15×18 in T-shirt front only comes in 300 DPI. At 1500 DPI it would be
22,500×27,000 pixels, which print shops and most image apps won't open.

## Screen resolutions

`logo/` and `press/` are for screens (72 DPI). Pick the pixel size you need:
marks from 256 to 4096 px, wordmarks at 1200, 2400 and 4800 px wide, stacked
lockups at 1024 and 2048 px.

## Beta testers

Badges, stickers and banners for the timeflow-testers group ("Since v1.0.0
(183)", "CAUTION: BETA TESTER" and friends) are in [testers/](testers/).

## Brand basics

- **Name:** TimeFlow (one word, capital T and F). On the App Store it's listed as *TimeFlow Planner*.
- **Tagline:** *Your day as a gentle river*
- **Typeface:** [Nunito](https://fonts.google.com/specimen/Nunito) Bold for the name, SemiBold for the tagline (SIL Open Font License, see `assets/fonts/OFL.txt`).
- **Colours:**

| Name | Hex | Use |
|---|---|---|
| River blue | `#42A5F5` | Main logo colour |
| Deep blue | `#1976D2` | Logo shading |
| Ink blue | `#1A6FC8` | "TimeFlow" text on light backgrounds |
| Paper | `#FAFAFA` | Light background |
| Night | `#121212` | Dark background |

- **Clear space:** leave at least half the mark's height empty around any logo.
- **Please don't:** stretch or squash the logo, recolour parts of it, add effects (shadows, outlines, glows), or put the full-colour mark on a busy photo; use a one-colour version instead.

## About

TimeFlow is made by [Rinse Repeat Labs](https://rinserepeatlabs.com/), Ian
McMurray's studio. Press and support:
https://imcmurray.github.io/TimeFlow/support.html
