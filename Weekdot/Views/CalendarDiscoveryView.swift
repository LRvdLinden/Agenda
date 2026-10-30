import SwiftUI

/// Two-stage discovery flow: choose a country first, then explore available
/// calendars by category. All subscription actions use the existing choice
/// sheet, including the separate Apple Calendar and direct Weekdot methods.
struct HolidayCalendarsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var countrySearch = ""
    /// Opened straight on a country (used by screenshot mode); empty = start with the country list.
    @State private var path: [String]

    init(initialCountry: String? = nil) {
        _path = State(initialValue: initialCountry.map { [$0] } ?? [])
    }

    private var countries: [SmartCalendars.Holiday] {
        SmartCalendars.holidays.filter { holiday in
            holiday.region.count == 2 &&
            (countrySearch.isEmpty || holiday.localizedName.localizedCaseInsensitiveContains(countrySearch)
                || holiday.region.localizedCaseInsensitiveContains(countrySearch))
        }
    }

    private var nearbyCountry: SmartCalendars.Holiday? {
        let code = Locale.current.region?.identifier ?? "NL"
        return SmartCalendars.holidays.first { $0.region == code }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if countrySearch.isEmpty {
                        countryIntro

                        if let nearbyCountry {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Suggested Country")
                                    .font(.headline)
                                NavigationLink(value: nearbyCountry.region) {
                                    countryRow(nearbyCountry, highlighted: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("All Countries")
                            .font(.headline)
                        LazyVStack(spacing: 0) {
                            ForEach(countries, id: \.region) { country in
                                NavigationLink(value: country.region) {
                                    countryRow(country, highlighted: false)
                                }
                                .buttonStyle(.plain)
                                if country.region != countries.last?.region {
                                    Divider().padding(.leading, 66)
                                }
                            }
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle(Text("Choose Country"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $countrySearch, prompt: Text("Search Countries"))
            .navigationDestination(for: String.self) { code in
                CalendarDiscoveryCatalogView(countryCode: code)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 530, minHeight: 640)
        #endif
    }

    private var countryIntro: some View {
        HStack(spacing: 16) {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 65, height: 65)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 17))
            VStack(alignment: .leading, spacing: 5) {
                Text("Explore Calendars")
                    .font(.title2.weight(.bold))
                Text("First choose a country. Then explore holidays, sport, school breaks and more.")
                    .font(.subheadline)
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [.weekdotRed, Color(red: 0.75, green: 0.08, blue: 0.18)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 23)
        )
    }

    private func countryRow(_ country: SmartCalendars.Holiday, highlighted: Bool) -> some View {
        HStack(spacing: 14) {
            Text(country.flag)
                .font(.system(size: 29))
                .frame(width: 45, height: 45)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(country.localizedName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(country.region)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            if highlighted {
                RoundedRectangle(cornerRadius: 17)
                    .fill(Color.accentColor.opacity(0.08))
            }
        }
        .contentShape(Rectangle())
    }
}

private enum DiscoveryFilter: String, CaseIterable, Identifiable {
    case all, holidays, sports, school, zodiac, waste, other

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .all: return "All"
        case .holidays: return "Public Holidays"
        case .sports: return "Sports Schedules"
        case .school: return "School Holidays"
        case .zodiac: return "Zodiac & Astronomy"
        case .waste: return "Waste Collection"
        case .other: return "Other Calendars"
        }
    }

    var symbol: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .holidays: return "sun.max.fill"
        case .sports: return "sportscourt.fill"
        case .school: return "graduationcap.fill"
        case .zodiac: return "moon.stars.fill"
        case .waste: return "trash.fill"
        case .other: return "calendar.badge.plus"
        }
    }

    var detailKey: String {
        switch self {
        case .all: return "Browse all available calendars"
        case .holidays: return "National holidays and special days"
        case .sports: return "Formula 1, leagues and football clubs"
        case .school: return "School breaks and regional holidays"
        case .zodiac: return "Moon phases, zodiac and astronomy"
        case .waste: return "Waste collection by address"
        case .other: return "Week numbers and custom subscriptions"
        }
    }

    var tint: Color {
        switch self {
        case .all, .holidays: return .weekdotRed
        case .sports: return Color(red: 0.17, green: 0.55, blue: 0.36)
        case .school: return Color(red: 0.13, green: 0.43, blue: 0.76)
        case .zodiac: return Color(red: 0.47, green: 0.29, blue: 0.75)
        case .waste: return Color(red: 0.23, green: 0.50, blue: 0.51)
        case .other: return Color(red: 0.78, green: 0.44, blue: 0.19)
        }
    }
}

private struct DiscoveryFeed: Identifiable {
    let title: String
    let link: String
    let source: String
    let category: DiscoveryFilter

    var id: String { link }

    var choice: SubscriptionChoice {
        SubscriptionChoice(title: title, link: link, category: category.rawValue, countryCode: nil)
    }
}

private struct CalendarDiscoveryCatalogView: View {
    let countryCode: String

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @State private var filter: DiscoveryFilter = .all
    @State private var selectedFeed: SubscriptionChoice?
    @State private var selectedCategory: SmartCalendarCategory?
    @State private var showSports = false
    @State private var showMaakAgenda = false
    @State private var showCustomFeed = false
    @State private var showCirculus = false

