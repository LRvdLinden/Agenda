# Changelog

## 1.0.0 (build 28) — 29 October 2026

- Removed the duplicate Today/Agenda calendar button from the bottom action menu on iOS and macOS. Today remains accessible from the date picker in the centered period heading.
- Version stays 1.0.0, build number advances to 28 for all targets.


## 1.0.0 (build 26) — 28 October 2026

This package uses the same features and source as the development build 26, but is versioned as **1.0.0** for release.

- iPhone's bottom controls now use the same native SwiftUI `TabView(selection:)` interaction model as the supplied Samen reference: persistent Views, Add and Settings tabs with an active selection, system tab bar and accent tint. Tabs remain icon-only with accessibility labels.
- The Views tab keeps the actual calendar; the selected calendar mode can be changed from a compact menu beneath the date heading. Add opens a dedicated action hub (new event, quick add, user-saved templates). Settings opens as a genuine tab rather than a modal sheet.
- On iPad with a regular width class and on Mac, keep Weekdot's existing compact floating glass controls to avoid moving the menu from the bottom and to preserve the larger-screen layout.
- Kept the Calendars and Search buttons at the top of the calendar, plus existing subscriptions, reminders, custom colours, translations and background-refresh behaviour.

## 1.0.1 (build 25) — 28 October 2026

- Corrected the floating bottom Settings gear tint to match the app's active accent colour, as Views and Add already do (Weekdot red by default).
- Redesigned the subscription discovery into a country-first, visual browse flow inspired by the supplied reference: searchable countries with flag previews, a country-specific landing page, recommended calendar cards, scrollable category chips, colourful category tiles and inline add buttons.
- Kept public holidays, sports/football clubs, school breaks, astronomy, custom feeds, weather and the two existing Apple Calendar/Weekdot subscription methods, including background feed refresh.
- Routed the main **Subscribe to Calendar** entry to the new country browser, and retained a separate custom ICS/webcal entry.
- Localized the new browser interface in Dutch and English. Other existing app languages currently fall back to English for newly introduced strings pending the wider translation review.

## 1.0.1 (build 24) — 28 October 2026

- Added two subscription methods for curated holiday, sports, school and astronomy calendars and user-provided webcal/ICS links:
  - **Apple Calendar subscription (recommended):** Weekdot opens the subscription's `webcal://` URL, and Apple Calendar asks for confirmation and manages the live updates, including while Weekdot is closed. Choose an iCloud location and allow Weekdot Apple Calendar access to display the subscribed calendar on every device.
  - **Direct Weekdot subscription:** retains build 22's dedicated writable Apple-calendar mirror, EventKit download/import, Refresh Now and Unsubscribe controls.
- Extended Weekdot's existing iOS `BGAppRefreshTask` for notifications to refresh direct ICS subscriptions when iOS grants background time, with a short time budget, per-feed download timeout and cancellation check.
- System subscriptions are not mirrored a second time by Weekdot. A warning appears if the same feed already has a Weekdot-managed direct copy.
- Added Dutch localizations and Xcode verification steps for both subscription methods. Automatic background updates are best-effort, not a guaranteed timer.

## 1.0.1 (build 23) — 28 October 2026

- Fixed iOS simulator compilation error in `FeedSubscriptionManager.swift`: the EventKit `EKRecurrenceRule` initializer requires the `end:` argument, supplied as `nil` for unbounded simple recurrence rules.

## 1.0.1 (build 22) — 28 October 2026

- Subscription browser now starts with a country, followed by calendar categories. Sport continues into Formula 1 or Football, with separate competitions/cups and searchable individual football clubs (club favicons where available).
- Ready-to-add football calendars include Eredivisie, KNVB Beker, clubs such as Ajax, PSV, Feyenoord and NEC, and selected leagues/clubs in the UK, Germany, Spain, Italy, France, Portugal, Türkiye and North America; Formula 1 is available internationally.
- Direct in-app ICS/webcal subscriptions: Weekdot downloads the public calendar, creates a dedicated writable Apple Calendar calendar and mirrors the events into it without opening the Calendar app.
- Subscription management now includes refresh, status, duplicate protection and removal of the dedicated mirrored calendar. The app checks live feeds for changes when active; it is not a system-level background subscription.
- Added country holiday calendars for 70+ countries, curated school/construction breaks, astronomy, astrology, week numbers and sports calendars. Network and third-party provider availability may vary.
- Downloaded ICS files, such as address-specific Circulus waste calendars, can be imported as **one-time** snapshots; a live URL is required for auto-refresh.
- Forecast now appears as a separate weather line inside each day of the default seven-day week grid.

## 1.0.1 (build 21) — 28 October 2026

