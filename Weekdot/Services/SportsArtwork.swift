import SwiftUI
import CryptoKit
#if os(macOS)
import AppKit
typealias SportsPlatformImage = NSImage
#else
import UIKit
typealias SportsPlatformImage = UIImage
#endif

/// What a sports logo shows. Competition logos and national flags come from
/// maak-agenda.nl image URLs; club crests come from TheSportsDB (one request per
/// league, cached). Nothing is bundled in the app: crests are third-party marks
/// shown only to identify the club or competition.
enum SportsArt: Hashable, Sendable {
    /// maak-agenda.nl competition slug (images/leagues/{slug}.png).
    case league(String)
    /// ISO 3166-1 alpha-2 country code (images/national/{code}.png).
    case flag(String)
    /// Club crest looked up by name in the given TheSportsDB leagues.
    case club(name: String, leagues: [String])
    /// SF Symbol only, no remote image.
    case symbol(String)
}

/// Small JSON / file cache in the Caches directory. Every read is optional:
/// a missing or expired file simply means "fetch again".
enum SportsDiskCache {
    static var directory: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("WeekdotSports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func fileURL(_ name: String) -> URL? {
        directory?.appendingPathComponent(name)
    }

    static func hashed(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    static func read(_ name: String, maxAge: TimeInterval) -> Data? {
        guard let url = fileURL(name),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attributes[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < maxAge else { return nil }
        return try? Data(contentsOf: url)
    }

    static func write(_ data: Data, to name: String) {
        guard let url = fileURL(name) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func readJSON<T: Decodable>(_ type: T.Type, _ name: String, maxAge: TimeInterval) -> T? {
        guard let data = read(name, maxAge: maxAge) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func writeJSON<T: Encodable>(_ value: T, to name: String) {
        if let data = try? JSONEncoder().encode(value) { write(data, to: name) }
    }
}

/// Downloads logo images once and keeps them in memory and on disk (7 days).
actor SportsImageStore {
    static let shared = SportsImageStore()
    private static let maxAge: TimeInterval = 7 * 24 * 3600

    private var memory: [URL: Data] = [:]
    private var missing: Set<URL> = []
    private var inFlight: [URL: Task<Data?, Never>] = [:]

    func data(for url: URL) async -> Data? {
        if let cached = memory[url] { return cached }
        if missing.contains(url) { return nil }
        let file = "img-" + SportsDiskCache.hashed(url.absoluteString)
        if let disk = SportsDiskCache.read(file, maxAge: Self.maxAge) {
            memory[url] = disk
            return disk
        }
        if let running = inFlight[url] { return await running.value }
        let task = Task<Data?, Never> {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  !data.isEmpty,
                  (http.mimeType ?? "image").lowercased().hasPrefix("image") else { return nil }
            return data
        }
        inFlight[url] = task
        let result = await task.value
        inFlight[url] = nil
        if let result {
            memory[url] = result
            SportsDiskCache.write(result, to: file)
        } else {
            missing.insert(url)
        }
        return result
    }
}

/// Club crest lookup through TheSportsDB's free API. One request per league
/// (`search_all_teams.php?l=`) builds a name → badge index that is cached in
/// memory and on disk for 7 days. A single-team search is only used for a
/// detail page when the league lists have no match.
actor ClubCrestDirectory {
    static let shared = ClubCrestDirectory()
    private static let maxAge: TimeInterval = 7 * 24 * 3600
    private static let endpoint = "https://www.thesportsdb.com/api/v1/json/3/"

    private struct LeagueIndex: Codable { var teams: [String: String] }

    private var indexes: [String: [String: String]] = [:]
    private var loading: [String: Task<[String: String], Never>] = [:]
    private var searched: [String: URL] = [:]
    private var searchMisses: Set<String> = []
    private var resolved: [String: URL] = [:]

    /// Common club prefixes/suffixes that publishers add or drop.
    private static let affixes: Set<String> = [
        "fc", "sc", "afc", "cf", "ac", "sv", "bv", "vv", "fk", "sk", "if", "bk",
        "club", "cd", "ud", "sd", "rc", "rcd", "ss", "as", "us", "ogc", "losc", "the"
    ]

    static func keys(for name: String) -> [String] {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                                  locale: Locale(identifier: "en_US")).lowercased()
        let tokens = folded.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let full = tokens.joined()
        let stripped = tokens.filter { !affixes.contains($0) }.joined()
        var result: [String] = []
        for key in [full, stripped] where !key.isEmpty && !result.contains(key) { result.append(key) }
        return result
    }

    func crest(for name: String, leagues: [String], allowSearch: Bool = false) async -> URL? {
        let cacheKey = name + "|" + leagues.joined(separator: ",")
        if let hit = resolved[cacheKey] { return hit }
        let wanted = Self.keys(for: name)
        guard !wanted.isEmpty else { return nil }
        for league in leagues {
            let index = await self.index(for: league)
            if let found = Self.match(wanted, in: index) {
                resolved[cacheKey] = found
                return found
            }
        }
        guard allowSearch else { return nil }
        let found = await search(name, wanted: wanted)
        if let found { resolved[cacheKey] = found }
        return found
    }

    private static func match(_ wanted: [String], in index: [String: String]) -> URL? {
        for key in wanted {
            if let hit = index[key], let url = URL(string: hit) { return url }
        }
        // Unique prefix match, e.g. "Heracles" → "Heracles Almelo".
        for key in wanted where key.count >= 3 {
            let candidates = Set(index.filter { $0.key.hasPrefix(key) || (key.hasPrefix($0.key) && $0.key.count >= 4) }.values)
            if candidates.count == 1, let only = candidates.first, let url = URL(string: only) { return url }
        }
        return nil
    }

    private func index(for league: String) async -> [String: String] {
        if let cached = indexes[league] { return cached }
        let file = "crests-" + SportsDiskCache.hashed(league) + ".json"
        if let disk = SportsDiskCache.readJSON(LeagueIndex.self, file, maxAge: Self.maxAge) {
            indexes[league] = disk.teams
            return disk.teams
        }
        if let running = loading[league] { return await running.value }
        let task = Task<[String: String], Never> {
            guard var components = URLComponents(string: Self.endpoint + "search_all_teams.php") else { return [:] }
            components.queryItems = [URLQueryItem(name: "l", value: league)]
            guard let url = components.url else { return [:] }
            return await Self.fetchIndex(url, soccerOnly: false) ?? [:]
        }
        loading[league] = task
        let result = await task.value
        loading[league] = nil
        indexes[league] = result
        if !result.isEmpty { SportsDiskCache.writeJSON(LeagueIndex(teams: result), to: file) }
        return result
    }

    private func search(_ name: String, wanted: [String]) async -> URL? {
        let key = wanted[0]
        if let hit = searched[key] { return hit }
        if searchMisses.contains(key) { return nil }
        let file = "crest-search-" + SportsDiskCache.hashed(key) + ".json"
        if let disk = SportsDiskCache.readJSON(LeagueIndex.self, file, maxAge: Self.maxAge),
           let found = Self.match(wanted, in: disk.teams) {
            searched[key] = found
            return found
        }
        guard var components = URLComponents(string: Self.endpoint + "searchteams.php") else { return nil }
        components.queryItems = [URLQueryItem(name: "t", value: name)]
        // Only soccer records: the same name can exist in other sports.
        guard let url = components.url, let index = await Self.fetchIndex(url, soccerOnly: true) else {
            searchMisses.insert(key)
            return nil
        }
        guard let found = Self.match(wanted, in: index) else {
            searchMisses.insert(key)
            return nil
        }
        SportsDiskCache.writeJSON(LeagueIndex(teams: index), to: file)
        searched[key] = found
        return found
    }

    private static func fetchIndex(_ url: URL, soccerOnly: Bool) async -> [String: String]? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        var records = json["teams"] as? [[String: Any]] ?? []
        if soccerOnly { records = records.filter { (($0["strSport"] as? String) ?? "Soccer") == "Soccer" } }
        return buildIndex(records)
    }

    private static func buildIndex(_ records: [[String: Any]]) -> [String: String] {
        var index: [String: String] = [:]
        for record in records {
            guard let badge = (record["strBadge"] as? String)?.trimmingCharacters(in: .whitespaces),
                  badge.lowercased().hasPrefix("https://") else { continue }
            let thumb = badge.hasSuffix("/small") ? badge : badge + "/small"
            var names: [String] = []
            for field in ["strTeam", "strTeamShort"] {
                if let value = record[field] as? String { names.append(value) }
            }
            if let alternates = record["strTeamAlternate"] as? String {
                names += alternates.split(separator: ",").map { String($0) }
            }
            for name in names {
                for key in keys(for: name) where index[key] == nil { index[key] = thumb }
            }
        }
        return index
    }
}

/// Decoded images for the current session, shared by all logo views.
@MainActor
enum SportsImageMemory {
    static var images: [SportsArt: SportsPlatformImage] = [:]
}

enum SportsArtResolver {
    static func url(for art: SportsArt, allowSearch: Bool) async -> URL? {
        switch art {
        case .league(let slug):
            let clean = slug.split(separator: "/").last.map(String.init) ?? slug
            return URL(string: "https://maak-agenda.nl/images/leagues/\(clean).png")
        case .flag(let code):
            return URL(string: "https://maak-agenda.nl/images/national/\(code.uppercased()).png")
        case .club(let name, let leagues):
            return await ClubCrestDirectory.shared.crest(for: name, leagues: leagues, allowSearch: allowSearch)
        case .symbol:
            return nil
        }
    }
}

extension Image {
    init(sportsImage image: SportsPlatformImage) {
        #if os(macOS)
        self.init(nsImage: image)
        #else
        self.init(uiImage: image)
        #endif
    }
}

/// Logo, crest or flag with a neat monogram placeholder while loading or when
/// nothing is available. Never blocks the UI.
struct SportsLogoView: View {
    let art: SportsArt
    let title: String
    var size: CGFloat = 44
    var allowSearch = false

    @State private var image: SportsPlatformImage?

    init(art: SportsArt, title: String, size: CGFloat = 44, allowSearch: Bool = false) {
        self.art = art
        self.title = title
        self.size = size
        self.allowSearch = allowSearch
    }

    var body: some View {
        ZStack {
            if let image {
                Image(sportsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .transition(.opacity)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .task(id: art) { await load() }
    }

    @MainActor private func load() async {
        if let cached = SportsImageMemory.images[art] {
            image = cached
            return
        }
        image = nil
        guard let url = await SportsArtResolver.url(for: art, allowSearch: allowSearch),
              let data = await SportsImageStore.shared.data(for: url),
              let decoded = SportsPlatformImage(data: data) else { return }
        SportsImageMemory.images[art] = decoded
        withAnimation(.easeOut(duration: 0.2)) { image = decoded }
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(Self.tint(for: title).opacity(0.16))
            if case .symbol(let name) = art {
                Image(systemName: name)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Self.tint(for: title))
            } else {
                Text(Self.monogram(title))
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(Self.tint(for: title))
                    .padding(size * 0.12)
            }
        }
    }

    static func monogram(_ title: String) -> String {
        let skip: Set<String> = ["fc", "sc", "afc", "cf", "ac", "sv", "de", "the", "fk", "sk", "club"]
        let words = title.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        if words.count == 1, let only = words.first, only.count <= 3, only == only.uppercased() { return only }
        let significant = words.filter { !skip.contains($0.lowercased()) }
        let source = significant.isEmpty ? words : significant
        let letters = source.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return letters.joined()
    }

    static func tint(for title: String) -> Color {
        let palette: [Color] = [
            .weekdotRed, Color(red: 0.13, green: 0.43, blue: 0.76), Color(red: 0.17, green: 0.55, blue: 0.36),
            Color(red: 0.47, green: 0.29, blue: 0.75), Color(red: 0.78, green: 0.44, blue: 0.19),
            Color(red: 0.23, green: 0.50, blue: 0.51)
        ]
        let value = title.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return palette[value % palette.count]
    }
}
