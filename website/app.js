(function () {
  "use strict";
  var I18N = window.WEEKDOT_I18N || window.SEVN_I18N || { en: {} };
  var RTL = ["ar", "he"];
  var RED = "#e8352f";

  function pickLanguage() {
    try {
      var saved = localStorage.getItem("weekdot.lang");
      if (saved && I18N[saved]) return saved;
    } catch (e) {}
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
  function t(key) { var d = I18N[lang] || {}; return d[key] || (I18N.en || {})[key] || ""; }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }
  function cap(s) { return s ? s.charAt(0).toLocaleUpperCase(lang) + s.slice(1) : s; }
  function fmt(d, o) { try { return new Intl.DateTimeFormat(lang, o).format(d); } catch (e) { return ""; } }

  function apply() {
    document.documentElement.lang = lang;
    document.documentElement.dir = RTL.indexOf(lang) >= 0 ? "rtl" : "ltr";
    document.querySelectorAll("[data-i18n]").forEach(function (el) { var v = t(el.getAttribute("data-i18n")); if (v) el.textContent = v; });
    document.querySelectorAll("[data-i18n-content]").forEach(function (el) { var v = t(el.getAttribute("data-i18n-content")); if (v) el.setAttribute("content", v); });
    var title = document.querySelector("[data-i18n-title]");
    if (title) { var tv = t(title.getAttribute("data-i18n-title")); document.title = tv ? "Weekdot — " + tv : "Weekdot"; }
    renderWeek(); renderMonth(); renderCalendars();
  }

  function buildPicker() {
    var sel = document.getElementById("lang");
    if (!sel) return;
    var names = Object.keys(I18N).map(function (c) {
      var name = c;
      try { name = new Intl.DisplayNames([c], { type: "language" }).of(c) || c; } catch (e) {}
      return { code: c, name: name.charAt(0).toLocaleUpperCase(c) + name.slice(1) };
    }).sort(function (a, b) { return a.name.localeCompare(b.name); });
    sel.innerHTML = "";
    names.forEach(function (n) {
      var o = document.createElement("option");
      o.value = n.code; o.textContent = n.name; if (n.code === lang) o.selected = true;
      sel.appendChild(o);
    });
    sel.addEventListener("change", function () {
      lang = sel.value;
      try { localStorage.setItem("weekdot.lang", lang); } catch (e) {}
      apply();
    });
  }

  var now = new Date();
  var dow = (now.getDay() + 6) % 7; // Monday first
  var monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dow);

  function header(idMonth, idToday) {
    var m = document.getElementById(idMonth);
    if (m) m.textContent = cap(fmt(now, { month: "long", year: "numeric" }));
    var td = document.getElementById(idToday);
    if (td) td.textContent = t("mock.Today") || "Today";
  }

  function renderWeek() {
    var box = document.getElementById("mock-week");
    if (!box) return;
    header("mock-month", "mock-today");
    var seg = document.getElementById("mock-seg");
    if (seg) seg.innerHTML = ["Day", "Week", "Month", "Year", "List"].map(function (k) {
      return '<span class="' + (k === "Week" ? "on" : "") + '">' + esc(t("mock." + k) || k) + "</span>";
    }).join("");
    // per day: [all-day items], [timed items]
    var ev = [
      [[["#ff9500", t("mock.Holiday")]], [["08:15", "#ffcc00", "School"], ["20:00", "#ff2d55", "Zumba"]]],
      [[], [["09:00", RED, t("mock.Meeting")], ["14:00", "#a2d729", "Jumbo"]]],
      [[["#af52de", t("mock.Birthday")]], [["11:30", "#007aff", t("mock.Meeting")], ["12:00", "#ff9500", t("mock.Lunch")]]],
      [[], [["08:30", "#32ade6", t("mock.Dentist")], ["18:00", "#34c759", t("mock.Gym")]]],
      [[["#ff9500", t("mock.Holiday")]], [["10:00", RED, t("mock.Meeting")], ["19:30", "#5856d6", "F1"]]],
      [[], [["11:00", "#34c759", t("mock.Gym")]]],
      [[["#32ade6", t("mock.Flight")]], []]
    ];
    function day(i) {
      var d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      var label = fmt(d, { weekday: "short", day: "numeric", month: "short" }).replace(/\./g, "");
      var h = '<div class="dbox' + (i === dow ? " today" : "") + '"><h6>' + esc(label) + "</h6>";
      ev[i][0].forEach(function (a) { h += '<div class="ad" style="background:' + a[0] + '">' + esc(a[1]) + "</div>"; });
      ev[i][1].forEach(function (e) { h += '<div class="te"><i style="background:' + e[1] + '">' + e[0] + "</i>" + esc(e[2]) + "</div>"; });
      return h + "</div>";
    }
    box.innerHTML = '<div class="wcol l">' + day(0) + day(1) + day(2) + '</div><div class="wcol r">' + day(3) + day(4) + day(5) + day(6) + "</div>";
  }

  function renderMonth() {
    var box = document.getElementById("mock-month-grid");
    if (!box) return;
    header("mock-month2", "mock-today2");
    var first = new Date(now.getFullYear(), now.getMonth(), 1);
    var start = new Date(first.getFullYear(), first.getMonth(), 1 - ((first.getDay() + 6) % 7));
    var h = "";
    for (var i = 0; i < 7; i++) {
      var wd = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      h += '<div class="wd">' + esc(fmt(wd, { weekday: "narrow" })) + "</div>";
    }
    var colors = [RED, "#007aff", "#34c759", "#ff9500", "#af52de", "#32ade6", "#ffcc00"];
    var words = [t("mock.Meeting"), t("mock.Gym"), t("mock.Lunch"), t("mock.Dentist"), t("mock.Birthday"), t("mock.Flight")];
    for (var c = 0; c < 35; c++) {
      var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + c);
      var inMonth = d.getMonth() === now.getMonth();
      var isToday = d.toDateString() === now.toDateString();
      h += '<div class="mcell' + (inMonth ? "" : " out") + '"><div class="n' + (isToday ? " t" : "") + '">' + d.getDate() + "</div>";
      var n = (d.getDate() * 7 + d.getMonth()) % 3;
      for (var k = 0; k < n; k++) {
        var idx = (d.getDate() + k * 3) % colors.length;
        h += '<div class="c" style="background:' + colors[idx] + '">' + esc(words[(d.getDate() + k) % words.length] || "") + "</div>";
      }
      h += "</div>";
    }
    box.innerHTML = h;
  }

  function renderCalendars() {
    var box = document.getElementById("mock-cals");
    if (!box) return;
    var tick = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>';
    function row(color, name, note) {
      return '<div class="crow"><span class="dot" style="background:' + color + '">' + tick + "</span>" + esc(name) + (note ? "<em>" + esc(note) + "</em>" : "") + "</div>";
    }
    var h = "<h5>Weekdot</h5>" + row(RED, "Weekdot") + row("#34c759", t("mock.Gym"));
    h += "<h5>iCloud</h5>" + row("#007aff", t("mock.Meeting")) + row("#af52de", t("mock.Birthdays"));
    h += "<h5>Google</h5>" + row("#ff9500", t("mock.Holiday"), "Google");
    h += "<h5>" + esc(t("mock.Color") || "Color") + '</h5><div class="swatches">';
    ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#00c7be", "#007aff", "#5856d6", "#af52de"].forEach(function (c, i) {
      h += '<span class="' + (i === 5 ? "sel" : "") + '" style="background:' + c + '"></span>';
    });
    box.innerHTML = h + "</div>";
  }

  document.addEventListener("DOMContentLoaded", function () {
    buildPicker();
    apply();
    var y = document.getElementById("year");
    if (y) y.textContent = new Date().getFullYear();
  });
})();
