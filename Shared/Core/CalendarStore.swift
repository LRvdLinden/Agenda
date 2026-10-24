import EventKit
import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Everything Sevn does with the calendars of the Apple Calendar app (iCloud, Google, Exchange,
/// CalDAV, subscriptions …) goes through here.
@MainActor
final class CalendarStore: ObservableObject {
    let eventStore = EKEventStore()
    let synced: SyncedStore

    @Published private(set) var authorization: EKAuthorizationStatus
    @Published private(set) var calendars: [EKCalendar] = []
    /// Bumped whenever events change, so views refetch.
    @Published private(set) var revision = 0
    @Published var lastError: String?

    private var cache: [String: [EventItem]] = [:]
    private var changeObserver: NSObjectProtocol?

    init(synced: SyncedStore = .shared) {
        self.synced = synced
        authorization = EKEventStore.authorizationStatus(for: .event)
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: eventStore, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.reload() }
            }
        if hasAccess { reloadCalendars() }
    }

    var hasAccess: Bool { authorization == .fullAccess }
    var isDenied: Bool { authorization == .denied || authorization == .restricted || authorization == .writeOnly }

    func requestAccess() async {
        do {
            _ = try await eventStore.requestFullAccessToEvents()
        } catch {
            lastError = error.localizedDescription
        }
        authorization = EKEventStore.authorizationStatus(for: .event)
        if hasAccess { reload() }
    }

    func refreshAuthorization() {
        let new = EKEventStore.authorizationStatus(for: .event)
        if new != authorization {
            authorization = new
            if hasAccess { reload() }
        }
    }

    /// Re-reads everything (after an external change or a settings change).
    func reload() {
        #if !os(watchOS)
        eventStore.refreshSourcesIfNecessary()
        #endif
        reloadCalendars()
        cache.removeAll()
        revision += 1
        writeWidgetSnapshot()
    }

    func invalidate() {
        cache.removeAll()
        revision += 1
        writeWidgetSnapshot()
    }

    private func reloadCalendars() {
        calendars = eventStore.calendars(for: .event).sorted {
            if $0.source.title != $1.source.title { return $0.source.title < $1.source.title }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    // MARK: Reading

    var hiddenCalendarIDs: Set<String> { Set(synced.settings.hiddenCalendarIDs) }

    var styleBook: StyleBook { StyleBook(styles: synced.styles, rules: synced.rules) }

    func events(from: Date, to: Date) -> [EventItem] {
        guard hasAccess else { return [] }
        let key = "\(from.timeIntervalSince1970)-\(to.timeIntervalSince1970)"
        if let hit = cache[key] { return hit }
        let items = EventFetcher.fetch(store: eventStore, from: from, to: to, hidden: hiddenCalendarIDs,
                                       book: styleBook, showDeclined: synced.settings.showDeclined)
        if cache.count > 60 { cache.removeAll() }
        cache[key] = items
        return items
    }

    func events(on day: Date, calendar: Calendar) -> [EventItem] {
        let s = calendar.startOfDay(for: day)
        return events(from: s, to: calendar.addingDays(1, to: s))
    }

    /// Events per day for a range, for month/year grids.
    func eventsByDay(from: Date, days: Int, calendar: Calendar) -> [Date: [EventItem]] {
        let start = calendar.startOfDay(for: from)
        let end = calendar.addingDays(days, to: start)
        let all = events(from: start, to: end)
        var map: [Date: [EventItem]] = [:]
        for item in all {
            var d = max(calendar.startOfDay(for: item.start), start)
            let last = item.isAllDay ? item.end.addingTimeInterval(-1) : max(item.start, item.end.addingTimeInterval(-1))
            var guardCount = 0
            while d <= last && d < end && guardCount < 400 {
                map[d, default: []].append(item)
                d = calendar.addingDays(1, to: d)
                guardCount += 1
            }
        }
        return map
    }

    func search(_ text: String) -> [EventItem] {
        let q = text.trimmingCharacters(in: .whitespaces)
        guard hasAccess, !q.isEmpty else { return [] }
        let cal = synced.settings.calendar
        let now = Date()
        let from = cal.date(byAdding: .year, value: -1, to: now) ?? now
        let to = cal.date(byAdding: .year, value: 2, to: now) ?? now
        let calendarsList = eventStore.calendars(for: .event).filter { !hiddenCalendarIDs.contains($0.calendarIdentifier) }
        guard !calendarsList.isEmpty else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: calendarsList)
        let book = styleBook
        return eventStore.events(matching: predicate)
            .filter { e in
                [e.title, e.location, e.notes].compactMap { $0 }
                    .contains { $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
            }
            .prefix(300)
            .map { EventFetcher.item(from: $0, book: book) }
            .sorted { $0.start < $1.start }
    }

    /// Finds the EKEvent (the right occurrence for repeating events) behind an item.
    func ekEvent(for item: EventItem) -> EKEvent? {
        let from = item.start.addingTimeInterval(-1)
        let to = max(item.end, item.start).addingTimeInterval(1)
        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: nil)
        if let match = eventStore.events(matching: predicate).first(where: {
            ($0.eventIdentifier ?? $0.calendarItemIdentifier) == item.eventIdentifier && $0.startDate == item.start
        }) { return match }
        return eventStore.event(withIdentifier: item.eventIdentifier)
    }

    func calendar(withID id: String?) -> EKCalendar? {
        guard let id else { return nil }
        return eventStore.calendar(withIdentifier: id)
    }

    var writableCalendars: [EKCalendar] { calendars.filter { $0.allowsContentModifications } }

    #if !os(watchOS)
    var defaultCalendar: EKCalendar? {
        if let c = calendar(withID: synced.settings.defaultCalendarID), c.allowsContentModifications { return c }
        return eventStore.defaultCalendarForNewEvents ?? writableCalendars.first
    }
    #endif

    // MARK: Writing events (iPhone, iPad, Mac; the watch app is read-only)
    #if !os(watchOS)

    func newEvent(start: Date, allDay: Bool = false) -> EKEvent {
        let e = EKEvent(eventStore: eventStore)
        e.calendar = defaultCalendar
        e.isAllDay = allDay
        e.startDate = start
        e.endDate = allDay ? start : start.addingTimeInterval(TimeInterval(synced.settings.defaultDurationMinutes * 60))
        if synced.settings.defaultAlarmMinutes >= 0 && !allDay {
            e.addAlarm(EKAlarm(relativeOffset: TimeInterval(-synced.settings.defaultAlarmMinutes * 60)))
        }
        return e
    }

    func newEvent(from template: EventTemplate, on day: Date, at start: Date?) -> EKEvent {
        let cal = synced.settings.calendar
        let startDate: Date = start ?? cal.date(on: day, minutes: template.startMinutes ?? 9 * 60)
        let realStart: Date = template.isAllDay ? cal.startOfDay(for: startDate) : startDate
        let realEnd: Date = template.isAllDay ? realStart
            : startDate.addingTimeInterval(TimeInterval(template.durationMinutes * 60))
        let e = EKEvent(eventStore: eventStore)
        e.calendar = calendar(withID: template.calendarID) ?? defaultCalendar
        e.title = template.title
        e.location = template.location.isEmpty ? nil : template.location
        e.notes = template.notes.isEmpty ? nil : template.notes
        e.url = URL(string: template.urlString)
        e.isAllDay = template.isAllDay
        e.startDate = realStart
        e.endDate = realEnd
        for m in template.alarmMinutes { e.addAlarm(EKAlarm(relativeOffset: TimeInterval(-m * 60))) }
        return e
    }

    @discardableResult
    func save(_ event: EKEvent, span: EKSpan = .thisEvent, style: EventStyle? = nil) -> Bool {
        do {
            try eventStore.save(event, span: span, commit: true)
            if let style { synced.setStyle(style, forKey: EventFetcher.styleKey(event)) }
            let minutes = Int((event.endDate.timeIntervalSince(event.startDate)) / 60)
            synced.remember(title: event.title ?? "", durationMinutes: max(minutes, 0), location: event.location ?? "",
                            alarmMinutes: (event.alarms ?? []).map { Int(-$0.relativeOffset / 60) },
                            calendarID: event.calendar?.calendarIdentifier, isAllDay: event.isAllDay)
            invalidate()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func delete(_ item: EventItem, span: EKSpan = .thisEvent) -> Bool {
        guard let e = ekEvent(for: item) else { return false }
        do {
            try eventStore.remove(e, span: span, commit: true)
            invalidate()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Moves an event to a new start (keeps its duration). Used by drag & drop.
    @discardableResult
    func move(_ item: EventItem, toStart newStart: Date, allDay: Bool? = nil, span: EKSpan = .thisEvent) -> Bool {
        guard let e = ekEvent(for: item), e.calendar.allowsContentModifications else { return false }
        let duration = e.endDate.timeIntervalSince(e.startDate)
        if let allDay { e.isAllDay = allDay }
        e.startDate = newStart
        e.endDate = e.isAllDay ? newStart.addingTimeInterval(max(duration, 0)) : newStart.addingTimeInterval(max(duration, 15 * 60))
        if let allDay, !allDay, duration >= 86_000 {
            e.endDate = newStart.addingTimeInterval(TimeInterval(synced.settings.defaultDurationMinutes * 60))
        }
        return save(e, span: span)
    }

    /// Changes only the end time (resize in day/week view).
    @discardableResult
    func resize(_ item: EventItem, toEnd newEnd: Date) -> Bool {
        guard let e = ekEvent(for: item), e.calendar.allowsContentModifications else { return false }
        e.endDate = max(newEnd, e.startDate.addingTimeInterval(15 * 60))
        return save(e, span: .thisEvent)
    }

    /// Copies an event to a new start (copy & paste / duplicate).
    @discardableResult
    func copy(_ item: EventItem, toStart newStart: Date) -> Bool {
        guard let src = ekEvent(for: item) else { return false }
        let e = EKEvent(eventStore: eventStore)
        e.calendar = src.calendar.allowsContentModifications ? src.calendar : defaultCalendar
        e.title = src.title
        e.location = src.location
        e.notes = src.notes
        e.url = src.url
        e.isAllDay = src.isAllDay
        e.timeZone = src.timeZone
        let duration = src.endDate.timeIntervalSince(src.startDate)
        e.startDate = newStart
        e.endDate = newStart.addingTimeInterval(duration)
        for a in src.alarms ?? [] { e.addAlarm(EKAlarm(relativeOffset: a.relativeOffset)) }
        let style = synced.styles[item.styleKey]
        return save(e, span: .thisEvent, style: style)
    }

    // MARK: Calendars

    /// Accounts in which a new calendar can be created (iCloud, CalDAV, Exchange, "On My iPhone/Mac").
    var sourcesForNewCalendars: [EKSource] {
        eventStore.sources.filter { s in
            switch s.sourceType {
            case .local, .calDAV, .exchange, .mobileMe: return true
            default: return false
            }
        }
        .sorted { a, b in
            func rank(_ s: EKSource) -> Int { s.title.lowercased().contains("icloud") ? 0 : (s.sourceType == .local ? 2 : 1) }
            return rank(a) < rank(b)
        }
    }

    @discardableResult
    func createCalendar(title: String, colorHex: String, source: EKSource) -> EKCalendar? {
        let c = EKCalendar(for: .event, eventStore: eventStore)
        c.title = title
        c.cgColor = ColorHex.cgColor(colorHex)
        c.source = source
        do {
            try eventStore.saveCalendar(c, commit: true)
            reload()
            return c
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func updateCalendar(_ c: EKCalendar, title: String, colorHex: String) -> Bool {
        c.title = title
        c.cgColor = ColorHex.cgColor(colorHex)
        do {
            try eventStore.saveCalendar(c, commit: true)
            reload()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func deleteCalendar(_ c: EKCalendar) -> Bool {
        do {
            try eventStore.removeCalendar(c, commit: true)
            reload()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    #endif

    func isVisible(_ c: EKCalendar) -> Bool { !synced.settings.hiddenCalendarIDs.contains(c.calendarIdentifier) }

    func setVisible(_ c: EKCalendar, _ visible: Bool) {
        var hidden = Set(synced.settings.hiddenCalendarIDs)
        if visible { hidden.remove(c.calendarIdentifier) } else { hidden.insert(c.calendarIdentifier) }
        synced.settings.hiddenCalendarIDs = Array(hidden).sorted()
        synced.settings.activeSetID = nil
        invalidate()
    }

    func apply(set: CalendarSet) {
        let wanted = Set(set.calendarIDs)
        synced.settings.hiddenCalendarIDs = calendars.map(\.calendarIdentifier).filter { !wanted.contains($0) }
        synced.settings.activeSetID = set.id
        invalidate()
    }

    func showAllCalendars() {
        synced.settings.hiddenCalendarIDs = []
        synced.settings.activeSetID = nil
        invalidate()
    }

    var visibleCalendarIDs: [String] {
        calendars.map(\.calendarIdentifier).filter { !hiddenCalendarIDs.contains($0) }
    }

    // MARK: Widgets

    func writeWidgetSnapshot() {
        #if os(iOS) || os(macOS)
        guard hasAccess else { return }
        let cal = synced.settings.calendar
        let start = cal.startOfWeek(for: Date())
        let items = EventFetcher.fetch(store: eventStore, from: start, to: cal.addingDays(21, to: start),
                                       hidden: hiddenCalendarIDs, book: styleBook,
                                       showDeclined: synced.settings.showDeclined)
        WidgetSnapshot(generated: Date(), firstWeekday: cal.firstWeekday, items: items).save()
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
