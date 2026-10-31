#!/usr/bin/env python3
"""Builds website/support/index.html from the hs.* strings in tools/i18n/source.json (English is the HTML default;
app.js swaps in the visitor's language). Also writes the FAQPage JSON-LD from the same strings.
Run: python3 tools/build_support.py && python3 tools/build_strings.py && python3 tools/bust_cache.py"""
import html, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = json.load(open(os.path.join(ROOT, "tools", "i18n", "source.json")))["web"]
TESTFLIGHT = "https://testflight.apple.com/join/kaFEvrXd"
COMMUNITY = "https://community.homey.app/t/app-pro-weekdot/161566"

def e(k):
    return html.escape(W[k], quote=False)

def ea(k):
    return html.escape(W[k], quote=True)

# topic id, number of questions, icon path(s)
# section ids used in the address bar (must not clash with ids app.js fills on the home page)
SID = {"start": "getting-started", "cals": "calendars", "views": "views", "subs": "subscriptions", "alerts": "alerts",
       "watch": "apple-watch", "sync": "sync", "homey": "homey"}
TOPICS = [
    ("start", 5, '<path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/>'),
    ("cals", 6, '<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>'),
    ("views", 7, '<rect x="3.5" y="4.5" width="7" height="7" rx="1.8"/><rect x="13.5" y="4.5" width="7" height="7" rx="1.8"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.8"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.8"/>'),
    ("subs", 5, '<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5a12.5 12.5 0 0 1 0 17M12 3.5a12.5 12.5 0 0 0 0 17M3.8 9.5h16.4M3.8 14.5h16.4"/>'),
    ("alerts", 7, '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z"/><path d="M10 21h4"/>'),
    ("watch", 4, '<rect x="6" y="6" width="12" height="12" rx="3.5"/><path d="M9 6l.8-3h4.4l.8 3M9 18l.8 3h4.4l.8-3M12 9.5V12l1.6 1.2"/>'),
    ("sync", 5, '<path d="M7 18.5h10a4 4 0 0 0 .6-7.96A6 6 0 0 0 6.1 9.2 4.7 4.7 0 0 0 7 18.5z"/><path d="m10 14 1.6 1.6L15 12"/>'),
    ("homey", 6, '<path d="M4 11 12 4l8 7"/><path d="M6 9.5V20h12V9.5"/><path d="M10 20v-5h4v5"/>'),
]

def svg(p, cls=""):
    return ('<svg class="%s" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" '
            'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">%s</svg>') % (cls, p)

CHECK = '<path d="m5 12.5 4.2 4.2L19 7"/>'
ARROW = '<path d="M5 12h14M13 6l6 6-6 6"/>'
EXT = '<path d="M14 5h5v5M19 5l-8 8"/><path d="M18 14v4a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 4 18V7.5A1.5 1.5 0 0 1 5.5 6H10"/>'

topics = "\n".join(
    '      <a class="sp-topic" href="#%s"><span class="sp-ic">%s</span><b data-i18n="hs.t.%s">%s</b>'
    '<small data-i18n="hs.t.%s.d">%s</small><em><span>%d</span> <span data-i18n="hs.count">%s</span></em></a>'
    % (SID[t], svg(ic), t, e("hs.t." + t), t, e("hs.t.%s.d" % t), n, e("hs.count")) for t, n, ic in TOPICS)

sections = []
faq_ld = []
for t, n, ic in TOPICS:
    qs = []
    for i in range(1, n + 1):
        k = "hs.%s.%d" % (t, i)
        extra = ""
        if k == "hs.start.3":
            extra = '<a class="sp-more" href="%s" target="_blank" rel="noopener"><span data-i18n="hs.st.cta">%s</span>%s</a>' % (TESTFLIGHT, e("hs.st.cta"), svg(EXT))
        elif k == "hs.sync.5":
            extra = '<a class="sp-more" href="/privacy/"><span data-i18n="hs.c3.cta">%s</span>%s</a>' % (e("hs.c3.cta"), svg(ARROW))
        elif t == "homey" and i == n:
            extra = '<a class="sp-more" href="%s" target="_blank" rel="noopener"><span data-i18n="hs.homey.more">%s</span>%s</a>' % (COMMUNITY, e("hs.homey.more"), svg(EXT))
        qs.append('      <details id="%s-%d"><summary data-i18n="%s.q">%s</summary><div class="sp-a"><p data-i18n="%s.a">%s</p>%s</div></details>'
                  % (SID[t], i, k, e(k + ".q"), k, e(k + ".a"), extra))
        faq_ld.append({"@type": "Question", "name": W[k + ".q"], "acceptedAnswer": {"@type": "Answer", "text": W[k + ".a"]}})
    sections.append(
        '    <section class="sp-sec" id="%s" data-topic>\n      <h2><span class="sp-ic">%s</span><span data-i18n="hs.t.%s">%s</span></h2>\n%s\n    </section>'
        % (SID[t], svg(ic), t, e("hs.t." + t), "\n".join(qs)))

