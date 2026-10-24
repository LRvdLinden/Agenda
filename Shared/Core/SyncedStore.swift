import Foundation
import Combine

/// Keeps Sevn's own data (settings, templates, calendar sets, colour/emoji rules, event styles and
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
    @Published private(set) var lastSync: Date?

    private enum Key {
        static let settings = "sevn.settings.v1"
        static let templates = "sevn.templates.v1"
        static let sets = "sevn.sets.v1"
        static let rules = "sevn.rules.v1"
        static let styles = "sevn.styles.v1"
        static let memory = "sevn.memory.v1"
        static let all = [settings, templates, sets, rules, styles, memory]
    }

    private let kvs = NSUbiquitousKeyValueStore.default
    private let local = Sevn.groupDefaults
    private var loading = false
    private var observer: NSObjectProtocol?

    var iCloudAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    private init() {
        loadAll(preferCloud: false)
        kvs.synchronize()
        loadAll(preferCloud: true)
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.loadAll(preferCloud: true)
                    self?.lastSync = Date()
                }
            }
        if rules.isEmpty && local.object(forKey: "sevn.seeded") == nil {
            seedDefaults()
        }
    }

    /// Ask iCloud to sync right away (pull to refresh / app becomes active).
    func syncNow() {
        kvs.synchronize()
        loadAll(preferCloud: true)
        lastSync = Date()
    }

    // MARK: Style resolution

    func style(forKey key: String, title: String) -> EventStyle {
        if let s = styles[key], !s.isEmpty { return s }
        if let rule = rules.first(where: { $0.matches(title) }) {
            return EventStyle(emoji: rule.emoji, colorHex: rule.colorHex)
        }
        return EventStyle()
    }

    func setStyle(_ style: EventStyle, forKey key: String) {
        if style.isEmpty { styles.removeValue(forKey: key) } else { styles[key] = style }
        if styles.count > 4000 {
            // keep the store small: drop arbitrary oldest entries
            for k in styles.keys.prefix(styles.count - 4000) { styles.removeValue(forKey: k) }
        }
    }

    // MARK: Auto-fill memory

    func remember(title: String, durationMinutes: Int, location: String, alarmMinutes: [Int],
                  calendarID: String?, isAllDay: Bool) {
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return }
        titleMemory[key] = TitleMemory(title: title, durationMinutes: durationMinutes, location: location,
                                       alarmMinutes: alarmMinutes, calendarID: calendarID, isAllDay: isAllDay,
                                       lastUsed: Date())
        if titleMemory.count > 400 {
            let old = titleMemory.sorted { $0.value.lastUsed < $1.value.lastUsed }.prefix(titleMemory.count - 400)
            for (k, _) in old { titleMemory.removeValue(forKey: k) }
        }
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
    }

    private func seedDefaults() {
        local.set(true, forKey: "sevn.seeded")
        rules = [
            StyleRule(keyword: String(localized: "Birthday"), emoji: "🎂", colorHex: "#FF2D55"),
            StyleRule(keyword: String(localized: "Dentist"), emoji: "🦷", colorHex: nil),
            StyleRule(keyword: String(localized: "Doctor"), emoji: "🩺", colorHex: nil),
            StyleRule(keyword: String(localized: "Gym"), emoji: "🏋️", colorHex: "#34C759"),
            StyleRule(keyword: String(localized: "Flight"), emoji: "✈️", colorHex: "#32ADE6"),
            StyleRule(keyword: String(localized: "Meeting"), emoji: "👥", colorHex: nil),
            StyleRule(keyword: String(localized: "Holiday"), emoji: "🏖️", colorHex: "#FF9500"),
        ]
        templates = [
            EventTemplate(name: String(localized: "Meeting"), title: String(localized: "Meeting"), durationMinutes: 60,
                          alarmMinutes: [15], emoji: "👥"),
            EventTemplate(name: String(localized: "Lunch"), title: String(localized: "Lunch"), durationMinutes: 60,
                          emoji: "🥪", startMinutes: 12 * 60),
            EventTemplate(name: String(localized: "Gym"), title: String(localized: "Gym"), durationMinutes: 90,
                          alarmMinutes: [30], emoji: "🏋️"),
        ]
    }
}
