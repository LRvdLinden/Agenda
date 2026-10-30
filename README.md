<p align="center"><img src="website/assets/icon.png" width="120" alt="Weekdot icon"></p>

<h1 align="center">Weekdot</h1>
<p align="center"><b>Your week at a glance.</b><br>A calendar for iPhone, iPad, Mac and Apple Watch — list, day, multiple days, week, multiple weeks, mini-month and year views on top of the calendars you already use.</p>

**Release version:** 1.0.0 (build 28). This package contains the same features as development build 26; only the release version has changed.

---

## Features

**Views**
- List, day, multiple days (2–6), **week (7 days, default)**, multiple weeks (2–4), mini-month and year
- On iPhone: native SwiftUI bottom tabs (like Samen) for Views, Add and Settings, with icon-only labels and selected-tab feedback. Choose the calendar mode from the chip beneath the date. On wide iPad/Mac layouts: retain the compact floating glass bottom menu. Calendars stays top-left and Search top-right in the calendar.
- Week starts on any day, week numbers, weekend shading, pinch to zoom the hours, current-time line
- Year view with busy-day heat map; tap a month/day to jump in
- Optional weather forecast as a separate line **inside every day** in the default week grid (Open-Meteo, approximate location)

**Events**
- Create, edit, delete; all-day, repeating (daily, weekdays, weekly, 2-weekly, monthly, yearly), alerts, URL, notes
- Drag to move (also across days), drag the handle to change the length, drag between days in the month view
- Copy & paste, duplicate, share as text or `.ics`
- Own **colour and emoji** per event, plus automatic **rules** ("Birthday" → 🎂 pink)
- Save **your own templates** for recurring types of events (no preloaded sample templates), and auto-fill suggestions from earlier events
- "This event / future events" choice for repeating events

**Calendars**
- Weekdot's **own calendars** (SwiftData + CloudKit, synced through iCloud) — Weekdot works fully on its own
- Optional integration with the Calendar app; own colour for every calendar
- Uses every calendar of the Calendar app: iCloud, Google, Outlook, Exchange, Yahoo, CalDAV, subscriptions, birthdays
- Show/hide calendars, **calendar sets** (Work, Family …), new calendars (iCloud or on device), edit colour/name, delete
- Choose between **Apple Calendar-managed webcal subscriptions** (Apple refreshes them even when Weekdot is closed) and **Weekdot-managed direct ICS imports** (Weekdot mirrors events to a separate writable Apple Calendar calendar). Apple Calendar asks for confirmation before adding system subscriptions
- Weekdot's directly managed feeds refresh when the app opens and during iOS's available `BGAppRefreshTask` windows; there is no guaranteed six-hour background refresh
- Visual, country-first calendar browser: searchable country/flag selection, then recommended feeds, category chips, colourful category tiles and individual `+` buttons. Includes **public holiday** calendars for 70+ countries, school/construction breaks, zodiac and astronomy events, Formula 1, football leagues and cups, and searchable football clubs with remote club icons
- Football feed choices for the Netherlands (including KNVB Beker, Eredivisie, Ajax, NEC, PSV, Feyenoord) and selected clubs/competitions in other countries; coverage varies by publisher
- For address-specific waste collections (e.g. Circulus), import a downloaded `.ics` calendar as a one-time snapshot or provide a live link if the publisher offers one
- A single system colour picker for accents, calendars and event colours, without preset swatches

**Everywhere**
- **iCloud sync** of Weekdot's own data (settings, templates, sets, rules, colours, emoji) — events sync through your accounts
- **Widgets**: Today (live day and date), Up Next, Week; lock-screen widgets on iPhone
- **Apple Watch** app: your day with a 7-day strip, and the coming week
- **Mac**: native app with keyboard shortcuts (⌘N, ⌘T, ⌘F, ⌘1–5, ⌘←/→)
- **34 language locales**, following the device language (per-app language on iPhone/iPad). Older UI is translated; recently added subscription/discovery strings have Dutch translations and English fallback in other locales until their translation review is finished.
- Light and dark mode — the app icon follows it too (white / black, iOS 18+)
- Week view as a grid of day boxes (like WeekCal) or as a time line

