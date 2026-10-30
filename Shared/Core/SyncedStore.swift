import Foundation
import Combine

/// Keeps Weekdot's own data (settings, templates, calendar sets, colour/emoji rules, event styles and
/// auto-fill memory) in iCloud (key-value store) so it is the same on iPhone, iPad, Mac and Apple Watch.
/// A copy lives in the app group so widgets can read it too.
@MainActor
final class SyncedStore: ObservableObject {
    static let shared = SyncedStore()

    @Published var settings: AppSettings = AppSettings() { didSet { if !loading { persist(Key.settings, settings) } } }
    @Published var templates: [EventTemplate] = [] { didSet { if !loading { persist(Key.templates, templates) } } }
    @Published var sets: [CalendarSet] = [] { didSet { if !loading { persist(Key.sets, sets) } } }
    @Published var rules: [StyleRule] = [] { didSet { if !loading { persist(Key.rules, rules) } } }
    @Published var styles: [String: EventStyle] = [:] { didSet { if !loading { persist(Key.styles, styles) } } }
    @Published var titleMemory: [String: TitleMemory] = [:] { didSet { if !loading { persist(Key.memory, titleMemory) } } }
    /// Own colour per calendar (works for every calendar, also read-only ones like Google or subscriptions).
    @Published var calendarColors: [String: String] = [:] { didSet { if !loading { persist(Key.calColors, calendarColors) } } }
    /// Events hidden in Weekdot, one occurrence each (see `HiddenEvent`). Kept apart from `styles` so they are
    /// never dropped when the style list is trimmed, and so Settings can list them and show them again.
    @Published var hiddenEvents: [String: HiddenEvent] = [:] { didSet { if !loading { persist(Key.hidden, hiddenEvents) } } }
    @Published private(set) var lastSync: Date?
    /// Set when iCloud reported that Weekdot's key-value storage was full (cleared after trimming).
    @Published private(set) var quotaWarning = false

    private enum Key {
        static let settings = "weekdot.settings.v1"
        static let templates = "weekdot.templates.v1"
        static let sets = "weekdot.sets.v1"
        static let rules = "weekdot.rules.v1"
        static let styles = "weekdot.styles.v1"
        static let memory = "weekdot.memory.v1"
        static let calColors = "weekdot.calcolors.v1"
        static let hidden = "weekdot.hidden.v1"
        static let all = [settings, templates, sets, rules, styles, memory, calColors, hidden]
    }

    private let kvs = NSUbiquitousKeyValueStore.default
    private let local = Weekdot.groupDefaults
    private var loading = false
    private var observer: NSObjectProtocol?

