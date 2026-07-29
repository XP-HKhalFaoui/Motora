#!/usr/bin/env python3
"""Generates Motora's launcher icon and splash mark.

Placeholder artwork, kept as a script so it is reproducible and easy to
replace: drop a real 1024x1024 logo at assets/icon/icon.png and rerun
`dart run flutter_launcher_icons` instead of this.

The mark reuses the app's own visual language — the circular km gauge from
the vehicle hub (a dim track with a primary-blue arc) wrapped around a
geometric M — on the dark background from the palette.

    python3 tool/generate_icon.py

Requires Pillow. Everything is drawn at 4x and downsampled, because PIL's
arc and polygon rasterisers do not antialias.
"""

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersampling factor
S = SIZE * SS

# lib/core/theme.dart — AppPalette.dark
BACKGROUND = (14, 21, 32, 255)      # #0E1520
SURFACE = (23, 32, 46, 255)         # #17202E
PRIMARY = (46, 207, 217, 255)       # #2ECFD9 — teal, dark-theme primary
ACCENT = (234, 240, 247, 255)       # #EAF0F7 — the pip is a highlight now;
#                                     an orange one read as off-brand once
#                                     the app went teal.
TRACK = (45, 58, 76, 255)
WHITE = (234, 240, 247, 255)        # textPrimary


def draw_mark(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float):
    """Gauge ring + M, centred on (cx, cy). `scale` is the ring diameter."""
    r = scale / 2
    stroke = scale * 0.085
    box = [cx - r, cy - r, cx + r, cy + r]

    # Full track, then the "consumed" arc on top — same idiom as KmGauge,
    # which starts at 12 o'clock and sweeps clockwise.
    draw.arc(box, 0, 360, fill=TRACK, width=int(stroke))
    draw.arc(box, -90, -90 + 252, fill=PRIMARY, width=int(stroke))

    # Pip marking the end of the sweep.
    pip_r = stroke * 0.62
    draw.ellipse(
        [cx - pip_r, cy - r - pip_r, cx + pip_r, cy - r + pip_r],
        fill=ACCENT,
    )

    # Geometric M drawn as a stroked polyline so no font is required.
    mw = scale * 0.40
    mh = scale * 0.34
    w = scale * 0.105
    left, right = cx - mw / 2, cx + mw / 2
    top, bottom = cy - mh / 2, cy + mh / 2
    draw.line(
        [(left, bottom), (left, top), (cx, cy + mh * 0.10),
         (right, top), (right, bottom)],
        fill=WHITE,
        width=int(w),
        joint="curve",
    )
    # `joint="curve"` rounds the interior joins but leaves the four ends
    # square; cap them so the strokes read as one solid letter.
    for x, y in ((left, bottom), (left, top), (right, top), (right, bottom)):
        draw.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=WHITE)


def rounded_background() -> Image.Image:
    """Vertical surface -> background gradient.

    A shaped highlight (an offset ellipse) leaves a visible hard edge once
    the icon is scaled down; a gradient gives the same depth with none.
    """
    img = Image.new("RGBA", (S, S), BACKGROUND)
    draw = ImageDraw.Draw(img)
    for y in range(S):
        t = y / (S - 1)
        draw.line(
            [(0, y), (S, y)],
            fill=tuple(
                round(a + (b - a) * t) for a, b in zip(SURFACE, BACKGROUND)
            ),
        )
    return img


def main() -> None:
    # --- full icon (iOS, legacy Android) --------------------------------
    icon = rounded_background()
    draw_mark(ImageDraw.Draw(icon), S / 2, S / 2, S * 0.60)
    icon.resize((SIZE, SIZE), Image.LANCZOS).save("assets/icon/icon.png")

    # --- Android adaptive foreground -----------------------------------
    # Only the centre ~66% of an adaptive icon is guaranteed visible, so
    # the mark is drawn smaller on a transparent canvas.
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(fg), S / 2, S / 2, S * 0.42)
    fg.resize((SIZE, SIZE), Image.LANCZOS).save(
        "assets/icon/icon_foreground.png")

    # --- splash mark ----------------------------------------------------
    splash = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(splash), S / 2, S / 2, S * 0.70)
    splash.resize((SIZE, SIZE), Image.LANCZOS).save(
        "assets/icon/splash.png")

    print("wrote assets/icon/{icon,icon_foreground,splash}.png")


if __name__ == "__main__":
    main()
