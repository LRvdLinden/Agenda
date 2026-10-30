#!/usr/bin/env python3
"""Builds the complete App Store Connect package for Weekdot (nl-NL, en-US, en-GB).

    python3 appstore/tools/build.py <shotsDir>

<shotsDir> is the "shots" folder from the Screenshots workflow (branch "screenshots": shots/<lang>/<device>/<scene>.png).
Output: appstore/out/Weekdot-AppStore/... and appstore/out/Weekdot-AppStore-NL-EN.zip

Every size App Store Connect accepts is made, so each upload slot works:
  iPhone 6.9" 1320x2868 · 6.5" 1284x2778 · 6.3" 1206x2622 · 6.1" 1179x2556
  iPad 13" 2064x2752 · iPad 11" 1668x2388 · Mac 2880x1800
  Apple Watch Ultra 3 422x514 · Ultra 2 410x502 · Series 11 416x496 · Series 9 396x484
  Promotional artwork 5244x2950 · 3840x1646 · 3840x2560 · 1920x1280
"""
import json, os, shutil, subprocess, sys, zipfile
from PIL import Image, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
APPSTORE = os.path.dirname(HERE)
REPO = os.path.dirname(APPSTORE)
SHOTS = os.path.abspath(sys.argv[1])
OUT = os.path.join(APPSTORE, "out")
PKG = os.path.join(OUT, "Weekdot-AppStore")
ICON = os.path.join(REPO, "Weekdot", "Assets.xcassets", "AppIcon.appiconset", "icon-light-1024.png")
LOCALES = ["nl-NL", "en-US", "en-GB"]
SAME_AS = {"en-GB": "en-US"}

TARGETS = {  # design folder -> [(folder name, w, h)]
    "iphone": [("iPhone 6.9in (1320x2868)", 1320, 2868), ("iPhone 6.5in (1284x2778)", 1284, 2778),
               ("iPhone 6.3in (1206x2622)", 1206, 2622), ("iPhone 6.1in (1179x2556)", 1179, 2556)],
    "ipad13": [("iPad 13in (2064x2752)", 2064, 2752)],
    "ipad11": [("iPad 11in (1668x2388)", 1668, 2388)],
    "mac": [("Mac (2880x1800)", 2880, 1800)],
    "watch": [("Apple Watch Ultra 3 (422x514)", 422, 514), ("Apple Watch Ultra 2 (410x502)", 410, 502),
              ("Apple Watch Series 11 (416x496)", 416, 496), ("Apple Watch Series 9 (396x484)", 396, 484)],
}
FIELDS = [("name", "01 Name", 30), ("subtitle", "02 Subtitle", 30), ("promotional_text", "03 Promotional Text", 170),
          ("description", "04 Description", 4000), ("keywords", "05 Keywords", 100), ("release_notes", "06 Whats New", 4000)]


def fit(src, dst, w, h):
    im = Image.open(src).convert("RGB")           # App Store rejects images with transparency
    if im.size != (w, h):
        im = ImageOps.fit(im, (w, h), Image.LANCZOS, centering=(0.5, 0.5))
    im.save(dst, optimize=True)


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(OUT)
    subprocess.run(["node", os.path.join(HERE, "compose.js"), SHOTS, os.path.join(APPSTORE, "metadata"), OUT], check=True)
    subprocess.run(["node", os.path.join(HERE, "promo.js"), SHOTS, ICON, OUT], check=True)
    design = os.path.join(OUT, "_design")
    for loc in LOCALES:
        meta = json.load(open(os.path.join(APPSTORE, "metadata", loc + ".json"), encoding="utf-8"))
        base = os.path.join(PKG, loc)
        os.makedirs(os.path.join(base, "tekst"))
        for key, name, limit in FIELDS:
            assert len(meta[key]) <= limit, (loc, key, len(meta[key]))
            open(os.path.join(base, "tekst", name + ".txt"), "w", encoding="utf-8").write(meta[key])
        open(os.path.join(base, "tekst", "07 URLs.txt"), "w").write(
            f"Support URL: {meta['support_url']}\nMarketing URL: {meta['marketing_url']}\nPrivacy Policy URL: {meta['privacy_url']}\n")
        src_loc = SAME_AS.get(loc, loc)
        for fam, targets in TARGETS.items():
            d = os.path.join(design, src_loc, fam)
            if not os.path.isdir(d):
                continue
            for folder, w, h in targets:
                od = os.path.join(base, "screenshots", folder)
                os.makedirs(od, exist_ok=True)
                for f in sorted(os.listdir(d)):
                    fit(os.path.join(d, f), os.path.join(od, f), w, h)
        print("done", loc)
    for lang in ["nl", "en"]:
        d = os.path.join(design, "promo", lang)
        od = os.path.join(PKG, "promo", lang)
        os.makedirs(od)
        for f in sorted(os.listdir(d)):
            w, h = map(int, f[:-4].split("x"))
            fit(os.path.join(d, f), os.path.join(od, f), w, h)
    os.makedirs(os.path.join(PKG, "icoon"))
    fit(ICON, os.path.join(PKG, "icoon", "AppIcon-1024.png"), 1024, 1024)
    for f in ["LEESMIJ.txt", "app-store-connect.txt"]:
        shutil.copy(os.path.join(APPSTORE, f), PKG)
    shutil.rmtree(design)
    # check every file has the exact size of its folder
    bad = []
    for dp, _, fs in os.walk(PKG):
        for f in fs:
            if f.endswith(".png") and "(" in os.path.basename(dp):
                want = tuple(map(int, os.path.basename(dp).split("(")[1].rstrip(")").split("x")))
                if Image.open(os.path.join(dp, f)).size != want:
                    bad.append(os.path.join(dp, f))
    assert not bad, bad
    z = os.path.join(OUT, "Weekdot-AppStore-NL-EN.zip")
    with zipfile.ZipFile(z, "w", zipfile.ZIP_DEFLATED) as zf:
        for dp, _, fs in os.walk(PKG):
            for f in sorted(fs):
                p = os.path.join(dp, f)
                zf.write(p, os.path.relpath(p, OUT))
    print("package:", z, os.path.getsize(z) // 1_000_000, "MB")


if __name__ == "__main__":
    main()
