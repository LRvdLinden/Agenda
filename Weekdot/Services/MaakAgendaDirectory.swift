import Foundation

// MARK: - Maak-Agenda.nl directory
// Competition pages, team pages, logos and ICS feeds published by maak-agenda.nl.
// Competition feeds follow the verified v2 pattern; team feeds are resolved
// from the team page first and only fall back to the v2 team pattern.

struct MaakAgendaEntry: Identifiable, Hashable, Codable, Sendable {
    let title: String
    let url: URL
    var id: String { url.absoluteString }

    /// Path without leading/trailing slashes, e.g. "eredivisie" or "team/Ajax".
    var path: String { url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
    var isTeam: Bool { url.path.hasPrefix("/team/") }
    /// Competition slug for single-component competition pages.
    var leagueSlug: String? {
        guard !isTeam, !path.isEmpty, !path.contains("/") else { return nil }
        return path.lowercased()
    }
}

enum MaakAgendaIndex {
    static let host = "maak-agenda.nl"

    static func page(_ path: String) -> URL? { URL(string: "https://maak-agenda.nl/" + path) }

    static func competition(_ slug: String) -> MaakAgendaEntry {
        MaakAgendaEntry(title: MaakAgendaRegions.title(for: slug),
                        url: page(slug) ?? URL(string: "https://maak-agenda.nl/")!)
    }

    static func team(_ title: String, _ pageName: String) -> MaakAgendaEntry {
        let encoded = pageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pageName
        return MaakAgendaEntry(title: title, url: page("team/" + encoded) ?? URL(string: "https://maak-agenda.nl/")!)
    }

    static func leagueFeed(_ slug: String) -> URL? {
        URL(string: "webcal://ics.maak-agenda.nl/v2/league/\(slug).ics")
    }

    static func teamFeedFallback(_ entry: MaakAgendaEntry) -> URL? {
        let name = entry.url.lastPathComponent
        guard entry.isTeam, !name.isEmpty,
              let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "webcal://ics.maak-agenda.nl/v2/team/\(encoded).ics")
    }

    /// The calendar link for an entry: page resolution first for teams and
    /// non-football pages, the published v2 patterns as fallback.
    static func feedLink(for entry: MaakAgendaEntry) async -> URL? {
        if let slug = entry.leagueSlug, MaakAgendaRegions.allFootballSlugs.contains(slug) {
            return leagueFeed(slug)
        }
        if let html = try? await html(at: entry.url), let link = calendarLink(from: html, baseURL: entry.url) {
            return link
        }
        if entry.isTeam { return teamFeedFallback(entry) }
        if let slug = entry.leagueSlug { return leagueFeed(slug) }
        return nil
    }

    // MARK: HTML (memory cache, 30 minutes)

    private actor PageCache {
        var pages: [URL: (Date, String)] = [:]
        func get(_ url: URL) -> String? {
            guard let hit = pages[url], Date().timeIntervalSince(hit.0) < 1800 else { return nil }
            return hit.1
        }
        func set(_ url: URL, _ html: String) { pages[url] = (Date(), html) }
    }
    private static let cache = PageCache()

    static func html(at url: URL) async throws -> String {
        if let cached = await cache.get(url) { return cached }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let html = String(decoding: data, as: UTF8.self)
        await cache.set(url, html)
        return html
    }

    static func links(from html: String, baseURL: URL) -> [MaakAgendaEntry] {
        // Extract publisher links rather than guessing calendar identifiers.
        let pattern = #"<a\b[^>]*\bhref\s*=\s*[\"']([^\"']+)[\"'][^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        let strip = try? NSRegularExpression(pattern: "<[^>]+>")
        var seen = Set<String>()
        return regex.matches(in: html, range: range).compactMap { match in
            guard let hrefRange = Range(match.range(at: 1), in: html),
                  let textRange = Range(match.range(at: 2), in: html) else { return nil }
            let path = String(html[hrefRange]).replacingOccurrences(of: "&amp;", with: "&")
            guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL,
                  url.host?.lowercased() == host,
                  url.path != "/", url.path != baseURL.path,
                  !url.path.contains("/up-to-date"),
                  !url.path.contains("/help"),
                  !url.path.hasPrefix("/images/"),
                  seen.insert(url.absoluteString).inserted else { return nil }
            let raw = String(html[textRange])
            let clean = (strip?.stringByReplacingMatches(in: raw, range: NSRange(raw.startIndex..., in: raw), withTemplate: "") ?? raw)
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, clean.count < 110 else { return nil }
            return MaakAgendaEntry(title: clean, url: url)
        }
    }