- Floating glass navigation is now icon-only (Views, Add, Settings) with no text labels.
- Each icon uses a compact 44-point tap target and an 18-point symbol, matching the top toolbar controls.
- Accessibility labels remain available for VoiceOver.
- Colour editors now show only the system colour picker, without any preset swatches; inheriting the calendar colour remains available for events, templates and rules.

## 1.0.1 (build 20) — 28 October 2026

- Bottom navigation is now a compact, centred floating Liquid Glass capsule on iOS/macOS 26+.
- Older OS versions use an ultra-thin material capsule with a subtle shadow; no full-width bottom bar.
- Calendars remains top-left, Search top-right; Views, Add and Settings stay in the floating menu.

## 1.0.1 (build 19) — 28 October 2026

- Calendars at the top-left and Search at the top-right.
- Bottom menu now contains Views, Add and Settings (in that order).
- Fixed an extra closing brace in the custom colour picker that prevented the iOS build from compiling.

## 1.0.1 (build 18) — 28 October 2026

- Moved Settings to the top-left and Search to the top-right, as requested.
- The bottom bar now contains only Calendars, Views and Add.

## 1.0.1 (build 17) — 28 October 2026

- Bottom navigation introduced (Calendars, Views and Add); the segmented view switcher has been removed from the header
- Seven modes: list, day, multiple days (2–6), classic seven-day week (default), multiple weeks (2–4), mini-month and year
- Compact month and multi-week calendar with event dots and a selectable daily agenda
- Extended accent and calendar colour palette with a custom system colour picker
- New installs no longer receive example event templates; saving and managing your own templates is unchanged
- Smart Calendar discovery for school holidays, sports schedules, zodiac/astronomy and Circulus waste collection; uses publishers' ICS/webcal feeds and official links, with existing country-specific holiday subscriptions
- Optional location-based Open-Meteo forecast is now shown in the classic week grid as well
- New Dutch translations for the 1.0.1 interface

## 1.0.0 (build 16) — 25 October 2026

- Today complication (corner) now looks like Apple's Date complication: the weekday big and white, and yesterday · today · tomorrow as number tiles along the edge, today brighter in the middle

## 1.0.0 (build 15) — 25 October 2026

- Tapping an alert opens that event in Weekdot (with its day behind it), also when the app was closed
- Today complication like Apple's: weekday in the corner, yesterday · today · tomorrow along the edge with today in the middle (from build 14)

## 1.0.0 (build 14) — 25 October 2026

- Today complication like Apple's Date complication: the weekday in the corner and yesterday · today · tomorrow along the edge, today always in the middle and highlighted
- New rectangular Today complication: five days with today in the middle

## 1.0.0 (build 13) — 25 October 2026

