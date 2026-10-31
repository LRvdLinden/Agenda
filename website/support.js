// Support page: live search through the questions, deep links to a question (#cals-1) and the "/" shortcut.
(function () {
  "use strict";
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
  function norm(s) { return String(s || "").toLocaleLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, ""); }

  function openHash() {
    var id = decodeURIComponent(location.hash.slice(1));
    if (!id) return;
    var el = document.getElementById(id);
    if (el && el.tagName === "DETAILS") {
      el.open = true;
      setTimeout(function () { el.scrollIntoView({ block: "center" }); el.classList.add("sp-flash"); }, 60);
      setTimeout(function () { el.classList.remove("sp-flash"); }, 1800);
    }
  }

  // "4 questions" needs another word form than "5 questions" in these languages
  var FEW = { ru: "вопроса", uk: "питання", pl: "pytania", cs: "otázky", sk: "otázky" };
  function plurals() {
    var lang = document.documentElement.lang, few = FEW[lang];
    if (!few || !window.Intl || !Intl.PluralRules) return;
    var pr = new Intl.PluralRules(lang);
    $$(".sp-topic em").forEach(function (em) {
      var n = parseInt(em.firstElementChild.textContent, 10);
      if (pr.select(n) === "few") em.lastElementChild.textContent = few;
    });
  }

  function init() {
    plurals();
    var q = document.getElementById("sp-q");
    if (!q) return;
    var items = $$(".sp-sec details");
    var secs = $$(".sp-sec");
    var hide = $$("[data-hide-on-search]");
    var none = document.querySelector(".sp-none");

    function filter() {
      var words = norm(q.value).split(/\s+/).filter(Boolean);
      var any = false;
      items.forEach(function (d) {
        var text = norm(d.textContent);
        var hit = words.every(function (w) { return text.indexOf(w) >= 0; });
        d.hidden = !hit;
        if (hit) any = true;
      });
      // open the matches only when there are just a few
      if (words.length) {
        var shown = items.filter(function (d) { return !d.hidden; });
        shown.forEach(function (d) { d.open = shown.length <= 3; });
      } else {
        items.forEach(function (d) { d.open = false; });
      }
      secs.forEach(function (s) { s.hidden = !$$("details", s).some(function (d) { return !d.hidden; }); });
      hide.forEach(function (h) { h.hidden = words.length > 0; });
      if (none) none.hidden = any;
    }
    q.addEventListener("input", filter);
    q.addEventListener("keydown", function (ev) { if (ev.key === "Escape") { q.value = ""; filter(); q.blur(); } });
    document.addEventListener("keydown", function (ev) {
      if (ev.key === "/" && document.activeElement !== q && !/input|textarea|select/i.test(document.activeElement.tagName)) {
        ev.preventDefault(); q.focus();
      }
    });

    // keep the address bar in sync with the open question, so it can be shared
    items.forEach(function (d) {
      d.addEventListener("toggle", function () {
        if (d.open && !q.value && history.replaceState) history.replaceState(null, "", "#" + d.id);
      });
    });
    window.addEventListener("hashchange", openHash);
    openHash();
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
})();
