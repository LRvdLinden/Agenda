import Foundation

// MARK: - View modes and settings

enum CalendarViewMode: String, Codable, CaseIterable, Identifiable {
    case day, week, month, year, list
    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .list: return "List"
        }
    }

    var symbol: String {
        switch self {
        case .day: return "calendar.day.timeline.left"
        case .week: return "calendar"
        case .month: return "square.grid.3x3"
        case .year: return "square.grid.4x3.fill"
        case .list: return "list.bullet"
        }
    }
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .system: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum EventStyleMode: String, Codable, CaseIterable, Identifiable {
    case tinted, filled, outlined
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .tinted: return "Tinted"
        case .filled: return "Filled"
        case .outlined: return "Outlined"
        }
    }
}

enum WeekLayout: String, Codable, CaseIterable, Identifiable {
    case grid, timeline
    var id: String { rawValue }
    var titleKey: String { self == .grid ? "Grid" : "Timeline" }
}

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case system, celsius, fahrenheit
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .system: return "Automatic"
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
}

struct AppSettings: Codable, Equatable {
    /// 0 = follow the system, 1 = Sunday … 7 = Saturday.
    var firstWeekday: Int = 0
    /// Number of days shown in the week view (1…7). Default: a full week.
    var weekDayCount: Int = 7
    var defaultView: CalendarViewMode = .week
    /// Week view as day boxes (grid, default) or as a time line.
    var weekLayout: WeekLayout = .grid
    var hourHeight: Double = 52
    var dayStartHour: Int = 7
    var showWeekNumbers: Bool = true
    var shadeWeekends: Bool = true
    var defaultDurationMinutes: Int = 60
    /// Minutes before the start; -1 = no alert.
    var defaultAlarmMinutes: Int = 15
    var defaultCalendarID: String? = nil
    var hiddenCalendarIDs: [String] = []
    var appearance: AppearanceMode = .system
    var eventStyle: EventStyleMode = .tinted
    var textScale: Double = 1.0
    var showWeather: Bool = false
    var temperatureUnit: TemperatureUnit = .system
    var snapMinutes: Int = 15
    var showDeclined: Bool = true
    var showYearHeatmap: Bool = true
    var autofillFromHistory: Bool = true
    var accentHex: String? = nil
    var activeSetID: UUID? = nil

    init() {}

    enum CodingKeys: String, CodingKey {
        case firstWeekday, weekDayCount, defaultView, weekLayout, hourHeight, dayStartHour, showWeekNumbers, shadeWeekends,
             defaultDurationMinutes, defaultAlarmMinutes, defaultCalendarID, hiddenCalendarIDs, appearance,
             eventStyle, textScale, showWeather, temperatureUnit, snapMinutes, showDeclined, showYearHeatmap,
             autofillFromHistory, accentHex, activeSetID
    }

    // Tolerant decoding: new settings get their default instead of wiping everything.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        firstWeekday = (try? c.decode(Int.self, forKey: .firstWeekday)) ?? d.firstWeekday
        weekDayCount = (try? c.decode(Int.self, forKey: .weekDayCount)) ?? d.weekDayCount
        defaultView = (try? c.decode(CalendarViewMode.self, forKey: .defaultView)) ?? d.defaultView
        weekLayout = (try? c.decode(WeekLayout.self, forKey: .weekLayout)) ?? d.weekLayout
        hourHeight = (try? c.decode(Double.self, forKey: .hourHeight)) ?? d.hourHeight
        dayStartHour = (try? c.decode(Int.self, forKey: .dayStartHour)) ?? d.dayStartHour
        showWeekNumbers = (try? c.decode(Bool.self, forKey: .showWeekNumbers)) ?? d.showWeekNumbers
        shadeWeekends = (try? c.decode(Bool.self, forKey: .shadeWeekends)) ?? d.shadeWeekends
        defaultDurationMinutes = (try? c.decode(Int.self, forKey: .defaultDurationMinutes)) ?? d.defaultDurationMinutes
        defaultAlarmMinutes = (try? c.decode(Int.self, forKey: .defaultAlarmMinutes)) ?? d.defaultAlarmMinutes
        defaultCalendarID = try? c.decode(String.self, forKey: .defaultCalendarID)
        hiddenCalendarIDs = (try? c.decode([String].self, forKey: .hiddenCalendarIDs)) ?? d.hiddenCalendarIDs
        appearance = (try? c.decode(AppearanceMode.self, forKey: .appearance)) ?? d.appearance
        eventStyle = (try? c.decode(EventStyleMode.self, forKey: .eventStyle)) ?? d.eventStyle
        textScale = (try? c.decode(Double.self, forKey: .textScale)) ?? d.textScale
        showWeather = (try? c.decode(Bool.self, forKey: .showWeather)) ?? d.showWeather
        temperatureUnit = (try? c.decode(TemperatureUnit.self, forKey: .temperatureUnit)) ?? d.temperatureUnit
        snapMinutes = (try? c.decode(Int.self, forKey: .snapMinutes)) ?? d.snapMinutes
        showDeclined = (try? c.decode(Bool.self, forKey: .showDeclined)) ?? d.showDeclined
        showYearHeatmap = (try? c.decode(Bool.self, forKey: .showYearHeatmap)) ?? d.showYearHeatmap
        autofillFromHistory = (try? c.decode(Bool.self, forKey: .autofillFromHistory)) ?? d.autofillFromHistory
        accentHex = try? c.decode(String.self, forKey: .accentHex)
        activeSetID = try? c.decode(UUID.self, forKey: .activeSetID)
    }

    /// The calendar used for all date math (respects the chosen first weekday).
    var calendar: Calendar {
        var c = Calendar.autoupdatingCurrent
        if (1...7).contains(firstWeekday) { c.firstWeekday = firstWeekday }
        c.minimumDaysInFirstWeek = Calendar.autoupdatingCurrent.minimumDaysInFirstWeek
        return c
    }

    var clampedDayCount: Int { max(1, min(7, weekDayCount)) }
}

