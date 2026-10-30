import EventKit
import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// A calendar as shown in pickers and lists: a Weekdot calendar or an Apple Calendar one.
struct CalendarChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let colorHex: String
    let isLocal: Bool
    let writable: Bool
    let sourceTitle: String
    var isBirthday: Bool = false
    var isSubscription: Bool = false
}

/// Everything Weekdot shows comes together here: its own calendars (synced with iCloud) and,
/// optionally, the calendars of the Apple Calendar app (iCloud, Google, Exchange, CalDAV, subscriptions)
/// plus reminders.
@MainActor
final class CalendarStore: ObservableObject {
    let eventStore = EKEventStore()
    let synced: SyncedStore
    let local: LocalStore

    @Published private(set) var authorization: EKAuthorizationStatus
    @Published private(set) var reminderAuthorization: EKAuthorizationStatus
    @Published private(set) var calendars: [EKCalendar] = []
    /// Bumped whenever events change, so views refetch.
    @Published private(set) var revision = 0
    @Published var lastError: String?

    private var cache: [String: [EventItem]] = [:]
    private var reminderItems: [EventItem] = []
    private var reminderWindow: (Date, Date)?
    private var reminderGeneration = 0
    private var changeObserver: NSObjectProtocol?

    init(synced: SyncedStore? = nil) {
        self.synced = synced ?? SyncedStore.shared
        self.local = LocalStore()
        authorization = EKEventStore.authorizationStatus(for: .event)
        reminderAuthorization = EKEventStore.authorizationStatus(for: .reminder)
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: eventStore, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.reload() }
            }
        local.onChange = { [weak self] in self?.invalidate() }
        if hasAccess { reloadCalendars() }
    }

    /// Apple Calendar access (full).
    var hasAccess: Bool { authorization == .fullAccess }
    /// Apple calendars are shown: access granted and the user didn't switch the integration off.
    var appleEnabled: Bool { hasAccess && synced.settings.useAppleCalendar }
    var isDenied: Bool { authorization == .denied || authorization == .restricted || authorization == .writeOnly }
    var hasReminderAccess: Bool { reminderAuthorization == .fullAccess }

    func requestAccess() async {
        do {
            _ = try await eventStore.requestFullAccessToEvents()
        } catch {
            lastError = error.localizedDescription
        }
        authorization = EKEventStore.authorizationStatus(for: .event)
        if hasAccess { synced.settings.useAppleCalendar = true }
        reload()
    }

    func requestReminderAccess() async {
        #if !os(watchOS)
        _ = try? await eventStore.requestFullAccessToReminders()
        #endif
        reminderAuthorization = EKEventStore.authorizationStatus(for: .reminder)
        reminderWindow = nil
        invalidate()
    }

    func refreshAuthorization() {
        let new = EKEventStore.authorizationStatus(for: .event)
        let newR = EKEventStore.authorizationStatus(for: .reminder)
        if new != authorization || newR != reminderAuthorization {
            authorization = new
            reminderAuthorization = newR
            reload()
        }
    }

    /// Re-reads everything (after an external change or a settings change).
    func reload() {
        #if !os(watchOS)
        if hasAccess { eventStore.refreshSourcesIfNecessary() }
        #endif
        reloadCalendars()
        local.reloadCalendars()
        cache.removeAll()
        reminderWindow = nil
        revision += 1
        writeWidgetSnapshot()
    }

    /// Clears the event caches. Reminders are only fetched again when they can have changed (store change,
    /// access granted, a reminder toggled, or `reminders: true`).
    func invalidate(reminders: Bool = false) {
        cache.removeAll()
        if reminders { reminderWindow = nil }
        revision += 1
        writeWidgetSnapshot()
    }

    private func reloadCalendars() {
        guard hasAccess else { calendars = []; return }
        calendars = eventStore.calendars(for: .event).sorted {
            if $0.source.title != $1.source.title { return $0.source.title < $1.source.title }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    // MARK: Reading

    var hiddenCalendarIDs: Set<String> {
        var h = Set(synced.settings.hiddenCalendarIDs)
        if !synced.settings.showBirthdays {
            for c in calendars where c.type == .birthday { h.insert(c.calendarIdentifier) }
        }
        return h
    }

    var styleBook: StyleBook {
        StyleBook(styles: synced.styles, rules: synced.rules, calendarColors: synced.calendarColors,
                  hiddenEvents: Set(synced.hiddenEvents.keys))
    }

    /// Shows a hidden event (or series) again.
    func unhide(_ entry: HiddenEvent) {
        synced.unhide(entry)
        invalidate()
    }

    func events(from: Date, to: Date) -> [EventItem] {
        let key = "\(from.timeIntervalSince1970)-\(to.timeIntervalSince1970)"
        if let hit = cache[key] { return hit }
        var items: [EventItem] = []
        if appleEnabled {
            items += EventFetcher.fetch(store: eventStore, from: from, to: to, hidden: hiddenCalendarIDs,
                                        book: styleBook, showDeclined: synced.settings.showDeclined)
        }
        items += local.items(from: from, to: to, hidden: hiddenCalendarIDs, book: styleBook,
                             calendar: synced.settings.calendar)
        items += reminders(from: from, to: to)
        items.sort { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay }
            if a.start != b.start { return a.start < b.start }
            return a.title < b.title
        }
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
        guard !q.isEmpty else { return [] }
        let cal = synced.settings.calendar
        var results = local.search(q, book: styleBook, calendar: cal, hidden: hiddenCalendarIDs)
        if appleEnabled {
            let now = Date()
            let from = cal.date(byAdding: .year, value: -1, to: now) ?? now
            let to = cal.date(byAdding: .year, value: 2, to: now) ?? now
            let calendarsList = eventStore.calendars(for: .event).filter { !hiddenCalendarIDs.contains($0.calendarIdentifier) }
            if !calendarsList.isEmpty {
                let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: calendarsList)
                let book = styleBook
                results += eventStore.events(matching: predicate)
                    .filter { e in
                        [e.title, e.location, e.notes].compactMap { $0 }
                            .contains { $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
                    }
                    .prefix(300)
                    .map { EventFetcher.item(from: $0, book: book) }
            }
        }
        return results.sorted { $0.start < $1.start }
    }

    /// Finds the EKEvent (the right occurrence for repeating events) behind an Apple item.
    func ekEvent(for item: EventItem) -> EKEvent? {
        guard !item.isLocal, !item.isReminder, hasAccess else { return nil }
        let from = item.start.addingTimeInterval(-1)
        let to = max(item.end, item.start).addingTimeInterval(1)
        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: nil)
        if let match = eventStore.events(matching: predicate).first(where: {
            ($0.eventIdentifier ?? $0.calendarItemIdentifier) == item.eventIdentifier && $0.startDate == item.start
        }) { return match }
        return eventStore.event(withIdentifier: item.eventIdentifier)
    }

    func calendar(withID id: String?) -> EKCalendar? {
        guard let id, !LocalStore.isLocalID(id), hasAccess else { return nil }
        return eventStore.calendar(withIdentifier: id)
    }

    var writableCalendars: [EKCalendar] { calendars.filter { $0.allowsContentModifications } }

    // MARK: Calendar choices (Weekdot + Apple)

    func color(forCalendarID id: String) -> String {
        if let own = synced.calendarColors[id] { return own }
        if let l = local.calendar(withID: id) { return l.colorHex }
        if let c = calendar(withID: id) { return ColorHex.from(cgColor: c.cgColor) }
        return "#E8352F"
    }

    var allChoices: [CalendarChoice] {
        var list = local.calendars.map {
            CalendarChoice(id: $0.calendarID, title: $0.title, colorHex: color(forCalendarID: $0.calendarID),
                           isLocal: true, writable: true, sourceTitle: "Weekdot")
        }
        if appleEnabled {
            list += calendars.map {
                CalendarChoice(id: $0.calendarIdentifier, title: $0.title, colorHex: color(forCalendarID: $0.calendarIdentifier),
                               isLocal: false, writable: $0.allowsContentModifications, sourceTitle: $0.source.title,
                               isBirthday: $0.type == .birthday, isSubscription: $0.type == .subscription)
            }
        }
        return list
    }

    var writableChoices: [CalendarChoice] { allChoices.filter(\.writable) }

    /// Default calendar id for new events (setting, else Apple default, else Weekdot).
    var defaultCalendarID: String? {
        let wanted = synced.settings.defaultCalendarID
        if let w = wanted, writableChoices.contains(where: { $0.id == w }) { return w }
        #if !os(watchOS)
        if appleEnabled, let d = eventStore.defaultCalendarForNewEvents, d.allowsContentModifications {
            return d.calendarIdentifier
        }
        #endif
        return local.calendars.first?.calendarID ?? writableChoices.first?.id
    }

    func calendarTitle(_ id: String?) -> String {
        guard let id else { return "" }
        return allChoices.first { $0.id == id }?.title ?? ""
    }

    // MARK: Writing (iPhone, iPad, Mac; the watch app is read-only)
    #if !os(watchOS)

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

    /// Writes an event from the editor to the chosen calendar (Weekdot or Apple), moving it between
    /// kinds of calendars when needed. Read-only Apple events are replaced by an edited Weekdot copy.
    @discardableResult
    func saveEvent(_ input: LocalEventData, calendarID: String?, existing: EventItem?, span: EKSpan) -> Bool {
        let cal0 = synced.settings.calendar
        var data = input
        let targetLocal = LocalStore.isLocalID(calendarID) || !appleEnabled || calendar(withID: calendarID) == nil
        if targetLocal {
            if data.isAllDay {
                // Weekdot stores all-day events with an exclusive end (midnight after the last day)
                let last = cal0.startOfDay(for: max(data.end, data.start))
                data.start = cal0.startOfDay(for: data.start)
                data.end = cal0.addingDays(1, to: last)
            }
            let calID = LocalStore.isLocalID(calendarID) ? calendarID : local.defaultCalendar()?.calendarID
            if let ex = existing, ex.isLocal {
                guard local.save(data, calendarID: calID, existingUID: ex.eventIdentifier, occurrence: ex.start, span: span) != nil else {
                    lastError = local.storageError ?? "Could not save the Weekdot event."
                    return false
                }
            } else {
                guard local.save(data, calendarID: calID, existingUID: nil, occurrence: nil, span: .thisEvent) != nil else {
                    lastError = local.storageError ?? "Could not save the Weekdot event."
                    return false
                }
                if let ex = existing, !ex.isReminder {
                    if ex.canEdit { delete(ex, span: span) }
                    else { synced.hide(ex) }
                }
            }
            synced.remember(title: data.title, durationMinutes: Int(data.end.timeIntervalSince(data.start) / 60),
                            location: data.location, alarmMinutes: data.alarms, calendarID: calID, isAllDay: data.isAllDay)
            invalidate()
            return true
        }
        // Apple calendar
        guard let cal = calendar(withID: calendarID) else { return false }
        var e: EKEvent
        if let ex = existing, !ex.isLocal, let found = ekEvent(for: ex), found.calendar.allowsContentModifications {
            e = found
        } else {
            e = EKEvent(eventStore: eventStore)
        }
        e.calendar = cal
        e.title = data.title.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "New Event") : data.title
        e.location = data.location.isEmpty ? nil : data.location
        e.notes = data.notes.isEmpty ? nil : data.notes
        e.url = URL(string: data.urlString.trimmingCharacters(in: .whitespaces))
        e.isAllDay = data.isAllDay
        e.startDate = data.isAllDay ? cal0.startOfDay(for: data.start) : data.start
        e.endDate = data.isAllDay ? cal0.startOfDay(for: max(data.end, data.start)) : max(data.end, data.start)
        // Only change the time zone when one was chosen; nil would turn the event into a "floating" one
        // that shifts when the user travels.
        if let id = data.timeZoneID, let tz = TimeZone(identifier: id) { e.timeZone = tz }
        e.availability = data.availability == "free" ? .free : .busy
        for r in e.recurrenceRules ?? [] { e.removeRecurrenceRule(r) }
        if let rule = data.recurrence { e.addRecurrenceRule(rule.ekRule(start: data.start, calendar: synced.settings.calendar)) }
        for a in e.alarms ?? [] { e.removeAlarm(a) }
        for m in data.alarms { e.addAlarm(EKAlarm(relativeOffset: TimeInterval(-m * 60))) }
        let style = EventStyle(emoji: data.emoji.isEmpty ? nil : data.emoji, colorHex: data.colorHex,
                               travelMinutes: data.travelMinutes > 0 ? data.travelMinutes : nil)
        let wasNew = e.eventIdentifier == nil
        guard save(e, span: wasNew ? .thisEvent : span, style: style) else { return false }
        if let ex = existing, wasNew, !ex.isReminder {
            if ex.isLocal { local.delete(ex, span: .futureEvents) }
            else if !ex.canEdit { synced.hide(ex) }
        }
        return true
    }

    @discardableResult
    func delete(_ item: EventItem, span: EKSpan = .thisEvent) -> Bool {
        if item.isLocal { local.delete(item, span: span); return true }
        if item.isReminder { return false }
        guard let e = ekEvent(for: item) else { return false }
        guard e.calendar.allowsContentModifications else {
            // read-only (subscription/holiday): hide it in Weekdot
            synced.hide(item)
            invalidate()
            return true
        }
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
        if item.isLocal { local.move(item, toStart: newStart, span: span); return true }
        guard let e = ekEvent(for: item) else { return false }
        guard e.calendar.allowsContentModifications else {
            lastError = String(localized: "This calendar is read-only. Open the event and tap Edit to keep a changed copy in Weekdot.")
            return false
        }
        let duration = e.endDate.timeIntervalSince(e.startDate)
        if let allDay { e.isAllDay = allDay }
        e.startDate = newStart
        e.endDate = e.isAllDay ? newStart.addingTimeInterval(max(duration, 0)) : newStart.addingTimeInterval(max(duration, 15 * 60))
        return save(e, span: span)
    }

    /// Changes only the end time (resize in day/week view).
    @discardableResult
    func resize(_ item: EventItem, toEnd newEnd: Date, span: EKSpan = .thisEvent) -> Bool {
        if item.isLocal { local.resize(item, toEnd: newEnd, span: span); return true }
        guard let e = ekEvent(for: item), e.calendar.allowsContentModifications else { return false }
        e.endDate = max(newEnd, e.startDate.addingTimeInterval(15 * 60))
        return save(e, span: span)
    }

    /// Copies an event to a new start (copy & paste / duplicate).
    @discardableResult
    func copy(_ item: EventItem, toStart newStart: Date) -> Bool {
        if item.isLocal { local.copy(item, toStart: newStart); return true }
        guard let src = ekEvent(for: item) else { return false }
        var d = Self.data(from: src, style: synced.styles[item.styleKey])
        d.recurrence = nil
        let duration = src.endDate.timeIntervalSince(src.startDate)
        d.start = newStart
        d.end = newStart.addingTimeInterval(duration)
        let target = src.calendar.allowsContentModifications ? src.calendar.calendarIdentifier : defaultCalendarID
        return saveEvent(d, calendarID: target, existing: nil, span: .thisEvent)
    }

    static func data(from e: EKEvent, style: EventStyle?) -> LocalEventData {
        LocalEventData(
            title: e.title ?? "", location: e.location ?? "", notes: e.notes ?? "",
            urlString: e.url?.absoluteString ?? "", isAllDay: e.isAllDay, start: e.startDate, end: e.endDate,
            timeZoneID: e.timeZone?.identifier,
            recurrence: RecurrenceSpec(rule: e.recurrenceRules?.first),
            alarms: (e.alarms ?? []).map { Int((-$0.relativeOffset / 60).rounded()) }.sorted(),
            invitees: (e.attendees ?? []).map { $0.url.absoluteString.replacingOccurrences(of: "mailto:", with: "") },
            availability: e.availability == .free ? "free" : "busy",
            travelMinutes: style?.travelMinutes ?? 0,
            emoji: style?.emoji ?? "", colorHex: style?.colorHex)
    }

    /// Everything the editor needs for an existing item.
    func data(for item: EventItem) -> LocalEventData? {
        if item.isLocal, let e = local.event(uid: item.eventIdentifier) {
            var d = e.data
            let duration = e.end.timeIntervalSince(e.start)
            d.start = item.start
            d.end = item.start.addingTimeInterval(duration)
            return d
        }
        if let e = ekEvent(for: item) { return Self.data(from: e, style: synced.styles[item.styleKey]) }
        return nil
    }

    // MARK: Reminders

    func toggleReminder(_ item: EventItem) {
        guard item.isReminder,
              let r = eventStore.calendarItem(withIdentifier: item.eventIdentifier) as? EKReminder else { return }
        r.isCompleted.toggle()
        try? eventStore.save(r, commit: true)
        reminderWindow = nil
        invalidate()
    }

    // MARK: Apple calendars

    /// Accounts in which a new calendar can be created (iCloud, CalDAV, Exchange, "On My iPhone/Mac").
    var sourcesForNewCalendars: [EKSource] {
        guard appleEnabled else { return [] }
        return eventStore.sources.filter { s in
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

    /// Renames (when allowed) and recolours a calendar. The colour is always kept by Weekdot, so it also
    /// works for read-only calendars such as Google, Exchange or subscriptions.
    @discardableResult
    func updateCalendar(_ c: EKCalendar, title: String, colorHex: String) -> Bool {
        synced.calendarColors[c.calendarIdentifier] = colorHex
        if c.allowsContentModifications && !c.isImmutable {
            c.title = title
            c.cgColor = ColorHex.cgColor(colorHex)
            try? eventStore.saveCalendar(c, commit: true)
        }
        reload()
        return true
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

    private func reminders(from: Date, to: Date) -> [EventItem] {
        #if os(watchOS)
        return []
        #else
        guard synced.settings.showReminders, hasReminderAccess else { return [] }
        if let w = reminderWindow, w.0 <= from, w.1 >= to {
            return reminderItems.filter { $0.start >= from && $0.start < to }
        }
        let cal = synced.settings.calendar
        let wFrom = cal.addingDays(-62, to: from), wTo = cal.addingDays(62, to: to)
        reminderWindow = (wFrom, wTo)
        reminderGeneration += 1
        let generation = reminderGeneration
        let gcal = cal
        // Only reminders that can show in this window: open ones due in it, and ones completed in it.
        // (Fetching all reminders would also load the user's whole completed history every time.)
        let open = eventStore.predicateForIncompleteReminders(withDueDateStarting: wFrom, ending: wTo, calendars: nil)
        let done = eventStore.predicateForCompletedReminders(withCompletionDateStarting: wFrom, ending: wTo, calendars: nil)
        let store = eventStore
        func makeItems(_ list: [EKReminder]) -> [EventItem] {
            list.compactMap { r in
                guard let comps = r.dueDateComponents, let due = gcal.date(from: comps),
                      due >= wFrom, due < wTo else { return nil }
                let allDay = comps.hour == nil
                let ident = r.calendarItemIdentifier
                let day = gcal.startOfDay(for: due)
                var item = EventItem(
                    id: "rem|" + ident, eventIdentifier: ident, styleKey: "rem|" + ident,
                    title: r.title ?? "", location: nil,
                    start: allDay ? day : due,
                    end: allDay ? gcal.date(byAdding: .day, value: 1, to: day) ?? due : due,
                    isAllDay: allDay, calendarID: r.calendar?.calendarIdentifier ?? "",
                    calendarTitle: r.calendar?.title ?? "", colorHex: ColorHex.from(cgColor: r.calendar?.cgColor),
                    emoji: nil, isRecurring: r.hasRecurrenceRules, canEdit: false)
                item.isReminder = true
                item.isCompleted = r.isCompleted
                return item
            }
        }
        store.fetchReminders(matching: open) { openList in
            let openItems = makeItems(openList ?? [])
            store.fetchReminders(matching: done) { [weak self] doneList in
                var seen = Set<String>()
                let items = (openItems + makeItems(doneList ?? [])).filter { seen.insert($0.id).inserted }
                Task { @MainActor in
                    // a newer fetch (another window) may have started meanwhile; keep only the latest
                    guard let self, generation == self.reminderGeneration else { return }
                    self.reminderItems = items
                    self.cache.removeAll()
                    self.revision += 1
                }
            }
        }
        return reminderItems.filter { $0.start >= from && $0.start < to }
        #endif
    }

    // MARK: Visibility & sets

    func isVisible(id: String) -> Bool { !synced.settings.hiddenCalendarIDs.contains(id) }

    func setVisible(id: String, _ visible: Bool) {
        var hidden = Set(synced.settings.hiddenCalendarIDs)
        if visible { hidden.remove(id) } else { hidden.insert(id) }
        synced.settings.hiddenCalendarIDs = Array(hidden).sorted()
        synced.settings.activeSetID = nil
        invalidate()
    }

    func isVisible(_ c: EKCalendar) -> Bool { isVisible(id: c.calendarIdentifier) }
    func setVisible(_ c: EKCalendar, _ visible: Bool) { setVisible(id: c.calendarIdentifier, visible) }

    func apply(set: CalendarSet) {
        let wanted = Set(set.calendarIDs)
        synced.settings.hiddenCalendarIDs = allChoices.map(\.id).filter { !wanted.contains($0) }
        synced.settings.activeSetID = set.id
        invalidate()
    }

    func showAllCalendars() {
        synced.settings.hiddenCalendarIDs = []
        synced.settings.activeSetID = nil
        invalidate()
    }

    var visibleCalendarIDs: [String] {
        allChoices.map(\.id).filter { !hiddenCalendarIDs.contains($0) }
    }

    // MARK: Widgets

    private var snapshotTask: Task<Void, Never>?

    /// Writes the widget snapshot at most once per burst of changes (reloads, settings sliders, polling).
    func writeWidgetSnapshot() {
        snapshotTask?.cancel()
        snapshotTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            self?.writeWidgetSnapshotNow()
        }
    }

    private func writeWidgetSnapshotNow() {
        #if canImport(WidgetKit)
        let cal = synced.settings.calendar
        let start = cal.startOfWeek(for: Date())
        let end = cal.addingDays(21, to: start)
        var items = local.items(from: start, to: end, hidden: hiddenCalendarIDs, book: styleBook, calendar: cal)
        if appleEnabled {
            items += EventFetcher.fetch(store: eventStore, from: start, to: end, hidden: hiddenCalendarIDs,
                                        book: styleBook, showDeclined: synced.settings.showDeclined)
        }
        items.sort { $0.start < $1.start }
        WidgetSnapshot(generated: Date(), firstWeekday: cal.firstWeekday, items: items,
                       appleEnabled: appleEnabled).save()
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