    static func calendarLink(from html: String, baseURL: URL) -> URL? {
        // The website's iCal button may be generated by JavaScript. Do not
        // present its webpage URL as an ICS feed when an actual feed is absent.
        let pattern = #"(?:webcal|https?):(?:\\/\\/|//)[^\"'\s<>]+(?:\.ics(?:\?[^\"'\s<>]*)?|/ical[^\"'\s<>]*|/calendar\.ics[^\"'\s<>]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        for match in regex.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range, in: html) else { continue }
            let raw = String(html[range]).replacingOccurrences(of: "\\/", with: "/")
                .replacingOccurrences(of: "&amp;", with: "&")
            if let url = URL(string: raw, relativeTo: baseURL)?.absoluteURL,
               ["http", "https", "webcal"].contains(url.scheme?.lowercased() ?? "") { return url }
        }
        return nil
    }

    /// Team links listed on a competition page (cached on disk for a day).
    static func teams(onPage entry: MaakAgendaEntry) async -> [MaakAgendaEntry] {
        let file = "teams-" + SportsDiskCache.hashed(entry.id) + ".json"
        if let cached = SportsDiskCache.readJSON([MaakAgendaEntry].self, file, maxAge: 24 * 3600), !cached.isEmpty {
            return cached
        }
        guard let html = try? await html(at: entry.url) else {
            // Stale data is better than nothing when offline.
            return SportsDiskCache.readJSON([MaakAgendaEntry].self, file, maxAge: .infinity) ?? []
        }
        var seen = Set<String>()
        let teams = links(from: html, baseURL: entry.url)
            .filter { $0.isTeam && seen.insert($0.title.lowercased()).inserted }
        if !teams.isEmpty { SportsDiskCache.writeJSON(teams, to: file) }
        return teams
    }
}

// MARK: - Sports

enum SportKind: Int, CaseIterable, Identifiable, Hashable {
    case football, formula1, motoGP, tennis, cycling, basketball, hockey, cricket, nfl

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .football: return "Football"
        case .formula1: return "Formula 1"
        case .motoGP: return "MotoGP"
        case .tennis: return "Tennis"
        case .cycling: return "Cycling"
        case .basketball: return "Basketball"
        case .hockey: return "Hockey"
        case .cricket: return "Cricket"
        case .nfl: return "NFL"
        }
    }

    var photo: String {
        switch self {
        case .football: return "SportFootball"
        case .formula1: return "SportFormula1"
        case .motoGP: return "SportMotoGP"
        case .tennis: return "SportTennis"
        case .cycling: return "SportCycling"
        case .basketball: return "SportBasketball"
        case .hockey: return "SportHockey"
        case .cricket: return "SportCricket"
        case .nfl: return "SportNFL"
        }
    }

    var symbol: String {
        switch self {
        case .football: return "soccerball"
        case .formula1: return "flag.checkered"
        case .motoGP: return "motorcycle"
        case .tennis: return "tennis.racket"
        case .cycling: return "bicycle"
        case .basketball: return "basketball.fill"
        case .hockey: return "figure.hockey"
        case .cricket: return "figure.cricket"
        case .nfl: return "football.fill"
        }
    }

    /// maak-agenda.nl overview page for the sport.
    var pagePath: String {
        switch self {
        case .football: return "eredivisie"
        case .formula1: return "formula-1"
        case .motoGP: return "motogp"
        case .tennis: return "tennis"
        case .cycling: return "cycling"
        case .basketball: return "nba"
        case .hockey: return "hoofdklasse-heren"
        case .cricket: return "indian-premier-league"
        case .nfl: return "nfl"
        }
    }

    /// Featured publisher pages (source pages, resolved before subscribing).
    var featured: [MaakAgendaEntry] {
        let items: [(String, String)]
        switch self {
        case .football: items = []
        case .formula1: items = [("Formula 1", "formula-1")]
        case .motoGP: items = [("MotoGP", "motogp")]
        case .tennis: items = [("ATP Masters 1000", "tennis/atp-1000"), ("Tennis", "tennis")]
        case .cycling: items = [("UCI Men's WorldTour", "cycling/men-worldtour"), ("Cycling", "cycling")]
        case .basketball: items = [("NBA", "nba")]
        case .hockey: items = [("Hoofdklasse Heren", "hoofdklasse-heren")]
        case .cricket: items = [("Indian Premier League", "indian-premier-league")]
        case .nfl: items = [("NFL", "nfl")]
        }
        return items.compactMap { title, path in
            MaakAgendaIndex.page(path).map { MaakAgendaEntry(title: title, url: $0) }
        }
    }

    /// TheSportsDB leagues used for team crests in this sport.
    var crestLeagues: [String] {
        switch self {
        case .basketball: return ["NBA"]
        case .nfl: return ["NFL"]
        default: return []
        }
    }
}

