import SwiftUI
import EventKit
import CryptoKit

/// Weekdot-owned subscription: the feed is fetched by Weekdot, and its events
/// are mirrored into a dedicated writable Apple Calendar calendar. The Calendar
/// app is never launched to subscribe, and Weekdot refreshes when active.
struct FeedSubscription: Codable, Identifiable {
    var id = UUID()
    var title: String
    var url: String
    var category: String
    var countryCode: String?
    var calendarID: String
    var importedEventIDs: [String] = []
    var fingerprint: String = ""
    var lastRefreshed: Date?
    var eventCount: Int = 0
    var lastError: String?
    var oneTimeImport: Bool = false
}

enum FeedSubscriptionError: LocalizedError {
    case invalidURL, invalidFeed, duplicate, calendarAccess, accountUnavailable, calendarMissing, busy

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Use a valid HTTPS or webcal calendar link."
        case .invalidFeed: return "This link did not return an ICS calendar with valid events."
        case .duplicate: return "This calendar is already subscribed in Weekdot."
        case .calendarAccess: return "Allow full Calendar access in Settings to mirror subscriptions into Apple Calendar."
        case .accountUnavailable: return "No Apple Calendar account can create a calendar. Enable iCloud Calendar or add a writable account."
        case .calendarMissing: return "The linked Apple Calendar calendar no longer exists. Remove and subscribe again."
        case .busy: return "Please wait for the current subscription to finish."
        }
    }
}

@MainActor
final class FeedSubscriptionManager: ObservableObject {
    @Published private(set) var subscriptions: [FeedSubscription] = [] {
        didSet { save() }
    }
    @Published private(set) var isBusy = false

