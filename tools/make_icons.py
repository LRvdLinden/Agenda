#!/usr/bin/env python3
"""Draws the Sevn app icons (iOS-style calendar: abbreviated weekday above the date),
the launch logo and website images.  Run from the repo root:  python3 tools/make_icons.py
"""
import json, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = "/usr/share/fonts/opentype/inter"
S = 4

RED = (232, 53, 47)          # #E8352F, brand colour
BLACK = (17, 17, 17)
PURPLE = RED
PURPLE_DEEP = (91, 33, 182)  # #5B21B6
LILAC = (237, 233, 254)      # #EDE9FE
INK = (24, 24, 32)
WHITE = (255, 255, 255)
DARK_BG = (24, 20, 38)
INDIGO = PURPLE
INK = (24, 24, 32)

# Default icon + alternates (name, weekday label, dark?)
ICONS = [
    ("AppIcon", "MON", "white"),        # white tile (default)
    ("AppIcon-Black", "MON", "black"),  # black tile
]


def font(name, px):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), px)


def draw_face(img, box, label=None, style="white", number=None):
    """Sevn icon: white (or black) tile, red header band with two ring holes, and the name
    'Sevn' in bold below. label/number are ignored (kept for old callers)."""
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    w = x1 - x0
    k = w / 1024.0

    def P(x, y):
        return (x0 + x * k, y0 + y * k)

    tinted_mode = style == "tinted"
    band = WHITE if tinted_mode else RED
    text = WHITE if style in ("black", "tinted") else RED
    tile = (0, 0, 0) if tinted_mode else bg_for(style)
    # header band across the top of the tile
    d.rectangle([P(0, 0), P(1024, 318)], fill=band)
    # seven little day dots (one per weekday)
    dot = tile if tinted_mode else (WHITE if style != "black" else BLACK)
    for i in range(7):
        cx = 272 + i * 80
        d.ellipse([P(cx - 21, 159 - 21), P(cx + 21, 159 + 21)], fill=dot)
    # wordmark
    f = font("Inter-ExtraBold.otf", int(w * 0.285))
    word = "Sevn"
    bb = d.textbbox((0, 0), word, font=f)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    d.text((x0 + (w - tw) / 2 - bb[0], y0 + 318 * k + (706 * k - th) / 2 - bb[1] - 10 * k), word, font=f, fill=text)


def bg_for(style):
    return {"black": BLACK}.get(style, WHITE)


def icon_full(label, style="white", size=1024):
    img = Image.new("RGBA", (1024 * S, 1024 * S), bg_for(style) + (255,))
    draw_face(img, (0, 0, 1024 * S, 1024 * S), label, style)
    return img.resize((size, size), Image.LANCZOS)


def icon_mac(label, style="white", size=1024):
    big = Image.new("RGBA", (1024 * S, 1024 * S), (0, 0, 0, 0))
    sh = Image.new("RGBA", big.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([100 * S, 114 * S, 924 * S, 938 * S], radius=185 * S, fill=(0, 0, 0, 80))
    big.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14 * S)))
    face = Image.new("RGBA", (824 * S, 824 * S), bg_for(style) + (255,))
    draw_face(face, (0, 0, 824 * S, 824 * S), label, style)
    m = Image.new("L", face.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, 824 * S - 1, 824 * S - 1], radius=185 * S, fill=255)
    face.putalpha(m)
    big.alpha_composite(face, (100 * S, 100 * S))
    return big.resize((size, size), Image.LANCZOS)


def rounded(im, r=0.225):
    im = im.copy().convert("RGBA")
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius=int(im.size[0] * r), fill=255)
    im.putalpha(m)
    return im


