#!/usr/bin/env python3
# The series cover (1000 × 420, dev.to and LinkedIn; docs/posts/STYLE.md): a stylised screen of tiled windows, the
# focused one outlined with the fn layer's focus gradient (#33ccff → #00ff99), the series tag, the title, a subtitle
# and a row of key caps. Drawn at 2× and scaled down. Defaults draw the Omarchy-ish cover.
#   uv run --with pillow docs/posts/tools/header.py images/00-cover.png \
#     --title "My AI agent's loop" --highlight "ran once" --subtitle "zsh · bash · Claude Code" --series 1 --keys zsh,bash
import argparse

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 2
W, H = 1000 * S, 420 * S
CYAN, GREEN = (51, 204, 255), (0, 255, 153)
INK = (242, 242, 242)
FONT = "/System/Library/Fonts/SFNS.ttf"


def lerp(a, b, t):
    return tuple(int(x + (y - x) * t) for x, y in zip(a, b))


def diagonal(size, a, b):
    w, h = size
    g = Image.new("RGB", size)
    px = g.load()
    for y in range(h):
        for x in range(0, w, 2):
            c = lerp(a, b, (x / w + y / h) / 2)
            px[x, y] = c
            if x + 1 < w:
                px[x + 1, y] = c
    return g


def rounded(size, r):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], r, fill=255)
    return m