// MARK: - National teams

struct NationalTeam: Identifiable, Hashable, Sendable {
    let title: String
    let flag: String
    /// Competition pages that list this team.
    let leagues: [String]
    /// Publisher names to look for (maak-agenda uses Dutch names).
    let names: [String]
    let exact: Bool
    var id: String { title + flag + leagues.joined() }

    static let menLeagues = ["nations-league", "world-cup-qualifiers", "oefen-interlands", "fifa-world-cup-2026"]
    static let womenLeagues = ["womens-nations-league", "oefen-interlands-vrouwen", "womens-world-cup-qualification-europe"]

    static func country(_ code: String) -> NationalTeam {
        let isEngland = code == "GB-EN" || code == "GB"
        let title = isEngland ? String(localized: "England")
            : (Locale.current.localizedString(forRegionCode: code) ?? code)
        let dutch = isEngland ? "Engeland" : (Locale(identifier: "nl_NL").localizedString(forRegionCode: code) ?? code)
        let english = isEngland ? "England" : (Locale(identifier: "en_US").localizedString(forRegionCode: code) ?? code)
        return NationalTeam(title: title, flag: isEngland ? "GB" : code, leagues: menLeagues,
                            names: [dutch, english], exact: true)
    }

    static func teams(for countryCode: String) -> [NationalTeam] {
        var result: [NationalTeam] = []
        if countryCode == "NL" {
            result = [
                NationalTeam(title: "Nederlands Elftal", flag: "NL", leagues: menLeagues,
                             names: ["Nederland", "Netherlands"], exact: true),
                NationalTeam(title: "Oranje Leeuwinnen", flag: "NL", leagues: womenLeagues,
                             names: ["Nederland", "Nederland Vrouwen", "Netherlands"], exact: false),
                NationalTeam(title: "Jong Oranje", flag: "NL", leagues: ["uefa-under-21"],
                             names: ["Jong Oranje", "Nederland O21", "Nederland", "Netherlands U21"], exact: false)
            ]
        } else if countryCode.count == 2 || countryCode == "GB-EN" {
            result = [country(countryCode)]
        }
        let others = ["NL", "DE", "FR", "GB", "ES", "IT", "BE", "PT"]
        for code in others where code != countryCode && !(code == "GB" && countryCode == "GB-EN") {
            result.append(country(code))
        }
        return result
    }

    /// Finds the team page on maak-agenda.nl from the listed competitions.
    func resolvePage() async -> MaakAgendaEntry? {
        let wanted = names.flatMap { ClubCrestDirectory.keys(for: $0) }
        for slug in leagues {
            let teams = await MaakAgendaIndex.teams(onPage: MaakAgendaIndex.competition(slug))
            let keyed = teams.map { (ClubCrestDirectory.keys(for: $0.title), $0) }
            if let hit = keyed.first(where: { keys, _ in keys.contains { wanted.contains($0) } }) { return hit.1 }
            if !exact, let hit = keyed.first(where: { keys, _ in
                keys.contains { key in wanted.contains { key.hasPrefix($0) } }
            }) { return hit.1 }
        }
        return nil
    }
}

