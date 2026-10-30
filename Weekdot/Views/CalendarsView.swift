import SwiftUI
import EventKit
import UniformTypeIdentifiers

/// Manage calendars: Weekdot's own calendars (synced with iCloud) and, optionally, the calendars of the
/// Apple Calendar app. Every calendar can get its own colour, sets switch groups of calendars.
struct CalendarsView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var showNew = false
    @State private var wasteDetails: FeedSubscription?
    @State private var showSubscribe = false
    @State private var showHolidays = false
    @State private var showAccounts = false
    @State private var newSetName = ""
    @State private var askSetName = false
    @State private var editing: CalendarChoice?
    @State private var removingSubscription: FeedSubscription?
    @State private var subscriptionError: String?

    private var appleGroups: [(String, [CalendarChoice])] {
        let apple = store.allChoices.filter { !$0.isLocal }
        let groups = Dictionary(grouping: apple) { $0.sourceTitle }
        return groups.keys.sorted { a, b in
            if a.lowercased().contains("icloud") != b.lowercased().contains("icloud") { return a.lowercased().contains("icloud") }
            return a < b
        }
        .map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(synced.sets) { set in
                        Button { store.apply(set: set) } label: {
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                Text(set.name)
                                Spacer()
                                Text("\(set.calendarIDs.count)").foregroundStyle(.secondary)
                                if synced.settings.activeSetID == set.id {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { idx in synced.sets.remove(atOffsets: idx) }
                    Button { askSetName = true } label: {
                        Label("Save Current Selection as Set", systemImage: "plus.square.on.square")
                    }
                    Button { store.showAllCalendars() } label: {
                        Label("Show All Calendars", systemImage: "eye")
                    }
                } header: {
                    Text("Calendar Sets")
                } footer: {
                    Text("Switch quickly between groups of calendars, for example Work and Family.")
                }

                Section {
                    ForEach(store.allChoices.filter(\.isLocal)) { c in
                        CalendarRow(choice: c, visible: store.isVisible(id: c.id),
                                    toggle: { store.setVisible(id: c.id, !store.isVisible(id: c.id)) },
                                    edit: { editing = c })
                    }
                    Button { showNew = true } label: { Label("New Calendar", systemImage: "plus.circle") }
                } header: {
                    Text("Weekdot")
                } footer: {
                    Text("Weekdot's own calendars. They sync through iCloud on all your devices, also without the Calendar app.")
                }

                if store.appleEnabled {
                    ForEach(appleGroups, id: \.0) { source, list in
                        Section(source) {
                            ForEach(list) { c in
                                CalendarRow(choice: c, visible: store.isVisible(id: c.id),
                                            toggle: { store.setVisible(id: c.id, !store.isVisible(id: c.id)) },
                                            edit: { editing = c })
                            }
                        }
                    }
                } else {
                    Section {
                        Button {
                            Task { await store.requestAccess() }
                        } label: {
                            Label("Connect Apple Calendar", systemImage: "link")
                        }
                    } footer: {
                        Text("Also show your iCloud, Google, Outlook and Exchange calendars from the Calendar app.")
                    }
                }

                Section {
                    Button { showHolidays = true } label: { Label("Subscribe to Calendar", systemImage: "sparkles") }
                    Button { showSubscribe = true } label: { Label("Add ICS / webcal Subscription", systemImage: "link.badge.plus") }
                    if store.appleEnabled {
                        Button { showAccounts = true } label: { Label("Add Account (Google, Outlook …)", systemImage: "person.crop.circle.badge.plus") }
                    }
                }

                if !subscriptions.subscriptions.isEmpty {
                    Section("Subscriptions added by Weekdot") {
                        ForEach(subscriptions.subscriptions) { subscription in
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(subscription.title)
                                    Text("\(subscription.eventCount) events")
                                        .font(.caption).foregroundStyle(.secondary)
                                    if subscription.oneTimeImport {
                                        Text("One-time ICS import · no auto-refresh")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    if let date = subscription.lastRefreshed {
                                        Text("Updated \(date.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    if let error = subscription.lastError {
                                        Text(error).font(.caption2).foregroundStyle(.red)
                                    }
                                }
                                Spacer()
                                Menu {
                                    if subscription.wasteAddress != nil {
                                        Button { wasteDetails = subscription } label: { Label("Bekijk ophaaldagen en bewerk tekst", systemImage: "list.bullet.rectangle") }
                                    }
                                    if !subscription.oneTimeImport {
                                        Button {
                                            Task {
                                                do { try await subscriptions.refresh(id: subscription.id, store: store) }
                                                catch { subscriptionError = error.localizedDescription }
                                            }
                                        } label: { Label("Refresh Now", systemImage: "arrow.clockwise") }
                                    }
                                    Button(role: .destructive) { removingSubscription = subscription } label: {
                                        Label("Unsubscribe", systemImage: "trash")
                                    }
                                } label: { Image(systemName: "ellipsis.circle") }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Calendars"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("New Calendar Set", isPresented: $askSetName) {
                TextField("Name", text: $newSetName)
                Button("Save") {
                    let name = newSetName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let set = CalendarSet(name: name, calendarIDs: store.visibleCalendarIDs)
                    synced.sets.append(set)
                    synced.settings.activeSetID = set.id
                    newSetName = ""
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The calendars that are visible now are saved in this set.")
            }
            .sheet(isPresented: $showNew) { CalendarEditView(choice: nil) }
            .sheet(item: $editing) { c in CalendarEditView(choice: c) }
            .sheet(isPresented: $showSubscribe) { SubscribeView() }
            .sheet(item: $wasteDetails) { sub in WasteSubscriptionDetailView(subscription: sub).environmentObject(subscriptions).environmentObject(store) }
            .sheet(isPresented: $showHolidays) { HolidayCalendarsView() }
            .sheet(isPresented: $showAccounts) { AddAccountInfoView() }
            .confirmationDialog("Remove this subscription and its Apple Calendar calendar?",
                                isPresented: Binding(get: { removingSubscription != nil },
                                                     set: { if !$0 { removingSubscription = nil } }),
                                titleVisibility: .visible) {
                Button("Remove Subscription and Calendar", role: .destructive) {
                    if let item = removingSubscription {
                        do { try subscriptions.unsubscribe(id: item.id, store: store) }
                        catch { subscriptionError = error.localizedDescription }
                    }
                    removingSubscription = nil
                }
                Button("Cancel", role: .cancel) { removingSubscription = nil }
            }
            .alert("Subscription Error", isPresented: Binding(get: { subscriptionError != nil },
                                                              set: { if !$0 { subscriptionError = nil } })) {
                Button("OK", role: .cancel) { subscriptionError = nil }
            } message: { Text(subscriptionError ?? "") }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }
}

private struct CalendarRow: View {
    let choice: CalendarChoice
    let visible: Bool
    let toggle: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color(hex: choice.colorHex) ?? .gray).frame(width: 22, height: 22)
                        if visible {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    .opacity(visible ? 1 : 0.35)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(choice.title)
                        if choice.isSubscription {
                            Text("Subscription").font(.caption).foregroundStyle(.secondary)
                        } else if choice.isBirthday {
                            Text("Birthdays from Contacts").font(.caption).foregroundStyle(.secondary)
                        } else if !choice.writable {
                            Text("Read only").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: edit) {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
        }
    }
}

/// New calendar (Weekdot or an Apple account) or edit name/colour of an existing one.
struct CalendarEditView: View {
    let choice: CalendarChoice?

    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var synced: SyncedStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var colorHex: String? = "#E8352F"
    @State private var account = "weekdot"
    @State private var askDelete = false

    private var apple: EKCalendar? { choice.flatMap { $0.isLocal ? nil : store.calendar(withID: $0.id) } }
    private var localCal: WDCalendar? { choice.flatMap { store.local.calendar(withID: $0.id) } }
    private var canRename: Bool { choice == nil || choice?.isLocal == true || (apple?.allowsContentModifications ?? false) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $title)
                        .disabled(!canRename)
                } footer: {
                    if !canRename {
                        Text("The name of this calendar can't be changed here. The colour is kept by Weekdot.")
                    }
                }
                Section("Color") {
                    ColorPaletteRow(selection: $colorHex)
                        .padding(.vertical, 4)
                }
                if choice == nil {
                    Section {
                        Picker("Account", selection: $account) {
                            Text("Weekdot (iCloud)").tag("weekdot")
                            ForEach(store.sourcesForNewCalendars, id: \.sourceIdentifier) { s in
                                Text(s.sourceType == .local ? String(localized: "On this device") : s.title)
                                    .tag(s.sourceIdentifier)
                            }
                        }
                    } footer: {
                        Text("Weekdot calendars sync through iCloud on all your devices with Weekdot.")
                    }
                } else if let c = choice {
                    Section {
                        LabeledContent("Account", value: c.isLocal ? String(localized: "Weekdot (iCloud)") : c.sourceTitle)
                    }
                    if c.isLocal || (apple.map { $0.allowsContentModifications || $0.type == .subscription } ?? false) {
                        Section {
                            Button("Delete Calendar", role: .destructive) { askDelete = true }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(choice == nil ? Text("New Calendar") : Text("Edit Calendar"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this calendar and all its events?", isPresented: $askDelete,
                                titleVisibility: .visible) {
                Button("Delete Calendar", role: .destructive) {
                    if let l = localCal { store.local.deleteCalendar(l); dismiss() }
                    else if let a = apple, store.deleteCalendar(a) { dismiss() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
        .onAppear {
            if let c = choice {
                title = c.title
                colorHex = c.colorHex
            }
        }
    }

    private func save() {
        let hex = colorHex ?? "#E8352F"
        let name = title.trimmingCharacters(in: .whitespaces)
        if let l = localCal {
            store.local.updateCalendar(l, title: name, colorHex: hex)
            synced.calendarColors.removeValue(forKey: l.calendarID)
            dismiss()
        } else if let a = apple {
            if store.updateCalendar(a, title: name, colorHex: hex) { dismiss() }
        } else if choice == nil {
            if account == "weekdot" {
                store.local.createCalendar(title: name, colorHex: hex)
                dismiss()
            } else if let source = store.sourcesForNewCalendars.first(where: { $0.sourceIdentifier == account }) {
                if store.createCalendar(title: name, colorHex: hex, source: source) != nil { dismiss() }
            }
        }
    }
}

struct SubscribeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @EnvironmentObject private var store: CalendarStore
    var suggestedURL: String = ""
    var suggestedName: String = ""
    var category: String = "custom"
    var countryCode: String? = nil
    @State private var urlText = ""
    @State private var nameText = ""
    @State private var errorText: String?
    @State private var showFileImport = false
    @State private var isOpeningApple = false

    private var hasLink: Bool {
        !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Calendar Name", text: $nameText)
                    TextField("webcal:// or https:// …ics", text: $urlText)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                } footer: {
                    Text("Paste a public ICS or webcal link. Choose Apple Calendar for an OS-managed live subscription, or choose Weekdot to import and manage a copy.")
                }
                Section {
                    Button { openInAppleCalendar() } label: {
                        Label("Add to Apple Calendar · automatic updates", systemImage: "calendar.badge.plus")
                    }
                    .disabled(!hasLink || isOpeningApple || subscriptions.isBusy)

                    Button {
                        Task {
                            do {
                                try await subscriptions.subscribe(title: nameText, link: urlText,
                                                                  category: category, countryCode: countryCode,
                                                                  store: store)
                                dismiss()
                            } catch { errorText = error.localizedDescription }
                        }
                    } label: {
                        Label("Subscribe directly in Weekdot", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(!hasLink || isOpeningApple || subscriptions.isBusy)

                    if let shareURL = SystemCalendarSubscription.webcalURL(for: urlText) {
                        ShareLink(item: shareURL) {
                            Label("Share Subscription Link", systemImage: "square.and.arrow.up")
                        }
                    }

                    if subscriptions.isBusy || isOpeningApple { ProgressView("Adding calendar…") }
                } footer: {
                    Text("Apple Calendar confirms and refreshes its own subscriptions. Weekdot's direct copies use foreground and opportunistic background refresh. Enable Apple Calendar access to show native subscriptions in Weekdot.")
                }
                Section {
                    Button { showFileImport = true } label: {
                        Label("Import Downloaded ICS File", systemImage: "square.and.arrow.down")
                    }
                    .disabled(subscriptions.isBusy)
                } footer: {
                    Text("For example, export an address-specific waste calendar from Circulus. Imported files are snapshots and do not automatically refresh.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Subscribe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear {
                if urlText.isEmpty { urlText = suggestedURL }
                if nameText.isEmpty { nameText = suggestedName }
            }
            .alert("Subscription Error", isPresented: Binding(get: { errorText != nil },
                                                               set: { if !$0 { errorText = nil } })) {
                Button("OK", role: .cancel) { errorText = nil }
            } message: { Text(errorText ?? "") }
            .fileImporter(isPresented: $showFileImport,
                          allowedContentTypes: [UTType(filenameExtension: "ics") ?? .data]) { result in
                do {
                    let url = try result.get()
                    let granted = url.startAccessingSecurityScopedResource()
                    defer { if granted { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url)
                    let title = nameText.isEmpty ? url.deletingPathExtension().lastPathComponent : nameText
                    Task {
                        do {
                            try await subscriptions.importCalendarFile(data, title: title, store: store)
                            dismiss()
                        } catch { errorText = error.localizedDescription }
                    }
                } catch { errorText = error.localizedDescription }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 260)
        #endif
    }

    private func openInAppleCalendar() {
        guard let url = SystemCalendarSubscription.webcalURL(for: urlText) else {
            errorText = String(localized: "Use a valid HTTPS or webcal calendar link.")
            return
        }
        isOpeningApple = true
        Task {
            if !store.hasAccess { await store.requestAccess() }
            if store.hasAccess {
                store.synced.settings.useAppleCalendar = true
                store.reload()
            }
            isOpeningApple = false
            openURL(url) { accepted in
                if accepted { dismiss() }
                else { errorText = String(localized: "Could not open Apple Calendar. Use Share Subscription Link instead.") }
            }
        }
    }
}

enum SmartCalendarCategory: String, CaseIterable, Identifiable {
    case school, sports, zodiac, waste, other

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .school: return "School Holidays"
        case .sports: return "Sports"
        case .zodiac: return "Zodiac & Astronomy"
        case .waste: return "Waste Collection"
        case .other: return "Other Calendars"
        }
    }

    var symbol: String {
        switch self {
        case .school: return "graduationcap"
        case .sports: return "sportscourt"
        case .zodiac: return "moon.stars"
        case .waste: return "trash"
        case .other: return "square.grid.2x2"
        }
    }

    var instructions: LocalizedStringKey {
        switch self {
        case .school:
            return "School holidays differ by country, region and sometimes school. In the Netherlands, consult the official government dates for North, Central and South; for updates, subscribe to an ICS feed published by your school or municipality."
        case .sports:
            return "Get a webcal or ICS subscription link from your team, league or sports calendar provider. Paste it below to add live fixtures and match dates to Apple Calendar and Weekdot."
        case .zodiac:
            return "For zodiac signs, moon phases or astronomy dates, use an ICS calendar from a trusted provider. Paste its subscription link below. Weekdot does not currently generate astrological predictions."
        case .waste:
            return "Add a live address-based waste calendar to keep collection dates updated. One-time ICS imports remain available."
        case .other:
            return "Other useful calendars, such as week numbers, day numbers or any public ICS feed you choose."
        }
    }

    var officialURL: URL? {
        switch self {
        case .school:
            return URL(string: "https://www.rijksoverheid.nl/themas/onderwijs/schoolvakanties/overzicht-schoolvakanties-per-schooljaar/overzicht-schoolvakanties-2026-2027")
        case .sports:
            return URL(string: "https://www.footballcalculator.co.uk/calendar")
        case .waste:
            return URL(string: "https://www.circulus.nl/afvalkalender/")
        case .zodiac:
            return nil
        case .other:
            return URL(string: "https://agenda-abonnement.nl/")
        }
    }

    func featured(for country: String) -> [FeaturedCalendarFeed] {
        switch self {
        case .school:
            guard country == "NL" else { return [] }
            return [
                FeaturedCalendarFeed(name: "School holidays · North", url: "https://agenda-abonnement.nl/schoolvakantiesnoordnederland.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "School holidays · Central", url: "https://agenda-abonnement.nl/schoolvakantiesmiddennederland.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "School holidays · South", url: "https://agenda-abonnement.nl/schoolvakantieszuidnederland.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "School holidays · All Netherlands", url: "https://agenda-abonnement.nl/schoolvakanties.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "Construction holidays · North", url: "https://agenda-abonnement.nl/bouwvakantienoordnederland.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "Construction holidays · Central", url: "https://agenda-abonnement.nl/bouwvakantiemiddennederland.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "Construction holidays · South", url: "https://agenda-abonnement.nl/bouwvakantiezuidnederland.ics", source: "agenda-abonnement.nl"),
            ]
        case .sports:
            return [
                FeaturedCalendarFeed(name: "Formula 1 · all sessions", url: "https://agenda-abonnement.nl/formule1.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "Formula 1 · races & qualifying", url: "https://agenda-abonnement.nl/formula1.ics", source: "agenda-abonnement.nl"),
            ]
        case .zodiac:
            return [
            FeaturedCalendarFeed(name: "Zodiac seasons", url: "https://cosmyday.com/feeds/zodiac-seasons.ics", source: "CosmyDay"),
            FeaturedCalendarFeed(name: "Astrology events", url: "https://cosmyday.com/feeds/all-events.ics", source: "CosmyDay"),
            FeaturedCalendarFeed(name: "Moon phases & zodiac", url: "https://cosmyday.com/feeds/moon-phases.ics", source: "CosmyDay"),
            FeaturedCalendarFeed(name: "Retrograde planets", url: "https://cosmyday.com/feeds/retrogrades.ics", source: "CosmyDay"),
            FeaturedCalendarFeed(name: "Astrological eclipses", url: "https://cosmyday.com/feeds/eclipses.ics", source: "CosmyDay"),
            FeaturedCalendarFeed(name: "Moon phases", url: "https://www.cyclecalcs.com/calendar/moon-phases.ics", source: "CycleCalcs"),
            FeaturedCalendarFeed(name: "Full moons", url: "https://www.cyclecalcs.com/calendar/full-moons.ics", source: "CycleCalcs"),
            FeaturedCalendarFeed(name: "Solar & lunar eclipses", url: "https://www.cyclecalcs.com/calendar/eclipses.ics", source: "CycleCalcs"),
            FeaturedCalendarFeed(name: "Equinoxes & solstices", url: "https://www.cyclecalcs.com/calendar/seasons.ics", source: "CycleCalcs"),
            FeaturedCalendarFeed(name: "All sky events", url: "https://www.cyclecalcs.com/calendar/sky-events.ics", source: "CycleCalcs"),
            FeaturedCalendarFeed(name: "Wheel of the Year", url: "https://www.cyclecalcs.com/calendar/sabbats.ics", source: "CycleCalcs"),
            ]
        case .other:
            guard country == "NL" else { return [] }
            return [
                FeaturedCalendarFeed(name: "Week numbers", url: "https://agenda-abonnement.nl/weeknummers.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "Day numbers", url: "https://agenda-abonnement.nl/dagnummers.ics", source: "agenda-abonnement.nl"),
                FeaturedCalendarFeed(name: "Dutch public & special holidays", url: "https://agenda-abonnement.nl/feestdagen.ics", source: "agenda-abonnement.nl"),
            ]
        case .waste:
            return []
        }
    }
}

struct FeaturedCalendarFeed: Identifiable {
    let name: String
    let url: String
    let source: String
    var id: String { url }
    var localizedName: String { NSLocalizedString(name, comment: "Published calendar feed title") }
}

struct SmartCalendarCategoryView: View {
    let category: SmartCalendarCategory
    let countryCode: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @EnvironmentObject private var store: CalendarStore
    @State private var showSubscribe = false
    @State private var selectedFeed: SubscriptionChoice?
    @State private var errorText: String?
    private var featured: [FeaturedCalendarFeed] { category.featured(for: countryCode) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(category.instructions)
                }
                if !featured.isEmpty {
                    Section("Ready to Subscribe") {
                        ForEach(featured) { feed in
                            Button {
                                selectedFeed = SubscriptionChoice(title: feed.localizedName, link: feed.url,
                                                                  category: category.rawValue,
                                                                  countryCode: countryCode)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(feed.localizedName)
                                        Text("Source: " + feed.source)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: subscriptions.isSubscribed(to: feed.url)
                                          ? "checkmark.circle.fill" : "plus.circle")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .disabled(subscriptions.isBusy)
                        }
                    }
                }
                if (countryCode == "NL" || category == .sports || category == .other),
                   let officialURL = category.officialURL {
                    Section {
                        Button { openURL(officialURL) } label: {
                            Label("Open Official Website", systemImage: "safari")
                        }
                    }
                }
                Section {
                    Button { showSubscribe = true } label: {
                        Label("Add ICS / webcal Subscription", systemImage: "calendar.badge.plus")
                    }
                    if subscriptions.isBusy { ProgressView("Importing and syncing events…") }
                } footer: {
                    Text("Weekdot imports the feed directly into its own Apple Calendar calendar. It checks for updates when the app is active. If a provider only offers a downloaded .ics file, a live URL is needed for automatic updates.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(LocalizedStringKey(category.titleKey)))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showSubscribe) {
                SubscribeView(suggestedName: category.titleKey,
                              category: category.rawValue, countryCode: countryCode)
            }
            .sheet(item: $selectedFeed) { selection in SubscriptionMethodView(choice: selection) }
            .alert("Subscription Error", isPresented: Binding(get: { errorText != nil },
                                                               set: { if !$0 { errorText = nil } })) {
                Button("OK", role: .cancel) { errorText = nil }
            } message: { Text(errorText ?? "") }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 340)
        #endif
    }
}

struct AddAccountInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Weekdot uses the accounts of the Calendar app. Add Google, Outlook, Exchange, Yahoo or CalDAV once and all its calendars appear in Weekdot automatically.")
                #if os(iOS)
                Text("iPhone and iPad: Settings › Apps › Calendar › Calendar Accounts › Add Account.")
                    .foregroundStyle(.secondary)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Text("Open Settings").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                #else
                Text("Mac: open the Calendar app › Calendar › Add Account…")
                    .foregroundStyle(.secondary)
                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                } label: {
                    Text("Open Calendar").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                #endif
                Spacer()
            }
            .padding(24)
            .navigationTitle(Text("Add Account"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 320)
        #endif
    }
}
