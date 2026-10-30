import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Detail target: a maak-agenda.nl page, or a national team whose page is
/// looked up from the competitions it plays in.
enum SportsTarget: Hashable {
    case entry(MaakAgendaEntry)
    case national(NationalTeam)

    var title: String {
        switch self {
        case .entry(let entry): return entry.title
        case .national(let team): return team.title
        }
    }
}

private extension View {
    func sportsCard(cornerRadius: CGFloat = 16) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}

private func sportsArt(for entry: MaakAgendaEntry, crestLeagues: [String]) -> SportsArt {
    entry.isTeam ? .club(name: entry.title, leagues: crestLeagues) : .league(entry.path.lowercased())
}

// MARK: - Overview

/// The sports overview ("Sports"): hero, sport tiles, upcoming matches from
/// published feeds, popular competitions, national teams and clubs.
struct MaakAgendaDirectoryView: View {
    let countryCode: String

    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @State private var fixtures: [SportsFixture] = []
    @State private var clubs: [MaakAgendaEntry] = []
    @State private var selectedCompetition: SubscriptionChoice?

    init(countryCode: String) {
        self.countryCode = countryCode
    }

    private var countryName: String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }

    /// Localized country name (named so the string extractor reads it as text).
    private var homeLand: String { countryName }

    private var clubCrestLeagues: [String] {
        MaakAgendaRegions.crestLeagueNames[countryCode] ?? MaakAgendaRegions.majorCrestLeagues
    }

    private var popularCompetitions: [MaakAgendaEntry] {
        let local = MaakAgendaRegions.competitions(for: countryCode).prefix(3)
        let europe = MaakAgendaRegions.european(for: countryCode).prefix(3)
        let world = MaakAgendaRegions.competitions(for: "WORLD").prefix(2)
        return Array(local) + Array(europe) + Array(world)
    }

    private static var heroImageName: String {
        #if os(macOS)
        return NSImage(named: "SportsHero") != nil ? "SportsHero" : "SportFootball"
        #else
        return UIImage(named: "SportsHero") != nil ? "SportsHero" : "SportFootball"
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                sportsGrid
                if !fixtures.isEmpty { comingUp }
                competitionsSection
                nationalTeamsSection
                if !clubs.isEmpty { clubsSection }
                Text("Logos and crests are trademarks of their respective owners and are shown for identification only.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle(Text("Sports"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: countryCode) { await load() }
        .sheet(item: $selectedCompetition) { choice in
            SubscriptionMethodView(choice: choice)
        }
    }

    @MainActor private func load() async {
        async let upcoming = SportsFixtures.upcoming(competitions: SportsFixtures.featuredCompetitions(for: countryCode),
                                                     perCompetition: 5, limit: 10)
        async let popular = MaakAgendaRegions.popularClubs(for: countryCode)
        let loadedClubs = await popular
        withAnimation { clubs = Array(loadedClubs.prefix(14)) }
        let loadedFixtures = await upcoming
        withAnimation { fixtures = loadedFixtures }
    }

    // MARK: Hero

    private var hero: some View {
        Color.clear
            .frame(height: 200)
            .overlay {
                Image(Self.heroImageName)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.30), .black.opacity(0.82)],
                               startPoint: .top, endPoint: .bottom)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sports")
                        .textCase(.uppercase)
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .opacity(0.9)
                    Text("Follow the biggest matches")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text("From local clubs to international championships.")
                        .font(.subheadline)
                        .opacity(0.92)
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    // MARK: Sports

    private var sportsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Your Sport")
                .font(.title3.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(SportKind.allCases) { sport in
                    NavigationLink {
                        SportPageView(sport: sport, countryCode: countryCode)
                    } label: {
                        SportTile(sport: sport)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Coming up

    private var comingUp: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Up")
                .font(.title3.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(fixtures) { fixture in
                        Button {
                            if let feed = MaakAgendaIndex.leagueFeed(fixture.slug) {
                                selectedCompetition = SubscriptionChoice(title: fixture.competition, link: feed.absoluteString,
                                                                         category: "sports", countryCode: countryCode)
                            }
                        } label: {
                            FixtureCard(fixture: fixture,
                                        crestLeagues: MaakAgendaRegions.crestLeagues(forCompetition: fixture.slug,
                                                                                     country: countryCode))
                        }
                        .buttonStyle(.plain)
                        .disabled(subscriptions.isBusy)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
            }
            .padding(.vertical, -8)
        }
    }

    // MARK: Competitions, national teams, clubs

    private var competitionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SportsSectionHeader(title: Text("Popular Competitions")) {
                SportPageView(sport: .football, countryCode: countryCode)
            }
            cardScroller {
                ForEach(popularCompetitions) { entry in
                    NavigationLink {
                        MaakAgendaPageView(target: .entry(entry), art: .league(entry.path.lowercased()),
                                           countryCode: countryCode)
                    } label: {
                        LogoCard(title: entry.title, art: .league(entry.path.lowercased()))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var nationalTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("National Teams")
                .font(.title3.bold())
            cardScroller {
                ForEach(NationalTeam.teams(for: countryCode)) { team in
                    NavigationLink {
                        MaakAgendaPageView(target: .national(team), art: .flag(team.flag), countryCode: countryCode)
                    } label: {
                        LogoCard(title: team.title, art: .flag(team.flag))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var clubsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SportsSectionHeader(title: Text("Popular Clubs (\(homeLand))")) {
                SportsClubListView(countryCode: countryCode)
            }
            cardScroller {
                ForEach(clubs) { club in
                    let art = SportsArt.club(name: club.title, leagues: clubCrestLeagues)
                    NavigationLink {
                        MaakAgendaPageView(target: .entry(club), art: art, countryCode: countryCode)
                    } label: {
                        LogoCard(title: club.title, art: art)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func cardScroller<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 11) { content() }
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
        }
        .padding(.vertical, -8)
    }
}

// MARK: - Building blocks

private struct SportsSectionHeader<Destination: View>: View {
    let title: Text
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            title.font(.title3.bold())
            Spacer(minLength: 8)
            NavigationLink {
                destination()
            } label: {
                Text("See All")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
    }
}

private struct SportTile: View {
    let sport: SportKind

    var body: some View {
        Color.clear
            .aspectRatio(1.1, contentMode: .fit)
            .overlay {
                Image(sport.photo)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Image(systemName: sport.symbol)
                        .font(.system(size: 17, weight: .semibold))
                    Text(LocalizedStringKey(sport.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(.white)
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct LogoCard: View {
    let title: String
    let art: SportsArt

    var body: some View {
        VStack(spacing: 10) {
            SportsLogoView(art: art, title: title, size: 54)
                .frame(height: 58)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .frame(width: 118, height: 128)
        .sportsCard()
        .contentShape(Rectangle())
    }
}

private struct FixtureCard: View {
    let fixture: SportsFixture
    let crestLeagues: [String]

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 6) {
                team(fixture.home)
                Text(verbatim: "–")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 13)
                team(fixture.away)
            }
            Divider()
            HStack(spacing: 6) {
                SportsLogoView(art: .league(fixture.slug), title: fixture.competition, size: 18)
                Text(fixture.competition)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(fixture.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(width: 268)
        .sportsCard()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func team(_ name: String) -> some View {
        VStack(spacing: 6) {
            SportsLogoView(art: .club(name: name, leagues: crestLeagues), title: name, size: 44)
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SportsEntryRow: View {
    let title: String
    let art: SportsArt

    var body: some View {
        HStack(spacing: 13) {
            SportsLogoView(art: art, title: title, size: 38)
                .frame(width: 44, height: 44)
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

/// Rounded list of entries with logos; each row opens the detail page.
private struct SportsEntryList: View {
    let title: Text
    let entries: [MaakAgendaEntry]
    let crestLeagues: [String]
    let countryCode: String

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                title.font(.headline)
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        let art = sportsArt(for: entry, crestLeagues: crestLeagues)
                        NavigationLink {
                            MaakAgendaPageView(target: .entry(entry), art: art, countryCode: countryCode,
                                               teamCrestLeagues: crestLeagues)
                        } label: {
                            SportsEntryRow(title: entry.title, art: art)
                        }
                        .buttonStyle(.plain)
                        if entry.id != entries.last?.id { Divider().padding(.leading, 71) }
                    }
                }
                .sportsCard(cornerRadius: 18)
            }
        }
    }
}

// MARK: - Sport page

/// One sport: competitions, teams and featured calendars with logos.
struct SportPageView: View {
    let sport: SportKind
    let countryCode: String

    @State private var region = ""
    @State private var leagues: [MaakAgendaEntry] = []
    @State private var teams: [MaakAgendaEntry] = []
    @State private var isLoading = false
    @State private var failed = false

    private var countryName: String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }

    private var footballCrests: [String] {
        MaakAgendaRegions.crestLeagues(forCompetition: nil, country: countryCode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                banner
                if sport == .football { football } else { otherSport }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle(Text(LocalizedStringKey(sport.titleKey)))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
        .refreshable { await load() }
    }

    private var banner: some View {
        Color.clear
            .frame(height: 140)
            .overlay {
                Image(sport.photo)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)
            }
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 10) {
                    Image(systemName: sport.symbol)
                        .font(.system(size: 24, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(sport.titleKey))
                            .font(.title2.bold())
                        Text("Competitions, teams and calendars")
                            .font(.subheadline)
                            .opacity(0.9)
                    }
                }
                .foregroundStyle(.white)
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Football

    @ViewBuilder private var football: some View {
        HStack {
            Text("Region")
                .font(.headline)
            Spacer()
            Menu {
                Button(countryName) { region = "" }
                ForEach(MaakAgendaRegions.regions, id: \.self) { code in
                    Button { region = code } label: {
                        Text(LocalizedStringKey(MaakAgendaRegions.regionTitleKey(code)))
                    }
                }
            } label: {
                Label {
                    if region.isEmpty { Text(countryName) }
                    else { Text(LocalizedStringKey(MaakAgendaRegions.regionTitleKey(region))) }
                } icon: {
                    Image(systemName: "globe.europe.africa")
                }
                .font(.subheadline.weight(.medium))
            }
        }

        if region.isEmpty {
            nationalTeams
            SportsEntryList(title: Text("Leagues & Cups"), entries: MaakAgendaRegions.competitions(for: countryCode),
                            crestLeagues: footballCrests, countryCode: countryCode)
            SportsEntryList(title: Text("European Competitions"), entries: MaakAgendaRegions.european(for: countryCode),
                            crestLeagues: footballCrests, countryCode: countryCode)
            SportsEntryList(title: Text("International Tournaments"), entries: MaakAgendaRegions.competitions(for: "WORLD"),
                            crestLeagues: footballCrests, countryCode: countryCode)
            if isLoading && teams.isEmpty { ProgressView().frame(maxWidth: .infinity) }
            SportsEntryList(title: Text("Clubs"), entries: teams,
                            crestLeagues: footballCrests, countryCode: countryCode)
        } else {
            SportsEntryList(title: Text(LocalizedStringKey(MaakAgendaRegions.regionTitleKey(region))),
                            entries: MaakAgendaRegions.competitions(for: region),
                            crestLeagues: MaakAgendaRegions.majorCrestLeagues, countryCode: countryCode)
        }
    }

    private var nationalTeams: some View {
        let list = NationalTeam.teams(for: countryCode)
        return VStack(alignment: .leading, spacing: 10) {
            Text("National Teams").font(.headline)
            LazyVStack(spacing: 0) {
                ForEach(list) { team in
                    NavigationLink {
                        MaakAgendaPageView(target: .national(team), art: .flag(team.flag), countryCode: countryCode)
                    } label: {
                        SportsEntryRow(title: team.title, art: .flag(team.flag))
                    }
                    .buttonStyle(.plain)
                    if team.id != list.last?.id { Divider().padding(.leading, 71) }
                }
            }
            .sportsCard(cornerRadius: 18)
        }
    }

    // MARK: Other sports

    @ViewBuilder private var otherSport: some View {
        SportsEntryList(title: Text("Featured"), entries: sport.featured,
                        crestLeagues: sport.crestLeagues, countryCode: countryCode)
        if isLoading { ProgressView().frame(maxWidth: .infinity) }
        SportsEntryList(title: Text("Competitions"), entries: leagues,
                        crestLeagues: sport.crestLeagues, countryCode: countryCode)
        SportsEntryList(title: Text("Teams"), entries: teams,
                        crestLeagues: sport.crestLeagues, countryCode: countryCode)
        if failed {
            Text("The live directory is unavailable right now. The featured calendars remain available.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor private func load() async {
        isLoading = true
        failed = false
        defer { isLoading = false }
        if sport == .football {
            let clubs = await MaakAgendaRegions.popularClubs(for: countryCode)
            teams = clubs.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            return
        }
        guard let url = MaakAgendaIndex.page(sport.pagePath),
              let html = try? await MaakAgendaIndex.html(at: url) else {
            failed = true
            return
        }
        let all = MaakAgendaIndex.links(from: html, baseURL: url)
        let prefix = "/" + sport.pagePath + "/"
        let featured = Set(sport.featured.map(\.id))
        leagues = all.filter { !$0.isTeam && $0.url.path.hasPrefix(prefix) && !featured.contains($0.id) }
        var seen = Set<String>()
        teams = all.filter { $0.isTeam && seen.insert($0.title.lowercased()).inserted }
    }
}

// MARK: - All clubs

struct SportsClubListView: View {
    let countryCode: String

    @State private var clubs: [MaakAgendaEntry] = []
    @State private var search = ""
    @State private var isLoading = true

    private var crestLeagues: [String] {
        MaakAgendaRegions.crestLeagueNames[countryCode] ?? MaakAgendaRegions.majorCrestLeagues
    }

    private var results: [MaakAgendaEntry] {
        search.isEmpty ? clubs : clubs.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading && clubs.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if clubs.isEmpty {
                    Text("No clubs are listed for this country yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                SportsEntryList(title: Text("Clubs"), entries: results, crestLeagues: crestLeagues,
                                countryCode: countryCode)
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle(Text("Clubs"))
        .searchable(text: $search, prompt: Text("Search Clubs"))
        .task {
            var list: [MaakAgendaEntry] = []
            if let top = MaakAgendaRegions.topLeague(for: countryCode) {
                list = await MaakAgendaIndex.teams(onPage: MaakAgendaIndex.competition(top))
            }
            if list.isEmpty && countryCode == "NL" { list = MaakAgendaRegions.dutchClubs }
            clubs = list.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            isLoading = false
        }
    }
}

// MARK: - Detail page

/// Competition, club or national team: big logo, subscribe button (with a
/// subscribed state), upcoming matches from the feed and listed clubs.
struct MaakAgendaPageView: View {
    let target: SportsTarget
    let art: SportsArt
    let countryCode: String
    var teamCrestLeagues: [String]? = nil

    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @State private var entry: MaakAgendaEntry?
    @State private var feedURL: URL?
    @State private var isLoading = true
    @State private var fixtures: [SportsFixture] = []
    @State private var clubs: [MaakAgendaEntry] = []
    @State private var showSubscription = false

    private var isSubscribed: Bool {
        guard let feedURL else { return false }
        return subscriptions.isSubscribed(to: feedURL.absoluteString)
    }

    private var kindText: Text {
        switch target {
        case .national: return Text("National Team")
        case .entry(let entry): return entry.isTeam ? Text("Club") : Text("Competition")
        }
    }

    private var clubCrests: [String] {
        if let teamCrestLeagues, !teamCrestLeagues.isEmpty { return teamCrestLeagues }
        return MaakAgendaRegions.crestLeagues(forCompetition: entry?.leagueSlug, country: countryCode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if !fixtures.isEmpty { upcoming }
                SportsEntryList(title: Text("Clubs"), entries: clubs, crestLeagues: clubCrests,
                                countryCode: countryCode)
                if let entry {
                    Link(destination: entry.url) {
                        Label("View on maak-agenda.nl", systemImage: "safari")
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle(target.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
        .sheet(isPresented: $showSubscription) {
            if let feedURL {
                SubscriptionMethodView(choice: SubscriptionChoice(
                    title: target.title, link: feedURL.absoluteString,
                    category: "sports", countryCode: countryCode))
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            SportsLogoView(art: art, title: target.title, size: 92, allowSearch: true)
                .padding(14)
                .sportsCard(cornerRadius: 26)
            VStack(spacing: 4) {
                Text(target.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                kindText
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if isLoading {
                ProgressView()
                    .frame(height: 44)
            } else if feedURL != nil {
                Button { showSubscription = true } label: {
                    Label {
                        if isSubscribed { Text("Subscribed") } else { Text("Subscribe") }
                    } icon: {
                        Image(systemName: isSubscribed ? "checkmark.circle.fill" : "plus.circle.fill")
                    }
                    .font(.headline)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(isSubscribed ? Color.green : Color.weekdotRed)
                .controlSize(.large)
                .disabled(subscriptions.isBusy)
            } else {
                Text("No direct calendar subscription was found for this page yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Matches").font(.headline)
            LazyVStack(spacing: 0) {
                ForEach(fixtures) { fixture in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fixture.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                                .font(.caption.weight(.semibold))
                            Text(fixture.start.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 84, alignment: .leading)
                        SportsLogoView(art: .club(name: fixture.home, leagues: clubCrests), title: fixture.home, size: 24)
                        Text(verbatim: "\(fixture.home) – \(fixture.away)")
                            .font(.subheadline)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        SportsLogoView(art: .club(name: fixture.away, leagues: clubCrests), title: fixture.away, size: 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    if fixture.id != fixtures.last?.id { Divider().padding(.leading, 14) }
                }
            }
            .sportsCard(cornerRadius: 18)
        }
    }

    @MainActor private func load() async {
        var resolved: MaakAgendaEntry?
        switch target {
        case .entry(let page): resolved = page
        case .national(let team): resolved = await team.resolvePage()
        }
        entry = resolved
        guard let resolved else {
            isLoading = false
            return
        }
        feedURL = await MaakAgendaIndex.feedLink(for: resolved)
        isLoading = false
        if let feedURL {
            let next = await SportsFixtures.upcoming(feed: feedURL, competition: resolved.title,
                                                     slug: resolved.leagueSlug ?? resolved.path, limit: 6)
            withAnimation { fixtures = next }
        }
        if !resolved.isTeam {
            let listed = await MaakAgendaIndex.teams(onPage: resolved)
            withAnimation { clubs = listed }
        }
    }
}