checks = "\n".join('        <li>%s<span data-i18n="hs.chk%d">%s</span></li>' % (svg(CHECK), i, e("hs.chk%d" % i)) for i in range(1, 7))

ld = {"@context": "https://schema.org", "@graph": [
    {"@type": "FAQPage", "@id": "https://weekdot.com/support/#faq", "url": "https://weekdot.com/support/", "name": "Weekdot — " + W["hs.title"],
     "inLanguage": "en", "mainEntity": faq_ld},
    {"@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": 1, "name": "Weekdot", "item": "https://weekdot.com/"},
        {"@type": "ListItem", "position": 2, "name": W["hs.title"], "item": "https://weekdot.com/support/"}]}]}

meta = ea("hs.meta")
title = "Weekdot — " + ea("hs.title")
page = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<meta name="description" content="{meta}" data-i18n-content="hs.meta">
<meta name="keywords" content="Weekdot help, Weekdot support, calendar app help, iPhone calendar, Google Calendar iPhone, Outlook calendar iPhone, calendar widgets, Apple Watch complications, iCloud calendar sync, Homey calendar, TestFlight beta, Weekdot">
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1">
<meta name="author" content="LRvdLinden">
<meta name="application-name" content="Weekdot">
<meta name="apple-mobile-web-app-title" content="Weekdot">
<meta name="apple-itunes-app" content="app-id=6826670273">
<link rel="canonical" href="https://weekdot.com/support/">
<link rel="alternate" hreflang="x-default" href="https://weekdot.com/support/">
<link rel="sitemap" type="application/xml" href="/sitemap.xml">
<meta name="theme-color" content="#e8352f">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Weekdot">
<meta property="og:url" content="https://weekdot.com/support/">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{meta}">
<meta property="og:image" content="https://weekdot.com/assets/og-en.jpg">
<meta property="og:image:secure_url" content="https://weekdot.com/assets/og-en.jpg">
<meta property="og:image:type" content="image/jpeg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="Weekdot — your week at a glance: the week view and sports subscriptions on iPhone">
<meta property="og:locale" content="en_US">
<meta property="og:locale:alternate" content="nl_NL">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{meta}">
<meta name="twitter:image" content="https://weekdot.com/assets/og-en.jpg">
<meta name="twitter:image:alt" content="Weekdot — your week at a glance: the week view and sports subscriptions on iPhone">
<link rel="icon" type="image/png" href="/assets/favicon.png">
<link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
<script>document.documentElement.setAttribute("data-i18n-wait","");setTimeout(function(){{document.documentElement.removeAttribute("data-i18n-wait")}},1500)</script>
<style>html[data-i18n-wait] body{{visibility:hidden}}</style>
<link rel="stylesheet" href="/styles.css">
<script src="/i18n.js" defer></script>
<script src="/lang.js" defer></script>
<script src="/app.js" defer></script>
<script src="/support.js" defer></script>
<script src="/consent.js" defer></script>
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False, separators=(",", ":"))}</script>
</head>
<body>
<header class="top">
  <div class="wrap">
    <a class="brand" href="/"><img src="/assets/icon.png" alt="">Weekdot</a>
    <nav class="nav">
      <a class="hide-sm" href="/#features" data-i18n="nav.features">Features</a>
      <a class="hide-sm" href="/#faq" data-i18n="nav.faq">FAQ</a>
      <a href="/support/" data-i18n="nav.support" aria-current="page">Support</a>
    </nav>
  </div>