def write_contents(path, data):
    with open(os.path.join(path, "Contents.json"), "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def ensure(p):
    os.makedirs(p, exist_ok=True)
    return p


INFO = {"author": "xcode", "version": 1}


def tinted(label=None):
    """Grayscale version for the iOS 18 'tinted' home screen (the system adds the tint)."""
    img = Image.new("RGBA", (1024 * S, 1024 * S), (0, 0, 0, 255))
    draw_face(img, (0, 0, 1024 * S, 1024 * S), style="tinted")
    return img.resize((1024, 1024), Image.LANCZOS)


def main():
    # One app icon that follows light / dark / tinted mode (iOS 18+; older iOS uses the light one).
    path = ensure(os.path.join(ROOT, "Sevn", "Assets.xcassets", "AppIcon.appiconset"))
    light, dark = icon_full("MON", "white"), icon_full("MON", "black")
    light.convert("RGB").save(os.path.join(path, "icon-light-1024.png"))
    dark.convert("RGB").save(os.path.join(path, "icon-dark-1024.png"))
    tinted("MON").convert("RGB").save(os.path.join(path, "icon-tinted-1024.png"))
    images = [
        {"filename": "icon-light-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "icon-dark-1024.png",
         "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "icon-tinted-1024.png",
         "idiom": "universal", "platform": "ios", "size": "1024x1024"},
    ]
    mac = icon_mac("MON", "white")
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            px = pt * scale
            mfn = f"icon-mac-{pt}@{scale}x.png"
            mac.resize((px, px), Image.LANCZOS).save(os.path.join(path, mfn))
            images.append({"filename": mfn, "idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}"})
    write_contents(path, {"images": images, "info": INFO})

    default = icon_full("MON")
    wicon = ensure(os.path.join(ROOT, "SevnWatch", "Assets.xcassets", "AppIcon.appiconset"))
    default.convert("RGB").save(os.path.join(wicon, "icon-watch-1024.png"))
    write_contents(wicon, {"images": [{"filename": "icon-watch-1024.png", "idiom": "universal",
                                       "platform": "watchos", "size": "1024x1024"}], "info": INFO})

    # launch screen logo: the mark on a transparent square (light + dark), 220 pt
    shared = os.path.join(ROOT, "Shared", "SharedAssets.xcassets")
    for old in ("SevnIcon.imageset",):
        if os.path.isdir(os.path.join(shared, old)):
            import shutil
            shutil.rmtree(os.path.join(shared, old))
    p = ensure(os.path.join(shared, "SevnLogo.imageset"))
    for f in os.listdir(p):
        if f.endswith(".png"):
            os.remove(os.path.join(p, f))
    imgs = []
    for mode in ("light", "dark"):
        tile = rounded(icon_full("MON", "white" if mode == "light" else "black").resize((660, 660), Image.LANCZOS))
        for scale in (1, 2, 3):
            fn = f"sevnlogo-{mode}@{scale}x.png"
            tile.resize((150 * scale, 150 * scale), Image.LANCZOS).save(os.path.join(p, fn))
            e = {"filename": fn, "idiom": "universal", "scale": f"{scale}x"}
            if mode == "dark":
                e["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
            imgs.append(e)
    write_contents(p, {"images": imgs, "info": INFO})

    default = icon_full("MON")
    web = ensure(os.path.join(ROOT, "website", "assets"))
    r512 = rounded(default.resize((512, 512), Image.LANCZOS))
    r512.save(os.path.join(web, "icon.png"))
    default.resize((180, 180), Image.LANCZOS).convert("RGB").save(os.path.join(web, "apple-touch-icon.png"))
    r512.resize((64, 64), Image.LANCZOS).save(os.path.join(web, "favicon.png"))
    icon_mac("MON").resize((512, 512), Image.LANCZOS).save(os.path.join(web, "icon-mac.png"))
    card = Image.new("RGB", (1200, 630), INDIGO)
    t = rounded(default.resize((340, 340), Image.LANCZOS))
    card.paste(t, (430, 145), t)
    card.save(os.path.join(web, "og-image.png"))
    print("icons written")


if __name__ == "__main__":
    main()
