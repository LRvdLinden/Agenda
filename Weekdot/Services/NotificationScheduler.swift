import Foundation
import UserNotifications
import EventKit

/// Alerts for Weekdot's own events and for birthdays (Apple Calendar events alert through the system).
@MainActor
enum NotificationScheduler {
    private static let prefix = "wd."

    static func reschedule(store: CalendarStore) async {
        let cal = store.synced.settings.calendar
        let now = Date()
        var list = store.local.upcomingAlarms(limit: 50, calendar: cal)
        if let m = store.synced.settings.birthdayAlarmMinutes, store.appleEnabled {
            let ids = Set(store.calendars.filter { $0.type == .birthday }.map(\.calendarIdentifier))
            if !ids.isEmpty {
                for item in store.events(from: now, to: cal.addingDays(30, to: now)) where ids.contains(item.calendarID) {
                    let fire = cal.startOfDay(for: item.start).addingTimeInterval(TimeInterval(-m * 60))
                    if fire > now { list.append((id: "bd." + item.id, title: item.displayTitle, body: String(localized: "Birthday"), fire: fire)) }
                }
            }
        }
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        guard !list.isEmpty else { return }
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        for a in list.sorted(by: { $0.fire < $1.fire }).prefix(60) {
            let content = UNMutableNotificationContent()
            content.title = a.title
            content.body = a.body
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: a.fire)
            let req = UNNotificationRequest(identifier: prefix + a.id, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(req)
        }
    }
}
