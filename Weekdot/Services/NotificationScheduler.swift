import Foundation
import SwiftUI
import UserNotifications
import EventKit
import ImageIO
import UniformTypeIdentifiers
#if os(iOS)
import BackgroundTasks
import UIKit
#endif

/// Real notifications (banner, sound, lock screen, Apple Watch) for event alerts, as rich as Apple Calendar's:
/// title, "in 15 minutes · Calendar", "Today at 14:00 – 15:00", the place and the travel time, a date tile in
/// the calendar's colour, and Snooze / Directions / Open actions.
///
/// They are scheduled on the device itself, so they also arrive when Weekdot is closed or offline and
/// need no server. Weekdot's own events always alert this way; Apple Calendar events alert through the
/// Calendar app, or through Weekdot when "Weekdot Alerts for All Calendars" is on.
@MainActor
enum NotificationScheduler {
    static let refreshTaskID = "nl.lrvdlinden.weekdot.refresh"
    static let categoryID = "wd.event"
    static let categoryWithPlaceID = "wd.event.place"
    static let snoozeAction = "wd.snooze"
    static let openAction = "wd.open"
    static let routeAction = "wd.route"
    private static let prefix = "wd."
    /// iOS keeps at most 64 pending notifications per app.
    private static let maxPending = 60

    /// Set at launch so background refresh and notification actions can reach the data.
    static weak var store: CalendarStore?

    /// Registers the delegate and the actions. Call once at launch.
    static func setUp(store: CalendarStore) {
        self.store = store
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        let snooze = UNNotificationAction(identifier: snoozeAction, title: String(localized: "Snooze 10 Minutes"),
                                          options: [], icon: UNNotificationActionIcon(systemImageName: "zzz"))
        let route = UNNotificationAction(identifier: routeAction, title: String(localized: "Directions"),
                                         options: [.foreground], icon: UNNotificationActionIcon(systemImageName: "car.fill"))
        let open = UNNotificationAction(identifier: openAction, title: String(localized: "Open in Weekdot"),
                                        options: [.foreground], icon: UNNotificationActionIcon(systemImageName: "calendar"))
        // Ask for permission right away (also for new users), so alerts arrive from the first event on.
        Task {
            guard !ScreenshotMode.isActive else { return }
            let auth = await center.notificationSettings()
            if auth.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
        }
        center.setNotificationCategories([
            UNNotificationCategory(identifier: categoryID, actions: [snooze, open], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: categoryWithPlaceID, actions: [snooze, route, open], intentIdentifiers: [], options: []),
        ])
    }

    struct Alarm {
        let id: String
        let item: EventItem
        let fire: Date
        var isBirthday = false
    }

    static func reschedule() async {
        guard let store else { return }
        await reschedule(store: store)
    }

    private static var isRunning = false
    private static var runAgain = false

    /// Schedules all alerts. Calls that arrive while a run is busy are merged into one extra run, so two
    /// runs never interleave (that could remove alerts the other run had just added).
    static func reschedule(store: CalendarStore) async {
        if ScreenshotMode.isActive { return }
        if isRunning { runAgain = true; return }
        isRunning = true
        #if os(iOS)
        // Finish scheduling even when the user leaves Weekdot right after saving an event.
        let bg = UIApplication.shared.beginBackgroundTask(withName: "Weekdot alerts")
        #endif
        repeat {
            runAgain = false
            await scheduleAll(store: store)
        } while runAgain
        isRunning = false
        #if os(iOS)
        if bg != .invalid { UIApplication.shared.endBackgroundTask(bg) }
        #endif
    }

    private static func scheduleAll(store: CalendarStore) async {
        let settings = store.synced.settings
        let cal = settings.calendar
        let now = Date()
        var list: [Alarm] = store.local.upcomingAlarms(limit: maxPending, calendar: cal).map { a in
            var item = a.item
            item.colorHex = store.color(forCalendarID: item.calendarID)
            return Alarm(id: a.id, item: item, fire: a.fire)
        }

        if store.appleEnabled {
            let horizon = cal.addingDays(14, to: now)
            let apple = store.events(from: now, to: horizon).filter { !$0.isLocal && !$0.isReminder }
            if let m = settings.birthdayAlarmMinutes {
                let ids = Set(store.calendars.filter { $0.type == .birthday }.map(\.calendarIdentifier))
                for item in apple where ids.contains(item.calendarID) {
                    let fire = cal.startOfDay(for: item.start).addingTimeInterval(TimeInterval(-m * 60))
                    if fire > now { list.append(Alarm(id: "bd." + item.id, item: item, fire: fire, isBirthday: true)) }
                }
            }
            if settings.alertsForAllCalendars {
                for item in apple where store.calendar(withID: item.calendarID)?.type != .birthday {
                    guard let e = store.ekEvent(for: item), let alarms = e.alarms else { continue }
                    for alarm in alarms {
                        let fire = alarm.absoluteDate ?? item.start.addingTimeInterval(alarm.relativeOffset)
                        guard fire > now else { continue }
                        list.append(Alarm(id: "ap." + item.id + "|\(Int(fire.timeIntervalSince1970))", item: item, fire: fire))
                    }
                }
            }
        }

        let center = UNUserNotificationCenter.current()
        var auth = await center.notificationSettings()
        if auth.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            auth = await center.notificationSettings()
        }
        guard auth.authorizationStatus == .authorized || auth.authorizationStatus == .provisional else { return }

