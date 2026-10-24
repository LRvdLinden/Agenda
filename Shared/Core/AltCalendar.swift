import Foundation

/// Alternate calendars shown next to the normal date (like Apple Calendar's "Alternate Calendars").
enum AltCalendar {
    static let all = ["chinese", "hebrew", "islamic", "persian", "indian", "japanese", "buddhist"]

    static func identifier(_ id: String) -> Calendar.Identifier? {
        switch id {
        case "chinese": return .chinese
        case "hebrew": return .hebrew
        case "islamic": return .islamicUmmAlQura
        case "persian": return .persian
        case "indian": return .indian
        case "japanese": return .japanese
        case "buddhist": return .buddhist
        default: return nil
        }
    }

    static func name(_ id: String) -> String {
        guard let ident = identifier(id) else { return id }
        return Locale.current.localizedString(for: ident) ?? id
    }

    private static var formatters: [String: DateFormatter] = [:]

    /// Short date in the alternate calendar, e.g. "10 Tishri".
    static func label(for date: Date, id: String) -> String? {
        guard let ident = identifier(id) else { return nil }
        let f: DateFormatter
        if let cached = formatters[id] {
            f = cached
        } else {
            f = DateFormatter()
            f.calendar = Calendar(identifier: ident)
            f.locale = Locale.current
            f.setLocalizedDateFormatFromTemplate("MMMd")
            formatters[id] = f
        }
        return f.string(from: date)
    }
}
