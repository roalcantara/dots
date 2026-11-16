# Blog cover safe area

**Status:** approved 2026-11-16

## Intent

LinkedIn's link card shows the dev.to cover at 1.91 : 1, cropped from the center, so it keeps only the middle ~800 px
of the 1000 × 420 cover: the title and the window were cut. And at 400 px wide (the phone test, ≥ 8 px text) the
subtitle (19 px), the terminal (15.5 px) and the pill (15 px) failed. A throwaway render (variant A) showed both fixed.

## Goals, non-goals

- **Goals:** every element inside LinkedIn's crop with a margin; readable text ≥ 20 px at 1×; the author sees the crop
  and the phone view before posting.
- **Non-goals:** a second image for LinkedIn (it reads dev.to's page); dropping the window (the approved look stays);
  changing published covers.

## Approaches

1. **A safe area on the same canvas (picked):** content inside x 120–880, readable text ≥ 20 px, title 40 px.
2. A separate 1.91 : 1 image: LinkedIn takes the image from dev.to's page, which offers no second one.
3. No window: passes easily, but loses the series look and the code wink.

## Design

- `docs/blog/tools/cover.html`: side padding 120 px; subtitle, hashtags, terminal, app window text, pill and window
  name ≥ 20 px (window name 16 px is decoration; kept ≥ 16); title 40 px; window ~330 px wide; circles may bleed.
- `blog:cover` also writes `raw/00-cover-linkedin.png` (center crop, height × 1.91) and `raw/00-cover-phone.png`
  (400 px wide), with `sips` (macOS, like Chrome), and prints both paths.
- STYLE.md: the Cover row (safe area, sizes, content limits: title lines ~18 characters, subtitle ~45, terminal 3–5
  lines of ~24) and the rubric's Images row ("passes the LinkedIn crop"); the `cover.json` template notes the limits.
- Tests: the template's readable sizes ≥ 20 px and side padding ≥ 120 px; the crop width (2000 × 840 → 1604).
- This post's cover is re-rendered; the live article and LinkedIn keep the old image unless republished.
