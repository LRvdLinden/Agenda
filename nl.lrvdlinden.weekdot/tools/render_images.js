// Renders the Homey app images (assets/images) and the widget previews (no real text, as Homey requires).
// Run from the repo root:  node nl.lrvdlinden.weekdot/tools/render_images.js   (needs Playwright)
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..');
const ICON = path.join(ROOT, '..', 'Weekdot', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-light-1024.png');
const icon = 'data:image/png;base64,' + fs.readFileSync(ICON).toString('base64');

// App images: Weekdot icon on a red backdrop with a soft week grid
function appImage(w, h) {
  const s = h / 350;
  const cells = Array.from({ length: 7 }, (_, i) => `<div class="c" style="left:${(i * 14.6 + 1.5)}%"></div>`).join('');
  return `<html><body style="margin:0;width:${w}px;height:${h}px;overflow:hidden;position:relative;
    background:radial-gradient(${600 * s}px ${420 * s}px at 70% 20%, #ff6a5f 0%, #e8352f 50%, #b4211b 100%)">
    <style>.c{position:absolute;top:-10%;width:12%;height:120%;border-radius:${18 * s}px;background:rgba(255,255,255,.06)}</style>
    ${cells}
    <div style="position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:${190 * s}px;height:${190 * s}px;border-radius:${44 * s}px;
      overflow:hidden;box-shadow:0 ${24 * s}px ${60 * s}px rgba(0,0,0,.35)"><img src="${icon}" style="width:100%;height:100%;display:block"></div>
  </body></html>`;
}

// Widget preview: abstract agenda card (coloured bars and grey lines instead of text)
function preview(dark) {
  const card = dark ? '#1d1d22' : '#ffffff', line = dark ? 'rgba(255,255,255,.16)' : 'rgba(0,0,0,.10)',
    line2 = dark ? 'rgba(255,255,255,.09)' : 'rgba(0,0,0,.06)', now = dark ? 'rgba(255,90,79,.16)' : 'rgba(232,53,47,.08)';
  const rows = [['#007AFF', 46, 70, false], ['#E8352F', 34, 52, true], ['#34C759', 58, 40, false], ['#FF9500', 40, 60, false]];
  const dots = Array.from({ length: 7 }, (_, i) => `<circle cx="${30 + i * 12.6}" cy="20" r="4.2" fill="#fff"/>`).join('');
  const row = ([c, a, b, isNow]) => `<div style="display:flex;gap:22px;align-items:stretch;padding:18px 20px;border-radius:26px;background:${isNow ? now : 'transparent'};margin:0 -20px">
      <div style="width:12px;border-radius:8px;background:${c}"></div>
      <div style="width:120px;display:flex;flex-direction:column;gap:12px;justify-content:center"><div style="height:20px;border-radius:10px;background:${line}"></div><div style="height:16px;width:70%;border-radius:8px;background:${line2}"></div></div>
      <div style="flex:1;display:flex;flex-direction:column;gap:12px;justify-content:center"><div style="height:22px;width:${a + 30}%;border-radius:11px;background:${line}"></div><div style="height:16px;width:${b}%;border-radius:8px;background:${line2}"></div></div></div>`;
  return `<html><body style="margin:0;width:1024px;height:1024px;background:transparent;display:flex;align-items:center;justify-content:center">
    <div style="width:880px;border-radius:64px;background:${card};padding:52px 60px 46px;box-shadow:0 30px 80px rgba(0,0,0,${dark ? .5 : .18})">
      <div style="display:flex;align-items:center;gap:22px;margin-bottom:22px">
        <svg width="64" height="64" viewBox="0 0 120 120"><defs><clipPath id="k"><rect width="120" height="120" rx="28"/></clipPath></defs>
          <g clip-path="url(#k)"><rect width="120" height="120" fill="#fff"/><rect width="120" height="40" fill="#E8352F"/>${dots}<rect x="26" y="66" width="68" height="14" rx="7" fill="#E8352F"/></g></svg>
        <div style="height:26px;width:120px;border-radius:13px;background:#E8352F;opacity:.9"></div>
        <div style="height:26px;width:200px;border-radius:13px;background:${line}"></div>
        <div style="flex:1"></div><div style="height:26px;width:40px;border-radius:13px;background:${line2}"></div>
      </div>
      ${rows.map(row).join('')}
    </div></body></html>`;
}

(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  for (const [name, w, h] of [['small', 250, 175], ['large', 500, 350], ['xlarge', 1000, 700]]) {
    await p.setViewportSize({ width: w, height: h });
    await p.setContent(appImage(w, h));
    await p.screenshot({ path: path.join(ROOT, 'assets', 'images', name + '.png') });
  }
  await p.setViewportSize({ width: 1024, height: 1024 });
  for (const dark of [false, true]) {
    await p.setContent(preview(dark));
    await p.screenshot({ path: path.join(ROOT, 'widgets', 'agenda', `preview-${dark ? 'dark' : 'light'}.png`), omitBackground: true });
  }
  // preview of the monochrome icon (for checking only)
  await p.setViewportSize({ width: 240, height: 240 });
  await p.setContent(`<html><body style="margin:0;background:#fff"><img src="data:image/svg+xml;base64,${fs.readFileSync(path.join(ROOT, 'assets', 'icon.svg')).toString('base64')}" style="width:240px"></body></html>`);
  await p.screenshot({ path: path.join(__dirname, '..', '.icon-check.png') });
  await b.close();
  console.log('images done');
})();