// MARK: - Competitions per country

// Explicit competition-to-country mapping. Never treat the site's global footer
// (which links every league) as evidence that a league belongs to this country.
enum MaakAgendaRegions {
    static let leagues: [String: [String]] = [
        "NL": ["eredivisie", "eredivisie-vrouwen", "keuken-kampioen-divisie", "tweede-divisie", "johan-cruijff-schaal", "beker"],
        "BE": ["jupiler-pro-league", "beker-van-belgie", "belgian-super-cup"],
        "DE": ["bundesliga", "2-bundesliga", "bundesliga-frauen", "dfb-pokal", "dfl-supercup"],
        "GB": ["premier-league", "efl-championship", "fa-cup", "league-cup", "league-one", "league-two", "fa-womens-super-league", "fa-womens-championship", "fa-community-shield", "english-national-league", "efl-trophy"],
        "GB-EN": ["premier-league", "efl-championship", "fa-cup", "league-cup", "league-one", "league-two", "fa-womens-super-league", "fa-womens-championship", "fa-community-shield", "english-national-league", "efl-trophy"],
        "GB-SC": ["scottish-premier-league", "scottish-championship", "scottish-cup", "scottish-league-cup", "scottish-league-one", "scottish-league-two", "scottish-womens-premier-league"],
        "GB-NI": ["nifl-premiership"], "GB-WL": ["cymru-premier"],
        "ES": ["primera-division", "segunda-division-a", "copa-del-rey", "supercopa-de-espana", "primera-division-femenina"],
        "IT": ["serie-a", "serie-b", "coppa-italia", "serie-a-women"],
        "FR": ["ligue-1", "ligue-2", "division-1-feminine", "trophee-des-champions"],
        "AT": ["bundesliga-at", "ofb-cup"], "PT": ["liga-portugal-2", "liga-3-portugal", "taca-de-portugal", "super-cup-portugal"],
        "PL": ["ekstraklasa", "pierwsza-liga", "puchar-polski", "superpuchar-polski"],
        "SE": ["swedish-allsvenskan", "damallsvenskan"], "NO": ["eliteserien"],
        "DK": ["danish-superligaen", "superliga"], "FI": ["veikkausliiga"],
        "CH": ["super-league", "swiss-cup", "swiss-womens-super-league"],
        "TR": ["superlig", "turkish-cup", "turkiye-tff-1-lig", "super-kupa"],
        "GR": ["super-league-greece", "super-league-2-greece", "greek-football-cup"],
        "IE": ["irish-premier-division"], "IS": ["urvalsdeild"],
        "CZ": ["ceska-liga"], "HU": ["hungarian-nemzeti-bajnoksag-nb-1"],
        "RO": ["romania-liga-i"], "RS": ["serbia-superliga"], "SI": ["slovenia-prvaliga"],
        "SK": ["slovak-super-liga"], "HR": ["croatia-hnl"], "CY": ["cyprus-first-division"],
        "EE": ["meistriliiga"], "IL": ["israel-ligat-ha-al"], "UA": ["ukraine-premjer-liha"],
        "RU": ["premjer-liga"],
        "US": ["mls-major-league-soccer", "mls-next-pro", "us-open-cup", "usl-championship", "usl-league-one", "usl-super-league", "nwsl-national-womens-soccer-league", "nisa-national-independent-soccer-association"],
        "CA": ["canadian-premier-league", "northern-super-league"],
        "MX": ["liga-mx", "liga-mx-femenil", "liga-de-expansion-mx"],
        "AR": ["primera-division-argentina", "argentine-nacional-b", "argentine-primera-b", "argentine-primera-c", "copa-argentina"],
        "BR": ["serie-a-brazil", "serie-b-brazil", "copa-do-brasil"],
        "CL": ["primera-division-de-chile"], "CO": ["primera-a", "copa-colombia"],
        "EC": ["ecuador-primera-categoria-serie-a"], "PY": ["paraguay-primera-division"],
        "UY": ["uruguay-primera-division", "copa-uruguay"],
        "EG": ["egyptian-premier-league"], "MA": ["botola-pro"],
        "ZA": ["south-african-premier-division"],
        "JP": ["japan-j1-league"], "CN": ["chinese-super-league", "china-league-one", "china-league-two", "china-womens-super-league", "chinese-fa-cup", "chinese-fa-super-cup"],
        "IN": ["indian-super-league"], "ID": ["indonesia-liga-1"],
        "QA": ["qatar-stars-league"], "SA": ["saudi-professional-league"],
        "TH": ["thai-league-1", "thai-fa-cup"], "KR": ["south-korea-k-league-1"],
        "AU": ["australia-a-league"],
        "EU": ["champions-league", "europa-league", "uefa-conference-league", "nations-league", "uefa-super-cup", "uefa-under-21", "uefa-euro-u19-championship", "womens-champions-league", "womens-nations-league", "womens-world-cup-qualification-europe"],
        "WORLD": ["fifa-world-cup-2026", "fifa-club-world-cup", "world-cup-qualifiers", "club-friendlies", "oefen-interlands", "oefen-interlands-vrouwen", "fifa-womens-world-cup-2023"],
        "AMERICA": ["concacaf-champions-league", "leagues-cup", "copa-america", "copa-libertadores", "copa-sudamericana"],
        "AFRICA": ["africa-cup-of-nations", "caf-champions-league", "caf-confederation-cup"],
        "ASIA": ["afc-asian-cup", "afc-champions-league", "afc-cup"]
    ]

