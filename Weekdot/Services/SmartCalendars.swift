import Foundation

/// Public holiday calendars (ICS feeds) the user can subscribe to with one tap.
enum SmartCalendars {
    struct Holiday {
        let id: String
        let region: String
        var customURL: String? = nil
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
            if let customURL { return URL(string: customURL) }
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
        // Additional published country feeds from Office Holidays. These are
        // validated on download before Weekdot creates a subscription.
        let more: [(String, String)] = [
            ("belgium", "BE"), ("switzerland", "CH"), ("new-zealand", "NZ"), ("south-africa", "ZA"),
            ("argentina", "AR"), ("chile", "CL"), ("colombia", "CO"), ("peru", "PE"),
            ("singapore", "SG"), ("malaysia", "MY"), ("thailand", "TH"), ("philippines", "PH"),
            ("vietnam", "VN"), ("czech-republic", "CZ"), ("slovakia", "SK"), ("hungary", "HU"),
            ("croatia", "HR"), ("romania", "RO"), ("bulgaria", "BG"), ("serbia", "RS"),
            ("ukraine", "UA"), ("israel", "IL"), ("united-arab-emirates", "AE"),
            ("saudi-arabia", "SA"), ("qatar", "QA"), ("egypt", "EG"), ("kenya", "KE"),
            ("nigeria", "NG"), ("iceland", "IS"), ("luxembourg", "LU"), ("estonia", "EE"),
            ("latvia", "LV"), ("lithuania", "LT"), ("slovenia", "SI"), ("indonesia", "ID"),
            ("pakistan", "PK"), ("bangladesh", "BD"), ("morocco", "MA"), ("tunisia", "TN"),
            ("algeria", "DZ"), ("ethiopia", "ET"), ("ghana", "GH"), ("costa-rica", "CR"),
            ("cuba", "CU"), ("panama", "PA"), ("jamaica", "JM"),
        ]
        let items = list.map { Holiday(id: $0.0, region: $0.1) } + more.map {
            Holiday(id: $0.0, region: $0.1, customURL: "https://www.officeholidays.com/ics/\($0.0)")
        }
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
