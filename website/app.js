(function () {
  "use strict";
  var I18N = window.WEEKDOT_I18N || { en: {} };
  var RTL = ["ar", "he"];
  var RED = "#e8352f";
  var WX = {"sun": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\"><circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4\"/></svg>", "cloud": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 18a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A4 4 0 0 1 17.5 18z\"/></svg>", "rain": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 15a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A4 4 0 0 1 17.5 15z\"/><path d=\"M8 18l-1 2M12 18l-1 2M16 18l-1 2\"/></svg>", "pcloud": "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M9 5v1M4.5 9.5h1M5.8 5.8l.7.7M12.2 6.5l.7-.7\"/><path d=\"M6 11a3.5 3.5 0 0 1 6.6-1.4\"/><path d=\"M9 20a4 4 0 0 1-.4-8 5 5 0 0 1 9.6.5A3.7 3.7 0 0 1 18 20z\"/></svg>"};

  function pickLanguage() {
    var prefs = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || "en"];
    for (var i = 0; i < prefs.length; i++) {
      var p = prefs[i], low = p.toLowerCase();
      if (I18N[p]) return p;
      if (low.indexOf("zh") === 0) return /hant|tw|hk|mo/.test(low) ? "zh-Hant" : "zh-Hans";
      if (low.indexOf("pt") === 0) return low === "pt-br" ? "pt-BR" : "pt-PT";
      var base = low.split("-")[0];
      if (base === "no" || base === "nn") base = "nb";
      if (I18N[base]) return base;
    }
    return "en";
  }
  var lang = pickLanguage();
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
    var title = document.querySelector("[data-i18n-title]");
    if (title) { var tv = t(title.getAttribute("data-i18n-title")); document.title = tv ? "Weekdot — " + tv : "Weekdot"; }
    render();
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
    // the 7 dots light up today's weekday
    $$(".dots7").forEach(function (g) { $$(".dots7 i").forEach(function () {}); Array.prototype.forEach.call(g.children, function (d, i) { d.className = i === dow ? "on" : ""; }); });
  }

  document.addEventListener("DOMContentLoaded", function () {
    apply();
    var y = document.getElementById("year"); if (y) y.textContent = new Date().getFullYear();
    var top = document.querySelector(".top");
    if (top) window.addEventListener("scroll", function () { top.classList.toggle("scrolled", window.scrollY > 8); }, { passive: true });
  });
})();