// MARK: - Synced user content

/// Per-event look (emoji + colour) that Weekdot keeps on top of the calendar data.
struct EventStyle: Codable, Hashable {
    var emoji: String?
    var colorHex: String?

    var isEmpty: Bool { (emoji ?? "").isEmpty && (colorHex ?? "").isEmpty }
}

/// Automatically gives events an emoji and/or colour when the title contains a keyword.
struct StyleRule: Codable, Identifiable, Hashable {
    var id = UUID()
    var keyword: String
    var emoji: String?
    var colorHex: String?
    var enabled: Bool = true

    func matches(_ title: String) -> Bool {
        let k = keyword.trimmingCharacters(in: .whitespaces)
        guard enabled, !k.isEmpty else { return false }
        return title.range(of: k, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

/// A saved event that can be added with one tap.
struct EventTemplate: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var title: String
    var location: String = ""
    var notes: String = ""
    var urlString: String = ""
    var durationMinutes: Int = 60
    var isAllDay: Bool = false
    var alarmMinutes: [Int] = []
    var calendarID: String? = nil
    var emoji: String? = nil
    var colorHex: String? = nil
    /// Optional fixed start time (minutes after midnight).
    var startMinutes: Int? = nil
}

/// A named selection of visible calendars ("Work", "Family", …).
struct CalendarSet: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var calendarIDs: [String]
}

/// What Weekdot remembers about earlier events with the same title (for auto-fill).
struct TitleMemory: Codable, Hashable {
    var title: String
    var durationMinutes: Int
    var location: String
    var alarmMinutes: [Int]
    var calendarID: String?
    var isAllDay: Bool
    var lastUsed: Date
}

// MARK: - Render model

/// A lightweight, platform-neutral copy of an event occurrence.
struct EventItem: Identifiable, Hashable, Codable {
    var id: String
    var eventIdentifier: String
    var styleKey: String
    var title: String
    var location: String?
    var start: Date
    var end: Date
    var isAllDay: Bool
    var calendarID: String
    var calendarTitle: String
    var colorHex: String
    var emoji: String?
    var isRecurring: Bool
    var canEdit: Bool
    var isDeclined: Bool = false
    var hasAlarms: Bool = false

    var displayTitle: String {
        let t = title.isEmpty ? String(localized: "New Event") : title
        if let e = emoji, !e.isEmpty { return e + " " + t }
        return t
    }

    var durationMinutes: Int { max(0, Int(end.timeIntervalSince(start) / 60)) }

    /// Does this event cover any part of `day` (start of day)?
    func overlaps(dayStart: Date, dayEnd: Date) -> Bool {
        if isAllDay { return start < dayEnd && end > dayStart }
        return start < dayEnd && (end > dayStart || (end == start && start >= dayStart))
    }
}

/// Events written by the app for the widgets (works even when the widget may not read the calendar itself).
struct WidgetSnapshot: Codable {
    var generated: Date
    var firstWeekday: Int
    var items: [EventItem]

    static var fileURL: URL? { Weekdot.groupContainer?.appendingPathComponent("widget-snapshot.json") }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .secondsSince1970
        return try? dec.decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let url = WidgetSnapshot.fileURL else { return }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .secondsSince1970
        if let data = try? enc.encode(self) { try? data.write(to: url, options: .atomic) }
    }
}
