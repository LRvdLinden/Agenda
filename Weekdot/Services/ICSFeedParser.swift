import Foundation

/// Reads common RFC 5545 VEVENT fields. Unknown fields are ignored; no executable
/// content is used. This parser is intentionally limited to events, not VTODOs.
enum ICSFeedParser {
    struct Entry {
        let uid: String
        let title: String
        let start: Date
        let end: Date
        let isAllDay: Bool
        let location: String
        let details: String
        let recurrence: String?
    }

    static func parse(_ data: Data) -> [Entry] {
        guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1),
              text.uppercased().contains("BEGIN:VCALENDAR") else { return [] }

        // Folded lines begin with a space or tab and continue the previous line.
        var lines: [String] = []
        for raw in text.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .components(separatedBy: "\n") {
            if raw.hasPrefix(" ") || raw.hasPrefix("\t") {
                if !lines.isEmpty { lines[lines.count - 1] += String(raw.dropFirst()) }
            } else {
                lines.append(raw)
            }
        }

        var result: [Entry] = []
        var fields: [(String, String)] = []
        var inside = false
        var seen = Set<String>()

        for line in lines {
            let upper = line.uppercased()
            if upper == "BEGIN:VEVENT" {
                inside = true
                fields = []
            } else if upper == "END:VEVENT" {
                if let entry = entry(from: fields), seen.insert(entry.uid).inserted {
                    result.append(entry)
                }
                inside = false
                if result.count >= 1_000 { break }
            } else if inside, let colon = line.firstIndex(of: ":") {
                fields.append((String(line[..<colon]), String(line[line.index(after: colon)...])))
            }
        }
        return result
    }

    private static func entry(from fields: [(String, String)]) -> Entry? {
        func field(_ name: String) -> (String, String)? {
            fields.first { $0.0.split(separator: ";", maxSplits: 1).first?.uppercased() == name }
        }
        guard field("STATUS")?.1.uppercased() != "CANCELLED",
              let startField = field("DTSTART"),
              let start = date(startField) else { return nil }
        let isAllDay = startField.1.count == 8 || startField.0.uppercased().contains("VALUE=DATE")
        let calendar = Calendar(identifier: .gregorian)
        let fallbackEnd = isAllDay
            ? (calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400))
            : start.addingTimeInterval(3_600)
        let end = field("DTEND").flatMap(date) ?? fallbackEnd
        guard end > start else { return nil }
        let title = unescape(field("SUMMARY")?.1 ?? "Untitled Event")
        let uid = field("UID")?.1.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "\(title)-\(start.timeIntervalSince1970)"
        let occurrence = field("RECURRENCE-ID")?.1 ?? ""
        return Entry(
            uid: String((uid + "|" + occurrence).prefix(300)),
            title: String(title.prefix(300)), start: start, end: end, isAllDay: isAllDay,
            location: String(unescape(field("LOCATION")?.1 ?? "").prefix(500)),
            details: String(unescape(field("DESCRIPTION")?.1 ?? "").prefix(3_000)),
            recurrence: field("EXDATE") == nil ? field("RRULE")?.1 : nil
        )
    }

    private static func date(_ field: (String, String)) -> Date? {
        let (key, value) = field
        if value.count == 8, let year = Int(value.prefix(4)),
           let month = Int(value.dropFirst(4).prefix(2)), let day = Int(value.suffix(2)) {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = .current
            return cal.date(from: DateComponents(year: year, month: month, day: day))
        }
        let utc = value.hasSuffix("Z")
        let zone = key.split(separator: ";").first(where: { $0.uppercased().hasPrefix("TZID=") })
            .map { String($0.dropFirst(5)) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = utc ? TimeZone(secondsFromGMT: 0) : (zone.flatMap(TimeZone.init(identifier:)) ?? .current)
        if value.count == (utc ? 16 : 15) {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss" + (utc ? "'Z'" : "")
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmm" + (utc ? "'Z'" : "")
        }
        return formatter.date(from: value)
    }

    private static func unescape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
