import Foundation

/// Public holiday calendars (ICS feeds) the user can subscribe to with one tap.
enum SmartCalendars {
    struct Holiday {
        let id: String
        let region: String
        var flag: String {
            guard region.count == 2 else { return "✝️" }
            return region.uppercased().unicodeScalars
                .compactMap { UnicodeScalar(127_397 + $0.value) }
                .map { String($0) }.joined()
        }
        var localizedName: String {
            if region.count == 2 { return Locale.current.localizedString(forRegionCode: region) ?? region }
            return String(localized: "Christian Holidays")
        }
        var url: URL? {
            let lang = Locale.current.language.languageCode?.identifier ?? "en"
            let calID = "\(lang).\(id)#holiday@group.v.calendar.google.com"
            let encoded = calID.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: ".-_"))) ?? calID
            return URL(string: "webcal://calendar.google.com/calendar/ical/\(encoded)/public/basic.ics")
        }
    }

    static let holidays: [Holiday] = {
        let list: [(String, String)] = [
            ("dutch", "NL"), ("german", "DE"), ("french", "FR"), ("uk", "GB"), ("usa", "US"),
            ("spain", "ES"), ("italian", "IT"), ("portuguese", "PT"), ("austrian", "AT"), ("irish", "IE"),
            ("danish", "DK"), ("swedish", "SE"), ("norwegian", "NO"), ("finnish", "FI"), ("polish", "PL"),
            ("greek", "GR"), ("turkish", "TR"), ("russian", "RU"), ("australian", "AU"), ("canadian", "CA"),
            ("brazilian", "BR"), ("mexican", "MX"), ("japanese", "JP"), ("south_korea", "KR"), ("china", "CN"),
            ("indian", "IN"), ("christian", "christian"),
        ]
        let items = list.map { Holiday(id: $0.0, region: $0.1) }
        let mine = Locale.current.region?.identifier
        return items.sorted { a, b in
            if a.region == mine { return true }
            if b.region == mine { return false }
            return a.localizedName.localizedCompare(b.localizedName) == .orderedAscending
        }
    }()

    /// Turns a pasted link into a webcal:// link the system can subscribe to.
    static func webcalURL(from text: String) -> URL? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("https://") { s = "webcal://" + s.dropFirst("https://".count) }
        else if s.hasPrefix("http://") { s = "webcal://" + s.dropFirst("http://".count) }
        else if !s.hasPrefix("webcal://") { s = "webcal://" + s }
        guard let url = URL(string: s), url.host != nil else { return nil }
        return url
    }
}
