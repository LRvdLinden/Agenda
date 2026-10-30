// Renders the Homey app images (assets/images) and the widget previews (no real text, as Homey requires).
// Run from the repo root:  node nl.lrvdlinden.weekdot/tools/render_images.js   (needs Playwright)
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..');
const ICON = path.join(ROOT, '..', 'Weekdot', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-light-1024.png');
const icon = 'data:image/png;base64,' + fs.readFileSync(ICON).toString('base64');

// App images: like the App Store promo — Weekdot on iPhone next to the Weekdot Agenda widget on Homey,
// with a Flow glyph (calendar → house → light) on a red backdrop. Designed at 1000×700 and scaled down.
const SHOT = path.join(ROOT, '..', 'website', 'assets', 'shots', 'en', 'iphone-week.png');
const shot = 'data:image/png;base64,' + fs.readFileSync(SHOT).toString('base64');
function appImage(w, h) {
  const z = w / 1000;
  const ev = (c, t, e, title, sub, now) => `<div style="display:flex;gap:14px;align-items:stretch;padding:10px 12px;border-radius:16px;margin:0 -12px;${now ? 'background:rgba(232,53,47,.09)' : ''}">
      <div style="width:6px;border-radius:4px;background:${c}"></div>
      <div style="width:62px;font-weight:700;font-size:19px;line-height:1.25;font-variant-numeric:tabular-nums">${t}<div style="font-weight:400;color:#8a8a93;font-size:15px">${e}</div></div>
      <div style="flex:1;min-width:0"><div style="font-weight:700;font-size:20px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${title}${now ? '<span style="font-size:12px;color:#fff;background:#E8352F;border-radius:7px;padding:2px 8px;margin-left:8px;vertical-align:3px">NOW</span>' : ''}</div><div style="color:#8a8a93;font-size:15px">${sub}</div></div></div>`;
  const glyph = (svg) => `<div style="width:70px;height:70px;border-radius:22px;background:rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;box-shadow:0 14px 30px rgba(0,0,0,.22)">${svg}</div>`;
  const arrow = `<svg width="34" height="20" viewBox="0 0 34 20"><path d="M2 10H30M22 3l8 7-8 7" stroke="#fff" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  const cal = `<svg width="38" height="38" viewBox="0 0 64 64"><rect x="6" y="8" width="52" height="50" rx="12" fill="#fff" stroke="#E8352F" stroke-width="5"/><rect x="6" y="8" width="52" height="16" rx="8" fill="#E8352F"/>${[0,1,2,3,4,5,6].map(i => `<circle cx="${15 + i * 5.7}" cy="16" r="1.7" fill="#fff"/>`).join('')}<rect x="17" y="36" width="30" height="7" rx="3.5" fill="#E8352F"/></svg>`;
  const house = `<svg width="38" height="38" viewBox="0 0 64 64"><path d="M10 30L32 11l22 19v24a4 4 0 0 1-4 4H14a4 4 0 0 1-4-4z" fill="#1d1d22"/><rect x="26" y="38" width="12" height="20" rx="3" fill="#fff"/></svg>`;
  const bulb = `<svg width="38" height="38" viewBox="0 0 64 64"><circle cx="32" cy="26" r="16" fill="#FFCC00"/><rect x="25" y="42" width="14" height="10" rx="3" fill="#8e8e93"/><g stroke="#FFCC00" stroke-width="4" stroke-linecap="round"><path d="M32 2v4M10 26H6M58 26h-4M15 9l3 3M49 9l-3 3"/></g></svg>`;
  return `<html><head><meta charset="utf-8"></head><body style="margin:0;width:${w}px;height:${h}px;overflow:hidden">
  <div style="width:1000px;height:700px;transform:scale(${z});transform-origin:0 0;position:relative;overflow:hidden;font-family:-apple-system,'SF Pro Display',Inter,'Helvetica Neue',Arial,sans-serif;
    background:radial-gradient(900px 700px at 78% 18%, #ff6a5f 0%, #e8352f 48%, #a8180f 100%)">
    <div style="position:absolute;inset:0;background-image:radial-gradient(rgba(255,255,255,.13) 2.2px, transparent 2.2px);background-size:34px 34px;-webkit-mask-image:linear-gradient(90deg,#000,transparent 60%)"></div>
    <!-- Weekdot icon -->
    <div style="position:absolute;left:60px;top:58px;width:118px;height:118px;border-radius:28px;overflow:hidden;box-shadow:0 18px 40px rgba(0,0,0,.3)"><img src="${icon}" style="width:100%;height:100%"></div>
    <!-- Flow glyph -->
    <div style="position:absolute;right:92px;top:478px;display:flex;align-items:center;gap:14px;transform:rotate(2deg)">${glyph(cal)}${arrow}${glyph(house)}${arrow}${glyph(bulb)}</div>
    <!-- iPhone -->
    <div style="position:absolute;left:300px;top:52px;width:270px;height:586px;border-radius:52px;background:#0d0d0f;padding:11px;box-sizing:border-box;
      box-shadow:0 50px 90px -30px rgba(0,0,0,.6),inset 0 0 0 2px #2d2d31;transform:rotate(-4deg)">
      <img src="${shot}" style="width:100%;height:100%;object-fit:cover;object-position:top;border-radius:42px;display:block;background:#fff"></div>
    <!-- Homey widget -->
    <div style="position:absolute;right:56px;top:150px;width:360px;border-radius:30px;background:#fff;padding:22px 24px 16px;box-shadow:0 40px 80px -24px rgba(0,0,0,.55);color:#141418;transform:rotate(2deg)">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px">
        <div style="width:28px;height:28px;border-radius:8px;overflow:hidden"><img src="${icon}" style="width:100%;height:100%"></div>
        <div style="font-weight:800;font-size:19px"><span style="color:#E8352F">Today</span> · Fri 30 Oct</div><div style="flex:1"></div><div style="color:#8a8a93;font-weight:700">3</div>
      </div>
      ${ev('#007AFF', '09:30', '10:30', '1:1 with Lisa', 'Studio 4', false)}
      ${ev('#E8352F', '12:30', '13:30', '🥗 Lunch', 'Café de Zon', true)}
      ${ev('#34C759', '16:00', '17:30', 'School pick-up', '', false)}
    </div>
  </div></body></html>`;
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
