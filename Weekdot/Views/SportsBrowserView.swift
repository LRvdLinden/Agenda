import SwiftUI

/// Land → sport → competitie of club. Selecting + subscribes inside Weekdot.
struct SportsBrowserView: View {
    let countryCode: String

    var body: some View {
        NavigationStack {
            MaakAgendaDirectoryView(countryCode: countryCode)
        }
    }
}

private struct FootballBrowserView: View {
    let countryCode: String

    private var clubs: [SportsFeed] { SportsCatalog.clubs(country: countryCode) }
    private var competitions: [SportsFeed] { SportsCatalog.competitions(country: countryCode) }

    var body: some View {
        List {
            Section("Football") {
                NavigationLink {
                    SportsFeedListView(title: "Leagues & Cups", feeds: competitions,
                                       countryCode: countryCode)
                } label: {
                    SportsGroupRow(icon: "trophy", title: "Leagues & Cups",
                                   detail: String(competitions.count) + " calendars")
                }
                NavigationLink {
                    SportsFeedListView(title: "Football Clubs", feeds: clubs,
                                       countryCode: countryCode)
                } label: {
                    SportsGroupRow(icon: "shield.lefthalf.filled", title: "Football Clubs",
                                   detail: clubs.isEmpty ? "Add a club's ICS link" : String(clubs.count) + " clubs")
                }
            }
        }
        .navigationTitle(Text("Football"))
    }
}

private struct SportsGroupRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

private struct SportsFeedListView: View {
    let title: String
    let feeds: [SportsFeed]
    let countryCode: String

    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @EnvironmentObject private var store: CalendarStore
    @State private var search = ""
    @State private var selectedFeed: SubscriptionChoice?
    @State private var errorText: String?
    @State private var showCustomFeed = false

    private var results: [SportsFeed] {
        search.isEmpty ? feeds : feeds.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            if feeds.isEmpty {
                Section {
                    ContentUnavailableView("No Preselected Clubs", systemImage: "soccerball",
                                           description: Text("You can add any club using its published ICS link."))
                }
            } else {
                Section {
                    ForEach(results) { feed in
                        Button {
                            selectedFeed = SubscriptionChoice(title: NSLocalizedString(feed.name, comment: "Sports feed name"), link: feed.url,
                                                              category: "sports", countryCode: countryCode)
                        } label: {
                            HStack(spacing: 12) {
                                if feed.kind == .club || feed.logoURL != nil { SportsClubLogo(feed: feed) }
                                else {
                                    Image(systemName: feed.kind == .motorsport ? "flag.checkered" : "trophy.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 34, height: 34)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString(feed.name, comment: "Sports feed name")).foregroundStyle(.primary)
                                    Text(feed.source).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 3)
                                Image(systemName: subscriptions.isSubscribed(to: feed.url)
                                      ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(subscriptions.isSubscribed(to: feed.url) ? .green : Color.accentColor)
                            }
                        }
                        .disabled(subscriptions.isBusy)
                    }
                } footer: {
                    Text("Calendars are mirrored to Apple Calendar without opening its app. Live feeds refresh while Weekdot is active.")
                }
            }
            Section {
                Button { showCustomFeed = true } label: {
                    Label("Add ICS / webcal Subscription", systemImage: "link.badge.plus")
                }
                if subscriptions.isBusy { ProgressView("Importing and syncing events…") }
                Link(destination: URL(string: "https://matchcalendar.football/teams/")!) {
                    Label("Find More Football Clubs", systemImage: "safari")
                }
            }
        }
        .searchable(text: $search, prompt: "Search teams or competitions")
        .navigationTitle(Text(title))
        .sheet(isPresented: $showCustomFeed) { SubscribeView(category: "sports", countryCode: countryCode) }
        .sheet(item: $selectedFeed) { selection in SubscriptionMethodView(choice: selection) }
        .alert("Subscription Error", isPresented: Binding(get: { errorText != nil },
                                                           set: { if !$0 { errorText = nil } })) {
            Button("OK", role: .cancel) { errorText = nil }
        } message: { Text(errorText ?? "") }
    }
}

/// Small live club favicon (when provided by the club website). An SF Symbol
/// remains available if the remote image is not available.
private struct SportsClubLogo: View {
    let feed: SportsFeed

    var body: some View {
        AsyncImage(url: feed.logoURL) { phase in
            if case let .success(image) = phase {
                image.resizable().scaledToFit().padding(2)
            } else {
                Image(systemName: "shield.fill")
                    .resizable().scaledToFit().padding(7)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
        .accessibilityLabel(feed.name)
    }
}
