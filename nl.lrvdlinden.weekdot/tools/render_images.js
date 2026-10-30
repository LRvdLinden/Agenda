// Renders the Homey app images (assets/images) and the widget previews (no real text, as Homey requires).
// Run from the repo root:  node nl.lrvdlinden.weekdot/tools/render_images.js   (needs Playwright)
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..');
const ICON = path.join(ROOT, '..', 'Weekdot', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-light-1024.png');
const icon = 'data:image/png;base64,' + fs.readFileSync(ICON).toString('base64');

// App images: a tilted collage of Weekdot widget cards on a soft gradient with the Weekdot icon,
// in the same style as Léon's other Homey apps (Apple-widget look). Designed at 1000×700 and scaled down.
function appImage(w, h) {
  const z = w / 1000;
  const RED = '#E8352F';
  const head = (color, glyph, title) => `<div class="hd"><span style="color:${color}">${glyph}</span><b style="color:${color}">${title}</b><i>9:41 ›</i></div>`;
  const cal = `<svg width="22" height="22" viewBox="0 0 64 64"><rect x="6" y="9" width="52" height="48" rx="11" fill="none" stroke="currentColor" stroke-width="6"/><rect x="6" y="9" width="52" height="15" rx="7" fill="currentColor"/></svg>`;
  const clock = `<svg width="22" height="22" viewBox="0 0 64 64"><circle cx="32" cy="32" r="25" fill="none" stroke="currentColor" stroke-width="6"/><path d="M32 18v15l10 6" stroke="currentColor" stroke-width="6" fill="none" stroke-linecap="round"/></svg>`;
  const flag = `<svg width="22" height="22" viewBox="0 0 64 64"><path d="M14 58V8h30l-4 10 4 10H20" fill="currentColor"/></svg>`;
  const house = `<svg width="22" height="22" viewBox="0 0 64 64"><path d="M8 30L32 10l24 20v24a4 4 0 0 1-4 4H12a4 4 0 0 1-4-4z" fill="currentColor"/></svg>`;
  const row = (c, t, title, sub) => `<div class="ev"><div class="bar" style="background:${c}"></div><div class="tm">${t}</div><div><div class="ti">${title}</div>${sub ? `<div class="sb">${sub}</div>` : ''}</div></div>`;
  const month = (() => {
    let cells = '';
    for (let i = 0; i < 35; i++) {
      const d = i - 2;
      const txt = d < 1 || d > 31 ? '' : d;
      const today = d === 30;
      const dot = [3, 8, 12, 17, 22, 29].includes(d);
      cells += `<div class="mc">${today ? `<span class="td">${txt}</span>` : txt}${dot && !today ? '<i></i>' : ''}</div>`;
    }
    return `<div class="mg">${['M','T','W','T','F','S','S'].map(x => `<div class="mh">${x}</div>`).join('')}${cells}</div>`;
  })();
  const week = (() => {
    const cols = [[['#007AFF', 10, 18], [RED, 40, 22]], [['#34C759', 20, 26], ['#007AFF', 58, 16]], [['#FF9500', 8, 14], [RED, 34, 30]],
      [['#007AFF', 16, 20], ['#34C759', 50, 24]], [[RED, 26, 18], ['#AF52DE', 54, 20]], [['#34C759', 12, 30]], [['#FF9500', 30, 26]]];
    return `<div class="wk">${cols.map((col, i) => `<div class="wc${i === 4 ? ' on' : ''}"><div class="wd">${'MTWTFSS'[i]}</div>${col.map(([c, t, hh]) => `<div class="wb" style="background:${c};top:${t + 18}%;height:${hh}%"></div>`).join('')}</div>`).join('')}</div>`;
  })();
  return `<html><head><meta charset="utf-8"><style>
    *{box-sizing:border-box} body{margin:0}
    .stage{width:1000px;height:700px;position:relative;overflow:hidden;font-family:-apple-system,'SF Pro Display',Inter,'Helvetica Neue',Arial,sans-serif;color:#141418;
      background:radial-gradient(700px 520px at 12% 8%, #ffc9c4 0%, transparent 60%),radial-gradient(800px 600px at 100% 100%, #d9d2ff 0%, transparent 60%),linear-gradient(135deg,#fbe9ea,#efeaf6)}
    .grid{position:absolute;left:-10px;top:-40px;width:1180px;transform:rotate(-8deg);transform-origin:50% 40%;display:grid;grid-template-columns:repeat(3, 340px);gap:26px;zoom:.92}
    .card{background:#fff;border-radius:34px;padding:22px 26px;box-shadow:0 22px 50px -18px rgba(60,40,70,.28)}
    .hd{display:flex;align-items:center;gap:8px;font-size:23px;margin-bottom:10px} .hd b{font-weight:700} .hd i{margin-left:auto;font-style:normal;color:#8e8e93;font-size:19px}
    .big{font-size:58px;font-weight:800;letter-spacing:-1.5px;line-height:1} .big small{font-size:24px;color:#8e8e93;font-weight:600;letter-spacing:0;margin-left:6px}
    .ev{display:flex;gap:12px;align-items:stretch;margin:9px 0} .bar{width:6px;border-radius:4px} .tm{width:58px;font-weight:700;font-size:19px;font-variant-numeric:tabular-nums}
    .ti{font-weight:700;font-size:20px} .sb{color:#8e8e93;font-size:16px}
    .mg{display:grid;grid-template-columns:repeat(7,1fr);gap:4px 0;text-align:center;font-size:16px;font-weight:600}
    .mh{color:#8e8e93;font-size:13px} .mc{height:30px;position:relative;line-height:30px} .mc i{position:absolute;left:50%;bottom:0;width:5px;height:5px;margin-left:-2.5px;border-radius:50%;background:${RED}}
    .td{display:inline-block;width:30px;height:30px;border-radius:50%;background:${RED};color:#fff}
    .wk{display:flex;gap:6px;height:150px} .wc{flex:1;position:relative;border-radius:10px;background:#f4f3f6} .wc.on{background:#fdecea}
    .wd{text-align:center;font-size:13px;font-weight:700;color:#8e8e93;padding-top:4px} .wc.on .wd{color:${RED}} .wb{position:absolute;left:4px;right:4px;border-radius:6px;opacity:.9}
    .chip{display:inline-flex;align-items:center;gap:8px;background:#f4f3f6;border-radius:14px;padding:8px 12px;font-weight:700;font-size:17px;margin:4px 6px 0 0}
  </style></head><body><div style="width:${w}px;height:${h}px;overflow:hidden"><div class="stage" style="transform:scale(${z});transform-origin:0 0">
    <div class="grid">
      <div class="card" style="margin-top:150px">${head(RED, clock, 'Up Next')}<div class="big">12:30</div><div class="ev"><div class="bar" style="background:${RED}"></div><div><div class="ti">🥗 Lunch</div><div class="sb">Café de Zon · in 25 min</div></div></div></div>
      <div class="card" style="margin-top:60px">${head(RED, cal, 'Today')}${row('#007AFF', '09:30', '1:1 with Lisa', 'Studio 4')}${row(RED, '12:30', '🥗 Lunch', 'Café de Zon')}${row('#34C759', '16:00', 'School pick-up', '')}</div>
      <div class="card">${head(RED, cal, 'October')}${month}</div>
      <div class="card">${head('#FF9500', flag, 'Countdown')}<div class="big">12<small>days</small></div><div class="sb" style="margin-top:8px;font-size:18px">🏖️ Autumn break</div></div>
      <div class="card">${head(RED, cal, 'Week 44')}${week}</div>
      <div class="card">${head('#5856D6', house, 'Homey Flow')}<div class="chip">${cal.replace('currentColor', RED).replace('currentColor', RED)} Event starts</div><div class="chip">💡 Lights on</div><div class="chip">🌡️ Heating 20°</div></div>
      <div class="card">${head('#34C759', cal, 'Tomorrow')}${row('#34C759', '', '♻️ Paper bin', 'All day')}${row('#007AFF', '10:00', 'Team planning', '')}</div>
      <div class="card">${head('#007AFF', clock, 'Week Number')}<div class="big">44</div><div class="sb" style="font-size:18px">26 Oct – 1 Nov</div></div>
      <div class="card">${head(RED, cal, 'Agenda')}<div class="big" style="font-size:44px">3<small>events today</small></div></div>
    </div>
    <div style="position:absolute;left:56px;bottom:54px;width:150px;height:150px;border-radius:36px;overflow:hidden;box-shadow:0 26px 50px -10px rgba(90,20,20,.45)"><img src="${icon}" style="width:100%;height:100%"></div>
  </div></div></body></html>`;
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
