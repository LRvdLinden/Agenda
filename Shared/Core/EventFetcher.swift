import EventKit
import Foundation

/// Emoji/colour lookup that works off the main actor (widgets) as well.
struct StyleBook {
    var styles: [String: EventStyle] = [:]
    var rules: [StyleRule] = []
    /// Own colours for calendars (Apple or Weekdot), by calendar id.
    var calendarColors: [String: String] = [:]

    func style(forKey key: String, title: String) -> EventStyle {
        var result = EventStyle()
        if let rule = rules.first(where: { $0.matches(title) }) {
            result = EventStyle(emoji: rule.emoji, colorHex: rule.colorHex)
        }
        if let s = styles[key] {
            if let e = s.emoji, !e.isEmpty { result.emoji = e }
            if let c = s.colorHex, !c.isEmpty { result.colorHex = c }
            result.travelMinutes = s.travelMinutes
            result.hidden = s.hidden
        }
        return result
    }

    /// Reads the copy that the app keeps in the app group (used by widgets).
    static func fromGroup() -> StyleBook {
        let d = Weekdot.groupDefaults
        var book = StyleBook()
        if let data = d.data(forKey: "weekdot.styles.v1"),
           let s = try? JSONDecoder().decode([String: EventStyle].self, from: data) { book.styles = s }
        if let data = d.data(forKey: "weekdot.rules.v1"),
           let r = try? JSONDecoder().decode([StyleRule].self, from: data) { book.rules = r }
        if let data = d.data(forKey: "weekdot.calcolors.v1"),
           let c = try? JSONDecoder().decode([String: String].self, from: data) { book.calendarColors = c }
        return book
    }

    static func settingsFromGroup() -> AppSettings {
        if let data = Weekdot.groupDefaults.data(forKey: "weekdot.settings.v1"),
           let s = try? JSONDecoder().decode(AppSettings.self, from: data) { return s }
        return AppSettings()
    }
}

enum EventFetcher {
    static var hasFullAccess: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Key under which Weekdot stores the style of an event (stable across devices where possible).
    static func styleKey(_ e: EKEvent) -> String {
        if let ext = e.calendarItemExternalIdentifier, !ext.isEmpty { return ext }
        return e.eventIdentifier ?? e.calendarItemIdentifier
    }

    static func item(from e: EKEvent, book: StyleBook) -> EventItem {
        let key = styleKey(e)
        let title = e.title ?? ""
        let style = book.style(forKey: key, title: title)
        let start = e.startDate ?? Date()
        let end = e.endDate ?? start
        var declined = false
        if let me = e.attendees?.first(where: { $0.isCurrentUser }) { declined = me.participantStatus == .declined }
        let ident = e.eventIdentifier ?? e.calendarItemIdentifier
        return EventItem(
            id: ident + "|" + String(Int(start.timeIntervalSince1970)),
            eventIdentifier: ident,
            styleKey: key,
            title: title,
            location: (e.location?.isEmpty ?? true) ? nil : e.location,
            start: start,
            end: end,
            isAllDay: e.isAllDay,
            calendarID: e.calendar?.calendarIdentifier ?? "",
            calendarTitle: e.calendar?.title ?? "",
            colorHex: style.colorHex ?? book.calendarColors[e.calendar?.calendarIdentifier ?? ""]
                ?? ColorHex.from(cgColor: e.calendar?.cgColor),
            emoji: style.emoji,
            isRecurring: e.hasRecurrenceRules || e.isDetached,
            canEdit: e.calendar?.allowsContentModifications ?? false,
            isDeclined: declined,
            hasAlarms: !(e.alarms ?? []).isEmpty,
            isFree: e.availability == .free,
            travelMinutes: style.travelMinutes ?? 0
        )
    }

    static func fetch(store: EKEventStore, from: Date, to: Date, hidden: Set<String>, book: StyleBook,
                      showDeclined: Bool = true) -> [EventItem] {
        guard from < to else { return [] }
        let calendars = store.calendars(for: .event).filter { !hidden.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: calendars)
        return store.events(matching: predicate)
            .filter { book.styles[styleKey($0)]?.hidden != true }
            .map { item(from: $0, book: book) }
            .filter { showDeclined || !$0.isDeclined }
            .sorted { a, b in
                if a.isAllDay != b.isAllDay { return a.isAllDay }
                if a.start != b.start { return a.start < b.start }
                return a.title < b.title
            }
    }
}
