# Weekdot 1.0.0 — Xcode checklist

Source version: **1.0.0 (build 26)**. This package contains the full Xcode project
for iPhone, iPad, Mac, Apple Watch and their widgets/extensions. It is **source**,
not a compiled App Store or TestFlight build.

## Open and build on a Mac

1. Open `Weekdot.xcodeproj` in Xcode 16 or newer.
2. Select the **Weekdot** scheme, your Apple Developer team, and an iPhone/iPad
   simulator or physical device. Verify signing, App Groups and iCloud.
3. Build and run the iOS target; then build the macOS, Apple Watch and widget
   targets. Verify the version shows `1.0.0 (26)`.
4. On a compact iPhone, check that the bottom bar is a native, persistent,
   icon-only three-tab layout matching Samen's interaction model. Switch Views
   → Add → Settings → Views. Add should show new event, quick add and saved
   templates; Settings should be a genuine tab without a Done button. In the
   Views tab, use the mode chip beneath the date to choose List, Day, Multiple
   Days, Week, Multiple Weeks, Mini Month or Year. Week must show seven days.
   Check Calendars top-left and Search top-right on the calendar.
   On wide iPad/Mac, check the previous floating glass menu still works.
5. In Settings, adjust the number of days/weeks and choose a custom accent.
   Create a calendar with a custom colour and verify it persists after relaunch.
6. Verify the template list begins empty on a **fresh install**, then use
   **Save as Template** in the event editor or details. Existing user templates
   are deliberately preserved when updating from an earlier version.
7. Under Calendars → Subscribe to Calendar, confirm a searchable country
   list with flags opens first. Choose a country to reach the recommended
   calendar cards, category chips, category tiles and inline `+` feed buttons.
   Verify changing a category filters the feeds; Back returns to the countries.
   In Sport, test Formula 1, Football → Competitions → Eredivisie
   or KNVB Beker, and Football → Clubs → Ajax/NEC. Tap **+**, choose
   **Add to Apple Calendar · automatic updates**, and confirm in Apple Calendar.
   Choose iCloud as account. Return to Weekdot and confirm the subscription
   appears among Apple's account calendars, with updated events.
8. Repeat with a second public feed but choose **Subscribe directly in Weekdot**.
   Verify it mirrors into a new `Weekdot · …` calendar without opening Apple
   Calendar. Check its events both in Weekdot and Apple Calendar. Refresh Now
   updates events; Unsubscribe deletes only the dedicated mirrored calendar.
9. Test custom HTTPS/webcal links in both methods, rejecting malformed URLs.
   A direct feed should not be duplicated in Weekdot's local registry. When
   adding a native Apple subscription for a feed already imported directly,
   verify the duplicate warning is shown (and manage the two separately).
10. Verify native subscriptions appear on a second iCloud device, without
    opening Weekdot. For direct imports, reopen Weekdot to check refreshing.
    On a **physical iPhone**, also verify the existing `nl.lrvdlinden.weekdot.refresh`
    iOS background app-refresh handler attempts to refresh direct feeds.
    Check Settings → General → Background App Refresh is enabled; iOS decides
    when to run the task and does not guarantee a six-hour schedule.
11. Test a downloaded `.ics` export from Circulus with **Import Downloaded
    ICS File**. Check that it explicitly says one-time import.
12. Enable Local Weather Forecast and test location permission and a weather
    line **inside each day** of the default seven-day grid. Open-Meteo is
    used; forecasts are limited by provider availability/horizon.
13. Check that the bottom menu uses the current accent colour (red by default)
    and has accessible labels even without visible text. Test the new subscription
    browser in both Dutch and English, and on iPhone/iPad and Mac screen sizes.

## External feed limitations

- Weekdot has ready-made sports, holiday, school and astronomy feed links but
  cannot guarantee third-party uptime or season coverage. Individual club
  favicon images are fetched online when available.
- **Apple Calendar mode** hands the feed to Apple's webcal handler, which
  requires the user to confirm in Calendar. The OS refreshes it, at its own
  interval, independently of Weekdot. Weekdot needs calendar permission to
  show the result.
- **Direct Weekdot mode** is an app-managed EventKit mirror, not a native
  webcal subscription. Full calendar access and a writable Apple calendar
  source are mandatory. A shared `BGAppRefreshTask` attempts to refresh direct
  feeds when the app is suspended, but iOS does not guarantee launches or exact
  timing. UserDefaults stores the local feed registry; events sync to other
  devices through the chosen account.
- Circulus uses its own address lookup. Address details are entered **on the
  official Circulus site**; Weekdot does not receive them. A downloaded ICS
  import is not necessarily an auto-refreshing subscription.
- School-holiday dates can vary by region and school. Check the official source.
- Public-holiday feeds come from independent Google and Office Holidays
  publishers, whose data and regional coverage can change.

## Before distribution

Run the Xcode tests available on your Mac, create an Archive and validate it
before uploading to App Store Connect / TestFlight. Check UI and translations
on both compact iPhone and large iPad/Mac screens.
