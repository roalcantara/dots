# Omarchy-on-macOS blog post Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A dev.to draft (`post.md`), a header image and 6–7 framed, blurred screenshots of the real desktop.

**Architecture:** Raw captures go to a git-ignored `raw/`; `tools/frame.py` (Pillow via `uv run --with pillow`) blurs
listed regions, crops, and frames each into `images/`; the header is an SVG exported to PNG with the same script.

**Tech Stack:** macOS `screencapture`, yabai (staging), Python 3 + Pillow (temporary, `uv`), `rsvg`-free SVG → PNG via
Pillow-drawn header (no extra tools).

**Spec:** `docs/superpowers/specs/2026-11-12-omarchy-post-design.md`

## Global Constraints

- Header 1000 × 420 PNG; screenshots framed on a dark background matching the header, rounded corners, soft shadow.
- No readable secret, token name, email, client or repo name in any image in `images/`; `raw/` is git-ignored.
- Links only to public dots (PRs #109, #110; files `config/bin/yb`, `config/karabiner/src/bindings.ts`,
  `config/tuis.toml`, `docs/TILING.md`); kb in screenshots only.
- Voice: the FCIS post's (DISCLAIMER, ALL-CAPS labels, 💡, "vs.", references), ~1,200–1,500 words.
- Windows restored afterwards (`yb balance`), nothing committed.

## Review Focus

- A blur region that misses text after a crop → every final image is looked at (Read) before hand-over.
- Retina scale (captures are 2× or more) → regions are chosen on the actual pixel size of each capture.
- The psc picker lists real secret names → its list area is blurred entirely, not word by word.
- Window titles in the menu bar / Ghostty titles may show paths → the menu bar's app area is blurred.
- The user's Omarchy screenshot is a different size → framed on the same background, scaled to the same width.

---

### Task 1: Tooling and folders

- [ ] `docs/posts/omarchy-on-macos/{images,raw,tools}`; `raw/` added to `.gitignore` (named path).
- [ ] `tools/frame.py <in> <out> [--crop x,y,w,h] [--blur x,y,w,h ...] [--width 1600]`: crop → blur boxes (Gaussian,
  radius 18) → scale to width → rounded corners (24) → shadow → centred on a 64 px dark gradient margin.
- [ ] `tools/header.py <out>`: 1000 × 420, dark gradient, a stylised screen with tiled windows (one outlined with the
  #33ccff → #00ff99 gradient), key caps (globe, ⇧, 1) and the title "Omarchy-ish macOS".
- [ ] Verify: run both on a sample; Read the PNGs.

### Task 2: Capture and process the scenes

For each scene: stage with yabai / the app, `screencapture -x raw/<n>.png`, Read it, pick blur boxes, run
`frame.py`, Read the result.

- [ ] 01-desktop (tiled space, outline, menu bar strip) · 02-strip (menu bar crop) · 03-hotkeys-list ·
  04-hotkeys-pane · 05-omarchy-keybindings (the user's image, framed) · 06-tui-psc (list blurred) · 07-zoom (amber
  outline) · 08-scratchpad (if it stages cleanly).
- [ ] Restore the layout (`yb balance`), close staged windows.

### Task 3: The draft

- [ ] `post.md` per the spec's outline, image references `./images/<n>.png`, links to the dots PRs and files.
- [ ] Hand over: list the images to review and which ones are likely re-captures.