    private var holiday: SmartCalendars.Holiday? {
        SmartCalendars.holidays.first { $0.region == countryCode }
    }

    private var countryName: String {
        holiday?.localizedName ?? (Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode)
    }

    private var feeds: [DiscoveryFeed] {
        var list: [DiscoveryFeed] = []
        if let holiday, let link = holiday.url?.absoluteString {
            list.append(DiscoveryFeed(title: String(localized: "Public Holidays") + " · " + holiday.localizedName,
                                      link: link, source: URL(string: link)?.host ?? "Calendar",
                                      category: .holidays))
        }
        // Country-specific flag-day subscriptions. These are published webcal
        // feeds, not automatically generated local events.
        switch countryCode {
        case "NL":
            list.append(DiscoveryFeed(
                title: "Vlagdagen Nederland",
                link: "webcal://vlagdagen.nl/api/functions/generateFlagDaysICS",
                source: "vlagdagen.nl",
                category: .holidays))
        case "BE":
            list.append(DiscoveryFeed(
                title: "Vlagdagen België",
                link: "webcal://vlagdagen.be/api/functions/flagDaysCalendarFeed",
                source: "vlagdagen.be",
                category: .holidays))
        default:
            break
        }
        for category in [DiscoveryFilter.school, .sports, .zodiac, .other] {
            let smartCategory: SmartCalendarCategory
            switch category {
            case .school: smartCategory = .school
            case .sports: smartCategory = .sports
            case .zodiac: smartCategory = .zodiac
            default: smartCategory = .other
            }
            for feed in smartCategory.featured(for: countryCode) {
                list.append(DiscoveryFeed(title: feed.localizedName, link: feed.url,
                                          source: feed.source, category: category))
            }
        }
        return list
    }

    private var recommendations: [DiscoveryFeed] {
        var result: [DiscoveryFeed] = []
        for kind in [DiscoveryFilter.holidays, .school, .sports, .zodiac] {
            if let item = feeds.first(where: { $0.category == kind }) { result.append(item) }
        }
        if let flagDays = feeds.first(where: {
            $0.link.contains("vlagdagen.nl") || $0.link.contains("vlagdagen.be")
        }) {
            result.append(flagDays)
        }
        return result
    }

    private var visibleFeeds: [DiscoveryFeed] {
        let filtered = filter == .all ? feeds.filter { $0.category != .sports } : feeds.filter { $0.category == filter }
        return filter == .all ? Array(filtered.prefix(10)) : filtered
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                countryBanner

                if filter == .all && !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for You")
                            .font(.title3.weight(.bold))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recommendations) { feed in
                                    recommendationCard(feed)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 13) {
                    Text("Browse Categories")
                        .font(.title3.weight(.bold))
                    categoryChips
                    if filter == .all { categoryTiles }
                }

                if filter == .all {
                    Button { showMaakAgenda = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "soccerball")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(DiscoveryFilter.sports.tint, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sporten")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Ontdek sporten, competities en clubs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(13)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if filter == .all {
                        Text("Popular Calendars").font(.title3.weight(.bold))
                    } else {
                        Text(LocalizedStringKey(filter.titleKey)).font(.title3.weight(.bold))
                    }

                    if visibleFeeds.isEmpty {
                        unavailableMessage
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(visibleFeeds) { feed in
                                feedRow(feed)
                                if feed.id != visibleFeeds.last?.id { Divider().padding(.leading, 62) }
                            }
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                }

                if ["NL", "BE", "NO"].contains(countryCode) && (filter == .all || filter == .waste) {
                    Button { showCirculus = true } label: {
                        Label("Waste Collection · automatic updates", systemImage: "trash.fill")
                            .font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(17).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
                    }
                    .buttonStyle(.plain)
                }

                Button { showCustomFeed = true } label: {
                    Label("Add Your Own ICS / webcal Feed", systemImage: "link.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(15)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                if subscriptions.isBusy {
                    ProgressView("Importing and syncing events…")
                }
            }
            .frame(maxWidth: 750)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle(countryName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $selectedFeed) { choice in
            SubscriptionMethodView(choice: SubscriptionChoice(title: choice.title, link: choice.link,
                                                               category: choice.category, countryCode: countryCode))
        }
        .sheet(item: $selectedCategory) { category in
            SmartCalendarCategoryView(category: category, countryCode: countryCode)
        }
        .sheet(isPresented: $showSports) { NavigationStack { MaakAgendaDirectoryView(countryCode: countryCode) } }
        .sheet(isPresented: $showMaakAgenda) { NavigationStack { MaakAgendaDirectoryView(countryCode: countryCode) } }
        .sheet(isPresented: $showCirculus) { CirculusImportView(initialCountryCode: countryCode) }
        .sheet(isPresented: $showCustomFeed) { SubscribeView(countryCode: countryCode) }
    }