def window(canvas, x, y, w, h, focus=False, alpha=46):
    if focus:
        # the gradient spans this window only, top-left cyan to bottom-right green, as JankyBorders draws it
        pad = 60
        local = diagonal((w + 2 * pad, h + 2 * pad), CYAN, GREEN)
        glow = Image.new("L", local.size, 0)
        ImageDraw.Draw(glow).rounded_rectangle([pad - 6, pad - 6, pad + w + 6, pad + h + 6], 22, fill=170)
        canvas.paste(local, (x - pad, y - pad), glow.filter(ImageFilter.GaussianBlur(26)))
        ring = Image.new("L", local.size, 0)
        d = ImageDraw.Draw(ring)
        d.rounded_rectangle([pad - 5, pad - 5, pad + w + 5, pad + h + 5], 20, fill=255)
        d.rounded_rectangle([pad + 2, pad + 2, pad + w - 2, pad + h - 2], 14, fill=0)
        canvas.paste(local, (x - pad, y - pad), ring)
    body = Image.new("RGB", (w, h), (30, 36, 50))
    canvas.paste(body, (x, y), rounded((w, h), 14))
    d = ImageDraw.Draw(canvas, "RGBA")
    # a title bar and a few "lines of text", no real content
    d.rounded_rectangle([x + 18, y + 18, x + 18 + 10 * 3 + 20, y + 30], 6, fill=(255, 255, 255, 30))
    for i, frac in enumerate([0.8, 0.55, 0.7, 0.4, 0.62, 0.5][: max(2, h // 70)]):
        yy = y + 56 + i * 30
        if yy + 10 < y + h - 16:
            d.rounded_rectangle([x + 18, yy, x + 18 + int((w - 36) * frac), yy + 10], 5,
                                fill=(*((CYAN if focus and i == 0 else INK)), alpha))


def cap(canvas, x, y, label, globe=False):
    size = 76
    w = size if (globe or len(label) <= 1) else size + 24 * (len(label) - 1)
    d = ImageDraw.Draw(canvas, "RGBA")
    d.rounded_rectangle([x, y + 6, x + w, y + size + 6], 16, fill=(0, 0, 0, 120))
    d.rounded_rectangle([x, y, x + w, y + size], 16, fill=(58, 58, 64, 255))
    d.rounded_rectangle([x + 3, y + 3, x + w - 3, y + size - 8], 13, fill=(70, 70, 78, 255))
    cx, cy = x + w / 2, y + size / 2 - 2
    if globe:
        r = 20
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=INK, width=4)
        d.ellipse([cx - r * 0.45, cy - r, cx + r * 0.45, cy + r], outline=INK, width=4)
        d.line([cx - r, cy, cx + r, cy], fill=INK, width=4)
        for dy in (-r * 0.5, r * 0.5):
            half = (r * r - dy * dy) ** 0.5
            d.line([cx - half, cy + dy, cx + half, cy + dy], fill=INK, width=3)
    else:
        f = ImageFont.truetype(FONT, 36)
        d.text((cx, cy), label, font=f, fill=INK, anchor="mm")
    return w


def fit(d, text, size, width):
    while size > 40 and d.textlength(text, font=ImageFont.truetype(FONT, size)) > width:
        size -= 4
    return ImageFont.truetype(FONT, size)


def main(out, title, highlight, subtitle, keys, series):
    canvas = diagonal((W, H), (12, 16, 26), (28, 22, 48))
    # soft colour blooms
    bloom = Image.new("L", (W, H), 0)
    ImageDraw.Draw(bloom).ellipse([W * 0.55, -H * 0.4, W * 1.2, H * 0.9], fill=90)
    canvas.paste(diagonal((W, H), CYAN, GREEN), (0, 0), bloom.filter(ImageFilter.GaussianBlur(160)))

    # the "screen": a frame with a menu bar strip and three tiled windows
    sx, sy, sw, sh = 1060, 120, 860, 620
    screen = Image.new("RGB", (sw, sh), (18, 22, 32))
    canvas.paste(screen, (sx, sy), rounded((sw, sh), 26))
    d = ImageDraw.Draw(canvas, "RGBA")
    d.rounded_rectangle([sx, sy, sx + sw, sy + sh], 26, outline=(255, 255, 255, 40), width=3)
    for i in range(10):  # the spaces strip
        bx = sx + 30 + i * 30 + (16 if i >= 5 else 0)
        fill = (*CYAN, 255) if i == 2 else (255, 255, 255, 60)
        d.rounded_rectangle([bx, sy + 22, bx + 20, sy + 40], 5, fill=fill)
    window(canvas, sx + 28, sy + 70, 400, 520, focus=True)
    window(canvas, sx + 448, sy + 70, 384, 250)
    window(canvas, sx + 448, sy + 340, 384, 250)

    # title, subtitle and key caps on the left
    d = ImageDraw.Draw(canvas, "RGBA")
    width = sx - 90 - 60  # the left column, up to the screen
    d.text((90, 150), title, font=fit(d, title, 104, width), fill=INK)
    if highlight:
        d.text((90, 268), highlight, font=fit(d, highlight, 104, width), fill=(*GREEN, 255))
    if subtitle:
        d.text((94, 410), subtitle, font=fit(d, subtitle, 34, width), fill=(255, 255, 255, 150))
    x = 94
    for label in keys:
        x += cap(canvas, x, 520, label, label == "fn") + 18
    if series is not None:  # the series tag, top right
        tag = f"dots · #{series}"
        d.text((W - 60, 56), tag, font=ImageFont.truetype(FONT, 32), fill=(255, 255, 255, 170), anchor="ra")

    canvas.resize((1000, 420), Image.LANCZOS).save(out, optimize=True)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description="Draw a series cover (1000 × 420).")
    p.add_argument("out", help="output PNG")
    p.add_argument("--title", default="Omarchy-ish", help="first title line (ink)")
    p.add_argument("--highlight", default="macOS", help="second title line (accent green); empty for none")
    p.add_argument("--subtitle", default="yabai · Karabiner · Raycast · SwiftBar", help="small line under the title")
    p.add_argument("--keys", default="fn,⇧,3", help="comma-separated key caps; fn draws the globe key")
    p.add_argument("--series", type=int, default=None, help="series number for the 'dots · #n' tag")
    a = p.parse_args()
    keys = [k for k in a.keys.split(",") if k]
    main(a.out, a.title, a.highlight, a.subtitle, keys, a.series)
