import Foundation
import SwiftData
import EventKit

// MARK: - Weekdot's own calendars and events (stored with SwiftData, synced through iCloud/CloudKit)

@Model
final class WDCalendar {
    var uid: String = UUID().uuidString
    var title: String = ""
    var colorHex: String = "#E8352F"
    var sortIndex: Int = 0
    var created: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \WDEvent.calendar)
    var events: [WDEvent]? = []

    init(title: String, colorHex: String, sortIndex: Int = 0) {
        self.title = title
        self.colorHex = colorHex
        self.sortIndex = sortIndex
    }

    /// The id used everywhere else in the app ("wd:" prefix = Weekdot calendar).
    var calendarID: String { LocalStore.prefix + uid }
}

@Model
final class WDEvent {
    var uid: String = UUID().uuidString
    var title: String = ""
    var location: String = ""
    var notes: String = ""
    var urlString: String = ""
    var start: Date = Date()
    var end: Date = Date()
    var isAllDay: Bool = false
    var timeZoneID: String? = nil
    var recurrenceData: Data? = nil
    var excludedData: Data? = nil
    var alarmsData: Data? = nil
    var inviteesData: Data? = nil
    var availability: String = "busy"
    var travelMinutes: Int = 0
    var emoji: String = ""
    var colorHex: String? = nil
    var modified: Date = Date()
    var calendar: WDCalendar?

    init() {}

    var recurrence: RecurrenceSpec? {
        get { recurrenceData.flatMap { try? JSONDecoder().decode(RecurrenceSpec.self, from: $0) } }
        set { recurrenceData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }

    var excludedDates: [Date] {
        get { excludedData.flatMap { try? JSONDecoder().decode([Date].self, from: $0) } ?? [] }
        set { excludedData = try? JSONEncoder().encode(newValue) }
    }

    var alarms: [Int] {
        get { alarmsData.flatMap { try? JSONDecoder().decode([Int].self, from: $0) } ?? [] }
        set { alarmsData = try? JSONEncoder().encode(newValue) }
    }

    var invitees: [String] {
        get { inviteesData.flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? [] }
        set { inviteesData = try? JSONEncoder().encode(newValue) }
    }

    var data: LocalEventData {
        LocalEventData(title: title, location: location, notes: notes, urlString: urlString, isAllDay: isAllDay,
                       start: start, end: end, timeZoneID: timeZoneID, recurrence: recurrence, alarms: alarms,
                       invitees: invitees, availability: availability, travelMinutes: travelMinutes,
                       emoji: emoji, colorHex: colorHex)
    }

    func apply(_ d: LocalEventData) {
        title = d.title
        location = d.location
        notes = d.notes
        urlString = d.urlString
        isAllDay = d.isAllDay
        start = d.start
        end = max(d.end, d.start)
        timeZoneID = d.timeZoneID
        recurrence = d.recurrence
        alarms = d.alarms
        invitees = d.invitees
        availability = d.availability
        travelMinutes = d.travelMinutes
        emoji = d.emoji
        colorHex = d.colorHex
        modified = Date()
    }
}

/// Plain copy of everything an event can hold (used by the editor for both kinds of calendars).
struct LocalEventData: Hashable {
    var title = ""
    var location = ""
    var notes = ""
    var urlString = ""
    var isAllDay = false
    var start = Date()
    var end = Date().addingTimeInterval(3600)
    var timeZoneID: String? = nil
    var recurrence: RecurrenceSpec? = nil
    var alarms: [Int] = []
    var invitees: [String] = []
    var availability = "busy"
    var travelMinutes = 0
    var emoji = ""
    var colorHex: String? = nil
}

@MainActor
final class LocalStore: ObservableObject {
    nonisolated static let prefix = "wd:"
    nonisolated static let cloudContainer = "iCloud.nl.lrvdlinden.weekdot"

    let container: ModelContainer?
    @Published private(set) var calendars: [WDCalendar] = []
    @Published private(set) var revision = 0
    /// Called after every change (local or from iCloud).
    var onChange: (() -> Void)?
    private var remoteObserver: NSObjectProtocol?

    nonisolated static func isLocalID(_ id: String?) -> Bool { id?.hasPrefix(prefix) ?? false }

