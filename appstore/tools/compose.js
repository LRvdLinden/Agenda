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
      const scenes = dev==='mac' ? ['week','month','month-screen'] : ORDER;
      let n = 0;
      for (const sc of scenes) {
        const f = path.join(dir, sc+'.png'); if (!fs.existsSync(f)) continue;
        const cap = (meta.screenshot_captions||{})[dev==='mac' && sc==='week' ? 'mac' : sc.replace('-screen','')] || sc;
        const { width: imgW, height: imgH } = await (async()=>{ const buf=fs.readFileSync(f); return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) }; })();
        await page.setViewportSize({ width: DEV[dev].w, height: DEV[dev].h });
        await page.setContent(html(dev, dataURL(f), imgW, imgH, cap, '', sc==='week-dark'));
        await page.waitForTimeout(80);
        n++;
        const outDir = path.join(OUT, '_design', loc, DEV[dev].folder); fs.mkdirSync(outDir, { recursive: true });
        await page.screenshot({ path: path.join(outDir, String(n).padStart(2,'0')+'-'+sc+'.png') });
      }
    }
    // Apple Watch: App Store wants the plain screenshot at device size (build.py makes every watch size)
    const wd = path.join(SHOTS, lang, 'watch');
    if (fs.existsSync(wd)) {
      const outDir = path.join(OUT, '_design', loc, 'watch'); fs.mkdirSync(outDir,{recursive:true});
      fs.readdirSync(wd).filter(f=>f.endsWith('.png')).sort().forEach((f,i)=>fs.copyFileSync(path.join(wd,f), path.join(outDir, String(i+1).padStart(2,'0')+'-'+f)));
    }
    console.log('done', loc);
  }
  await b.close();
})();
