#!/usr/bin/env python3
"""Gives the website's CSS/JS links a version based on their content (?v=<hash>), so browsers always load the
latest translations and scripts after an update instead of a cached copy."""
import hashlib, os, re

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "website")
ASSETS = ["styles.css", "i18n.js", "app.js"]
ver = {a: hashlib.md5(open(os.path.join(ROOT, a), "rb").read()).hexdigest()[:10] for a in ASSETS}

for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith(".html"):
            continue
        p = os.path.join(dp, f)
        s = open(p, encoding="utf-8").read()
        new = s
        for a, v in ver.items():
            new = re.sub(r'(/' + re.escape(a) + r')(\?v=[^"\']*)?(["\'])', r'\g<1>?v=' + v + r'\g<3>', new)
        if new != s:
            open(p, "w", encoding="utf-8").write(new)
            print("updated", os.path.relpath(p, ROOT))
