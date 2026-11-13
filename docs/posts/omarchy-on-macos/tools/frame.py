#!/usr/bin/env python3
# Frames a screenshot for the post: crop, blur sensitive boxes, scale, round the corners, drop a shadow and centre it
# on the header's dark gradient. Boxes are in the input's pixels (x,y,w,h), applied after the crop.
#   uv run --with pillow tools/frame.py raw/01.png images/01.png --crop 0,0,3000,1800 --blur 100,200,400,60
import argparse

from PIL import Image, ImageDraw, ImageFilter

BG_TOP, BG_BOTTOM = (14, 18, 28), (24, 30, 44)


def box(text: str) -> tuple[int, int, int, int]:
    x, y, w, h = (int(v) for v in text.split(","))
    return x, y, w, h


def gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    bg = Image.new("RGB", size)
    draw = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / max(h - 1, 1)
        draw.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)))
    return bg


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--crop", type=box)
    ap.add_argument("--blur", type=box, action="append", default=[])
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--radius", type=int, default=24)
    ap.add_argument("--margin", type=int, default=64)
    a = ap.parse_args()

    img = Image.open(a.src).convert("RGB")
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

    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], a.radius, fill=255)

    m = a.margin
    canvas = gradient((img.width + 2 * m, img.height + 2 * m))
    shadow = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle([m, m + 12, m + img.width, m + img.height + 12], a.radius, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.paste(Image.new("RGB", canvas.size, (0, 0, 0)), (0, 0), shadow)
    canvas.paste(img, (m, m), mask)
    canvas.save(a.out, optimize=True)


if __name__ == "__main__":
    main()