## Project

| Folder | What |
|---|---|
| `Weekdot/` | App for iPhone, iPad and Mac (one multiplatform SwiftUI target) |
| `WeekdotWatch/` | Apple Watch app |
| `WeekdotWidgets/` | Widgets (iOS + macOS) |
| `Shared/` | Code, assets and string catalogs used by all targets |
| `Config/` | Info.plist and entitlements |
| `website/` | Website (static, all languages) — published with GitHub Pages |
| `tools/` | Generators for the Xcode project, icons and translations |

- Bundle ID `nl.lrvdlinden.weekdot` (watch: `.watchkitapp`, widgets: `.widgets`), team `EU3UY476T6`
- iOS/iPadOS 17+, macOS 14+, watchOS 10+ · Xcode 16 or newer
- Capabilities: iCloud (Key-value storage **and CloudKit**, container `iCloud.nl.lrvdlinden.weekdot`), Push Notifications, Background Modes (fetch and remote notifications), App Groups (`group.nl.lrvdlinden.weekdot`), Calendars; on the Mac also App Sandbox with Calendars, Location and outgoing network

### Open in Xcode

Open `Weekdot.xcodeproj`, choose the **Weekdot** scheme and a device or *My Mac*. Signing is automatic; Xcode creates the App IDs, the app group and the iCloud key-value store the first time.

New Swift files in the folders above are picked up automatically. Regenerate the project only when targets or build settings change:

```sh
python3 tools/gen_xcodeproj.py   # Xcode project
python3 tools/make_icons.py      # app icons, splash logo, website images
python3 tools/build_strings.py   # string catalogs + website translations from tools/i18n/
```

### Translations

All texts live in `tools/i18n/<language>.json` (`app`, `plist` and `web` parts). After changing them, run `tools/build_strings.py`; it writes `Shared/Localizable.xcstrings`, `Shared/InfoPlist.xcstrings` and `website/i18n.js`. New UI strings: run `tools/extract_strings.py` first to refresh the key list.

### Third-party subscription behaviour

Apple EventKit does not provide Weekdot a public API for silently creating
system-level webcal subscriptions. The **Apple Calendar** method therefore
opens a `webcal://` link and lets the user confirm inside Apple Calendar, with
an iCloud account recommended to synchronize it between devices. Apple
manages refreshes independently of Weekdot, though the interval is under its
control. Weekdot displays native system subscriptions via EventKit when the
user permits Apple Calendar access. Weekdot never claims a native subscription
was created before the user confirms it.

The separate **Weekdot direct** method remains: Weekdot reads the public ICS
feed itself and mirrors appointments into a dedicated **writable** Apple
calendar. The feed registry and checks are local to that installation.
It refreshes approximately every six hours on active use, manually, and
opportunistically via the existing iOS app-refresh task while suspended. iOS
may delay or omit background runs and may stop them after force-quitting. A
downloaded `.ics` import cannot refresh automatically. Removing a Weekdot-owned
direct subscription deletes only its dedicated mirrored calendar, never an
unrelated calendar or an Apple-managed webcal subscription. The fixtures/feeds are
loaded from third-party providers; club marks are requested through Google's
favicon service using official club website domains, with an icon fallback.
Their availability is outside Weekdot's control.

### Builds

Every push to `main` builds iOS, macOS and watchOS on GitHub Actions (unsigned) to catch compile errors. The result is posted as a comment on the commit.

## Website

`website/` is uploaded via FTPS by `.github/workflows/website.yml` (secrets `FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD`, optional `FTP_DIR`). It never overwrites a folder that already holds another website. Pages live in folders (`/`, `/privacy/`, `/support/`) and `website/.htaccess` keeps URLs free of `.html` (old `.html` links redirect). The site always shows the language of the visitor's device (no language menu); `tools/bust_cache.py` versions CSS/JS by content on every deploy so browsers never keep old translations.

See [CHANGELOG.md](CHANGELOG.md) for versions.
