// Cookie notice (GDPR/ePrivacy), ported from bingr.online. Necessary storage (this choice, ?lang= for the session)
// is always on. Google Fonts (Inter, a third party) only loads after "Accept". The choice is kept for 12 months.
// Texts come from window.WEEKDOT_I18N in the language picked by lang.js (window.WeekdotLang).
(function () {
  "use strict";
  var KEY = "weekdot_consent", MAX = 365 * 24 * 3600, MAX_MS = MAX * 1000;
  var I18N = window.WEEKDOT_I18N || { en: {} };
  var lang = (window.WeekdotLang && window.WeekdotLang.lang) || "en";
  function t(k) { return ((I18N[lang] || {})[k]) || ((I18N.en || {})[k]) || ""; }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }

  function valid(v) { return v && (v.choice === "all" || v.choice === "necessary") && !(Date.now() - Date.parse(v.at) > MAX_MS); }
  function read() {
    try { var v = JSON.parse(localStorage.getItem(KEY)); if (valid(v)) return v; } catch (e) {}
    var m = document.cookie.match(/(?:^|; )weekdot_consent=([^;]+)/);
    if (m) { try { var c = JSON.parse(decodeURIComponent(m[1])); if (valid(c)) return c; } catch (e) {} }
    return null;
  }
  function save(choice) {
    var v = { choice: choice, at: new Date().toISOString(), v: 1 };
    try { localStorage.setItem(KEY, JSON.stringify(v)); } catch (e) {}
    try {
      document.cookie = KEY + "=" + encodeURIComponent(JSON.stringify(v)) + "; Max-Age=" + MAX + "; Path=/; SameSite=Lax" +
        (location.protocol === "https:" ? "; Secure" : "");
    } catch (e) {}
    return v;
  }
  function fonts() {
    if (document.getElementById("weekdot-fonts")) return;
    var l = document.createElement("link"); l.id = "weekdot-fonts"; l.rel = "stylesheet";
    l.href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap";
    document.head.appendChild(l);
  }

  var COOKIE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.3A9 9 0 1 1 11.7 3a3 3 0 0 0 3.8 3.8 3 3 0 0 0 3.7 3.7 3 3 0 0 0 1.8 1.8z"/><circle cx="8.5" cy="10.5" r="1" fill="currentColor"/><circle cx="12" cy="15.5" r="1" fill="currentColor"/><circle cx="16" cy="14" r="1" fill="currentColor"/><circle cx="8" cy="15" r=".6" fill="currentColor"/></svg>';

  // non-modal dialog: named by its heading, focus moves to it when shown and back to where it was when closed
  function banner() {
    if (document.getElementById("weekdot-consent")) return;
    var prev = document.activeElement;
    var d = document.createElement("div");
    d.id = "weekdot-consent"; d.setAttribute("role", "dialog"); d.setAttribute("aria-modal", "false");
    d.setAttribute("aria-labelledby", "weekdot-consent-t"); d.setAttribute("aria-describedby", "weekdot-consent-p"); d.tabIndex = -1;
    d.innerHTML = '<div class="t" id="weekdot-consent-t">' + esc(t("consent.title")) + "</div>" +
      '<p id="weekdot-consent-p">' + esc(t("consent.text")) + ' <a href="/privacy/#cookies">' + esc(t("consent.more")) + "</a></p>" +
      '<div class="b"><button type="button" class="y">' + esc(t("consent.accept")) + '</button><button type="button" class="n">' +
      esc(t("consent.necessary")) + "</button></div>";
    function close(choice) {
      save(choice); if (choice === "all") fonts();
      var hadFocus = d.contains(document.activeElement);
      d.remove(); showBubble(true);
      if (hadFocus) {
        var back = prev && prev !== document.body && document.contains(prev) ? prev : document.getElementById("weekdot-cookie-btn");
        if (back && back.focus) try { back.focus({ preventScroll: true }); } catch (e) { back.focus(); }
      }
    }
    d.querySelector(".y").onclick = function () { close("all"); };
    d.querySelector(".n").onclick = function () { close("necessary"); };
    (document.body || document.documentElement).appendChild(d);
    try { d.focus({ preventScroll: true }); } catch (e) { d.focus(); }
  }

  // small round cookie button bottom-left (once a choice exists): tap = show the notice again
  function bubble() {
    if (document.getElementById("weekdot-cookie-btn")) return;
    var b = document.createElement("button"); b.id = "weekdot-cookie-btn"; b.type = "button";
    b.title = t("consent.settings"); b.setAttribute("aria-label", b.title);
    b.innerHTML = COOKIE;
    b.onclick = function () { open(); };
    (document.body || document.documentElement).appendChild(b);
  }
  function showBubble(on) { var b = document.getElementById("weekdot-cookie-btn"); if (on) bubble(); else if (b) b.remove(); }
  function open() { var x = document.getElementById("weekdot-consent"); if (x) x.remove(); showBubble(false); banner(); }

  window.WeekdotConsent = { open: open, get: read };
  var c = read();
  if (c && c.choice === "all") fonts();
  function start() {
    if (c) bubble(); else banner();
    // footer link "Cookie settings" (falls back to /privacy/#cookies without JavaScript)
    Array.prototype.forEach.call(document.querySelectorAll("[data-consent-open]"), function (a) {
      a.addEventListener("click", function (e) { e.preventDefault(); open(); });
    });
  }
  // after app.js has applied the language (it un-hides the page on DOMContentLoaded), so the dialog can take focus
  // (deferred scripts already run in readyState "interactive", before DOMContentLoaded fires)
  var started = false;
  function go() { if (!started) { started = true; start(); } }
  if (document.readyState === "complete") go();
  else { document.addEventListener("DOMContentLoaded", go); window.addEventListener("load", go); }
})();
