#!/usr/bin/env python3
# Frames a screenshot in the series look (docs/blog/STYLE.md): crop, blur sensitive boxes, scale, put it in an
# OmniWM-style window (title bar with traffic lights and the app's name, rounded corners, optional cyan focus glow)
# on the Catppuccin Mocha base with the cover's two soft circles. Boxes are in the input's pixels (x,y,w,h), applied
# after the crop.
#   uv run --with pillow docs/blog/tools/frame.py raw/01.png images/01.png --app Ghostty --focus \
#     --crop 0,0,3000,1800 --blur 100,200,400,60
import argparse

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE, MAUVE, TEAL = (30, 30, 46), (203, 166, 247), (148, 226, 213)
BAR, BAR_LINE, NAME = (42, 42, 47), (29, 29, 33), (168, 168, 176)
LIGHTS = [(236, 106, 95), (244, 191, 79), (97, 197, 84)]
FOCUS = (98, 230, 240)
FONT = "/System/Library/Fonts/SFNS.ttf"


def box(text: str) -> tuple[int, int, int, int]:
    x, y, w, h = (int(v) for v in text.split(","))
    return x, y, w, h


def background(size: tuple[int, int]) -> Image.Image:
    w, h = size
    bg = Image.new("RGB", size, BASE)
    for colour, opacity, (cx, cy, r) in ((MAUVE, 0.18, (w * 0.92, h * 0.08, h * 0.45)), (TEAL, 0.16, (w * 0.7, h * 1.02, h * 0.32))):
        layer = Image.new("RGB", size, colour)
        mask = Image.new("L", size, 0)
        ImageDraw.Draw(mask).ellipse([cx - r, cy - r, cx + r, cy + r], fill=int(255 * opacity))
        bg.paste(layer, (0, 0), mask)
    return bg


def window(img: Image.Image, app: str, radius: int) -> Image.Image:
    bar_h = max(round(img.width * 0.035), 36)
    win = Image.new("RGB", (img.width, img.height + bar_h), BAR)
    d = ImageDraw.Draw(win)
    d.line([(0, bar_h - 1), (img.width, bar_h - 1)], fill=BAR_LINE, width=2)
    r, x = bar_h * 0.17, bar_h * 0.55
    for colour in LIGHTS:
        d.ellipse([x - r, bar_h / 2 - r, x + r, bar_h / 2 + r], fill=colour)
        x += r * 3.4
    try:
        font = ImageFont.truetype(FONT, round(bar_h * 0.4))
    except OSError:
        font = ImageFont.load_default()
    d.text((x + r, bar_h / 2), app, font=font, fill=NAME, anchor="lm")
    win.paste(img, (0, bar_h))
    return win


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--crop", type=box)
    ap.add_argument("--blur", type=box, action="append", default=[])
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--radius", type=int, default=24)
    ap.add_argument("--margin", type=int, default=64)
    ap.add_argument("--app", default="Ghostty", help="the window's name in its title bar")
    ap.add_argument("--focus", action="store_true", help="the cyan focus border and glow")
    a = ap.parse_args()

    src = Image.open(a.src).convert("RGBA")
    # Captures of rounded windows have transparent corners: fill them with the window's own background, not black.
    # The fill is the most common opaque colour in the middle of the capture (its background), not a fixed pixel that
    # may sit in a shadow margin or a title bar.
    mid = src.crop((src.width // 4, src.height // 4, 3 * src.width // 4, 3 * src.height // 4))
    counts = sorted(((n, c) for n, c in (mid.getcolors(mid.width * mid.height) or []) if c[3] == 255), reverse=True)
    fill = counts[0][1][:3] if counts else (17, 17, 22)
    img = Image.new("RGB", src.size, fill)
    img.paste(src, (0, 0), src)
    if a.crop:
        x, y, w, h = a.crop
        img = img.crop((x, y, x + w, y + h))
    for x, y, w, h in a.blur:
        region = img.crop((x, y, x + w, y + h))
        # Two passes: a heavy blur, then pixelate, so no glyph survives.
        region = region.filter(ImageFilter.GaussianBlur(24)).resize((max(w // 24, 1), max(h // 24, 1))).resize((w, h))
        img.paste(region.filter(ImageFilter.GaussianBlur(6)), (x, y))

    scale = a.width / img.width
    img = img.resize((a.width, round(img.height * scale)), Image.LANCZOS)

    img = window(img, a.app, a.radius)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], a.radius, fill=255)

    m = a.margin
    canvas = background((img.width + 2 * m, img.height + 2 * m))
    shadow = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle([m, m + 12, m + img.width, m + img.height + 12], a.radius, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.paste(Image.new("RGB", canvas.size, (10, 10, 16)), (0, 0), shadow)
    if a.focus:
        glow = Image.new("L", canvas.size, 0)
        ImageDraw.Draw(glow).rounded_rectangle([m - 6, m - 6, m + img.width + 6, m + img.height + 6], a.radius + 6, fill=120)
        canvas.paste(Image.new("RGB", canvas.size, FOCUS), (0, 0), glow.filter(ImageFilter.GaussianBlur(16)))
        ring = Image.new("L", canvas.size, 0)
        ImageDraw.Draw(ring).rounded_rectangle([m - 3, m - 3, m + img.width + 3, m + img.height + 3], a.radius + 3, outline=255, width=4)
        canvas.paste(Image.new("RGB", canvas.size, FOCUS), (0, 0), ring)
    canvas.paste(img, (m, m), mask)
    canvas.save(a.out, optimize=True)


if __name__ == "__main__":
    main()
