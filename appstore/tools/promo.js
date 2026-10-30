// Usage: node promo.js <shotsDir> <appIcon.png> <outDir>
// App Store promotional artwork (App Store Connect "Promotional artwork"/featuring assets) for nl and en.
// Rendered on a 1920-wide design canvas; build.py resizes to the exact sizes Apple asks for:
//   5244x2950, 3840x1646, 3840x2560 and 1920x1280.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const [,, SHOTS, ICON, OUT] = process.argv;
const T = {
  nl: { h: 'Je week in één oogopslag.', s: 'De gratis agenda voor iPhone, iPad, Mac en Apple Watch' },
  en: { h: 'Your week at a glance.', s: 'The free calendar for iPhone, iPad, Mac and Apple Watch' },
};
// design canvas per target (width 1920, height from the target's aspect ratio)
const SIZES = [[5244, 2950], [3840, 1646], [3840, 2560], [1920, 1280]];
const b64 = f => 'data:image/png;base64,' + fs.readFileSync(f).toString('base64');

(async () => {
  const b = await chromium.launch();
  for (const l of Object.keys(T)) for (const [tw, th] of SIZES) {
    const W = 1920, H = Math.round(W * th / tw), scale = tw / W;
    const p = await b.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: scale });
    const shot = s => { const f = path.join(SHOTS, l, 'iphone', s + '.png'); return fs.existsSync(f) ? b64(f) : ''; };
    // two phones side by side may use at most ~42% of the width, so they never touch the text
    const phH = Math.min(H * 0.84, (W * 0.42) / (2.14 * 1320 / 2868)), phW = phH * 1320 / 2868;
    const ph = (s, dy, z) => `<div class="ph" style="width:${phW}px;height:${phH}px;margin-top:${dy}px;z-index:${z}"><img src="${shot(s)}"></div>`;
    const narrow = H < 900;
    await p.setContent(`<!doctype html><html><head><meta charset="utf-8"><style>
      html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden}
      body{font-family:-apple-system,"SF Pro Display","Inter","Helvetica Neue",Arial,sans-serif;color:#fff;position:relative;
        background:radial-gradient(1200px 900px at 78% 20%, #ff6a5f 0%, #e8352f 45%, #a8180f 100%)}
      .dots{position:absolute;inset:0;background-image:radial-gradient(rgba(255,255,255,.12) 2px, transparent 2px);background-size:34px 34px;
        -webkit-mask-image:linear-gradient(90deg,#000,transparent 55%)}
      .t{position:absolute;left:${W*0.075}px;top:50%;transform:translateY(-50%);width:${narrow ? 700 : 720}px}
      .ic{width:${narrow ? 120 : 160}px;height:${narrow ? 120 : 160}px;border-radius:${narrow ? 28 : 36}px;box-shadow:0 18px 50px rgba(0,0,0,.28)}
      h1{font-size:${narrow ? 80 : 100}px;line-height:1;letter-spacing:-.04em;font-weight:800;margin:${narrow ? 26 : 40}px 0 ${narrow ? 16 : 26}px}
      p{font-size:${narrow ? 30 : 38}px;line-height:1.25;margin:0;opacity:.93;font-weight:500}
      .phs{position:absolute;right:${W*0.07}px;top:50%;transform:translateY(-50%);display:flex;gap:${phW*0.14}px;align-items:center}
      .ph{position:relative;border-radius:${phW*0.15}px;background:#0d0d0f;padding:${phW*0.035}px;box-shadow:0 50px 100px -30px rgba(0,0,0,.55),inset 0 0 0 2px #2d2d31;box-sizing:border-box}
      .ph img{width:100%;height:100%;object-fit:cover;object-position:top;border-radius:${phW*0.12}px;display:block;background:#fff}
    </style></head><body><div class="dots"></div>
      <div class="t"><img class="ic" src="${b64(ICON)}"><h1>${T[l].h}</h1><p>${T[l].s}</p></div>
      <div class="phs">${ph('week', -phH*0.04, 2)}${ph('sports', phH*0.06, 1)}</div>
    </body></html>`);
    await p.waitForTimeout(250);
    const dir = path.join(OUT, '_design', 'promo', l); fs.mkdirSync(dir, { recursive: true });
    await p.screenshot({ path: path.join(dir, `${tw}x${th}.png`) });
    await p.close();
  }
  await b.close();
})();
