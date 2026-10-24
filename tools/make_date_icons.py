#!/usr/bin/env python3
"""Generates the alternate app icons with every weekday + date combination (7 x 31 per language),
in light, dark and tinted, into Sevn/DateIcons.xcassets. The app picks today's icon when it opens.
Run from the repo root:  python3 tools/make_date_icons.py"""
import json, os, shutil, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_icons as mi

mi.S = 2  # faster; plenty sharp for 1024 px
ROOT = mi.ROOT
OUT = os.path.join(ROOT, "Sevn", "DateIcons.xcassets")

# weekday labels, index 1 = Sunday … 7 = Saturday (Calendar.weekday)
LABELS = {
    "en": ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"],
    "nl": ["ZO", "MA", "DI", "WO", "DO", "VR", "ZA"],
}


def face(label, number, style):
    img = Image.new("RGBA", (1024 * mi.S, 1024 * mi.S), mi.bg_for(style) + (255,))
    mi.draw_face(img, (0, 0, 1024 * mi.S, 1024 * mi.S), label, style, number)
    return img.resize((1024, 1024), Image.LANCZOS).convert("RGB")


def tinted(label, number):
    w = 1024 * mi.S
    img = Image.new("RGB", (w, w), (0, 0, 0))
    d = ImageDraw.Draw(img)
    pw, ph = w * 0.50, w * 0.165
    px0, py0 = (w - pw) / 2, w * 0.14
    d.rounded_rectangle([px0, py0, px0 + pw, py0 + ph], radius=ph / 2, fill=(255, 255, 255))
    f1 = mi.font("Inter-Bold.otf", int(w * 0.105))
    bb = d.textbbox((0, 0), label, font=f1)
    d.text((px0 + (pw - (bb[2] - bb[0])) / 2 - bb[0], py0 + (ph - (bb[3] - bb[1])) / 2 - bb[1]), label, font=f1, fill=(0, 0, 0))
    f2 = mi.font("Inter-ExtraBold.otf", int(w * 0.50))
    bb = d.textbbox((0, 0), number, font=f2)
    nw, nh = bb[2] - bb[0], bb[3] - bb[1]
    top, bottom = w * 0.36, w * 0.88
    d.text(((w - nw) / 2 - bb[0], top + (bottom - top - nh) / 2 - bb[1]), number, font=f2, fill=(255, 255, 255))
    return img.resize((1024, 1024), Image.LANCZOS)


def save_small(img, path):
    img.quantize(colors=48, method=Image.Quantize.MEDIANCUT).save(path, optimize=True)


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    json.dump({"info": {"author": "xcode", "version": 1}}, open(os.path.join(OUT, "Contents.json"), "w"), indent=2)
    for lang, labels in LABELS.items():
        for wd in range(1, 8):
            for day in range(1, 32):
                name = f"Today-{lang}-{wd}-{day}"
                p = os.path.join(OUT, name + ".appiconset")
                os.makedirs(p)
                lab, num = labels[wd - 1], str(day)
                save_small(face(lab, num, "white"), os.path.join(p, "light.png"))
                save_small(face(lab, num, "black"), os.path.join(p, "dark.png"))
                save_small(tinted(lab, num), os.path.join(p, "tinted.png"))
                json.dump({"images": [
                    {"filename": "light.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
                    {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "dark.png",
                     "idiom": "universal", "platform": "ios", "size": "1024x1024"},
                    {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "tinted.png",
                     "idiom": "universal", "platform": "ios", "size": "1024x1024"},
                ], "info": {"author": "xcode", "version": 1}}, open(os.path.join(p, "Contents.json"), "w"), indent=2)
        print(lang, "done")


if __name__ == "__main__":
    main()