        // 1. Build every request first (travel-time lookups can take a moment). The alerts that are already
        //    scheduled stay in place meanwhile, so nothing is missing while Weekdot works or is sent to the
        //    background halfway (before build 62 they were removed first, which could drop alerts).
        var requests: [UNNotificationRequest] = []
        var travelLookups = 0
        for a in list.filter({ $0.fire > Date() }).sorted(by: { $0.fire < $1.fire }).prefix(maxPending) {
            var travel: Int?
            if let loc = a.item.location, !loc.isEmpty, !a.item.isAllDay, travelLookups < 6,
               a.fire.timeIntervalSince(now) < 24 * 3600, TravelService.shared.canUseLocation {
                travelLookups += 1
                travel = await TravelService.shared.travelMinutes(to: loc)
            }
            let content = content(for: a.item, fire: a.fire, travel: travel, birthday: a.isBirthday, calendar: cal)
            requests.append(UNNotificationRequest(identifier: prefix + a.id, content: content, trigger: trigger(for: a.fire)))
        }

        // 2. Remove only alerts that are no longer needed; 3. add/replace the current ones (same identifier
        //    replaces the old request, so there is never a gap).
        let wanted = Set(requests.map(\.identifier))
        let stale = await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(prefix) && !$0.hasPrefix(prefix + "snooze.") && !wanted.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for req in requests {
            do {
                try await center.add(req)
            } catch {
                NSLog("[Weekdot Alerts] Unable to schedule alert: %@", error.localizedDescription)
            }
        }
    }

    /// Fires at the exact moment, independent of Weekdot's time-zone override or calendar settings:
    /// the components carry the device calendar and time zone.
    private static func trigger(for fire: Date) -> UNNotificationTrigger {
        var g = Calendar(identifier: .gregorian)
        g.timeZone = .current
        let comps = g.dateComponents(in: .current, from: fire)
        var c = DateComponents()
        c.calendar = g
        c.timeZone = .current
        c.year = comps.year; c.month = comps.month; c.day = comps.day
        c.hour = comps.hour; c.minute = comps.minute; c.second = comps.second
        return UNCalendarNotificationTrigger(dateMatching: c, repeats: false)
    }

    // MARK: Content

    static func content(for item: EventItem, fire: Date, travel: Int?, birthday: Bool, calendar cal: Calendar)
        -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = item.displayTitle

        // "In 15 minutes · Work" — like the relative time Apple Calendar shows on its alerts.
        var sub: [String] = []
        if !item.isAllDay && !birthday {
            sub.append(relative(item.start, from: fire))
        }
        sub.append(birthday ? String(localized: "Birthday") : item.calendarTitle)
        content.subtitle = sub.filter { !$0.isEmpty }.joined(separator: " · ")

        // "Today at 14:00 – 15:00", the place and the travel time.
        var lines = [when(item, calendar: cal)]
        if let loc = item.location, !loc.isEmpty { lines.append(loc) }
        if let t = travel { lines.append(String(localized: "\(Int(t)) min from current location")) }
        content.body = lines.joined(separator: "\n")

        content.sound = .default
        content.categoryIdentifier = (item.location?.isEmpty == false) ? categoryWithPlaceID : categoryID
        content.threadIdentifier = item.calendarID
        content.targetContentIdentifier = item.id
        var info: [String: Any] = ["start": item.start.timeIntervalSince1970, "event": item.id]
        if let loc = item.location { info["location"] = loc }
        content.userInfo = info
        content.relevanceScore = 1
        #if os(iOS)
        // Breaks through Focus like Apple Calendar alerts (when the user allows time-sensitive notifications).
        content.interruptionLevel = .timeSensitive
        #endif
        if let tile = DateTile.attachment(day: item.start, colorHex: item.colorHex, calendar: cal) {
            content.attachments = [tile]
        }
        return content
    }

    /// "in 15 minutes", "now" — in the user's language.
    private static func relative(_ start: Date, from fire: Date) -> String {
        if abs(start.timeIntervalSince(fire)) < 60 { return String(localized: "Now") }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        f.dateTimeStyle = .named
        return f.localizedString(for: start, relativeTo: fire).capitalizedFirst
    }

    /// "Today at 14:00 – 15:00", "Tomorrow, all-day", "Fri 30 Oct at 09:00 – 10:00".
    private static func when(_ item: EventItem, calendar cal: Calendar) -> String {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .medium
        if item.isAllDay {
            f.timeStyle = .none
            return f.string(from: item.start).capitalizedFirst + " · " + String(localized: "All-day")
        }
        f.timeStyle = .short
        var s = f.string(from: item.start).capitalizedFirst
        if item.end > item.start {
            if cal.isDate(item.end, inSameDayAs: item.start) {
                s += " – " + Fmt.time(item.end)
            } else {
                s += " – " + f.string(from: item.end)
            }
        }
        return s
    }

    /// Shows the same alert again in 10 minutes.
    static func snooze(_ request: UNNotificationRequest) async {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else { return }
        content.attachments = []
        if let t = content.userInfo["start"] as? Double {
            let start = Date(timeIntervalSince1970: t)
            var parts = content.subtitle.components(separatedBy: " · ")
            if parts.count > 1 { parts[0] = relative(start, from: Date().addingTimeInterval(600)) }
            content.subtitle = parts.joined(separator: " · ")
        }
        let req = UNNotificationRequest(identifier: prefix + "snooze." + UUID().uuidString, content: content,
                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false))
        try? await UNUserNotificationCenter.current().add(req)
    }

    // MARK: Background refresh (iOS)

    /// Asks iOS to wake Weekdot now and then, so alerts for events that were added elsewhere
    /// (iCloud, another device, Apple Calendar) are scheduled even when the app isn't opened.
    static func scheduleBackgroundRefresh() {
        #if os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date().addingTimeInterval(2 * 3600)
        try? BGTaskScheduler.shared.submit(request)
        #endif
    }
}