</header>
<main class="support" data-i18n-title="hs.title">
  <section class="sp-hero">
    <div class="wrap">
      <p class="kicker" data-i18n="nav.support">Support</p>
      <h1 data-i18n="hs.h1">{e("hs.h1")}</h1>
      <p class="lead" data-i18n="hs.sub">{e("hs.sub")}</p>
      <form class="sp-search" role="search" onsubmit="return false">
        {svg('<circle cx="11" cy="11" r="6.5"/><path d="m20 20-4.4-4.4"/>')}
        <input id="sp-q" type="search" autocomplete="off" spellcheck="false" placeholder="{ea("hs.search")}" data-i18n-ph="hs.search" aria-label="{ea("hs.search.label")}" data-i18n-aria="hs.search.label">
        <kbd aria-hidden="true">/</kbd>
      </form>
    </div>
  </section>

  <div class="wrap sp-body">
    <section class="sp-block sp-steps" data-hide-on-search>
      <h2 data-i18n="hs.start.h">{e("hs.start.h")}</h2>
      <ol>
        <li><span class="sp-num">1</span><b data-i18n="hs.st1.t">{e("hs.st1.t")}</b><p data-i18n="hs.st1.d">{e("hs.st1.d")}</p><a class="sp-more" href="{TESTFLIGHT}" target="_blank" rel="noopener"><span data-i18n="hs.st.cta">{e("hs.st.cta")}</span>{svg(EXT)}</a></li>
        <li><span class="sp-num">2</span><b data-i18n="hs.st2.t">{e("hs.st2.t")}</b><p data-i18n="hs.st2.d">{e("hs.st2.d")}</p></li>
        <li><span class="sp-num">3</span><b data-i18n="hs.st3.t">{e("hs.st3.t")}</b><p data-i18n="hs.st3.d">{e("hs.st3.d")}</p></li>
      </ol>
    </section>

    <section class="sp-block" data-hide-on-search>
      <h2 data-i18n="hs.topics.h">{e("hs.topics.h")}</h2>
      <nav class="sp-topics" aria-labelledby="">
{topics}
      </nav>
    </section>

    <div class="sp-faq faq">
{chr(10).join(sections)}
      <p class="sp-none" hidden data-i18n="hs.none">{e("hs.none")}</p>
    </div>

    <section class="sp-block sp-checks">
      <div>
        <h2 data-i18n="hs.checks.h">{e("hs.checks.h")}</h2>
        <p data-i18n="hs.checks.sub">{e("hs.checks.sub")}</p>
      </div>
      <ul>
{checks}
      </ul>
    </section>

    <section class="sp-block sp-contact" id="contact">
      <h2 data-i18n="hs.contact.h">{e("hs.contact.h")}</h2>
      <p class="sp-intro" data-i18n="hs.contact.sub">{e("hs.contact.sub")}</p>
      <div class="sp-cards">
        <a class="sp-card" href="{TESTFLIGHT}" target="_blank" rel="noopener"><span class="sp-ic">{svg('<path d="M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v8a2.5 2.5 0 0 1-2.5 2.5H10l-4.5 3.5V17A1.5 1.5 0 0 1 4 15.5z"/><path d="M8.5 9.5h7M8.5 12.5h4.5"/>')}</span><b data-i18n="hs.c1.t">{e("hs.c1.t")}</b><p data-i18n="hs.c1.d">{e("hs.c1.d")}</p><span class="sp-more"><span data-i18n="hs.c1.cta">{e("hs.c1.cta")}</span>{svg(EXT)}</span></a>
        <a class="sp-card" href="{COMMUNITY}" target="_blank" rel="noopener"><span class="sp-ic">{svg('<circle cx="9" cy="9" r="3.2"/><circle cx="17" cy="10" r="2.5"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0M14.5 15.3a4.4 4.4 0 0 1 6 3.7"/>')}</span><b data-i18n="hs.c2.t">{e("hs.c2.t")}</b><p data-i18n="hs.c2.d">{e("hs.c2.d")}</p><span class="sp-more"><span data-i18n="hs.c2.cta">{e("hs.c2.cta")}</span>{svg(EXT)}</span></a>
        <a class="sp-card" href="/privacy/"><span class="sp-ic">{svg('<path d="M12 3.5 5 6v5.5c0 4.3 3 7.8 7 9 4-1.2 7-4.7 7-9V6z"/><path d="m9.2 12 2 2 3.8-4"/>')}</span><b data-i18n="hs.c3.t">{e("hs.c3.t")}</b><p data-i18n="hs.c3.d">{e("hs.c3.d")}</p><span class="sp-more"><span data-i18n="hs.c3.cta">{e("hs.c3.cta")}</span>{svg(ARROW)}</span></a>
      </div>
    </section>
  </div>
</main>
<footer>
  <div class="wrap">
    <span>© <span id="year">2026</span> Weekdot. <span data-i18n="footer.rights">All rights reserved.</span></span>
    <nav>
      <a href="/privacy/" data-i18n="nav.privacy">Privacy</a>
      <a href="/support/" data-i18n="nav.support">Support</a>
      <a href="/privacy/#cookies" data-consent-open data-i18n="foot.cookies">Cookie settings</a>
    </nav>
  </div>
</footer>
</body>
</html>
'''
page = page.replace(' aria-labelledby=""', "")
open(os.path.join(ROOT, "website", "support", "index.html"), "w", encoding="utf-8").write(page)
print("support/index.html:", sum(n for _, n, _ in TOPICS), "questions")