    private var countryBanner: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geometry in
                Image(countryCode == "NL" ? "PhotoNetherlands" : "PhotoHolidays")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: 184)
                    .clipped()
            }
            .frame(height: 184)
            LinearGradient(colors: [.black.opacity(0.02), .black.opacity(0.80)],
                           startPoint: .top, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: 12) {
                Text(holiday?.flag ?? "🌍").font(.system(size: 38))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Discover Calendars").font(.caption.weight(.semibold))
                    Text(countryName).font(.title.weight(.bold))
                    Text("Select a calendar to add it to Weekdot.")
                        .font(.subheadline).lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(17)
        }
        .frame(height: 184)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func photoName(for category: DiscoveryFilter) -> String {
        switch category {
        case .holidays: return "PhotoHolidays"
        case .school: return "PhotoSchool"
        case .sports: return "PhotoSports"
        case .zodiac: return "PhotoStars"
        case .waste: return "PhotoWaste"
        case .other, .all: return "PhotoNetherlands"
        }
    }

    private func recommendationCard(_ feed: DiscoveryFeed) -> some View {
        Button { selectedFeed = feed.choice } label: {
            ZStack(alignment: .bottomLeading) {
                Image(feed.link.contains("vlagdagen.nl") ? "FlagDaysNL" :
                      feed.link.contains("vlagdagen.be") ? "FlagDaysBE" : photoName(for: feed.category))
                    .resizable().scaledToFill()
                    .frame(width: 232, height: 190).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.87)],
                               startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 7) {
                    Spacer(minLength: 0)
                    Text(feed.title)
                        .font(.headline).lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text(LocalizedStringKey(feed.category.titleKey))
                            .font(.caption).lineLimit(1)
                        Spacer(minLength: 3)
                        Image(systemName: subscriptions.isSubscribed(to: feed.link)
                              ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title3)
                    }
                }
                .foregroundStyle(.white).padding(14)
            }
            .frame(width: 232, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 19))
        }
        .disabled(subscriptions.isBusy)
        .buttonStyle(.plain)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(DiscoveryFilter.allCases) { kind in
                    Button {
                        if kind == .sports { showMaakAgenda = true }
                        else { withAnimation(.easeInOut(duration: 0.2)) { filter = kind } }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: kind.symbol).font(.caption)
                            Text(LocalizedStringKey(kind.titleKey))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(filter == kind ? .white : kind.tint)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(filter == kind ? kind.tint : Color.clear, in: Capsule())
                        .overlay(Capsule().strokeBorder(kind.tint.opacity(0.8), lineWidth: 1.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == kind ? .isSelected : [])
                }
            }
            .padding(.vertical, 3)
        }
        .contentMargins(.horizontal, 1)
    }

    private var categoryTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(DiscoveryFilter.allCases.filter { $0 != .all }) { kind in
                Button {
                    if kind == .waste && ["NL", "BE", "NO"].contains(countryCode) { showCirculus = true }
                    else if kind == .sports { showMaakAgenda = true }
                    else { withAnimation { filter = kind } }
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        GeometryReader { geometry in
                            Image(photoName(for: kind))
                                .resizable().scaledToFill()
                                .frame(width: geometry.size.width, height: 106)
                                .clipped()
                        }
                        .frame(height: 106)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        HStack(spacing: 6) {
                            Image(systemName: kind.symbol).foregroundStyle(kind.tint)
                            Text(LocalizedStringKey(kind.titleKey))
                                .foregroundStyle(.primary).font(.subheadline.weight(.bold))
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        Text(LocalizedStringKey(kind.detailKey))
                            .font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(height: 31, alignment: .topLeading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func feedRow(_ feed: DiscoveryFeed) -> some View {
        Button { selectedFeed = feed.choice } label: {
            HStack(spacing: 12) {
                Image(systemName: feed.category.symbol)
                    .font(.title3)
                    .foregroundStyle(feed.category.tint)
                    .frame(width: 42, height: 42)
                    .background(feed.category.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(feed.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(feed.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 3)
                Image(systemName: subscriptions.isSubscribed(to: feed.link)
                      ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(subscriptions.isSubscribed(to: feed.link) ? .green : Color.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(subscriptions.isBusy)
    }

    @ViewBuilder private var unavailableMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No curated live feeds for this category and country yet. You can still add any published ICS or webcal link.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if filter == .waste && ["NL", "BE", "NO"].contains(countryCode) {
                Button { showCirculus = true } label: {
                    Label("Add Live Waste Calendar", systemImage: "trash.fill")
                }
            }
            if let smart = smartCategory(for: filter) {
                Button { selectedCategory = smart } label: {
                    Label("More Information & Sources", systemImage: "info.circle")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func smartCategory(for kind: DiscoveryFilter) -> SmartCalendarCategory? {
        switch kind {
        case .school: return .school
        case .sports: return .sports
        case .zodiac: return .zodiac
        case .waste: return .waste
        case .other: return .other
        default: return nil
        }
    }

}


// MARK: - Live directory for Maak-Agenda.nl
// The publisher changes teams and competitions regularly; we never synthesize
// .ics URLs from page slugs. Only confirmed feed URLs are offered as subscriptions.
private struct MaakAgendaEntry: Identifiable, Hashable {
    let title: String
    let url: URL
    var id: String { url.absoluteString }
}

private enum MaakAgendaIndex {
    static let host = "maak-agenda.nl"
    static let sports: [(String, String)] = [
        ("Voetbal", "eredivisie"), ("Formule 1", "formula-1"),
        ("MotoGP", "motogp"), ("Tennis", "tennis"),
        ("Wielrennen", "cycling"), ("Cricket", "indian-premier-league"),
        ("Hockey", "hoofdklasse-heren"), ("NFL", "nfl"),
        ("Basketbal", "nba")
    ]

    // Publisher pages that must be visible from *every* supported country.
    // These are source pages, not invented ICS URLs. Their subscription links
    // are resolved by MaakAgendaPageView before offering direct subscription.
    static func globalFeatured(for selection: Int) -> [MaakAgendaEntry] {
        let items: [(String, String)]
        switch selection {
        case 1: items = [("Formula 1", "formula-1")]
        case 2: items = [("MotoGP", "motogp")]
        case 3: items = [("ATP Masters 1000", "tennis/atp-1000"), ("Tennis", "tennis")]
        case 4: items = [("UCI Men's WorldTour", "cycling/men-worldtour"), ("Wielrennen", "cycling")]
        case 5: items = [("Indian Premier League", "indian-premier-league")]
        case 6: items = [("Hoofdklasse Heren", "hoofdklasse-heren")]
        case 7: items = [("NFL", "nfl")]
        case 8: items = [("NBA", "nba")]
        default: items = []
        }
        return items.compactMap { title, path in
            guard let url = URL(string: "https://maak-agenda.nl/" + path) else { return nil }
            return MaakAgendaEntry(title: title, url: url)
        }
    }

    static func featuredEntries(for selection: Int) -> [MaakAgendaEntry] {
        let sets: [[(String, String)]] = [
            [],
            [("Formula 1", "formula-1")],
            [("MotoGP", "motogp")],
            [("ATP 1000", "tennis/atp-1000"), ("Tennis", "tennis")],
            [("UCI Men's WorldTour", "cycling/men-worldtour"), ("Wielrennen", "cycling")],
            [("Indian Premier League", "indian-premier-league")],
            [("Hoofdklasse Heren", "hoofdklasse-heren")],
            [("NFL", "nfl")],
            [("NBA", "nba")]
        ]
        guard sets.indices.contains(selection) else { return [] }
        return sets[selection].compactMap { title, path in
            guard let url = URL(string: "https://maak-agenda.nl/" + path) else { return nil }
            return MaakAgendaEntry(title: title, url: url)
        }
    }

    static func html(at url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return String(decoding: data, as: UTF8.self)
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
                  seen.insert(url.absoluteString).inserted else { return nil }
            let raw = String(html[textRange])
            let clean = (strip?.stringByReplacingMatches(in: raw, range: NSRange(raw.startIndex..., in: raw), withTemplate: "") ?? raw)
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&#39;", with: "'")
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
}

// Explicit competition-to-country mapping. Never treat the site's global footer
// (which links every league) as evidence that a league belongs to this country.
private enum MaakAgendaRegions {
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
    // Football association countries that participate in UEFA competitions.
    // These are UEFA countries, not just EU member states.
    static let europeanFootballCountries: Set<String> = [
        "AL", "AD", "AM", "AT", "AZ", "BE", "BA", "BG", "BY", "CH", "CY",
        "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GB", "GB-EN", "GB-SC",
        "GB-NI", "GB-WL", "GE", "GR", "HR", "HU", "IE", "IL", "IS", "IT",
        "KZ", "LI", "LT", "LU", "LV", "MD", "ME", "MK", "MT", "NL",
        "NO", "PL", "PT", "RO", "RS", "RU", "SE", "SI", "SK", "SM",
        "TR", "UA", "XK"
    ]
    // Every country gets worldwide tournaments. UEFA countries also get
    // European competitions, independent of its domestic competitions.
    static func sharedLinks(for code: String, from directory: [MaakAgendaEntry]) ->
        (europe: [MaakAgendaEntry], world: [MaakAgendaEntry]) {
        func resolved(_ region: String) -> [MaakAgendaEntry] {
            let index = Dictionary(directory.map {
                ($0.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased(), $0)
            }, uniquingKeysWith: { first, _ in first })
            let titles: [String: String] = [
                "champions-league": "Champions League",
                "europa-league": "Europa League",
                "uefa-conference-league": "Conference League",
                "nations-league": "Nations League",
                "uefa-super-cup": "UEFA Super Cup",
                "uefa-under-21": "UEFA Under 21",
                "uefa-euro-u19-championship": "UEFA Euro U19 Championship",
                "womens-champions-league": "Women's Champions League",
                "womens-nations-league": "Women's Nations League",
                "womens-world-cup-qualification-europe": "Women's World Cup Qualification Europe",
                "fifa-world-cup-2026": "FIFA World Cup 2026",
                "fifa-club-world-cup": "FIFA Club World Cup",
                "world-cup-qualifiers": "World Cup Qualifiers",
                "club-friendlies": "Club Friendlies",
                "oefen-interlands": "International Friendlies",
                "oefen-interlands-vrouwen": "Women's International Friendlies",
                "fifa-womens-world-cup-2023": "FIFA Women's World Cup"
            ]
            return (leagues[region] ?? []).map { slug in
                index[slug] ?? entry(titles[slug] ?? slug.replacingOccurrences(of: "-", with: " "), slug)
            }
        }
        return (europeanFootballCountries.contains(code) ? resolved("EU") : [], resolved("WORLD"))
    }
    static let regions: [(String, String)] = [
        ("EU", "Europe"), ("WORLD", "International"), ("AMERICA", "Americas"),
        ("AFRICA", "Africa"), ("ASIA", "Asia")
    ]
    static func links(for code: String, from directory: [MaakAgendaEntry]) -> [MaakAgendaEntry] {
        let index = Dictionary(directory.map { ($0.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
        return (leagues[code] ?? []).map { slug in
            index[slug] ?? entry(slug.replacingOccurrences(of: "-", with: " ").localizedCapitalized, slug)
        }
    }
    static func entry(_ title: String, _ path: String) -> MaakAgendaEntry {
        MaakAgendaEntry(title: title, url: URL(string: "https://maak-agenda.nl/" + path)!)
    }
}

struct MaakAgendaDirectoryView: View {
    let countryCode: String
    @State private var selectedSport: Int? = nil
    init(countryCode: String, initialSport: Int? = nil) {
        self.countryCode = countryCode
        self._selectedSport = State(initialValue: initialSport)
    }
    private var selection: Int { selectedSport ?? 0 }
    @State private var countryEntries: [MaakAgendaEntry] = []
    @State private var leagueEntries: [MaakAgendaEntry] = []
    @State private var clubEntries: [MaakAgendaEntry] = []
    @State private var europeanEntries: [MaakAgendaEntry] = []
    @State private var internationalEntries: [MaakAgendaEntry] = []
    @State private var regionCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var globalFeatured: [MaakAgendaEntry] {
        MaakAgendaIndex.globalFeatured(for: selection)
    }
    private var isFootball: Bool { selectedSport == 0 }
    private var oranje: [MaakAgendaEntry] {
        guard countryCode == "NL" && isFootball && regionCode.isEmpty else { return [] }
        return [
            MaakAgendaRegions.entry("Nederlands Elftal (mannen)", "team/nl"),
            MaakAgendaRegions.entry("Oranje Leeuwinnen (vrouwen)", "team/nl-women"),
            MaakAgendaRegions.entry("Jong Oranje (U21)", "team/jong-oranje")
        ]
    }
    private var displayedSportName: String {
        let name = MaakAgendaIndex.sports[selection].0
        return name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if selectedSport == nil { sportsHero }
                if selectedSport == nil {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Kies je sport")
                            .font(.title3.bold())
                        Spacer()
                        if selectedSport != nil {
                            Button("Alle sporten") { selectedSport = nil; regionCode = "" }
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                        ForEach(Array(MaakAgendaIndex.sports.enumerated()), id: \.offset) { index, sport in
                            NavigationLink {
                                MaakAgendaDirectoryView(countryCode: countryCode, initialSport: index)
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    ZStack(alignment: .bottomLeading) {
                                        GeometryReader { geo in
                                            Image(sportPhoto(index))
                                                .resizable().scaledToFill()
                                                .frame(width: geo.size.width, height: 92)
                                                .clipped()
                                        }
                                        LinearGradient(colors: [.clear, .black.opacity(0.58)], startPoint: .center, endPoint: .bottom)
                                        Image(systemName: sportSymbol(index))
                                            .font(.system(size: 23, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(11)
                                    }
                                    .frame(height: 92)
                                    HStack(spacing: 6) {
                                        Text(sport.0).font(.subheadline.bold())
                                            .lineLimit(1).minimumScaleFactor(0.9)
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right").font(.caption2.bold())
                                    }
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 12).padding(.vertical, 13)
                                }
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                } // end sport selection homepage
                if selectedSport == nil {
                    homeHorizontalSection("Populaire competities", entries: homeCompetitions, fallback: "trophy.fill")
                    homeHorizontalSection("Nationale elftallen", entries: homeNationalTeams, fallback: "shield.fill")
                    homeHorizontalSection("Populaire clubs", entries: homeClubs, fallback: "shield.fill")
                }
                if selectedSport != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayedSportName).font(.title2.bold())
                        Text("Bekijk competities, clubs en beschikbare kalenders")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                if isFootball {
                    HStack {
                        Text("Voetbal").font(.headline)
                        Spacer()
                        Menu {
                            Button("Geselecteerd land") { regionCode = ""; Task { await load() } }
                            ForEach(Array(MaakAgendaRegions.regions.enumerated()), id: \.offset) { _, region in
                                Button(region.1) { regionCode = region.0; Task { await load() } }
                            }
                        } label: {
                            Label(regionCode.isEmpty ? (Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode) : (MaakAgendaRegions.regions.first { $0.0 == regionCode }?.1 ?? regionCode), systemImage: "globe.europe.africa")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
                if selectedSport != nil && isLoading { ProgressView("Kalenders ophalen…").frame(maxWidth: .infinity) }
                if selectedSport != nil, let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.secondary) }
                if selectedSport != nil && !oranje.isEmpty { sportsSection("Nationale elftallen", entries: oranje, symbol: "person.3.fill") }
                if selectedSport != nil && !globalFeatured.isEmpty && !isFootball { sportsSection("Aanbevolen", entries: globalFeatured, symbol: sportSymbol(selection)) }
                if selectedSport != nil && !leagueEntries.isEmpty { sportsSection(isFootball ? "Competities en bekers" : "Kalenders", entries: leagueEntries, symbol: "trophy.fill") }
                if isFootball && regionCode.isEmpty && !europeanEntries.isEmpty { sportsSection("Europese competities", entries: europeanEntries, symbol: "star.circle.fill") }
                if isFootball && regionCode.isEmpty && !internationalEntries.isEmpty { sportsSection("Internationale toernooien", entries: internationalEntries, symbol: "globe") }
                if selectedSport != nil && !clubEntries.isEmpty { sportsSection("Clubs en teams", entries: clubEntries, symbol: "shield.fill") }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle(selectedSport == nil ? "Sporten" : displayedSportName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { if selectedSport != nil { await load() } }
        .refreshable { if selectedSport != nil { await load() } }
    }

    // The home page is an editorial landing page. Fixtures are deliberately not
    // invented: each card opens the corresponding real publisher page.
    private var homeCompetitions: [MaakAgendaEntry] {
        let local = MaakAgendaRegions.links(for: countryCode, from: [])
        let international = MaakAgendaRegions.sharedLinks(for: countryCode, from: [])
        return Array((Array(local.prefix(3)) + Array(international.europe.prefix(3)) + Array(international.world.prefix(2))).prefix(8))
    }
    private var homeNationalTeams: [MaakAgendaEntry] {
        if countryCode == "NL" {
            return [MaakAgendaRegions.entry("Nederlands Elftal", "team/nl"),
                    MaakAgendaRegions.entry("Oranje Leeuwinnen", "team/nl-women"),
                    MaakAgendaRegions.entry("Jong Oranje", "team/jong-oranje")]
        }
        return []
    }
    private var homeClubs: [MaakAgendaEntry] { featuredClubs }
    private var featuredClubs: [MaakAgendaEntry] {
        switch countryCode {
        case "NL": return [("Ajax", "Ajax"), ("PSV", "psv"), ("Feyenoord", "feyenoord"), ("AZ", "az"), ("FC Twente", "fc-twente")]
            .map { MaakAgendaRegions.entry($0.0, "team/" + $0.1) }
        default: return [] // do not invent club identifiers for other countries
        }
    }
    private var sportsHero: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                Image("SportFootball")
                    .resizable().scaledToFill()
                    .frame(width: geo.size.width, height: 205)
                    .clipped()
            }
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 7) {
                Text("SPORTWEDSTRIJDEN")
                    .font(.caption.bold()).tracking(2.2)
                Text("Volg de grootste wedstrijden")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                Text("Van lokale clubs tot internationale kampioenschappen.")
                    .font(.subheadline)
            }
            .foregroundStyle(.white).padding(20)
        }
        .frame(height: 205)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }
    private func homeHorizontalSection(_ title: String, entries: [MaakAgendaEntry], fallback: String) -> some View {
        Group {
            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(title).font(.title3.bold())
                        Spacer()
                        NavigationLink("Toon alles") {
                            MaakAgendaDirectoryView(countryCode: countryCode, initialSport: 0)
                        }.font(.subheadline.bold())
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 11) {
                            ForEach(entries) { entry in
                                NavigationLink {
                                    MaakAgendaPageView(entry: entry)
                                } label: {
                                    VStack(spacing: 10) {
                                        MaakAgendaLogoView(entry: entry, fallback: fallback)
                                            .frame(width: 65, height: 65)
                                        Text(entry.title).font(.caption.weight(.semibold))
                                            .lineLimit(2).multilineTextAlignment(.center)
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(width: 118, height: 125)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                }.buttonStyle(.plain)
                            }
                        }.padding(.vertical, 3)
                    }
                }
            }
        }
    }

    private func sportsSection(_ title: String, entries: [MaakAgendaEntry], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(entries.count)").font(.caption).foregroundStyle(.secondary)
            }
            LazyVStack(spacing: 0) {
                ForEach(entries) { entry in
                    NavigationLink {
                        MaakAgendaPageView(entry: entry)
                    } label: {
                        HStack(spacing: 13) {
                            MaakAgendaLogoView(entry: entry, fallback: symbol)
                            Text(entry.title).font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if entry.id != entries.last?.id { Divider().padding(.leading, 76) }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 19))
        }
    }

    private func sportPhoto(_ index: Int) -> String {
        switch index {
        case 0: return "SportFootball"
        case 1: return "SportFormula1"
        case 2: return "SportMotoGP"
        case 3: return "SportTennis"
        case 4: return "SportCycling"
        case 5: return "SportCricket"
        case 6: return "SportHockey"
        case 7: return "SportNFL"
        case 8: return "SportBasketball"
        default: return "PhotoSports"
        }
    }

    private func sportSymbol(_ index: Int) -> String {
        switch index {
        case 0: return "soccerball"
        case 1: return "flag.checkered"
        case 2: return "bicycle"
        case 3: return "tennis.racket"
        case 4: return "bicycle"
        case 5: return "figure.cricket"
        case 6: return "figure.hockey"
        case 7: return "sportscourt"
        case 8: return "basketball.fill"
        default: return "sportscourt.fill"
        }
    }

    @MainActor private func load() async {
        isLoading = true
        errorMessage = nil
        leagueEntries = []
        clubEntries = []
        europeanEntries = []
        internationalEntries = []
        defer { isLoading = false }
        guard let root = URL(string: "https://maak-agenda.nl/eredivisie"),
              let sportURL = URL(string: "https://maak-agenda.nl/" + MaakAgendaIndex.sports[selection].1) else { return }
        do {
            let directoryHTML = try await MaakAgendaIndex.html(at: root)
            let directory = MaakAgendaIndex.links(from: directoryHTML, baseURL: root)
            if isFootball {
                if regionCode.isEmpty {
                    let shared = MaakAgendaRegions.sharedLinks(for: countryCode, from: directory)
                    europeanEntries = shared.europe
                    internationalEntries = shared.world
                }
                leagueEntries = MaakAgendaRegions.links(for: regionCode.isEmpty ? countryCode : regionCode, from: directory)
                // Retrieve teams from each actual competition page, not the global footer.
                // Only links to /team/ are club/team links; never list unrelated leagues.
                let pages = Array(leagueEntries.prefix(8))
                var teams: [MaakAgendaEntry] = []
                for page in pages {
                    if let html = try? await MaakAgendaIndex.html(at: page.url) {
                        let children = MaakAgendaIndex.links(from: html, baseURL: page.url)
                        teams.append(contentsOf: children.filter { $0.url.path.hasPrefix("/team/") })
                    }
                }
                var seen = Set<String>()
                clubEntries = teams.filter { seen.insert($0.id).inserted }
                    .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            } else {
                let html = try await MaakAgendaIndex.html(at: sportURL)
                let all = MaakAgendaIndex.links(from: html, baseURL: sportURL)
                // Other sports are international: do not pretend that clubs belong
                // to the selected country without publisher country metadata.
                let featuredURLs = Set(globalFeatured.map(\.id))
                leagueEntries = all.filter {
                    !$0.url.path.hasPrefix("/team/") && !featuredURLs.contains($0.id)
                }
                clubEntries = all.filter { $0.url.path.hasPrefix("/team/") }
            }
            if leagueEntries.isEmpty && clubEntries.isEmpty && oranje.isEmpty && europeanEntries.isEmpty && internationalEntries.isEmpty {
                errorMessage = "No published calendars are listed for this country / category."
            }
        } catch {
            errorMessage = "Live directory unavailable. Featured calendar source pages remain available."
        }
    }
}


/// Public sports artwork lookup. Only accept an exact team or league match;
/// source metadata remains the fallback. Missing artwork never blocks navigation.
private enum VerifiedSportsArtwork {
    // TheSportsDB names often differ from publisher labels. Never guess using
    // a fuzzy first result: only verified aliases are accepted.
    static let aliases: [String: [String]] = [
        "ajax": ["Ajax", "AFC Ajax"], "psv": ["PSV Eindhoven", "PSV"],
        "feyenoord": ["Feyenoord"], "az": ["AZ Alkmaar", "AZ"],
        "fc twente": ["FC Twente"], "nederlands elftal": ["Netherlands", "Netherlands National Team"],
        "nederlands elftal (mannen)": ["Netherlands"],
        "oranje leeuwinnen": ["Netherlands Women", "Netherlands Women National Team"],
        "oranje leeuwinnen (vrouwen)": ["Netherlands Women"],
        "jong oranje": ["Netherlands U21", "Netherlands Under 21"],
        "eredivisie vrouwen": ["Vrouwen Eredivisie", "Eredivisie Women"],
        "keuken kampioen divisie": ["Eerste Divisie", "Keuken Kampioen Divisie"],
        "uefa champions league": ["UEFA Champions League", "Champions League"],
        "champions league": ["UEFA Champions League"],
        "europa league": ["UEFA Europa League"],
        "uefa conference league": ["UEFA Europa Conference League", "UEFA Conference League"],
        "premier league": ["English Premier League", "Premier League"],
        "bundesliga": ["German Bundesliga", "Bundesliga"],
        "eredivisie": ["Dutch Eredivisie", "Eredivisie"]
    ]
    private static func canonical(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased().filter { $0.isLetter || $0.isNumber }
    }
    static func logo(named title: String, isTeam: Bool) async -> URL? {
        let names = Array(Set([title] + (aliases[title.lowercased()] ?? []))).sorted { $0 == title && $1 != title }
        for name in names {
            guard var components = URLComponents(string: "https://www.thesportsdb.com/api/v1/json/3/" + (isTeam ? "searchteams.php" : "search_all_leagues.php")) else { continue }
            components.queryItems = [URLQueryItem(name: isTeam ? "t" : "s", value: name)]
            guard let endpoint = components.url else { continue }
            var req = URLRequest(url: endpoint)
            req.timeoutInterval = 7
            guard let (data, response) = try? await URLSession.shared.data(for: req),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            let records = (json[isTeam ? "teams" : "countrys"] as? [[String: Any]]) ??
                          (json["leagues"] as? [[String: Any]]) ?? []
            let accepted = Set(([title] + (aliases[title.lowercased()] ?? [])).map(canonical))
            for record in records {
                let candidate = (record[isTeam ? "strTeam" : "strLeague"] as? String) ?? ""
                guard accepted.contains(canonical(candidate)) else { continue }
                for key in (isTeam ? ["strBadge", "strLogo"] : ["strBadge", "strLogo"]) {
                    if let path = record[key] as? String, let url = URL(string: path), url.scheme == "https" { return url }
                }
            }
        }
        return nil
    }
}

private enum PublisherSportsArtwork {
    // On Maak-Agenda, a club image is sometimes adjacent to its link instead
    // of nested inside it. Prefer images whose ALT names the exact entity.
    static func logo(in html: String, for entry: MaakAgendaEntry) -> URL? {
        return pageLogo(in: html, page: entry.url, title: entry.title)
    }
    static func pageLogo(in html: String, page: URL, title: String) -> URL? {
        let pattern = #"<img\b[^>]*>"#
        let srcPattern = #"(?:src|data-src|data-original|srcset)\s*=\s*["']([^"']+)["']"#
        guard let images = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let sources = try? NSRegularExpression(pattern: srcPattern, options: .caseInsensitive) else { return nil }
        func norm(_ str: String) -> String {
            str.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased().filter { $0.isLetter || $0.isNumber }
        }
        let acceptedNames = [title] + (VerifiedSportsArtwork.aliases[title.lowercased()] ?? [])
        let accepted = acceptedNames.map(norm).filter { !$0.isEmpty }
        for hit in images.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let r = Range(hit.range, in: html) else { continue }
            let tag = String(html[r])
            let normalized = norm(tag)
            let hasSpecificName = accepted.contains { normalized.contains($0) }
            let hasLogoCue = tag.range(of: "logo|badge|crest|emblem", options: .regularExpression) != nil
            guard hasSpecificName && (hasLogoCue || tag.range(of: "alt=", options: .caseInsensitive) != nil) else { continue }
            guard let source = sources.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)),
                  let value = Range(source.range(at: 1), in: tag) else { continue }
            let raw = String(tag[value]).components(separatedBy: ",")[0].components(separatedBy: " ")[0]
                .replacingOccurrences(of: "&amp;", with: "&")
            if let url = URL(string: raw, relativeTo: page)?.absoluteURL,
               ["https", "http"].contains(url.scheme?.lowercased() ?? "") { return url }
        }
        return nil
    }
}

/// Best-effort logo discovery from the publisher page. Never substitute an
/// unrelated stock photo for a club's crest. Keep a clear fallback.
private struct MaakAgendaLogoView: View {
    let entry: MaakAgendaEntry
    let fallback: String
    @State private var logoURL: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.055))
            if let logoURL {
                AsyncImage(url: logoURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit().padding(5)
                    } else { fallbackView }
                }
            } else { fallbackView }
        }
        .frame(width: 48, height: 48)
        .task(id: entry.id) {
            logoURL = nil
            let isTeam = entry.url.path.hasPrefix("/team/")
            if let html = try? await MaakAgendaIndex.html(at: entry.url),
               let publisherLogo = PublisherSportsArtwork.pageLogo(in: html, page: entry.url, title: entry.title) {
                logoURL = publisherLogo
                return
            }
            // Club and league listings can have a crest next to the link,
            // while the destination page itself has no branded image.
            if let listingURL = URL(string: "https://maak-agenda.nl/eredivisie"),
               let listing = try? await MaakAgendaIndex.html(at: listingURL),
               let publisherLogo = PublisherSportsArtwork.logo(in: listing, for: entry) {
                logoURL = publisherLogo
                return
            }
            if let verified = await VerifiedSportsArtwork.logo(named: entry.title, isTeam: isTeam) {
                logoURL = verified
            }
        }
    }

    private var fallbackView: some View {
        Image(systemName: fallback)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.weekdotRed)
    }
}

private struct MaakAgendaPageView: View {
    let entry: MaakAgendaEntry
    @State private var entries: [MaakAgendaEntry] = []
    @State private var feedURL: URL?
    @State private var showSubscription = false
    @State private var isLoading = true

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    MaakAgendaLogoView(entry: entry, fallback: "trophy.fill")
                    Text(entry.title).font(.title3.bold())
                }
                if isLoading { ProgressView("Checking calendar subscription…") }
                if feedURL != nil {
                    Button("Abonneren") { showSubscription = true }
                } else if !isLoading {
                    Text("Er is voor deze kalender nog geen rechtstreeks abonnement gevonden.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if !entries.isEmpty {
                Section("Competitions and clubs") {
                    ForEach(entries) { child in
                        NavigationLink(child.title) { MaakAgendaPageView(entry: child) }
                    }
                }
            }
        }
        .navigationTitle(entry.title)
        .task {
            defer { isLoading = false }
            do {
                let html = try await MaakAgendaIndex.html(at: entry.url)
                feedURL = MaakAgendaIndex.calendarLink(from: html, baseURL: entry.url)
                entries = MaakAgendaIndex.links(from: html, baseURL: entry.url)
                    .filter { $0.url.path.hasPrefix("/team/") || $0.url.path.hasPrefix("/league/") }
            } catch { entries = [] }
        }
        .sheet(isPresented: $showSubscription) {
            if let feedURL {
                SubscriptionMethodView(choice: SubscriptionChoice(
                    title: entry.title, link: feedURL.absoluteString,
                    category: "sports", countryCode: nil))
            }
        }
    }
}