    static let allFootballSlugs: Set<String> = Set(leagues.values.flatMap { $0 })

    // Football association countries that participate in UEFA competitions.
    static let europeanFootballCountries: Set<String> = [
        "AL", "AD", "AM", "AT", "AZ", "BE", "BA", "BG", "BY", "CH", "CY",
        "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GB", "GB-EN", "GB-SC",
        "GB-NI", "GB-WL", "GE", "GR", "HR", "HU", "IE", "IL", "IS", "IT",
        "KZ", "LI", "LT", "LU", "LV", "MD", "ME", "MK", "MT", "NL",
        "NO", "PL", "PT", "RO", "RS", "RU", "SE", "SI", "SK", "SM",
        "TR", "UA", "XK"
    ]

    static let regions: [String] = ["EU", "WORLD", "AMERICA", "AFRICA", "ASIA"]

    static func regionTitleKey(_ code: String) -> String {
        switch code {
        case "EU": return "Europe"
        case "WORLD": return "International"
        case "AMERICA": return "Americas"
        case "AFRICA": return "Africa"
        case "ASIA": return "Asia"
        default: return code
        }
    }

    /// Official competition names (proper names, not translated).
    private static let titles: [String: String] = [
        "eredivisie": "Eredivisie", "eredivisie-vrouwen": "Eredivisie Vrouwen",
        "keuken-kampioen-divisie": "Keuken Kampioen Divisie", "tweede-divisie": "Tweede Divisie",
        "johan-cruijff-schaal": "Johan Cruijff Schaal", "beker": "KNVB Beker",
        "jupiler-pro-league": "Jupiler Pro League", "beker-van-belgie": "Beker van België",
        "belgian-super-cup": "Belgian Super Cup",
        "bundesliga": "Bundesliga", "2-bundesliga": "2. Bundesliga", "bundesliga-frauen": "Frauen-Bundesliga",
        "dfb-pokal": "DFB-Pokal", "dfl-supercup": "DFL-Supercup",
        "premier-league": "Premier League", "efl-championship": "EFL Championship", "fa-cup": "FA Cup",
        "league-cup": "EFL Cup", "league-one": "EFL League One", "league-two": "EFL League Two",
        "fa-womens-super-league": "Women's Super League", "fa-community-shield": "FA Community Shield",
        "scottish-premier-league": "Scottish Premiership",
        "primera-division": "LaLiga", "segunda-division-a": "LaLiga Hypermotion", "copa-del-rey": "Copa del Rey",
        "supercopa-de-espana": "Supercopa de España", "primera-division-femenina": "Liga F",
        "serie-a": "Serie A", "serie-b": "Serie B", "coppa-italia": "Coppa Italia", "serie-a-women": "Serie A Women",
        "ligue-1": "Ligue 1", "ligue-2": "Ligue 2", "division-1-feminine": "Première Ligue",
        "trophee-des-champions": "Trophée des Champions",
        "liga-portugal-2": "Liga Portugal 2", "taca-de-portugal": "Taça de Portugal",
        "superlig": "Süper Lig", "turkish-cup": "Türkiye Kupası",
        "mls-major-league-soccer": "MLS", "us-open-cup": "U.S. Open Cup",
        "nwsl-national-womens-soccer-league": "NWSL",
        "champions-league": "Champions League", "europa-league": "Europa League",
        "uefa-conference-league": "Conference League", "nations-league": "Nations League",
        "uefa-super-cup": "UEFA Super Cup", "uefa-under-21": "UEFA Under 21",
        "uefa-euro-u19-championship": "UEFA Euro U19 Championship",
        "womens-champions-league": "Women's Champions League", "womens-nations-league": "Women's Nations League",
        "womens-world-cup-qualification-europe": "Women's World Cup Qualification Europe",
        "fifa-world-cup-2026": "FIFA World Cup 2026", "fifa-club-world-cup": "FIFA Club World Cup",
        "world-cup-qualifiers": "World Cup Qualifiers", "club-friendlies": "Club Friendlies",
        "oefen-interlands": "International Friendlies", "oefen-interlands-vrouwen": "Women's International Friendlies",
        "fifa-womens-world-cup-2023": "FIFA Women's World Cup"
    ]

