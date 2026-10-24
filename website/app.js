(function () {
  "use strict";
  var I18N = window.WEEKDOT_I18N || { en: {} };
  var RTL = ["ar", "he"];

  function pickLanguage() {
    try {
      var saved = localStorage.getItem("weekdot.lang");
      if (saved && I18N[saved]) return saved;
    } catch (e) {}
    var prefs = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || "en"];
    for (var i = 0; i < prefs.length; i++) {
      var p = prefs[i];
      var low = p.toLowerCase();
      if (I18N[p]) return p;
      if (low.indexOf("zh") === 0) {
        if (/hant|tw|hk|mo/.test(low)) return I18N["zh-Hant"] ? "zh-Hant" : "en";
        return I18N["zh-Hans"] ? "zh-Hans" : "en";
      }
      if (low.indexOf("pt") === 0) {
        if (low === "pt-br" && I18N["pt-BR"]) return "pt-BR";
        if (I18N["pt-PT"]) return "pt-PT";
      }
      var base = low.split("-")[0];
      if (base === "no" || base === "nn") base = "nb";
      if (I18N[base]) return base;
    }
    return "en";
  }

  var lang = pickLanguage();

  function t(key) {
    var d = I18N[lang] || {};
    return d[key] || (I18N.en || {})[key] || "";
  }

  function apply() {
    document.documentElement.lang = lang;
    document.documentElement.dir = RTL.indexOf(lang) >= 0 ? "rtl" : "ltr";
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var v = t(el.getAttribute("data-i18n"));
      if (v) el.textContent = v;
    });
    document.querySelectorAll("[data-i18n-content]").forEach(function (el) {
      var v = t(el.getAttribute("data-i18n-content"));
      if (v) el.setAttribute("content", v);
    });
    var title = document.querySelector("[data-i18n-title]");
    if (title) {
      var tv = t(title.getAttribute("data-i18n-title"));
      document.title = tv ? "Weekdot — " + tv : "Weekdot";
    }
    renderMockup();
  }

  function buildPicker() {
    var sel = document.getElementById("lang");
    if (!sel) return;
    var codes = Object.keys(I18N);
    var names = codes.map(function (c) {
      var name = c;
      try { name = new Intl.DisplayNames([c], { type: "language" }).of(c) || c; } catch (e) {}
      return { code: c, name: name.charAt(0).toLocaleUpperCase(c) + name.slice(1) };
    });
    names.sort(function (a, b) { return a.name.localeCompare(b.name); });
    sel.innerHTML = "";
    names.forEach(function (n) {
      var o = document.createElement("option");
      o.value = n.code;
      o.textContent = n.name;
      if (n.code === lang) o.selected = true;
      sel.appendChild(o);
    });
    sel.addEventListener("change", function () {
      lang = sel.value;
      try { localStorage.setItem("weekdot.lang", lang); } catch (e) {}
      apply();
    });
  }

  function renderMockup() {
    var box = document.getElementById("mock-week");
    if (!box) return;
    var now = new Date();
    var day = (now.getDay() + 6) % 7; // Monday first
    var monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - day);
    var locale = lang;
    var month = "";
    try { month = new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }).format(now); } catch (e) {}
    var head = document.getElementById("mock-month");
    if (head) head.textContent = month.charAt(0).toLocaleUpperCase(locale) + month.slice(1);
    var seg = document.getElementById("mock-seg");
    if (seg) {
      seg.innerHTML = ["Day", "Week", "Month", "Year", "List"].map(function (k) {
        return '<span class="' + (k === "Week" ? "on" : "") + '">' + esc(t("mock." + k) || k) + "</span>";
      }).join("");
    }
    var html = '<div class="d"></div>';
    for (var i = 0; i < 7; i++) {
      var d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      var wd = "";
      try { wd = new Intl.DateTimeFormat(locale, { weekday: "short" }).format(d).replace(".", ""); } catch (e) {}
      html += '<div class="d' + (i === day ? " today" : "") + '">' + esc(wd) + "<i>" + d.getDate() + "</i></div>";
    }
    var events = [
      [0, 1.0, 1.2, "#e8352f", "👥 " + t("mock.Meeting"), "09:00"],
      [1, 3.0, 1.0, "#34c759", "🏋️ " + t("mock.Gym"), "11:00"],
      [2, 0.5, 1.0, "#007aff", "🦷 " + t("mock.Dentist"), "08:30"],
      [2, 4.0, 1.0, "#ff9500", "🥪 " + t("mock.Lunch"), "12:00"],
      [3, 1.5, 2.0, "#e8352f", "👥 " + t("mock.Meeting"), "09:30"],
      [4, 2.5, 1.5, "#af52de", "🎂 " + t("mock.Birthday"), "10:30"],
      [5, 0.8, 2.6, "#32ade6", "✈️ " + t("mock.Flight"), "08:45"],
      [6, 3.5, 1.4, "#ff9500", "🏖️ " + t("mock.Holiday"), "11:30"]
    ];
    html += '<div class="grid">';
    events.forEach(function (e) {
      var col = e[0], top = e[1] * 50, h = e[2] * 50;
      var side = document.documentElement.dir === "rtl" ? "right" : "left";
      html += '<div class="ev" style="' + side + ":calc(30px + (100% - 30px) / 7 * " + col + " + 2px);width:calc((100% - 30px) / 7 - 4px);top:" +
        top + "px;height:" + h + "px;color:" + e[3] + ";background:" + e[3] + '22">' + esc(e[4]) + "<small>" + e[5] + "</small></div>";
    });
    html += '<div class="now" style="top:' + (2.2 * 50) + 'px"></div></div>';
    box.innerHTML = html;
  }

  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; });
  }

  document.addEventListener("DOMContentLoaded", function () {
    buildPicker();
    apply();
    var y = document.getElementById("year");
    if (y) y.textContent = new Date().getFullYear();
  });
})();