    init() {
        let schema = Schema([WDCalendar.self, WDEvent.self])
        var made: ModelContainer?
        do {
            let config = ModelConfiguration("Weekdot", schema: schema, groupContainer: .identifier(Weekdot.appGroup),
                                            cloudKitDatabase: .private(LocalStore.cloudContainer))
            made = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // No iCloud (or no entitlement): keep the data on this device.
            if let c = try? ModelContainer(for: schema, configurations: [
                ModelConfiguration("Weekdot", schema: schema, groupContainer: .identifier(Weekdot.appGroup), cloudKitDatabase: .none)]) {
                made = c
            } else {
                made = try? ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            }
        }
        container = made
        reloadCalendars()
        remoteObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("NSPersistentStoreRemoteChangeNotification"), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.changed() }
            }
    }

    private var context: ModelContext? { container?.mainContext }

    private func changed() {
        reloadCalendars()
        revision += 1
        onChange?()
    }

    private func commit() {
        try? context?.save()
        changed()
    }

    // MARK: Calendars

    func reloadCalendars() {
        let d = FetchDescriptor<WDCalendar>(sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.created)])
        calendars = (try? context?.fetch(d)) ?? []
    }

    func calendar(withID id: String?) -> WDCalendar? {
        guard let id, id.hasPrefix(Self.prefix) else { return nil }
        let uid = String(id.dropFirst(Self.prefix.count))
        return calendars.first { $0.uid == uid }
    }

    @discardableResult
    func createCalendar(title: String, colorHex: String) -> WDCalendar? {
        guard let context else { return nil }
        let c = WDCalendar(title: title, colorHex: colorHex, sortIndex: (calendars.map(\.sortIndex).max() ?? 0) + 1)
        context.insert(c)
        commit()
        return c
    }

    func updateCalendar(_ c: WDCalendar, title: String, colorHex: String) {
        c.title = title
        c.colorHex = colorHex
        commit()
    }

    func deleteCalendar(_ c: WDCalendar) {
        context?.delete(c)
        commit()
    }

    /// The calendar for new events when nothing else is available ("Weekdot", created on first use).
    func defaultCalendar() -> WDCalendar? {
        if let first = calendars.first { return first }
        return createCalendar(title: "Weekdot", colorHex: "#E8352F")
    }

    // MARK: Events

    func event(uid: String) -> WDEvent? {
        let d = FetchDescriptor<WDEvent>(predicate: #Predicate { $0.uid == uid })
        return try? context?.fetch(d).first
    }

    func items(from: Date, to: Date, hidden: Set<String>, book: StyleBook, calendar cal: Calendar) -> [EventItem] {
        guard let context else { return [] }
        let d = FetchDescriptor<WDEvent>(predicate: #Predicate { $0.start < to })
        let events = (try? context.fetch(d)) ?? []
        var out: [EventItem] = []
        for e in events {
            guard let c = e.calendar, !hidden.contains(c.calendarID) else { continue }
            let duration = max(e.end.timeIntervalSince(e.start), 0)
            if let rule = e.recurrence {
                let starts = rule.occurrences(seriesStart: e.start, duration: duration, from: from, to: to,
                                              excluded: Set(e.excludedDates), calendar: cal)
                for s in starts {
                    let item = makeItem(e, calendar: c, start: s, end: s.addingTimeInterval(duration), book: book)
                    if item.overlapsRange(from, to) { out.append(item) }
                }
            } else {
                let item = makeItem(e, calendar: c, start: e.start, end: e.end, book: book)
                if item.overlapsRange(from, to) { out.append(item) }
            }
        }
        return out
    }

    private func makeItem(_ e: WDEvent, calendar c: WDCalendar, start: Date, end: Date, book: StyleBook) -> EventItem {
        let key = Self.prefix + e.uid
        let ruleStyle = book.style(forKey: key, title: e.title)
        var item = EventItem(
            id: e.uid + "|" + String(Int(start.timeIntervalSince1970)),
            eventIdentifier: e.uid,
            styleKey: key,
            title: e.title,
            location: e.location.isEmpty ? nil : e.location,
            start: start,
            end: end,
            isAllDay: e.isAllDay,
            calendarID: c.calendarID,
            calendarTitle: c.title,
            colorHex: e.colorHex ?? ruleStyle.colorHex ?? book.calendarColors[c.calendarID] ?? c.colorHex,
            emoji: e.emoji.isEmpty ? ruleStyle.emoji : e.emoji,
            isRecurring: e.recurrence != nil,
            canEdit: true,
            hasAlarms: !e.alarms.isEmpty)
        item.isLocal = true
        item.isFree = e.availability == "free"
        item.travelMinutes = e.travelMinutes
        return item
    }

    /// Saves an event. `existing` + `occurrence` + `span` handle edits of repeating events.
    @discardableResult
    func save(_ data: LocalEventData, calendarID: String?, existingUID: String?, occurrence: Date?, span: EKSpan) -> WDEvent? {
        guard let context else { return nil }
        let cal = calendar(withID: calendarID) ?? defaultCalendar()
        if let uid = existingUID, let e = event(uid: uid) {
            if e.recurrence != nil, let occ = occurrence {
                if span == .thisEvent {
                    // detach this occurrence
                    var ex = e.excludedDates
                    ex.append(occ)
                    e.excludedDates = ex
                    let single = WDEvent()
                    var d = data
                    d.recurrence = nil
                    single.apply(d)
                    single.calendar = cal
                    context.insert(single)
                    commit()
                    return single
                } else if occ > e.start {
                    // end the old series before this occurrence and start a new one
                    var old = e.recurrence ?? RecurrenceSpec()
                    old.endDate = occ.addingTimeInterval(-86_400)
                    old.count = nil
                    e.recurrence = old
                    let next = WDEvent()
                    next.apply(data)
                    next.calendar = cal
                    context.insert(next)
                    commit()
                    return next
                }
            }
            e.apply(data)
            e.calendar = cal
            commit()
            return e
        }
        let e = WDEvent()
        e.apply(data)
        e.calendar = cal
        context.insert(e)
        commit()
        return e
    }

    func delete(_ item: EventItem, span: EKSpan) {
        guard let e = event(uid: item.eventIdentifier) else { return }
        if var rule = e.recurrence {
            if span == .thisEvent {
                var ex = e.excludedDates
                ex.append(item.start)
                e.excludedDates = ex
                commit()
                return
            } else if item.start > e.start {
                rule.endDate = item.start.addingTimeInterval(-86_400)
                rule.count = nil
                e.recurrence = rule
                commit()
                return
            }
        }
        context?.delete(e)
        commit()
    }

    func move(_ item: EventItem, toStart newStart: Date, span: EKSpan) {
        guard let e = event(uid: item.eventIdentifier) else { return }
        var d = e.data
        let duration = item.end.timeIntervalSince(item.start)
        if e.recurrence != nil && span == .futureEvents && item.start == e.start {
            // moving the whole series by the same offset
            let delta = newStart.timeIntervalSince(item.start)
            d.start = e.start.addingTimeInterval(delta)
            d.end = e.end.addingTimeInterval(delta)
        } else {
            d.start = newStart
            d.end = newStart.addingTimeInterval(duration)
        }
        save(d, calendarID: e.calendar?.calendarID, existingUID: e.uid, occurrence: item.start, span: span)
    }

    func resize(_ item: EventItem, toEnd newEnd: Date, span: EKSpan) {
        guard let e = event(uid: item.eventIdentifier) else { return }
        var d = e.data
        d.start = item.start
        d.end = max(newEnd, item.start.addingTimeInterval(15 * 60))
        if e.recurrence != nil && span == .futureEvents && item.start == e.start { d.recurrence = e.recurrence }
        save(d, calendarID: e.calendar?.calendarID, existingUID: e.uid, occurrence: item.start, span: span)
    }

    func copy(_ item: EventItem, toStart newStart: Date) {
        guard let e = event(uid: item.eventIdentifier) else { return }
        var d = e.data
        d.recurrence = nil
        d.start = newStart
        d.end = newStart.addingTimeInterval(item.end.timeIntervalSince(item.start))
        save(d, calendarID: e.calendar?.calendarID, existingUID: nil, occurrence: nil, span: .thisEvent)
    }

    func search(_ q: String, book: StyleBook, calendar cal: Calendar, hidden: Set<String>) -> [EventItem] {
        let now = Date()
        let from = cal.date(byAdding: .year, value: -1, to: now) ?? now
        let to = cal.date(byAdding: .year, value: 2, to: now) ?? now
        return items(from: from, to: to, hidden: hidden, book: book, calendar: cal).filter { i in
            guard let e = event(uid: i.eventIdentifier) else { return false }
            return [e.title, e.location, e.notes].contains { $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }

    /// Upcoming alarms of Weekdot events (for local notifications).
    func upcomingAlarms(limit: Int, calendar cal: Calendar) -> [(id: String, title: String, body: String, fire: Date)] {
        let now = Date()
        let end = cal.addingDays(30, to: now)
        var list: [(String, String, String, Date)] = []
        for item in items(from: now, to: end, hidden: [], book: StyleBook(), calendar: cal) {
            guard let e = event(uid: item.eventIdentifier) else { continue }
            for m in e.alarms {
                let fire = item.start.addingTimeInterval(TimeInterval(-m * 60))
                if fire > now {
                    let body = item.isAllDay ? String(localized: "All-day") : Fmt.time(item.start) + (item.location.map { " · " + $0 } ?? "")
                    list.append((item.id + "|\(m)", item.displayTitle, body, fire))
                }
            }
        }
        return list.sorted { $0.3 < $1.3 }.prefix(limit).map { (id: $0.0, title: $0.1, body: $0.2, fire: $0.3) }
    }
}

extension EventItem {
    func overlapsRange(_ from: Date, _ to: Date) -> Bool {
        start < to && (end > from || (end == start && start >= from))
    }
}
