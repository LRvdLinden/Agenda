// Picks the site language from the device, without a language picker.
// Chrome often lists its own UI language ("en-US") before the device language, so a supported
// non-English language anywhere in the list wins. If only a generic "en"/"en-US" is present, the
// time zone (and Intl locale) of the device is used as a hint. "?lang=xx" overrides it for this
// browser session only.  Shared by app.js and consent.js via window.WeekdotLang.
(function (root) {
  "use strict";
  var SUPPORTED = ["en", "ar", "ca", "cs", "da", "de", "el", "es", "fi", "fr", "he", "hi", "hr", "hu", "id", "it", "ja", "ko",
    "ms", "nb", "nl", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant"];
  var KEY = "weekdot.lang";
  // time zones of clearly non-English-speaking places (only used for generic en / en-US browsers)
  var TZ = {
    "Europe/Amsterdam": "nl", "Europe/Brussels": "nl", "America/Paramaribo": "nl", "America/Curacao": "nl", "America/Aruba": "nl",
    "Europe/Berlin": "de", "Europe/Vienna": "de", "Europe/Zurich": "de", "Europe/Busingen": "de", "Europe/Vaduz": "de",
    "Europe/Paris": "fr", "Europe/Luxembourg": "fr", "Europe/Monaco": "fr",
    "Europe/Madrid": "es", "Atlantic/Canary": "es", "America/Mexico_City": "es", "America/Bogota": "es", "America/Lima": "es",
    "America/Santiago": "es", "America/Argentina/Buenos_Aires": "es", "America/Buenos_Aires": "es", "America/Caracas": "es",
    "America/Montevideo": "es", "America/Guayaquil": "es", "America/La_Paz": "es", "America/Asuncion": "es",
    "America/Costa_Rica": "es", "America/Guatemala": "es", "America/Panama": "es", "America/Havana": "es",
    "America/Santo_Domingo": "es", "America/El_Salvador": "es", "America/Tegucigalpa": "es", "America/Managua": "es",
    "Europe/Andorra": "ca",
    "Europe/Rome": "it", "Europe/San_Marino": "it", "Europe/Vatican": "it",
    "Europe/Lisbon": "pt-PT", "Atlantic/Madeira": "pt-PT", "Atlantic/Azores": "pt-PT",
    "America/Sao_Paulo": "pt-BR", "America/Bahia": "pt-BR", "America/Fortaleza": "pt-BR", "America/Recife": "pt-BR",
    "America/Manaus": "pt-BR", "America/Belem": "pt-BR",
    "Europe/Stockholm": "sv", "Europe/Oslo": "nb", "Europe/Copenhagen": "da", "Europe/Helsinki": "fi",
    "Europe/Warsaw": "pl", "Europe/Prague": "cs", "Europe/Bratislava": "sk", "Europe/Budapest": "hu",
    "Europe/Bucharest": "ro", "Europe/Chisinau": "ro", "Europe/Zagreb": "hr", "Europe/Athens": "el", "Asia/Nicosia": "el",
    "Europe/Istanbul": "tr", "Asia/Istanbul": "tr", "Europe/Kiev": "uk", "Europe/Kyiv": "uk", "Europe/Moscow": "ru",
    "Asia/Tokyo": "ja", "Asia/Seoul": "ko", "Asia/Shanghai": "zh-Hans", "Asia/Chongqing": "zh-Hans", "Asia/Urumqi": "zh-Hans",
    "Asia/Taipei": "zh-Hant", "Asia/Hong_Kong": "zh-Hant", "Asia/Macau": "zh-Hant",
    "Asia/Bangkok": "th", "Asia/Ho_Chi_Minh": "vi", "Asia/Saigon": "vi", "Asia/Jakarta": "id", "Asia/Makassar": "id",
    "Asia/Jayapura": "id", "Asia/Kuala_Lumpur": "ms", "Asia/Kuching": "ms", "Asia/Jerusalem": "he", "Asia/Tel_Aviv": "he",
    "Asia/Kolkata": "hi", "Asia/Calcutta": "hi",
    "Asia/Riyadh": "ar", "Asia/Dubai": "ar", "Asia/Qatar": "ar", "Asia/Kuwait": "ar", "Asia/Bahrain": "ar", "Asia/Muscat": "ar",
    "Asia/Amman": "ar", "Asia/Baghdad": "ar", "Asia/Beirut": "ar", "Asia/Damascus": "ar", "Africa/Cairo": "ar",
    "Africa/Casablanca": "ar", "Africa/Algiers": "ar", "Africa/Tunis": "ar", "Africa/Tripoli": "ar"
  };
  var LOWER = {};
  SUPPORTED.forEach(function (c) { LOWER[c.toLowerCase()] = c; });

  // "nl-NL" -> "nl", "zh-TW" -> "zh-Hant", "pt" -> "pt-PT", "no" -> "nb"; unsupported -> null
  function normalize(tag) {
    if (!tag || typeof tag !== "string") return null;
    var low = tag.trim().replace(/_/g, "-").toLowerCase();
    if (!low) return null;
    if (LOWER[low]) return LOWER[low];
    var base = low.split("-")[0];
    if (base === "zh") return /hant|-tw|-hk|-mo/.test(low) ? "zh-Hant" : "zh-Hans";
    if (base === "pt") return /-br/.test(low) ? "pt-BR" : "pt-PT";
    if (base === "no" || base === "nn" || base === "nb") return "nb";
    if (base === "iw") return "he";
    if (base === "in") return "id";
    if (base === "zsm") return "ms";
    return LOWER[base] || null;
  }
  function isGenericEnglish(tag) { return /^en(?:[-_]us)?$/i.test(String(tag || "").trim()); }

  // languages: the browser's list (navigator.languages); locale / timeZone: from Intl
  function pick(languages, locale, timeZone) {
    var list = [];
    (languages || []).forEach(function (l) { if (l && typeof l === "string") list.push(l); });
    var english = [];
    for (var i = 0; i < list.length; i++) {
      var c = normalize(list[i]);
      if (c && c !== "en") return c;            // (a) first supported non-English language wins
      if (c === "en") english.push(list[i]);
    }
    if (!english.length) {                     // nothing supported in the list: only trust a non-English locale
      var l0 = normalize(locale);
      return l0 || "en";
    }
    // (b) only English: switch only for a generic en / en-US default in a clearly non-English place
    if (!english.every(isGenericEnglish)) return "en";
    var fromLocale = normalize(locale);
    if (fromLocale && fromLocale !== "en") return fromLocale;
    return (timeZone && TZ[timeZone]) || "en";
  }

  function override() {
    var q = null;
    try { q = normalize(new URLSearchParams(root.location.search).get("lang")); } catch (e) {}
    try {
      if (q) root.sessionStorage.setItem(KEY, q);
      else q = normalize(root.sessionStorage.getItem(KEY));
    } catch (e) {}
    return q;
  }

  function detect() {
    var nav = root.navigator || {};
    var langs = nav.languages && nav.languages.length ? Array.prototype.slice.call(nav.languages) : [nav.language || "en"];
    var ro = {};
    try { ro = Intl.DateTimeFormat().resolvedOptions() || {}; } catch (e) {}
    return pick(langs, ro.locale, ro.timeZone);
  }

  var lang = override() || detect();
  var dict = root.WEEKDOT_I18N || {};
  if (!dict[lang] && dict.en) lang = "en";
  root.WeekdotLang = { lang: lang, pick: pick, normalize: normalize, supported: SUPPORTED.slice(), timeZones: TZ };
})(typeof window !== "undefined" ? window : this);
