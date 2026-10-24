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

# Default icon + alternates (name, weekday label, dark?)
ICONS = [
    ("AppIcon", "MON", "white"),        # white tile (default)
    ("AppIcon-Black", "MON", "black"),  # black tile
]


def font(name, px):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), px)


def draw_face(img, box, label, style="purple", number="7"):
    """Sevn face: weekday in a rounded label at the top, bold date below."""
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    w = x1 - x0
    # red label around the weekday, weekday in the tile colour, red date
    pill, pill_txt, num_col = RED, bg_for(style), RED
    pw, ph = w * 0.50, w * 0.165
    px0, py0 = x0 + (w - pw) / 2, y0 + w * 0.14
    d.rounded_rectangle([px0, py0, px0 + pw, py0 + ph], radius=ph / 2, fill=pill)
    f1 = font("Inter-Bold.otf", int(w * 0.105))
    bb = d.textbbox((0, 0), label, font=f1)
    d.text((px0 + (pw - (bb[2] - bb[0])) / 2 - bb[0], py0 + (ph - (bb[3] - bb[1])) / 2 - bb[1]),
           label, font=f1, fill=pill_txt)
    f2 = font("Inter-ExtraBold.otf", int(w * 0.50))
    bb = d.textbbox((0, 0), number, font=f2)
    nw, nh = bb[2] - bb[0], bb[3] - bb[1]
    top, bottom = y0 + w * 0.36, y0 + w * 0.88
    d.text((x0 + (w - nw) / 2 - bb[0], top + (bottom - top - nh) / 2 - bb[1]), number, font=f2, fill=num_col)


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
    tile = Image.new("RGBA", big.size, (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle([100 * S, 100 * S, 924 * S, 924 * S], radius=185 * S, fill=bg_for(style) + (255,))
    draw_face(tile, (100 * S, 100 * S, 924 * S, 924 * S), label, style)
    big.alpha_composite(tile)
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


def tinted(label):
    """Grayscale version for the iOS 18 'tinted' home screen (system adds the tint)."""
    img = Image.new("RGBA", (1024 * S, 1024 * S), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    w = 1024 * S
    pw, ph = w * 0.50, w * 0.165
    px0, py0 = (w - pw) / 2, w * 0.14
    d.rounded_rectangle([px0, py0, px0 + pw, py0 + ph], radius=ph / 2, fill=(255, 255, 255))
    f1 = font("Inter-Bold.otf", int(w * 0.105))
    bb = d.textbbox((0, 0), label, font=f1)
    d.text((px0 + (pw - (bb[2] - bb[0])) / 2 - bb[0], py0 + (ph - (bb[3] - bb[1])) / 2 - bb[1]), label, font=f1, fill=(0, 0, 0))
    f2 = font("Inter-ExtraBold.otf", int(w * 0.50))
    bb = d.textbbox((0, 0), "7", font=f2)
    nw, nh = bb[2] - bb[0], bb[3] - bb[1]
    top, bottom = w * 0.36, w * 0.88
    d.text(((w - nw) / 2 - bb[0], top + (bottom - top - nh) / 2 - bb[1]), "7", font=f2, fill=(255, 255, 255))
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

    # launch / splash logo + in-app icon (rounded white tile, used on the indigo splash)
    shared = os.path.join(ROOT, "Shared", "SharedAssets.xcassets")
    for set_name, base in (("SevnLogo", 150), ("SevnIcon", 120)):
        p = ensure(os.path.join(shared, set_name + ".imageset"))
        for f in os.listdir(p):
            if f.endswith(".png"):
                os.remove(os.path.join(p, f))
        imgs = []
        for scale in (1, 2, 3):
            fn = f"{set_name.lower()}@{scale}x.png"
            rounded(default.resize((base * scale, base * scale), Image.LANCZOS)).save(os.path.join(p, fn))
            imgs.append({"filename": fn, "idiom": "universal", "scale": f"{scale}x"})
        write_contents(p, {"images": imgs, "info": INFO})

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