    static func title(for slug: String) -> String {
        if let known = titles[slug] { return known }
        return slug.replacingOccurrences(of: "-", with: " ").localizedCapitalized
    }

    static func competitions(for code: String) -> [MaakAgendaEntry] {
        (leagues[code] ?? []).map(MaakAgendaIndex.competition)
    }

    static func european(for code: String) -> [MaakAgendaEntry] {
        europeanFootballCountries.contains(code) ? competitions(for: "EU") : []
    }

    static func topLeague(for code: String) -> String? { leagues[code]?.first }

    // MARK: Club crests (TheSportsDB league names)

    static let crestLeagueNames: [String: [String]] = [
        "NL": ["Dutch Eredivisie", "Dutch Eerste Divisie"],
        "BE": ["Belgian Pro League"],
        "DE": ["German Bundesliga", "German 2. Bundesliga"],
        "GB": ["English Premier League", "English League Championship"],
        "GB-EN": ["English Premier League", "English League Championship"],
        "GB-SC": ["Scottish Premiership"],
        "ES": ["Spanish La Liga"], "IT": ["Italian Serie A"], "FR": ["French Ligue 1"],
        "PT": ["Portuguese Primeira Liga"], "TR": ["Turkish Super Lig"],
        "US": ["American Major League Soccer"],
        "AT": ["Austrian Bundesliga"], "CH": ["Swiss Super League"], "DK": ["Danish Superliga"],
        "SE": ["Swedish Allsvenskan"], "NO": ["Norwegian Eliteserien"], "GR": ["Greek Super League"]
    ]

    static let majorCrestLeagues = [
        "Dutch Eredivisie", "English Premier League", "Spanish La Liga", "German Bundesliga",
        "Italian Serie A", "French Ligue 1", "Portuguese Primeira Liga", "Belgian Pro League",
        "Turkish Super Lig", "Scottish Premiership", "UEFA Champions League", "UEFA Europa League",
        "UEFA Conference League"
    ]

