import Foundation
import UserNotifications
import EventKit
#if canImport(BackgroundTasks) && os(iOS)
import BackgroundTasks
#endif

/// Real notifications (banner, sound, lock screen, Apple Watch) for event alerts.
///
/// They are scheduled on the device itself, so they also arrive when Weekdot is closed or offline and
/// need no server. Weekdot's own events always alert this way; Apple Calendar events alert through the
/// Calendar app, or through Weekdot when "Weekdot Alerts for All Calendars" is on.
@MainActor
enum NotificationScheduler {
    static let refreshTaskID = "nl.lrvdlinden.weekdot.refresh"
    static let categoryID = "wd.event"
    static let snoozeAction = "wd.snooze"
    static let openAction = "wd.open"
    private static let prefix = "wd."
    /// iOS keeps at most 64 pending notifications per app.
    private static let maxPending = 60

    /// Set at launch so background refresh and notification actions can reach the data.
    static weak var store: CalendarStore?

    /// Registers the delegate and the Snooze / Open actions. Call once at launch.
    static func setUp(store: CalendarStore) {
        self.store = store
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        let snooze = UNNotificationAction(identifier: snoozeAction, title: String(localized: "Snooze 10 Minutes"),
                                          options: [], icon: UNNotificationActionIcon(systemImageName: "zzz"))
        let open = UNNotificationAction(identifier: openAction, title: String(localized: "Open in Weekdot"),
                                        options: [.foreground], icon: UNNotificationActionIcon(systemImageName: "calendar"))
        let category = UNNotificationCategory(identifier: categoryID, actions: [snooze, open], intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }

    struct Alarm {
        let id: String
        let title: String
        let body: String
        let fire: Date
        let start: Date
    }

    static func reschedule() async {
        guard let store else { return }
        await reschedule(store: store)
    }

    static func reschedule(store: CalendarStore) async {
        let settings = store.synced.settings
        let cal = settings.calendar
        let now = Date()
        // Weekdot's own events (id ends in "|<minutes before>", which gives back the start for tap-to-open).
        var list: [Alarm] = store.local.upcomingAlarms(limit: maxPending, calendar: cal).map { a in
            let minutes = Int(a.id.split(separator: "|").last ?? "0") ?? 0
            return Alarm(id: a.id, title: a.title, body: a.body, fire: a.fire,
                         start: a.fire.addingTimeInterval(TimeInterval(minutes * 60)))
        }

        if store.appleEnabled {
            let horizon = cal.addingDays(14, to: now)
            let apple = store.events(from: now, to: horizon).filter { !$0.isLocal && !$0.isReminder }
            // Birthdays
            if let m = settings.birthdayAlarmMinutes {
                let ids = Set(store.calendars.filter { $0.type == .birthday }.map(\.calendarIdentifier))
                for item in apple where ids.contains(item.calendarID) {
                    let fire = cal.startOfDay(for: item.start).addingTimeInterval(TimeInterval(-m * 60))
                    if fire > now {
                        list.append(Alarm(id: "bd." + item.id, title: item.displayTitle, body: String(localized: "Birthday"),
                                          fire: fire, start: item.start))
                    }
                }
            }
            // Alerts of Apple Calendar events (optional: the Calendar app alerts for these too).
            if settings.alertsForAllCalendars {
                for item in apple where store.calendar(withID: item.calendarID)?.type != .birthday {
                    guard let e = store.ekEvent(for: item), let alarms = e.alarms else { continue }
                    for alarm in alarms {
                        let fire = alarm.absoluteDate ?? item.start.addingTimeInterval(alarm.relativeOffset)
                        guard fire > now else { continue }
                        list.append(Alarm(id: "ap." + item.id + "|\(Int(fire.timeIntervalSince1970))",
                                          title: item.displayTitle, body: body(for: item), fire: fire, start: item.start))
                    }
                }
            }
        }

        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(prefix) && !$0.hasPrefix(prefix + "snooze.") }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        guard !list.isEmpty else { return }

        let auth = await center.notificationSettings()
        if auth.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        for a in list.sorted(by: { $0.fire < $1.fire }).prefix(maxPending) {
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: a.fire)
            let req = UNNotificationRequest(identifier: prefix + a.id,
                                            content: content(title: a.title, body: a.body, start: a.start),
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(req)
        }
    }

    static func content(title: String, body: String, start: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.threadIdentifier = "weekdot.events"
        content.userInfo = ["start": start.timeIntervalSince1970]
        #if os(iOS)
        // Breaks through Focus like Apple Calendar alerts (when the user allows time-sensitive notifications).
        content.interruptionLevel = .timeSensitive
        #endif
        return content
    }

    private static func body(for item: EventItem) -> String {
        if item.isAllDay { return String(localized: "All-day") }
        return Fmt.time(item.start) + (item.location.map { " · " + $0 } ?? "")
    }

    /// Shows the same alert again in 10 minutes.
    static func snooze(_ request: UNNotificationRequest) async {
        let c = request.content
        let start = Date(timeIntervalSince1970: c.userInfo["start"] as? Double ?? Date().timeIntervalSince1970)
        let req = UNNotificationRequest(identifier: prefix + "snooze." + UUID().uuidString,
                                        content: content(title: c.title, body: c.body, start: start),
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

/// Shows alerts while Weekdot is open and handles taps and actions.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()

    /// Called with the event start when the user taps an alert.
    @MainActor var onOpen: ((Date) -> Void)?
    @MainActor private var pendingOpen: Date?

    @MainActor func setHandler(_ handler: @escaping (Date) -> Void) {
        onOpen = handler
        if let d = pendingOpen { handler(d); pendingOpen = nil }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let request = response.notification.request
        switch response.actionIdentifier {
        case NotificationScheduler.snoozeAction:
            await NotificationScheduler.snooze(request)
        case UNNotificationDismissActionIdentifier:
            break
        default:
            guard let t = request.content.userInfo["start"] as? Double else { return }
            let date = Date(timeIntervalSince1970: t)
            await MainActor.run {
                if let onOpen { onOpen(date) } else { pendingOpen = date }
            }
        }
    }
}