/// Calendar-style date tile (weekday in the calendar's colour above the day number) shown on the alert,
/// like the date on Apple Calendar's icon.
@MainActor
enum DateTile {
    private static var cache: [String: Data] = [:]

    static func attachment(day: Date, colorHex: String, calendar cal: Calendar) -> UNNotificationAttachment? {
        let key = "\(cal.startOfDay(for: day).timeIntervalSince1970)-\(colorHex)"
        guard let data = cache[key] ?? render(day: day, colorHex: colorHex) else { return nil }
        cache[key] = data
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("wd-tiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(UUID().uuidString + ".png")
        guard (try? data.write(to: url)) != nil else { return nil }
        return try? UNNotificationAttachment(identifier: "date", url: url, options: [
            UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier,
        ])
    }

    private static func render(day: Date, colorHex: String) -> Data? {
        let color = Color(hex: colorHex) ?? .weekdotRed
        let view = VStack(spacing: -6) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)).capitalizedFirst)
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(color)
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 118, weight: .regular))
                .foregroundStyle(Color(white: 0.08))
                .monospacedDigit()
        }
        .frame(width: 240, height: 240)
        .background(Color.white)
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let cg = renderer.cgImage else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cg, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return out as Data
    }
}

private extension String {
    var capitalizedFirst: String {
        guard let f = first else { return self }
        return f.uppercased() + dropFirst()
    }
}

/// Shows alerts while Weekdot is open and handles taps and actions.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()

    /// Called with the event start when the user taps an alert.
    /// Called with the event start and the event's id when the user taps an alert.
    @MainActor var onOpen: ((Date, String?) -> Void)?
    @MainActor private var pendingOpen: (Date, String?)?

    @MainActor func setHandler(_ handler: @escaping (Date, String?) -> Void) {
        onOpen = handler
        if let p = pendingOpen { handler(p.0, p.1); pendingOpen = nil }
    }

    // The completion-handler versions are used on purpose: iOS calls these delegate methods on a background
    // thread, and the async versions finished on that thread too. UIKit then updated the app snapshot off
    // the main thread and stopped the app (crash when tapping an alert, build 54–61). Everything below runs
    // on the main thread and the completion handler is called there, after the work is done.

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let request = response.notification.request
        let action = response.actionIdentifier
        let start = request.content.userInfo["start"] as? Double
        let eventID = request.content.userInfo["event"] as? String
        let location = request.content.userInfo["location"] as? String
        Task { @MainActor in
            switch action {
            case NotificationScheduler.snoozeAction:
                await NotificationScheduler.snooze(request)
            case NotificationScheduler.routeAction:
                if let location { await TravelService.shared.openDirections(to: location) }
            case UNNotificationDismissActionIdentifier:
                break
            case NotificationScheduler.openAction, UNNotificationDefaultActionIdentifier:
                if let start {
                    let date = Date(timeIntervalSince1970: start)
                    if let onOpen { onOpen(date, eventID) } else { pendingOpen = (date, eventID) }
                }
            default:
                break
            }
            completionHandler()
        }
    }
}