    /// Leagues to search for crests of teams playing in a competition.
    static func crestLeagues(forCompetition slug: String?, country: String) -> [String] {
        let local = crestLeagueNames[country] ?? []
        if slug == "nba" { return ["NBA"] }
        if slug == "nfl" { return ["NFL"] }
        guard let slug else { return local.isEmpty ? majorCrestLeagues : local }
        if let owner = leagues.first(where: { $0.key.count <= 5 && !regions.contains($0.key) && $0.value.contains(slug) })?.key,
           let owned = crestLeagueNames[owner] {
            return owned
        }
        var result = local
        for league in majorCrestLeagues where !result.contains(league) { result.append(league) }
        return result
    }

    // MARK: Popular clubs

    /// Verified maak-agenda.nl team pages for the Netherlands.
    static let dutchClubs: [MaakAgendaEntry] = [
        ("Ajax", "Ajax"), ("PSV", "PSV"), ("Feyenoord", "Feyenoord"), ("AZ", "AZ"),
        ("FC Twente", "FC_Twente"), ("FC Utrecht", "FC_Utrecht"), ("Go Ahead Eagles", "Go_Ahead_Eagles"),
        ("N.E.C.", "N.E.C."), ("sc Heerenveen", "sc_Heerenveen"), ("Sparta Rotterdam", "Sparta_Rotterdam"),
        ("FC Groningen", "FC_Groningen"), ("PEC Zwolle", "PEC_Zwolle"), ("Fortuna Sittard", "Fortuna_Sittard"),
        ("Excelsior", "Excelsior"), ("Telstar", "Telstar"), ("ADO Den Haag", "ADO_Den_Haag"),
        ("SC Cambuur", "SC_Cambuur"), ("Willem II", "Willem_II")
    ].map { MaakAgendaIndex.team($0.0, $0.1) }

    /// Clubs shown first, matched against the team links of the top league page.
    static let popularClubNames: [String: [String]] = [
        "BE": ["Club Brugge", "Anderlecht", "Union", "Genk", "Antwerp", "Gent", "Standard"],
        "DE": ["Bayern", "Dortmund", "Leverkusen", "Leipzig", "Frankfurt", "Stuttgart", "Wolfsburg", "Gladbach"],
        "GB": ["Manchester City", "Liverpool", "Arsenal", "Manchester United", "Chelsea", "Tottenham", "Newcastle", "Aston Villa"],
        "GB-EN": ["Manchester City", "Liverpool", "Arsenal", "Manchester United", "Chelsea", "Tottenham", "Newcastle", "Aston Villa"],
        "ES": ["Real Madrid", "Barcelona", "Atletico", "Athletic", "Sevilla", "Real Sociedad", "Villarreal", "Betis"],
        "IT": ["Inter", "Milan", "Juventus", "Napoli", "Roma", "Lazio", "Atalanta", "Fiorentina"],
        "FR": ["Paris", "Marseille", "Lyon", "Monaco", "Lille", "Nice", "Lens", "Rennes"],
        "PT": ["Benfica", "Porto", "Sporting", "Braga", "Guimaraes"],
        "TR": ["Galatasaray", "Fenerbahce", "Besiktas", "Trabzonspor"],
        "US": ["Inter Miami", "LA Galaxy", "Los Angeles FC", "Seattle", "Atlanta", "New York"]
    ]

    static func rankedClubs(_ teams: [MaakAgendaEntry], country: String) -> [MaakAgendaEntry] {
        let popular = (popularClubNames[country] ?? []).map { ClubCrestDirectory.keys(for: $0).first ?? "" }
        func rank(_ entry: MaakAgendaEntry) -> Int {
            let key = ClubCrestDirectory.keys(for: entry.title).first ?? ""
            return popular.firstIndex { !$0.isEmpty && key.contains($0) } ?? Int.max
        }
        return teams.enumerated()
            .sorted { lhs, rhs in
                let (a, b) = (rank(lhs.element), rank(rhs.element))
                return a == b ? lhs.offset < rhs.offset : a < b
            }
            .map(\.element)
    }