    private let storageKey = "weekdot.feed-subscriptions.v1"
    private let refreshInterval: TimeInterval = 6 * 3_600

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let entries = try? JSONDecoder().decode([FeedSubscription].self, from: data) {
            subscriptions = entries
        }
    }

    func isSubscribed(to link: String) -> Bool {
        guard let url = try? Self.feedURL(link) else { return false }
        return subscriptions.contains { $0.url == url.absoluteString }
    }

    func subscribe(title: String, link: String, category: String, countryCode: String? = nil,
                   store: CalendarStore) async throws {
        guard !isBusy else { throw FeedSubscriptionError.busy }
        isBusy = true
        defer { isBusy = false }

        let url = try Self.feedURL(link)
        guard !isSubscribed(to: url.absoluteString) else { throw FeedSubscriptionError.duplicate }
        let data = try await download(url)
        let entries = ICSFeedParser.parse(data)
        guard !entries.isEmpty else { throw FeedSubscriptionError.invalidFeed }

        if !store.hasAccess { await store.requestAccess() }
        guard store.hasAccess else { throw FeedSubscriptionError.calendarAccess }
        if !store.appleEnabled {
            store.synced.settings.useAppleCalendar = true
            store.reload()
        }
        guard let source = store.sourcesForNewCalendars.first else { throw FeedSubscriptionError.accountUnavailable }
        let name = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(90))
        let calendarName = "Weekdot · " + (name.isEmpty ? "Subscription" : name)
        guard let calendar = store.createCalendar(title: calendarName, colorHex: "#5F9EA0", source: source) else {
            throw FeedSubscriptionError.accountUnavailable
        }

        do {
            let ids = try mirror(entries: entries, into: calendar, removing: [], store: store)
            subscriptions.append(FeedSubscription(
                title: name.isEmpty ? "Subscription" : name,
                url: url.absoluteString, category: category, countryCode: countryCode,
                calendarID: calendar.calendarIdentifier, importedEventIDs: ids,
                fingerprint: signature(entries), lastRefreshed: Date(), eventCount: ids.count
            ))
            store.reload()
        } catch {
            _ = store.deleteCalendar(calendar)
            throw error
        }
    }

    /// For providers such as Circulus that offer an exported ICS file instead
    /// of a live URL. This is an explicit one-time import, not a subscription.
    func importCalendarFile(_ data: Data, title: String, store: CalendarStore) async throws {
        guard !isBusy else { throw FeedSubscriptionError.busy }
        isBusy = true
        defer { isBusy = false }
        guard data.count <= 3_000_000 else { throw FeedSubscriptionError.invalidFeed }
        let entries = ICSFeedParser.parse(data)
        guard !entries.isEmpty else { throw FeedSubscriptionError.invalidFeed }
        if !store.hasAccess { await store.requestAccess() }
        guard store.hasAccess else { throw FeedSubscriptionError.calendarAccess }
        if !store.appleEnabled {
            store.synced.settings.useAppleCalendar = true
            store.reload()
        }
        guard let source = store.sourcesForNewCalendars.first else { throw FeedSubscriptionError.accountUnavailable }
        let cleanName = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(90))
        let name = cleanName.isEmpty ? "Imported Calendar" : cleanName
        guard let calendar = store.createCalendar(title: "Weekdot · " + name,
                                                  colorHex: "#5F9EA0", source: source) else {
            throw FeedSubscriptionError.accountUnavailable
        }
        do {
            let ids = try mirror(entries: entries, into: calendar, removing: [], store: store)
            subscriptions.append(FeedSubscription(title: name, url: "imported:" + UUID().uuidString,
                                                  category: "import", countryCode: nil,
                                                  calendarID: calendar.calendarIdentifier,
                                                  importedEventIDs: ids, fingerprint: signature(entries),
                                                  lastRefreshed: Date(), eventCount: ids.count,
                                                  oneTimeImport: true))
            store.reload()
        } catch {
            _ = store.deleteCalendar(calendar)
            throw error
        }
    }

    func refresh(id: UUID, store: CalendarStore, requestTimeout: TimeInterval = 25) async throws {
        guard !isBusy else { throw FeedSubscriptionError.busy }
        guard let subscription = subscriptions.first(where: { $0.id == id }) else { return }
        if subscription.oneTimeImport { return }
        isBusy = true
        defer { isBusy = false }

        do {
            guard store.hasAccess else { throw FeedSubscriptionError.calendarAccess }
            guard let calendar = store.calendar(withID: subscription.calendarID) else {
                throw FeedSubscriptionError.calendarMissing
            }
            let data = try await download(Self.feedURL(subscription.url), timeout: requestTimeout)
            try Task.checkCancellation()
            let entries = ICSFeedParser.parse(data)
            guard !entries.isEmpty else { throw FeedSubscriptionError.invalidFeed }
            let hash = signature(entries)
            let ids: [String]
            if hash == subscription.fingerprint {
                ids = subscription.importedEventIDs
            } else {
                ids = try mirror(entries: entries, into: calendar,
                                 removing: subscription.importedEventIDs, store: store)
            }
            guard let index = subscriptions.firstIndex(where: { $0.id == id }) else { return }
            subscriptions[index].importedEventIDs = ids
            subscriptions[index].fingerprint = hash
            subscriptions[index].eventCount = ids.count
            subscriptions[index].lastRefreshed = Date()
            subscriptions[index].lastError = nil
            store.reload()
        } catch {
            if let index = subscriptions.firstIndex(where: { $0.id == id }) {
                subscriptions[index].lastError = error.localizedDescription
            }
            throw error
        }
    }

    /// Foreground uses the normal network timeout. iOS background app-refresh
    /// has a short, system-controlled runtime, so callers can set a deadline
    /// and short per-feed timeout. Remaining feeds get another chance later.
    func refreshIfNeeded(store: CalendarStore, maxDuration: TimeInterval? = nil,
                         requestTimeout: TimeInterval = 25) async {
        guard store.hasAccess, !isBusy else { return }
        let end = maxDuration.map { Date().addingTimeInterval($0) }
        for item in subscriptions {
            if Task.isCancelled { break }
            if let end, Date() >= end { break }
            if item.oneTimeImport { continue }
            if let last = item.lastRefreshed, Date().timeIntervalSince(last) <= refreshInterval { continue }
            try? await refresh(id: item.id, store: store, requestTimeout: requestTimeout)
        }
    }

    func unsubscribe(id: UUID, store: CalendarStore) throws {
        guard let item = subscriptions.first(where: { $0.id == id }) else { return }
        guard store.hasAccess else { throw FeedSubscriptionError.calendarAccess }
        if let calendar = store.calendar(withID: item.calendarID), !store.deleteCalendar(calendar) {
            throw FeedSubscriptionError.calendarMissing
        }
        subscriptions.removeAll { $0.id == id }
        store.reload()
    }

    private func mirror(entries: [ICSFeedParser.Entry], into calendar: EKCalendar,
                        removing oldIDs: [String], store: CalendarStore) throws -> [String] {
        let eventStore = store.eventStore
        var newEvents: [EKEvent] = []
        let now = Date()
        let pastLimit = Calendar.current.date(byAdding: .year, value: -2, to: now) ?? now
        let futureLimit = Calendar.current.date(byAdding: .year, value: 5, to: now) ?? now
        do {
            for id in oldIDs {
                if let existing = eventStore.event(withIdentifier: id),
                   existing.calendar.calendarIdentifier == calendar.calendarIdentifier {
                    try eventStore.remove(existing,
                                          span: existing.hasRecurrenceRules ? .futureEvents : .thisEvent,
                                          commit: false)
                }
            }
            for entry in entries where (entry.start >= pastLimit && entry.start < futureLimit) || entry.recurrence != nil {
                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = entry.title
                event.startDate = entry.start
                event.endDate = entry.end
                event.isAllDay = entry.isAllDay
                event.location = entry.location.isEmpty ? nil : entry.location
                event.notes = "Managed by Weekdot subscription.\n" + entry.details
                if let rule = Self.simpleRecurrence(entry.recurrence) { event.addRecurrenceRule(rule) }
                try eventStore.save(event, span: .thisEvent, commit: false)
                newEvents.append(event)
            }
            guard !newEvents.isEmpty else { throw FeedSubscriptionError.invalidFeed }
            try eventStore.commit()
        } catch {
            eventStore.reset()
            throw error
        }
        return newEvents.compactMap(\.eventIdentifier)
    }

    /// Only map simple recurrence rules; more complex rules should be supplied
    /// as dated VEVENT instances by the feed provider.
    private static func simpleRecurrence(_ raw: String?) -> EKRecurrenceRule? {
        guard let raw else { return nil }
        let parts = raw.split(separator: ";").compactMap { part -> (String, String)? in
            let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
            return pair.count == 2 ? (pair[0], pair[1]) : nil
        }
        let values = Dictionary(parts, uniquingKeysWith: { first, _ in first })
        guard !values.keys.contains(where: { $0.hasPrefix("BY") || $0 == "UNTIL" || $0 == "COUNT" }) else { return nil }
        let interval = max(1, min(50, Int(values["INTERVAL"] ?? "1") ?? 1))
        let frequency: EKRecurrenceFrequency
        switch values["FREQ"] {
        case "DAILY": frequency = .daily
        case "WEEKLY": frequency = .weekly
        case "MONTHLY": frequency = .monthly
        case "YEARLY": frequency = .yearly
        default: return nil
        }
        return EKRecurrenceRule(recurrenceWith: frequency, interval: interval, end: nil)
    }

    private func download(_ url: URL, timeout: TimeInterval = 25) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("text/calendar, text/plain;q=0.8", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode), data.count <= 3_000_000 else {
            throw FeedSubscriptionError.invalidFeed
        }
        return data
    }

    private static func feedURL(_ text: String) throws -> URL {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let converted = raw.lowercased().hasPrefix("webcal://") ? "https://" + String(raw.dropFirst(9)) : raw
        guard let url = URL(string: converted), url.scheme?.lowercased() == "https",
              let host = url.host, host.contains("."), url.user == nil, url.password == nil,
              !host.lowercased().hasSuffix(".local"), !host.lowercased().hasSuffix(".internal") else {
            throw FeedSubscriptionError.invalidURL
        }
        return url
    }

    private func signature(_ entries: [ICSFeedParser.Entry]) -> String {
        // Ignore changing feed metadata such as DTSTAMP; only replace events
        // when actual content has changed.
        let stable = entries.map {
            "\($0.uid)|\($0.title)|\($0.start.timeIntervalSince1970)|\($0.end.timeIntervalSince1970)|\($0.location)|\($0.details)|\($0.recurrence ?? "")"
        }.sorted().joined(separator: "\n")
        return SHA256.hash(data: Data(stable.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
