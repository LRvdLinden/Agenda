// Usage: node compose.js <shotsDir> <metadataDir> <outDir>
// Makes App Store marketing screenshots: caption + device-framed real screenshot on a Weekdot backdrop.
// Renders one design per device family at design size into <outDir>/_design; build.py then resizes them to
// every size App Store Connect accepts.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const [,, SHOTS, LOCS, OUT] = process.argv;
const LANG_FOR = { 'en-US':'en','nl-NL':'nl' };   // en-GB uses the en-US screenshots (build.py copies them)
const ORDER = ['week','day','month','discover','sports','event','list','week-dark'];
// design canvases; ipad11 is the 11-inch iPad shape (1668x2388) drawn at 13-inch scale
const DEV = {
  iphone: { w:1320, h:2868, folder:'iphone', radius: 120, bezel: 28, scale: 0.80 },
  ipad:   { w:2064, h:2752, folder:'ipad13', radius: 60,  bezel: 30, scale: 0.80 },
  ipad11: { w:2064, h:2955, folder:'ipad11', radius: 60,  bezel: 30, scale: 0.80, src: 'ipad' },
  mac:    { w:2880, h:1800, folder:'mac',    radius: 22,  bezel: 0,  scale: 0.74 },
};
// Apple Watch: caption + the screenshot in a watch case, on a 4x canvas of the 422x514 Ultra screenshot size
function htmlWatch(img, caption) {
  const W = 1688, H = 2056, sw = 800, sh = sw * 514 / 422, pad = 56;
  const cw = sw + 2 * pad, ch = sh + 2 * pad, left = (W - cw) / 2 - 20, top = 760;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden;font-family:-apple-system,"SF Pro Display","Inter","Helvetica Neue",Arial,sans-serif;
    background:radial-gradient(1400px 1200px at 85% 0%, #ffe3df 0%, #fff7f5 45%, #f4f1ee 100%)}
  .cap{position:absolute;left:0;right:0;top:150px;text-align:center;color:#141418;font-weight:800;font-size:132px;letter-spacing:-.025em;line-height:1.02;padding:0 90px}
  .dots{position:absolute;left:50%;transform:translateX(-50%);top:80px;display:flex;gap:18px}
  .dots i{width:22px;height:22px;border-radius:50%;background:#e8352f;opacity:.35;display:block}.dots i.on{opacity:1}
  .band{position:absolute;left:${left + cw * 0.17}px;width:${cw * 0.66}px;background:linear-gradient(90deg,#2a2a2e,#3a3a40 50%,#2a2a2e);border-radius:60px}
  .case{position:absolute;left:${left}px;top:${top}px;width:${cw}px;height:${ch}px;border-radius:${cw * 0.24}px;
    background:linear-gradient(145deg,#d9d6cf,#a8a49b 40%,#e8e5de 70%,#8f8b83);padding:22px;box-sizing:border-box;
    box-shadow:0 90px 160px -60px rgba(0,0,0,.55)}
  .bezel{width:100%;height:100%;border-radius:${cw * 0.22}px;background:#050505;padding:${pad - 22}px;box-sizing:border-box}
  .bezel img{width:100%;height:100%;border-radius:${cw * 0.15}px;display:block}
  .crown{position:absolute;left:${left + cw - 6}px;top:${top + ch * 0.26}px;width:46px;height:170px;border-radius:14px;
    background:repeating-linear-gradient(0deg,#9a968e 0 8px,#cfccc4 8px 14px);box-shadow:inset -6px 0 10px rgba(0,0,0,.25)}
  .btn{position:absolute;left:${left + cw - 4}px;top:${top + ch * 0.52}px;width:30px;height:230px;border-radius:12px;background:linear-gradient(90deg,#b8b4ab,#8f8b83)}
  .act{position:absolute;left:${left - 26}px;top:${top + ch * 0.3}px;width:30px;height:260px;border-radius:12px;background:#e8352f}
  </style></head><body><div class="dots">${[0,1,2,3,4,5,6].map(i=>`<i class="${i===3?'on':''}"></i>`).join('')}</div>
  <div class="cap">${caption}</div>
  <div class="band" style="top:${top - 220}px;height:260px;-webkit-mask-image:linear-gradient(transparent,#000 70%)"></div><div class="band" style="top:${top + ch - 40}px;height:640px"></div>
  <div class="act"></div><div class="crown"></div><div class="btn"></div>
  <div class="case"><div class="bezel"><img src="${img}"></div></div></body></html>`;
}
// Mac: caption + the window on a soft desktop inside a MacBook frame, on the 2880x1800 canvas
function htmlMac(img, imgW, imgH, caption) {
  const W = 2880, H = 1800;
  const sw = 2040, sh = sw * 10 / 16;                 // the MacBook screen (16:10)
  const bez = 34, left = (W - sw) / 2, top = 330;
  let ww = sw * 0.86, wh = ww * imgH / imgW;          // the app window on that screen
  if (wh > sh * 0.84) { wh = sh * 0.84; ww = wh * imgW / imgH; }
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden;font-family:-apple-system,"SF Pro Display","Inter","Helvetica Neue",Arial,sans-serif;
    background:radial-gradient(1800px 1200px at 85% 0%, #ffe3df 0%, #fff7f5 45%, #f4f1ee 100%)}
  .cap{position:absolute;left:0;right:0;top:120px;text-align:center;color:#141418;font-weight:800;font-size:112px;letter-spacing:-.025em;line-height:1.05}
  .dots{position:absolute;left:50%;transform:translateX(-50%);top:60px;display:flex;gap:16px}
  .dots i{width:18px;height:18px;border-radius:50%;background:#e8352f;opacity:.35;display:block}.dots i.on{opacity:1}
  .lid{position:absolute;left:${left - bez}px;top:${top - bez}px;width:${sw + 2 * bez}px;height:${sh + 2 * bez + 10}px;border-radius:54px 54px 18px 18px;
    background:#0c0c0e;box-shadow:inset 0 0 0 4px #3a3a3f, 0 80px 140px -60px rgba(0,0,0,.5)}
  .notch{position:absolute;left:${W / 2 - 120}px;top:${top - 2}px;width:240px;height:34px;background:#0c0c0e;border-radius:0 0 18px 18px;z-index:3}
  .screen{position:absolute;left:${left}px;top:${top}px;width:${sw}px;height:${sh}px;border-radius:22px;overflow:hidden;
    background:linear-gradient(160deg,#ff8a7a 0%,#e8352f 40%,#7b1d18 100%)}
  .screen::before{content:"";position:absolute;inset:0;background:radial-gradient(900px 600px at 20% 110%,rgba(255,255,255,.25),transparent 60%)}
  .menubar{position:absolute;left:0;right:0;top:0;height:40px;background:rgba(255,255,255,.35);backdrop-filter:blur(10px)}
  .win{position:absolute;left:${(sw - ww) / 2}px;top:${40 + (sh - 40 - wh) / 2}px;width:${ww}px;height:${wh}px;border-radius:18px;overflow:hidden;
    box-shadow:0 40px 90px -20px rgba(0,0,0,.55),0 0 0 1px rgba(0,0,0,.25)}
  .win img{width:100%;height:100%;display:block}
  .base{position:absolute;left:${left - bez - 150}px;top:${top + sh + bez + 6}px;width:${sw + 2 * bez + 300}px;height:46px;border-radius:0 0 40px 40px;
    background:linear-gradient(#e4e2dd,#b9b6ae);box-shadow:0 30px 50px -20px rgba(0,0,0,.4)}
  .base::after{content:"";position:absolute;left:50%;transform:translateX(-50%);top:0;width:360px;height:18px;border-radius:0 0 22px 22px;background:#a9a69e}
  </style></head><body><div class="dots">${[0,1,2,3,4,5,6].map(i=>`<i class="${i===3?'on':''}"></i>`).join('')}</div>
  <div class="cap">${caption}</div>
  <div class="lid"></div><div class="screen"><div class="menubar"></div><div class="win"><img src="${img}"></div></div><div class="notch"></div><div class="base"></div>
  </body></html>`;
}
function dataURL(p){ return 'data:image/png;base64,' + fs.readFileSync(p).toString('base64'); }
function html(dev, img, imgW, imgH, caption, sub, dark){
  const d = DEV[dev];
  const capSize = dev==='mac' ? 96 : dev.startsWith('ipad') ? 120 : 112;
  const top = dev==='mac' ? 170 : dev.startsWith('ipad') ? 330 : 360;
  const availH = d.h - top - (dev==='mac'? 60 : 0);
  let ih = availH * (dev==='mac'?1:1.0), iw = ih * imgW / imgH;
  const maxW = d.w * (dev==='mac'? 0.86 : d.scale);
  if (iw > maxW) { iw = maxW; ih = iw * imgH / imgW; }
  // the CI Mac has a small screen: don't blow its window up more than ~1.8x (stays sharp)
  if (dev==='mac' && iw > imgW*1.8) { iw = imgW*1.8; ih = iw * imgH / imgW; }
  const bg = dark ? 'radial-gradient(1200px 900px at 80% 10%, #3a1212 0%, #121214 60%)' : 'radial-gradient(1400px 1000px at 85% 0%, #ffe3df 0%, #fff7f5 45%, #f4f1ee 100%)';
  const ink = dark ? '#fff' : '#141418';
  const frame = dev==='mac'
    ? `<div style="position:absolute;left:${(d.w-iw)/2}px;top:${top}px;width:${iw}px;height:${ih}px;border-radius:${d.radius}px;overflow:hidden;box-shadow:0 60px 120px -40px rgba(0,0,0,.45),0 0 0 2px rgba(0,0,0,.08)"><img src="${img}" style="width:100%;height:100%;display:block"></div>`
    : `<div style="position:absolute;left:${(d.w-iw)/2 - d.bezel}px;top:${top}px;width:${iw + 2*d.bezel}px;height:${ih + 2*d.bezel}px;border-radius:${d.radius + d.bezel}px;background:#111;box-shadow:0 80px 160px -50px rgba(0,0,0,.55), inset 0 0 0 3px #2c2c30">
         <div style="position:absolute;left:${d.bezel}px;top:${d.bezel}px;width:${iw}px;height:${ih}px;border-radius:${d.radius}px;overflow:hidden"><img src="${img}" style="width:100%;height:100%;display:block"></div></div>`;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;width:${d.w}px;height:${d.h}px;overflow:hidden;background:${bg};font-family:-apple-system,"SF Pro Display","Inter","Helvetica Neue",Arial,sans-serif}
  .cap{position:absolute;left:0;right:0;top:${dev==='mac'?60:110}px;text-align:center;color:${ink};font-weight:800;font-size:${capSize}px;letter-spacing:-.02em;line-height:1.05;padding:0 80px}
  .dots{position:absolute;left:50%;transform:translateX(-50%);top:${dev==='mac'?30:60}px;display:flex;gap:14px}
  .dots i{width:16px;height:16px;border-radius:50%;background:#e8352f;opacity:.35;display:block}.dots i.on{opacity:1}
  </style></head><body><div class="dots">${[0,1,2,3,4,5,6].map(i=>`<i class="${i===3?'on':''}"></i>`).join('')}</div>
  <div class="cap">${caption}</div>${frame}</body></html>`;
}
(async () => {
  const b = await chromium.launch();
  const page = await b.newPage();
  const locales = fs.readdirSync(LOCS).filter(f=>f.endsWith('.json') && !f.startsWith('_')).map(f=>f.slice(0,-5));
  for (const loc of locales) {
    const meta = JSON.parse(fs.readFileSync(path.join(LOCS, loc+'.json')));
    const lang = LANG_FOR[loc]; if (!lang) continue;           // other locales fall back to the primary language's screenshots
    for (const dev of ['iphone','ipad','ipad11','mac']) {
      const dir = path.join(SHOTS, lang, DEV[dev].src || dev); if (!fs.existsSync(dir)) continue;
      const scenes = dev==='mac' ? ['week','day','month','sports','list'] : ORDER;
      let n = 0;
      for (const sc of scenes) {
        const f = path.join(dir, sc+'.png'); if (!fs.existsSync(f)) continue;
        const caps = meta.screenshot_captions||{};
        const cap = (dev==='mac' ? caps['mac-' + sc] : null) || caps[sc] || sc;
        const { width: imgW, height: imgH } = await (async()=>{ const buf=fs.readFileSync(f); return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) }; })();
        await page.setViewportSize({ width: DEV[dev].w, height: DEV[dev].h });
        await page.setContent(dev==='mac' ? htmlMac(dataURL(f), imgW, imgH, cap) : html(dev, dataURL(f), imgW, imgH, cap, '', sc==='week-dark'));
        await page.waitForTimeout(80);
        n++;
        const outDir = path.join(OUT, '_design', loc, DEV[dev].folder); fs.mkdirSync(outDir, { recursive: true });
        await page.screenshot({ path: path.join(outDir, String(n).padStart(2,'0')+'-'+sc+'.png') });
      }
    }
    // Apple Watch: framed like the other screenshots (build.py makes every watch size from it)
    const wd = path.join(SHOTS, lang, 'watch');
    if (fs.existsSync(wd)) {
      const outDir = path.join(OUT, '_design', loc, 'watch'); fs.mkdirSync(outDir,{recursive:true});
      let n = 0;
      for (const sc of ['day','week','event']) {
        const f = path.join(wd, sc + '.png'); if (!fs.existsSync(f)) continue;
        const cap = (meta.screenshot_captions||{})['watch-' + sc] || (meta.screenshot_captions||{}).watch || sc;
        await page.setViewportSize({ width: 1688, height: 2056 });
        await page.setContent(htmlWatch(dataURL(f), cap));
        await page.waitForTimeout(80);
        n++;
        await page.screenshot({ path: path.join(outDir, String(n).padStart(2,'0') + '-' + sc + '.png') });
      }
    }
    console.log('done', loc);
  }
  await b.close();
})();