    /// Popular clubs for a country: verified NL pages, otherwise the team
    /// links of the country's top competition page.
    static func popularClubs(for country: String) async -> [MaakAgendaEntry] {
        if country == "NL" { return dutchClubs }
        guard let top = topLeague(for: country) else { return [] }
        let teams = await MaakAgendaIndex.teams(onPage: MaakAgendaIndex.competition(top))
        return rankedClubs(teams, country: country)
    }
}

// MARK: - Upcoming fixtures from published ICS feeds

struct SportsFixture: Identifiable, Hashable, Sendable {
    let id: String
    let home: String
    let away: String
    let start: Date
    let competition: String
    let slug: String
}

enum SportsFixtures {
    private actor Store {
        var cache: [String: (Date, [SportsFixture])] = [:]
        func get(_ key: String) -> [SportsFixture]? {
            guard let hit = cache[key], Date().timeIntervalSince(hit.0) < 1800 else { return nil }
            return hit.1
        }
        func set(_ key: String, _ value: [SportsFixture]) { cache[key] = (Date(), value) }
    }
    private static let store = Store()

    /// Splits "Home - Away" (also "–", "—", "vs", "v").
    static func split(_ summary: String) -> (String, String)? {
        var text = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        text = String(text.drop { !$0.isLetter && !$0.isNumber })
        if text.hasSuffix(")"), let open = text.lastIndex(of: "("), open > text.startIndex {
            text = String(text[..<open]).trimmingCharacters(in: .whitespaces)
        }
        for separator in [" - ", " – ", " — ", " vs. ", " vs ", " v "] {
            guard let range = text.range(of: separator, options: .caseInsensitive) else { continue }
            var home = String(text[..<range.lowerBound])
            if let colon = home.range(of: ": ", options: .backwards) { home = String(home[colon.upperBound...]) }
            home = home.trimmingCharacters(in: .whitespaces)
            let away = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            guard !home.isEmpty, !away.isEmpty, home.count < 60, away.count < 60 else { return nil }
            return (home, away)
        }
        return nil
    }

    static func httpsURL(_ link: URL) -> URL? {
        let text = link.absoluteString
        if text.lowercased().hasPrefix("webcal://") { return URL(string: "https://" + String(text.dropFirst(9))) }
        return link
    }

    /// Next matches from one feed.
    static func upcoming(feed: URL, competition: String, slug: String, limit: Int) async -> [SportsFixture] {
        let key = feed.absoluteString
        if let cached = await store.get(key) { return Array(cached.prefix(limit)) }
        guard let url = httpsURL(feed) else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return [] }
        let now = Date()
        let fixtures: [SportsFixture] = ICSFeedParser.parse(data)
            .filter { $0.start > now && !$0.isAllDay }
            .sorted { $0.start < $1.start }
            .prefix(40)
            .compactMap { entry in
                guard let teams = split(entry.title) else { return nil }
                return SportsFixture(id: slug + entry.uid, home: teams.0, away: teams.1, start: entry.start,
                                     competition: competition, slug: slug)
            }
        await store.set(key, fixtures)
        return Array(fixtures.prefix(limit))
    }

    /// Next matches of several competitions, merged by date.
    static func upcoming(competitions slugs: [String], perCompetition: Int = 5, limit: Int = 10) async -> [SportsFixture] {
        let merged = await withTaskGroup(of: [SportsFixture].self) { group in
            for slug in slugs {
                guard let feed = MaakAgendaIndex.leagueFeed(slug) else { continue }
                let title = MaakAgendaRegions.title(for: slug)
                group.addTask { await SportsFixtures.upcoming(feed: feed, competition: title, slug: slug, limit: perCompetition) }
            }
            var all: [SportsFixture] = []
            for await part in group { all += part }
            return all
        }
        return Array(merged.sorted { $0.start < $1.start }.prefix(limit))
    }

    /// Competitions for the "Coming up" section of a country.
    static func featuredCompetitions(for country: String) -> [String] {
        var result: [String] = []
        if let top = MaakAgendaRegions.topLeague(for: country) { result.append(top) }
        if MaakAgendaRegions.europeanFootballCountries.contains(country) {
            result.append("champions-league")
        } else {
            result.append("fifa-world-cup-2026")
        }
        return result
    }
}
