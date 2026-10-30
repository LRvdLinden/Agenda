(function () {
  "use strict";
  var I18N = window.WEEKDOT_I18N || { en: {} };
  var RTL = ["ar", "he"];
  var RED = "#e8352f";
  var WX = {"sun": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\"><circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4\"/></svg>", "cloud": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 18a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A4 4 0 0 1 17.5 18z\"/></svg>", "rain": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 15a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A4 4 0 0 1 17.5 15z\"/><path d=\"M8 18l-1 2M12 18l-1 2M16 18l-1 2\"/></svg>", "pcloud": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M9 5v1M4.5 9.5h1M5.8 5.8l.7.7M12.2 6.5l.7-.7\"/><path d=\"M6 11a3.5 3.5 0 0 1 6.6-1.4\"/><path d=\"M9 20a4 4 0 0 1-.4-8 5 5 0 0 1 9.6.5A3.7 3.7 0 0 1 18 20z\"/></svg>"};

  // language: see lang.js (device language, Chrome-safe, ?lang= override)
  var lang = (window.WeekdotLang && window.WeekdotLang.lang) || "en";
  if (!I18N[lang]) lang = "en";
  function t(k) { var d = I18N[lang] || {}; return d[k] || (I18N.en || {})[k] || ""; }
  function m(k) { return t("mock." + k) || k; }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }
  function cap(s) { return s ? s.charAt(0).toLocaleUpperCase(lang) + s.slice(1) : s; }
  function fmt(d, o) { try { return new Intl.DateTimeFormat(lang, o).format(d); } catch (e) { return ""; } }
  function $$(sel) { return Array.prototype.slice.call(document.querySelectorAll(sel)); }

  var now = new Date();
  var dow = (now.getDay() + 6) % 7;
  var monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dow);
  function addDays(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n); }

  function apply() {
    document.documentElement.lang = lang;
    document.documentElement.dir = RTL.indexOf(lang) >= 0 ? "rtl" : "ltr";
    $$("[data-i18n]").forEach(function (el) { var v = t(el.getAttribute("data-i18n")); if (v) el.textContent = v; });
    $$("[data-i18n-content]").forEach(function (el) { var v = t(el.getAttribute("data-i18n-content")); if (v) el.setAttribute("content", v); });
    $$("[data-i18n-alt]").forEach(function (el) { var v = t(el.getAttribute("data-i18n-alt")); if (v) el.setAttribute("alt", v); });
    $$("[data-i18n-aria]").forEach(function (el) { var v = t(el.getAttribute("data-i18n-aria")); if (v) el.setAttribute("aria-label", v); });
    var title = document.querySelector("[data-i18n-title]");
    if (title) { var tv = t(title.getAttribute("data-i18n-title")); document.title = tv ? "Weekdot — " + tv : "Weekdot"; }
    render();
    document.documentElement.removeAttribute("data-i18n-wait");
  }

  function week() {
    var ev = [
      [[["#ff9500", m("Holiday")]], [["08:15", "#ffcc00", "School"], ["20:00", "#ff2d55", "Zumba"]]],
      [[], [["09:00", RED, m("Meeting")], ["14:00", "#34c759", m("Gym")]]],
      [[["#af52de", m("Birthday")]], [["11:30", "#007aff", m("Meeting")], ["12:00", "#ff9500", m("Lunch")]]],
      [[], [["08:30", "#32ade6", m("Dentist")], ["18:00", "#34c759", m("Gym")]]],
      [[["#ff9500", m("Holiday")]], [["10:00", RED, m("Meeting")], ["19:30", "#5856d6", "Formula 1"]]],
      [[], [["11:00", "#34c759", m("Gym")], ["20:00", "#ff2d55", m("Birthday")]]],
      [[["#32ade6", m("Flight")]], [["15:00", "#ff9500", m("Lunch")]]]
    ];
    function day(i) {
      var d = addDays(monday, i);
      var label = fmt(d, { weekday: "short", day: "numeric", month: "short" }).replace(/\./g, "");
      var h = '<div class="dbox' + (i === dow ? " today" : "") + '"><h6>' + esc(label) + "</h6>";
      ev[i][0].forEach(function (a) { h += '<div class="ad" style="background:' + a[0] + '">' + esc(a[1]) + "</div>"; });
      ev[i][1].forEach(function (e) { h += '<div class="te"><i style="background:' + e[1] + '">' + e[0] + "</i>" + esc(e[2]) + "</div>"; });
      return h + "</div>";
    }
    return '<div class="wcol l">' + day(0) + day(1) + day(2) + '</div><div class="wcol r">' + day(3) + day(4) + day(5) + day(6) + "</div>";
  }

  function month() {
    var first = new Date(now.getFullYear(), now.getMonth(), 1);
    var start = addDays(first, -((first.getDay() + 6) % 7));
    var h = "";
    for (var i = 0; i < 7; i++) h += '<div class="wd">' + esc(fmt(addDays(monday, i), { weekday: "short" }).replace(/\./g, "")) + "</div>";
    var colors = [RED, "#007aff", "#34c759", "#ff9500", "#af52de", "#32ade6", "#ffcc00"];
    var words = [m("Meeting"), m("Gym"), m("Lunch"), m("Dentist"), m("Birthday"), m("Flight"), m("Holiday")];
    for (var c = 0; c < 35; c++) {
      var d = addDays(start, c);
      var isToday = d.toDateString() === now.toDateString();
      h += '<div class="mcell' + (d.getMonth() === now.getMonth() ? "" : " out") + '"><div class="n' + (isToday ? " t" : "") + '">' + d.getDate() + "</div>";
      var n = (d.getDate() * 7 + 3) % 4;
      for (var k = 0; k < Math.min(n, 3); k++) {
        var idx = (d.getDate() * 3 + k * 5) % colors.length;
        h += '<div class="c" style="background:' + colors[idx] + '">' + esc(words[(d.getDate() + k) % words.length]) + "</div>";
      }
      h += "</div>";
    }
    return h;
  }

  function render() {
    var monthTitle = cap(fmt(now, { month: "long", year: "numeric" }));
    $$(".m-month").forEach(function (el) { el.textContent = monthTitle; });
    $$(".m-today").forEach(function (el) { el.textContent = m("Today"); });
    $$(".m-seg").forEach(function (el) {
      el.innerHTML = ["Day", "Week", "Month", "Year", "List"].map(function (k) { return '<span class="' + (k === "Week" ? "on" : "") + '">' + esc(m(k)) + "</span>"; }).join("");
    });
    var w = week();
    $$(".m-week").forEach(function (el) { el.innerHTML = w; });
    var mm = document.getElementById("mac-month"); if (mm) mm.innerHTML = month();

    var cals = [["Weekdot", RED], ["iCloud", "#007aff"], [m("Birthdays"), "#af52de"], ["Google", "#34c759"], [m("Holiday"), "#ff9500"]];
    var side = document.getElementById("mac-cals");
    if (side) side.innerHTML = "<h5>" + esc(m("Calendars")) + "</h5>" + cals.map(function (c) { return '<p><i style="background:' + c[1] + '"></i>' + esc(c[0]) + "</p>"; }).join("");

    var watch = document.getElementById("watch");
    if (watch) watch.innerHTML = "<h6>" + esc(cap(fmt(now, { weekday: "short", day: "numeric" }))) + "</h6>" +
      '<div class="wrow"><b>' + esc(m("Meeting")) + "</b><small>09:00 – 10:00</small></div>" +
      '<div class="wrow" style="border-color:#34c759"><b>' + esc(m("Gym")) + "</b><small>18:00 – 19:00</small></div>";

    // year heat map (26 weeks x 7 days)
    var heat = document.getElementById("heat");
    if (heat) {
      var h = "", seed = 7;
      for (var i = 0; i < 26 * 7; i++) {
        seed = (seed * 9301 + 49297) % 233280;
        var r = seed / 233280, lvl = r < .35 ? 0 : r < .6 ? 1 : r < .8 ? 2 : r < .93 ? 3 : 4;
        h += "<i" + (lvl ? ' class="l' + lvl + '"' : "") + "></i>";
      }
      // column-major: 7 rows per week
      heat.style.gridTemplateColumns = "repeat(26, 1fr)";
      heat.style.gridAutoFlow = "column";
      heat.style.gridTemplateRows = "repeat(7, 1fr)";
      heat.innerHTML = h;
      var keys = document.getElementById("heatkeys");
      if (keys) keys.innerHTML = '<i style="background:color-mix(in srgb, var(--ink) 7%, transparent)"></i><i style="background:color-mix(in srgb,#e8352f 25%,transparent)"></i><i style="background:color-mix(in srgb,#e8352f 50%,transparent)"></i><i style="background:color-mix(in srgb,#e8352f 75%,transparent)"></i><i style="background:#e8352f"></i>';
    }

    var ring = document.getElementById("ring");
    if (ring) {
      $$("#ring span").forEach(function (s) { s.remove(); });
      ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#00c7be", "#007aff", "#5856d6", "#af52de", "#ff2d55", "#a2845e"].forEach(function (c, i, a) {
        var ang = (i / a.length) * Math.PI * 2 - Math.PI / 2, s = document.createElement("span");
        s.style.background = c; s.style.transform = "translate(" + Math.cos(ang) * 76 + "px," + Math.sin(ang) * 76 + "px)";
        ring.appendChild(s);
      });
    }
    var dc = document.getElementById("dragcard"); if (dc) dc.textContent = "09:00 " + m("Meeting");

    var chips = document.getElementById("chips");
    if (chips) chips.innerHTML = [m("Meeting"), m("Lunch"), m("Gym"), m("Dentist"), m("Doctor")].map(function (w, i) { return '<span class="' + (i === 0 ? "hot" : "") + '">' + esc(w) + "</span>"; }).join("");
    var cc = document.getElementById("calchips");
    if (cc) cc.innerHTML = cals.concat([["Outlook", "#32ade6"], ["Exchange", "#5856d6"], ["CalDAV", "#a2845e"], [".ics", "#ff2d55"]]).map(function (c) {
      return '<span><i style="display:inline-block;width:9px;height:9px;border-radius:50%;margin-inline-end:7px;background:' + c[1] + '"></i>' + esc(c[0]) + "</span>";
    }).join("");

    var wgd = document.getElementById("wg-day"); if (wgd) wgd.textContent = fmt(now, { weekday: "short" }).replace(/\./g, "").toLocaleUpperCase(lang);
    var wgn = document.getElementById("wg-num"); if (wgn) wgn.textContent = now.getDate();
    var wl = document.getElementById("wg-list");
    if (wl) wl.innerHTML = '<div style="border-color:#e8352f">' + esc(m("Meeting")) + "<small>09:00</small></div>" +
      '<div style="border-color:#ff9500">' + esc(m("Lunch")) + "<small>12:30</small></div>" +
      '<div style="border-color:#34c759">' + esc(m("Gym")) + "<small>18:00</small></div>";

    // alert mock: relative time, day and duration come from the browser's own language data
    var CAR = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M5 11l1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11a2 2 0 0 1 2 2v4a1 1 0 0 1-1 1h-1a2 2 0 0 1-4 0H9a2 2 0 0 1-4 0H4a1 1 0 0 1-1-1v-4a2 2 0 0 1 2-2zm2.1 0h9.8l-1.2-3.6a.6.6 0 0 0-.6-.4H8.9a.6.6 0 0 0-.6.4z"/></svg>';
    var ZZZ = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6h6l-6 8h6M14 4h6l-6 8h6"/></svg>';
    function rel(n, unit) { try { return new Intl.RelativeTimeFormat(lang, { numeric: "auto" }).format(n, unit); } catch (e) { return ""; } }
    function mins(n) { try { return new Intl.NumberFormat(lang, { style: "unit", unit: "minute", unitDisplay: "short" }).format(n); } catch (e) { return n + " min"; } }
    var start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 14, 0);
    var tm = function (d) { return fmt(d, { hour: "numeric", minute: "2-digit" }); };
    var notif = document.getElementById("notif");
    if (notif) notif.innerHTML =
      '<div class="n"><div class="ic"><b><i></i><i></i><i></i><i></i><i></i><i></i><i></i></b><span>Weekdot</span></div>' +
      '<div class="tx"><small>Weekdot</small><strong>' + esc(m("Meeting")) + "</strong>" +
      '<span class="sl">' + esc(cap(rel(15, "minute"))) + " · iCloud</span><br>" +
      esc(cap(rel(0, "day"))) + " " + esc(tm(start)) + " – " + esc(tm(new Date(start.getTime() + 36e5))) + "<br>" +
      '<span class="car">' + CAR + esc(mins(11)) + "</span></div>" +
      '<div class="tile-d"><em>' + esc(fmt(now, { weekday: "short" }).replace(/\./g, "").toLocaleUpperCase(lang)) + "</em><strong>" + now.getDate() + "</strong></div></div>" +
      '<div class="acts"><span>' + ZZZ + esc(mins(10)) + "</span><span>" + CAR + esc(mins(11)) + "</span></div>";
    var wf = document.getElementById("wface");
    if (wf) {
      var dots = ""; for (var di = 0; di < 7; di++) dots += "<i" + (di === dow ? ' class="on"' : "") + "></i>";
      wf.innerHTML = '<div class="tm">' + esc(tm(new Date(start.getTime() - 15 * 6e4))) + "</div>" +
        '<div class="rect"><b>' + esc(m("Meeting")) + "</b><small>" + esc(tm(start)) + " – " + esc(tm(new Date(start.getTime() + 36e5))) + "</small></div>" +
        '<div class="circs"><div class="c"><em>' + esc(fmt(now, { weekday: "short" }).replace(/\./g, "").toLocaleUpperCase(lang)) + "</em><strong>" + now.getDate() + "</strong></div>" +
        '<div class="c ring"><span>15m</span></div><div class="c"><div class="dots">' + dots + "</div></div></div>";
    }
    var eta = document.getElementById("eta"); if (eta) eta.innerHTML = CAR + esc(mins(11));
    var go = document.getElementById("go"); if (go) go.innerHTML = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l9.5 9.5a.7.7 0 0 1 0 1L12 22l-9.5-9.5a.7.7 0 0 1 0-1zm-1 13h2v-3h2.5l-3.5-3.5L8.5 12H11z"/></svg>' + esc(tm(new Date(start.getTime() - 11 * 6e4)));

    var wx = document.getElementById("wx");
    if (wx) {
      var icons = ["sun", "pcloud", "cloud", "rain", "sun"], temps = [[17, 9], [15, 8], [13, 7], [11, 6], [16, 8]];
      wx.innerHTML = icons.map(function (ic, i) {
        return "<div>" + esc(fmt(addDays(now, i), { weekday: "short" }).replace(/\./g, "")) + WX[ic] + "<b>" + temps[i][0] + "°</b>" + temps[i][1] + "°</div>";
      }).join("");
    }
    renderSubs();
    renderSports();
    // the 7 dots light up today's weekday
    $$(".dots7").forEach(function (g) { $$(".dots7 i").forEach(function () {}); Array.prototype.forEach.call(g.children, function (d, i) { d.className = i === dow ? "on" : ""; }); });
  }


  // ---------- calendar subscriptions tile ----------
  var IC = {
    flag: '<path d="M6 21V4M6 4h10l-2 4 2 4H6"/>',
    school: '<path d="M3 9l9-5 9 5-9 5z"/><path d="M7 11.2V16c0 1.4 2.2 3 5 3s5-1.6 5-3v-4.8M21 9v5"/>',
    ball: '<circle cx="12" cy="12" r="9"/><path d="M12 7.5l4.2 3-1.6 4.9H9.4L7.8 10.5z"/><path d="M12 3v4.5M16.2 10.5l4.3-1.6M14.6 15.4l2.7 3.8M9.4 15.4l-2.7 3.8M7.8 10.5L3.5 8.9"/>',
    moon: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/><path d="M17 3.5v3M15.5 5h3"/>',
    bin: '<path d="M4 7h16M9 7V4.5h6V7M6 7l1 13h10l1-13"/><path d="M10 11v5M14 11v5"/>',
    link: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
    sync: '<path d="M20 11a8 8 0 0 0-14.3-4.3L4 8.5M4 13a8 8 0 0 0 14.3 4.3l1.7-1.8"/><path d="M4 4v4.5h4.5M20 20v-4.5h-4.5"/>',
    f1: '<path d="M5 21V4"/><path d="M5 4h14v9H5"/><path d="M5 4h3.5v3H5zM12 4h3.5v3H12zM8.5 7H12v3H8.5zM15.5 7H19v3h-3.5zM5 10h3.5v3H5zM12 10h3.5v3H12z" fill="currentColor" stroke="none"/>',
    tennis: '<circle cx="12" cy="12" r="9"/><path d="M5.6 5.6a9 9 0 0 1 0 12.8M18.4 5.6a9 9 0 0 0 0 12.8"/>',
    bike: '<circle cx="6" cy="16" r="4"/><circle cx="18" cy="16" r="4"/><path d="M6 16l4-8h5l3 8M10 8l3.5 8H6M14 5h2.5"/>',
    basket: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3v18M5.6 5.6c3 3 3 9.8 0 12.8M18.4 5.6c-3 3-3 9.8 0 12.8"/>',
    oval: '<ellipse cx="12" cy="12" rx="10" ry="6.2" transform="rotate(-35 12 12)"/><path d="M9 15l6-6M10.2 11.6l2.2 2.2M11.8 10l2.2 2.2"/>',
    moto: '<circle cx="5.5" cy="16.5" r="3.5"/><circle cx="18.5" cy="16.5" r="3.5"/><path d="M5.5 16.5L9 10h5l4.5 6.5M14 10l-1.5-3h3M9 10l-2-2.5H4.5"/>'
  };
  function icon(k) { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + IC[k] + "</svg>"; }

  function renderSubs() {
    var el = document.getElementById("subs");
    if (!el) return;
    var rows = [
      ["flag", "#e8352f", "sub.holidays", "60+", 1],
      ["school", "#ff9500", "sub.school", "", 1],
      ["ball", "#34c759", "sub.sports", "", 1],
      ["moon", "#5856d6", "sub.astro", "", 0],
      ["bin", "#00a5a8", "sub.waste", "NL · BE · NO", 1]
    ];
    el.innerHTML = rows.map(function (r) {
      return '<div class="srow"><span class="sic" style="background:' + r[1] + '">' + icon(r[0]) + '</span><span class="snm">' + esc(t(r[2])) +
        (r[3] ? "<small>" + esc(r[3]) + "</small>" : "") + '</span><span class="tog' + (r[4] ? " on" : "") + '"><i></i></span></div>';
    }).join("") +
      '<div class="srow link"><span class="sic">' + icon("link") + '</span><span class="snm"><code>webcal://…/calendar.ics</code></span><span class="plus">+</span></div>';
    var live = document.getElementById("sub-live");
    if (live) live.innerHTML = icon("sync") + esc(t("sub.live"));
  }

  // ---------- sports tile ----------
  function renderSports() {
    var pick = document.getElementById("sport-pick");
    if (!pick) return;
    pick.innerHTML = ["ball", "f1", "moto", "tennis", "bike", "oval", "basket"].map(function (k, i) {
      return '<span class="sp' + (i === 0 ? " on" : "") + '">' + icon(k) + "</span>";
    }).join("");
    // next Saturday / Sunday, formatted by the browser in the page language
    var sat = addDays(now, ((5 - dow) + 7) % 7 || 7), sun = addDays(sat, 1);
    function at(d, h, mi) { return new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, mi); }
    function day(d) { return cap(fmt(d, { weekday: "short", day: "numeric", month: "short" }).replace(/\./g, "")); }
    function tm(d) { return fmt(d, { hour: "numeric", minute: "2-digit" }); }
    function crest(a, b, kind) { return '<i class="crest ' + kind + '" style="--a:' + a + ";--b:" + b + '"></i>'; }
    var fx = document.getElementById("fixtures");
    if (fx) fx.innerHTML =
      '<div class="fx"><span class="fx-d">' + esc(day(sat)) + '</span><span class="vs">' + crest("#e8352f", "#ffffff", "half") + '<b>' + esc(tm(at(sat, 14, 30))) + "</b>" + crest("#0a84ff", "#ffffff", "stripe") + "</span></div>" +
      '<div class="fx"><span class="fx-d">' + esc(day(sat)) + '</span><span class="vs">' + crest("#34c759", "#ffffff", "ring") + '<b>' + esc(tm(at(sat, 20, 0))) + "</b>" + crest("#7b2cbf", "#ffffff", "half") + "</span></div>" +
      '<div class="fx race"><span class="fx-d">' + esc(day(sun)) + '</span><span class="vs"><span class="chq">' + icon("f1") + "</span><b>" + esc(tm(at(sun, 15, 0))) + "</b><em>Grand Prix</em></span></div>";
  }

  // ---------- real app screenshots in the device frames ----------
  // tools/bust_cache.py writes the available files into <meta name="weekdot-shots"> as {"<lang>": {"<slot>": "<hash>"}}.
  // A slot only gets an <img> when its file exists (no 404s); if it still fails to load, the HTML mock stays.
  var SHOT = {
    "iphone-week": [1179, 2556, "shot.iphone-week"], "iphone-month": [1179, 2556, "shot.iphone-month"],
    "ipad-week": [1668, 2388, "shot.ipad-week"], "mac-week": [2880, 1800, "shot.mac-week"], "watch-day": [396, 484, "shot.watch-day"]
  };
  function shots() {
    var meta = document.querySelector('meta[name="weekdot-shots"]');
    var have = {};
    try { have = JSON.parse(meta && meta.content || "{}") || {}; } catch (e) { have = {}; }
    var order = lang === "nl" ? ["nl", "en"] : ["en"];
    $$("[data-shot]").forEach(function (screen) {
      var slot = screen.getAttribute("data-shot"), spec = SHOT[slot];
      if (!spec || screen.querySelector("img.shot")) return;
      var from = null;
      for (var i = 0; i < order.length; i++) if (have[order[i]] && have[order[i]][slot]) { from = order[i]; break; }
      if (!from) return;
      var holder = screen.closest(".band-phone");
      var img = document.createElement("img");
      img.className = "shot";
      img.width = spec[0]; img.height = spec[1];
      img.alt = t(spec[2]);
      img.decoding = "async";
      img.loading = screen.hasAttribute("data-lazy") ? "lazy" : "eager";
      img.onload = function () { screen.classList.add("has-shot"); };
      img.onerror = function () {          // keep the HTML mock
        img.remove(); screen.classList.remove("has-shot");
        if (holder) { holder.hidden = true; holder.parentNode.classList.remove("has-phone"); }
      };
      if (holder) { holder.hidden = false; holder.parentNode.classList.add("has-phone"); }
      screen.appendChild(img);
      img.src = "/assets/shots/" + from + "/" + slot + ".png?v=" + encodeURIComponent(have[from][slot]);
    });
  }

  // ---------- gallery: big, readable screens (assets/shots/<lang>/gallery/<scene>.jpg) + lightbox ----------
  var GALLERY = ["week", "day", "month", "list", "event", "discover", "sports"];
  var gitems = [];
  function gallery() {
    var meta = document.querySelector('meta[name="weekdot-gallery"]'), have = {};
    try { have = JSON.parse(meta && meta.content || "{}") || {}; } catch (e) { have = {}; }
    var order = lang === "nl" ? ["nl", "en"] : ["en"];
    GALLERY.forEach(function (scene) {
      for (var i = 0; i < order.length; i++) {
        var h = have[order[i]] && have[order[i]][scene];
        if (h) { gitems.push({ scene: scene, src: "/assets/shots/" + order[i] + "/gallery/" + scene + ".jpg?v=" + encodeURIComponent(h), cap: t("gallery." + scene) }); break; }
      }
    });
    var strip = document.getElementById("gstrip");
    if (!strip) return;
    gitems.forEach(function (it, i) {
      var fig = document.createElement("figure"); fig.className = "g-item";
      var btn = document.createElement("button"); btn.type = "button"; btn.className = "g-frame"; btn.setAttribute("aria-label", it.cap);
      var img = document.createElement("img"); img.src = it.src; img.alt = it.cap; img.loading = "lazy"; img.decoding = "async"; img.width = 1000; img.height = 2173;
      btn.appendChild(img); btn.addEventListener("click", function () { openLightbox(i); });
      var cap = document.createElement("figcaption"); cap.textContent = it.cap;
      fig.appendChild(btn); fig.appendChild(cap); strip.appendChild(fig);
    });
    // the device screens in the hero and the band open the matching big screen too
    $$("[data-shot]").forEach(function (screen) {
      var scene = (screen.getAttribute("data-shot") || "").split("-")[1];
      screen.addEventListener("click", function () {
        for (var i = 0; i < gitems.length; i++) if (gitems[i].scene === scene) { openLightbox(i); return; }
      });
    });
    var lb = document.getElementById("lightbox");
    if (!lb) return;
    lb.querySelector(".lb-close").addEventListener("click", function () { lb.close(); });
    lb.querySelector(".lb-prev").addEventListener("click", function () { openLightbox(lbIndex - 1); });
    lb.querySelector(".lb-next").addEventListener("click", function () { openLightbox(lbIndex + 1); });
    lb.addEventListener("click", function (e) { if (e.target === lb || e.target.tagName === "FIGURE") lb.close(); });
    lb.addEventListener("keydown", function (e) {
      if (e.key === "ArrowRight") openLightbox(lbIndex + 1);
      if (e.key === "ArrowLeft") openLightbox(lbIndex - 1);
    });
    var x0 = null;
    lb.addEventListener("touchstart", function (e) { x0 = e.touches[0].clientX; }, { passive: true });
    lb.addEventListener("touchend", function (e) {
      if (x0 === null) return; var dx = e.changedTouches[0].clientX - x0; x0 = null;
      if (Math.abs(dx) > 50) openLightbox(lbIndex + (dx < 0 ? 1 : -1));
    });
  }
  var lbIndex = 0;
  function openLightbox(i) {
    var lb = document.getElementById("lightbox");
    if (!lb || !gitems.length || typeof lb.showModal !== "function") return;
    lbIndex = (i + gitems.length) % gitems.length;
    var it = gitems[lbIndex];
    lb.querySelector("img").src = it.src; lb.querySelector("img").alt = it.cap;
    lb.querySelector("figcaption").textContent = it.cap;
    if (!lb.open) lb.showModal();
  }

  document.addEventListener("DOMContentLoaded", function () {
    apply();
    shots();
    gallery();
    var y = document.getElementById("year"); if (y) y.textContent = new Date().getFullYear();
    var top = document.querySelector(".top");
    if (top) window.addEventListener("scroll", function () { top.classList.toggle("scrolled", window.scrollY > 8); }, { passive: true });
  });
})();
