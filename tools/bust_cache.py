#!/usr/bin/env python3
"""Gives the website's CSS/JS links a version based on their content (?v=<hash>), so browsers always load the
latest translations and scripts after an update instead of a cached copy.

It also lists the app screenshots in website/assets/shots/<lang>/<slot>.png (slots: iphone-week, iphone-month,
ipad-week, mac-week, watch-day) in <meta name="weekdot-shots"> with a content hash, so app.js only shows the
screenshots that exist and falls back to the HTML mockups for the rest. Run it after adding or replacing a screenshot."""
import hashlib, json, os, re

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "website")
ASSETS = ["styles.css", "i18n.js", "lang.js", "app.js", "consent.js", "support.js"]
ver = {a: hashlib.md5(open(os.path.join(ROOT, a), "rb").read()).hexdigest()[:10] for a in ASSETS}

SLOTS = ["iphone-week", "iphone-month", "ipad-week", "mac-week", "watch-day"]
SHOTS_DIR = os.path.join(ROOT, "assets", "shots")
shots = {}
if os.path.isdir(SHOTS_DIR):
    for lang in sorted(os.listdir(SHOTS_DIR)):
        for slot in SLOTS:
            f = os.path.join(SHOTS_DIR, lang, slot + ".png")
            if os.path.isfile(f):
                shots.setdefault(lang, {})[slot] = hashlib.md5(open(f, "rb").read()).hexdigest()[:10]
gal = {}
if os.path.isdir(SHOTS_DIR):
    for lang in sorted(os.listdir(SHOTS_DIR)):
        gd = os.path.join(SHOTS_DIR, lang, "gallery")
        if os.path.isdir(gd):
            for f in sorted(os.listdir(gd)):
                if f.endswith(".jpg"):
                    gal.setdefault(lang, {})[f[:-4]] = hashlib.md5(open(os.path.join(gd, f), "rb").read()).hexdigest()[:10]
gal_meta = '<meta name="weekdot-gallery" content="' + json.dumps(gal, separators=(",", ":"), sort_keys=True).replace('"', "&quot;") + '">'
shots_meta = '<meta name="weekdot-shots" content="' + json.dumps(shots, separators=(",", ":"), sort_keys=True).replace('"', "&quot;") + '">'

for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith(".html"):
            continue
        p = os.path.join(dp, f)
        s = open(p, encoding="utf-8").read()
        new = s
        for a, v in ver.items():
            new = re.sub(r'(/' + re.escape(a) + r')(\?v=[^"\']*)?(["\'])', r'\g<1>?v=' + v + r'\g<3>', new)
        new = re.sub(r'<meta name="weekdot-shots" content="[^"]*">', lambda m: shots_meta, new)
        new = re.sub(r'<meta name="weekdot-gallery" content="[^"]*">', lambda m: gal_meta, new)
        if new != s:
            open(p, "w", encoding="utf-8").write(new)
            print("updated", os.path.relpath(p, ROOT))
print("gallery:", ", ".join(l + ": " + " ".join(sorted(v)) for l, v in sorted(gal.items())) or "none")
print("screenshots:", ", ".join(l + ": " + " ".join(sorted(v)) for l, v in sorted(shots.items())) or "none (HTML mockups)")
