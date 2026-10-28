import SwiftUI

/// Two-stage discovery flow: choose a country first, then explore available
/// calendars by category. All subscription actions use the existing choice
/// sheet, including the separate Apple Calendar and direct Weekdot methods.
struct HolidayCalendarsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var countrySearch = ""

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
        NavigationStack {
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
    @State private var showCustomFeed = false

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
        for category in [DiscoveryFilter.school, .sports, .zodiac, .other] {
            let smartCategory: SmartCalendarCategory
            switch category {
            case .school: smartCategory = .school
            case .sports: smartCategory = .sports
            case .zodiac: smartCategory = .zodiac
            default: smartCategory = .other
            }
            for feed in smartCategory.featured(for: countryCode) {
                list.append(DiscoveryFeed(title: feed.name, link: feed.url,
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
        return result
    }

    private var visibleFeeds: [DiscoveryFeed] {
        let filtered = filter == .all ? feeds : feeds.filter { $0.category == filter }
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

                if filter == .all || filter == .sports {
                    Button { showSports = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "soccerball")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(DiscoveryFilter.sports.tint, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Explore Sports & Clubs")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Formula 1, competitions and individual clubs")
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

                if filter == .all || filter == .other {
                    weatherCard
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
        .sheet(isPresented: $showSports) { SportsBrowserView(countryCode: countryCode) }
        .sheet(isPresented: $showCustomFeed) { SubscribeView(countryCode: countryCode) }
    }

    private var countryBanner: some View {
        HStack(spacing: 14) {
            Text(holiday?.flag ?? "🌍")
                .font(.system(size: 42))
            VStack(alignment: .leading, spacing: 3) {
                Text("Discover Calendars")
                    .font(.caption.weight(.semibold))
                    .opacity(0.88)
                Text(countryName)
                    .font(.title2.weight(.bold))
                Text("Select a calendar to add it to Weekdot.")
                    .font(.subheadline)
                    .opacity(0.87)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [.weekdotRed, Color(red: 0.75, green: 0.08, blue: 0.18)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 23)
        )
    }

    private func recommendationCard(_ feed: DiscoveryFeed) -> some View {
        Button { selectedFeed = feed.choice } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: feed.category.symbol)
                    .font(.system(size: 32, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Spacer(minLength: 4)
                Text(feed.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack {
                    Text(LocalizedStringKey(feed.category.titleKey))
                        .font(.caption)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: subscriptions.isSubscribed(to: feed.link)
                          ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title3)
                }
            }
            .foregroundStyle(.white)
            .padding(16)
            .frame(width: 220, height: 170)
            .background(
                LinearGradient(colors: [feed.category.tint, feed.category.tint.opacity(0.72)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20)
            )
        }
        .disabled(subscriptions.isBusy)
        .buttonStyle(.plain)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(DiscoveryFilter.allCases) { kind in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { filter = kind }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: kind.symbol).font(.caption)
                            Text(LocalizedStringKey(kind.titleKey))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(filter == kind ? .white : kind.tint)
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
    }

    private var categoryTiles: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 11)], spacing: 11) {
            ForEach(DiscoveryFilter.allCases.filter { $0 != .all }) { kind in
                Button { withAnimation { filter = kind } } label: {
                    VStack(alignment: .leading, spacing: 9) {
                        Image(systemName: kind.symbol)
                            .font(.title2)
                            .foregroundStyle(kind.tint)
                            .frame(width: 40, height: 40)
                            .background(kind.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                        Text(LocalizedStringKey(kind.titleKey))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text(LocalizedStringKey(kind.detailKey))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
                    .padding(13)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
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

            if filter == .waste && countryCode == "NL" {
                Text("For Circulus, look up your own address on the official website and import its calendar export.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "cloud.sun.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Local Weather Forecast")
                        .font(.headline)
                    Text("Show weather inside each day of your week view.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Toggle("Local Weather Forecast", isOn: $synced.settings.showWeather)
                    .labelsHidden()
            }
            if synced.settings.showWeather {
                Picker("Temperature", selection: $synced.settings.temperatureUnit) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(LocalizedStringKey(unit.titleKey)).tag(unit)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