Apple Watch complications — everything Apple Calendar offers, and more (all also in the Smart Stack):
- Up Next — next event with colour, time and place; time on the circular face; "14:00 Meeting" in the corner and inline
- Day — today's remaining events (up to three) with time and calendar colour
- Countdown — ring that fills in the last hour before your next event, with "25m"
- Remaining Today — how many events are still to come today, with a progress ring
- Today — weekday and date
- Week Number — "Week 43"
- Week — this week with a dot on busy days
- Three Weeks — heat map of this week and the next two
- Weekdot — open the app from the watch face (the seven dots, today's one bigger)
- Complications rise in the Smart Stack shortly before and during an event, and update every 5 minutes near events

## 1.0.0 (build 12) — 25 October 2026

- Signing: one app group (group.nl.lrvdlinden.weekdot) on iPhone, iPad, Mac and Apple Watch, so Xcode no longer reports "Application Group identifiers should start with 'group.'" for the widgets

## 1.0.0 (build 11) — 25 October 2026

- Apple Watch complications for the watch face:
  - Up Next: the next event with its calendar colour, time and place (rectangular), "14:00 Meeting" (inline and corner), the start time (circular)
  - Today: weekday and date (circular, corner, inline)
  - Week: the seven days of this week with a dot on busy days (rectangular)
- The watch app keeps the complications up to date

## 1.0.0 (build 10) — 25 October 2026

- Apple Watch: simpler screen structure without the vertical page view and toolbar (the day, with Today and Week rows below the events)
- Apple Watch: if the app stops unexpectedly, the next launch shows the reason on the watch, so it can be fixed right away

## 1.0.0 (build 9) — 25 October 2026

- Apple Watch: fixed the crash at launch — the day and week pages each had their own navigation stack inside the vertical page view, which watchOS doesn't allow; now one navigation stack holds both pages
- Notifications are on by default for everyone: Weekdot asks for permission at first launch, and alerts for Apple Calendar events are on by default (also for existing users)

## 1.0.0 (build 8) — 25 October 2026

- Richer alerts, like Apple Calendar: "In 15 minutes · Calendar", "Today at 14:00 – 15:00", the place and the travel time from your current location, and a date tile in the calendar's colour
- Alert actions: Snooze 10 Minutes, Directions (opens the route in Apple Maps) and Open in Weekdot
- Alerts are grouped per calendar
- Apple Watch: Weekdot's own calendars only use the app group and iCloud when they are really available, so the app keeps running without them (fix attempt for the crash at launch)

## 1.0.0 (build 7) — 25 October 2026

- Apple Watch app no longer quits right after launch (missing watch app settings in its Info.plist)
- Alerts work like Apple Calendar: "Alert" and "Second Alert" rows with None, At time of event, 5/15/30 minutes, 1 hour, 1 day … a custom alert (any number of minutes, hours, days or weeks) and a travel-time alert ("11 min from current location")
- Addresses are completed by Apple Maps while typing and saved as a full address
- Event screen: map with the place, travel time from your current location, and a tap opens the route in Apple Maps
- Real notifications for alerts on iPhone, iPad, Mac and Apple Watch: banner and sound also when Weekdot is closed, Snooze 10 Minutes and Open actions, time-sensitive (breaks through Focus when allowed), shown while Weekdot is open, tap opens the day
- New setting "Weekdot Alerts for All Calendars" to also get Weekdot alerts for Apple Calendar events
- Background refresh keeps alerts up to date for events added on other devices

## 1.0.0 (build 6) — 25 October 2026

- Calendar pickers (event, default calendar, templates) show each calendar's own colour instead of all red, grouped per account
- Website is published to the web server via FTPS on every change

## 1.0.0 (build 5) — 25 October 2026

**Weekdot is now a complete calendar on its own**
- Own Weekdot calendars and events, synced through iCloud (CloudKit) on iPhone, iPad, Mac and Apple Watch — also without the Calendar app
- The Calendar app integration (iCloud, Google, Outlook, Exchange, subscriptions) is optional: choose at first start or in Settings
- Every calendar can get its own colour, including read-only ones (Google, Exchange, subscriptions, birthdays)
- Edit every event: writable calendars are changed directly, read-only events are replaced by an edited Weekdot copy; Edit button in the event screen
- Move events between Weekdot and Calendar app calendars

**Everything from Apple Calendar**
- Custom repeat: every N days/weeks/months/years, chosen weekdays, monthly on the same weekday, end on a date or after a number of times
- Show As (busy/free), time zone per event, travel time, invitees with "Send Invitation" (.ics)
- Location suggestions while typing and a map in the event screen
- Quick Add with natural language ("Lunch with Sam tomorrow at 1 pm"), Go to Date, Undo after moving or deleting
- Reminders with a due date in the calendar (tick them off right there)
- Settings like Apple Calendar: Time Zone Override, Alternate Calendars (Chinese, Hebrew, Islamic, Persian, Indian, Japanese, Buddhist), default alerts for all-day events and birthdays, show birthdays, location suggestions, default calendar
- Alerts for Weekdot events and birthdays as notifications

## 1.0.0 (build 4) — 24 October 2026

- Week grid: every day box now scrolls on its own, so boxes no longer run into each other (Friday, Saturday and Sunday overlapped)
- Smaller, calmer text in the week grid, month view, chips and time line
- Month view: the weekday row no longer takes up half the screen; the weeks use the full height again

## 1.0.0 (build 3) — 24 October 2026

- New name: **Weekdot** (was Sevn). App name, icon, splash screen, website and all languages updated; bundle ID now `nl.lrvdlinden.weekdot`

## 1.0.0 (build 2) — 24 October 2026

- Week view as a grid of day boxes: Monday–Wednesday on the left, Thursday–Friday on the right and the weekend sharing the last box; all-day events as coloured bars, timed events with a coloured time label; today highlighted, an arrow when a day has more events (switch to the time line under Settings › Week Layout)
- New app icon: red header with seven day dots and the Weekdot name; white in light mode, black in dark mode
- New splash screen: the icon continues from the launch screen, the day dots light up and today stays marked

## 1.0.0 (build 1) — 24 October 2026

First version of Weekdot for iPhone, iPad, Mac and Apple Watch.

- Day, week (7 days by default), month, year and list views
- Works with all calendars of the Calendar app; new calendars, subscriptions, holiday calendars and calendar sets
- Drag & drop, resize, copy & paste, duplicate and share events
- Own colours and emoji per event, automatic rules, templates and auto-fill from earlier events
- iCloud sync of settings, templates, sets, rules, colours and emoji
- Widgets (Today with live date, Up Next, Week) and an Apple Watch app
- Optional weather forecast in the week view
- 34 languages; light/dark app icon
- Website with privacy and support pages in all languages