    var iCloudAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    private init() {
        loadAll(preferCloud: false)
        kvs.synchronize()
        loadAll(preferCloud: true)
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs, queue: .main) { [weak self] note in
                let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
                Task { @MainActor in
                    guard let self else { return }
                    if reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
                        self.trimForQuota()
                        return
                    }
                    self.loadAll(preferCloud: true)
                    self.lastSync = Date()
                    self.cloudAnswered = true
                    self.seedIfNeeded()
                }
            }
        migrateLegacyHidden()
        trimIfNeeded()
        // Example colour/emoji rules are only added once, and only when iCloud has no rules yet. On a new device
        // iCloud may not have downloaded yet, so wait for its first answer (or a while) before deciding; otherwise
        // the examples would overwrite the rules the user made on their other devices.
        if local.object(forKey: "weekdot.seeded") == nil {
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                self?.cloudAnswered = true
                self?.seedIfNeeded()
            }
        }
    }

    private var cloudAnswered = false

    private func seedIfNeeded() {
        guard cloudAnswered, local.object(forKey: "weekdot.seeded") == nil else { return }
        if !rules.isEmpty || kvs.data(forKey: Key.rules) != nil || !iCloudAvailable && local.data(forKey: Key.rules) != nil {
            local.set(true, forKey: "weekdot.seeded")
            return
        }
        seedDefaults()
    }

    /// Ask iCloud to sync right away (pull to refresh / app becomes active).
    func syncNow() {
        kvs.synchronize()
        loadAll(preferCloud: true)
        lastSync = Date()
    }

    // MARK: Style resolution

    func style(forKey key: String, title: String) -> EventStyle {
        StyleBook(styles: styles, rules: rules, calendarColors: calendarColors).style(forKey: key, title: title)
    }

    func setStyle(_ style: EventStyle, forKey key: String) {
        var style = style
        style.usedAt = Date()
        if style.isEmpty { styles.removeValue(forKey: key) } else { styles[key] = style }
        trimIfNeeded()
    }

    // MARK: Hidden events

    func hide(_ item: EventItem) {
        let entry = HiddenEvent(key: item.styleKey, start: item.start, title: item.title, calendarTitle: item.calendarTitle)
        hiddenEvents[entry.id] = entry
    }

    func unhide(_ entry: HiddenEvent) {
        hiddenEvents.removeValue(forKey: entry.id)
        if entry.start == nil, var s = styles[entry.key], s.hidden == true {
            s.hidden = nil
            if s.isEmpty { styles.removeValue(forKey: entry.key) } else { styles[entry.key] = s }
        }
    }

    /// Older versions stored "hidden" in the style of the whole series; list those in Settings so they can be
    /// shown again.
    private func migrateLegacyHidden() {
        let legacy = styles.filter { $0.value.hidden == true && hiddenEvents[$0.key] == nil }
        guard !legacy.isEmpty else { return }
        var h = hiddenEvents
        for (k, _) in legacy { h[k] = HiddenEvent(key: k, start: nil, title: "") }
        hiddenEvents = h
    }

    // MARK: iCloud size

    /// iCloud key-value storage holds 1 MB for all keys together. When it is full, iCloud stops syncing all of
    /// Weekdot's settings, so the event styles and auto-fill memory are kept well below that: the oldest are
    /// dropped first. Hidden events are stored separately and never dropped.
    private static let styleBudget = 350_000
    private static let memoryLimit = 400

    private func trimIfNeeded(styleBudget: Int = SyncedStore.styleBudget, memoryLimit: Int = SyncedStore.memoryLimit) {
        if titleMemory.count > memoryLimit {
            let old = titleMemory.sorted { $0.value.lastUsed < $1.value.lastUsed }.prefix(titleMemory.count - memoryLimit)
            var m = titleMemory
            for (k, _) in old { m.removeValue(forKey: k) }
            titleMemory = m
        }
        // a style is roughly 100–250 bytes, so only measure when there are many
        guard styles.count > 1000 || styleBudget < Self.styleBudget,
              let size = try? JSONEncoder().encode(styles).count, size > styleBudget, !styles.isEmpty else { return }
        // roughly how many entries fit, then drop the oldest (never the legacy "hidden" ones)
        let keep = max(0, styles.count * styleBudget / size * 9 / 10)
        let removable = styles.filter { $0.value.hidden != true }
            .sorted { ($0.value.usedAt ?? .distantPast) < ($1.value.usedAt ?? .distantPast) }
        let dropCount = min(removable.count, styles.count - keep)
        guard dropCount > 0 else { return }
        var s = styles
        for (k, _) in removable.prefix(dropCount) { s.removeValue(forKey: k) }
        styles = s
    }

    private func trimForQuota() {
        quotaWarning = true
        trimIfNeeded(styleBudget: Self.styleBudget / 2, memoryLimit: Self.memoryLimit / 2)
        // write everything again so iCloud gets the smaller versions
        persist(Key.settings, settings); persist(Key.rules, rules); persist(Key.hidden, hiddenEvents)
        persist(Key.styles, styles); persist(Key.memory, titleMemory)
        kvs.synchronize()
    }

    // MARK: Auto-fill memory

    func remember(title: String, durationMinutes: Int, location: String, alarmMinutes: [Int],
                  calendarID: String?, isAllDay: Bool) {
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return }
        titleMemory[key] = TitleMemory(title: title, durationMinutes: durationMinutes, location: location,
                                       alarmMinutes: alarmMinutes, calendarID: calendarID, isAllDay: isAllDay,
                                       lastUsed: Date())
        if titleMemory.count > Self.memoryLimit { trimIfNeeded() }
    }

    func suggestions(for text: String, limit: Int = 5) -> [TitleMemory] {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard t.count >= 1 else { return [] }
        return titleMemory.values
            .filter { $0.title.range(of: t, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil
                && $0.title.caseInsensitiveCompare(t) != .orderedSame }
            .sorted { $0.lastUsed > $1.lastUsed }
            .prefix(limit).map { $0 }
    }

    func memory(forExactTitle text: String) -> TitleMemory? {
        titleMemory[text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }

    // MARK: Persistence

    private func persist<T: Encodable>(_ key: String, _ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        local.set(data, forKey: key)
        kvs.set(data, forKey: key)
        kvs.set(Date().timeIntervalSince1970, forKey: key + ".at")
        local.set(Date().timeIntervalSince1970, forKey: key + ".at")
    }

    private func read<T: Decodable>(_ key: String, as type: T.Type, preferCloud: Bool) -> T? {
        let cloudData = kvs.data(forKey: key)
        let localData = local.data(forKey: key)
        let cloudAt = kvs.double(forKey: key + ".at")
        let localAt = local.double(forKey: key + ".at")
        var data: Data?
        if preferCloud, let c = cloudData, cloudAt >= localAt || localData == nil {
            data = c
            local.set(c, forKey: key)
            local.set(cloudAt, forKey: key + ".at")
        } else {
            data = localData ?? cloudData
        }
        guard let d = data else { return nil }
        return try? JSONDecoder().decode(T.self, from: d)
    }

    private func loadAll(preferCloud: Bool) {
        loading = true
        defer { loading = false }
        if let v = read(Key.settings, as: AppSettings.self, preferCloud: preferCloud), v != settings { settings = v }
        if let v = read(Key.templates, as: [EventTemplate].self, preferCloud: preferCloud), v != templates { templates = v }
        if let v = read(Key.sets, as: [CalendarSet].self, preferCloud: preferCloud), v != sets { sets = v }
        if let v = read(Key.rules, as: [StyleRule].self, preferCloud: preferCloud), v != rules { rules = v }
        if let v = read(Key.styles, as: [String: EventStyle].self, preferCloud: preferCloud), v != styles { styles = v }
        if let v = read(Key.memory, as: [String: TitleMemory].self, preferCloud: preferCloud), v != titleMemory { titleMemory = v }
        if let v = read(Key.calColors, as: [String: String].self, preferCloud: preferCloud), v != calendarColors { calendarColors = v }
        if let v = read(Key.hidden, as: [String: HiddenEvent].self, preferCloud: preferCloud), v != hiddenEvents { hiddenEvents = v }
    }

    private func seedDefaults() {
        local.set(true, forKey: "weekdot.seeded")
        rules = [
            StyleRule(keyword: String(localized: "Birthday"), emoji: "🎂", colorHex: "#FF2D55"),
            StyleRule(keyword: String(localized: "Dentist"), emoji: "🦷", colorHex: nil),
            StyleRule(keyword: String(localized: "Doctor"), emoji: "🩺", colorHex: nil),
            StyleRule(keyword: String(localized: "Gym"), emoji: "🏋️", colorHex: "#34C759"),
            StyleRule(keyword: String(localized: "Flight"), emoji: "✈️", colorHex: "#32ADE6"),
            StyleRule(keyword: String(localized: "Meeting"), emoji: "👥", colorHex: nil),
            StyleRule(keyword: String(localized: "Holiday"), emoji: "🏖️", colorHex: "#FF9500"),
        ]
        // Do not ship example templates. Users can still save and manage their own.
        // Mark the examples as old, so rules that arrive later from the user's other devices always win.
        for key in [Key.rules] {
            kvs.set(1, forKey: key + ".at")
            local.set(1, forKey: key + ".at")
        }
    }
}
