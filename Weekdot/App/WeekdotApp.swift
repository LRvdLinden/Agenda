import SwiftUI

@main
struct WeekdotApp: App {
    @StateObject private var synced = SyncedStore.shared
    @StateObject private var store = CalendarStore()
    @StateObject private var state = AppState()
    @StateObject private var weather = WeatherService()
    @StateObject private var feedSubscriptions = FeedSubscriptionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(synced)
                .environmentObject(store)
                .environmentObject(state)
                .environmentObject(weather)
                .environmentObject(feedSubscriptions)
                .tint(Color(hex: synced.settings.accentHex) ?? Color.weekdotRed)
                .preferredColorScheme(colorScheme)
                .onOpenURL { url in handle(url) }
                .onAppear {
                    if ScreenshotMode.isActive { prepareScreenshot() }
                    applyTimeZone()
                    NotificationScheduler.setUp(store: store)
                    HomeyService.shared.calendarStore = store
                    NotificationScheduler.scheduleBackgroundRefresh()
                    Task { await feedSubscriptions.refreshIfNeeded(store: store) }
                    // Tapping an alert opens that event (and its day behind it), like Apple Calendar.
                    NotificationDelegate.shared.setHandler { date, eventID in
                        openEvent(date: date, eventID: eventID)
                    }
                }
                // Settings and calendar colours changed on another Apple device.
                // Redraw immediately after the ubiquitous key-value store reports an update.
                .onReceive(NotificationCenter.default.publisher(
                    for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
                        store.invalidate()
                    }
                // EventKit emits EKEventStoreChanged for local/external calendar updates.
                // Some account providers coalesce or delay that notification, so while
                // Weekdot is foregrounded we also recheck sources at a modest interval.
                // This task is cancelled automatically when the scene becomes inactive.
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    while !Task.isCancelled {
                        // Every 5 minutes (was 45 s, which re-scheduled all alerts and widgets constantly).
                        try? await Task.sleep(for: .seconds(300))
                        guard !Task.isCancelled else { break }
                        store.reload()
                    }
                }
                .onChange(of: synced.settings.timeZoneOverride) { _, _ in applyTimeZone(); store.invalidate() }
                #if os(macOS)
                .frame(minWidth: 760, minHeight: 520)
                #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                synced.syncNow()
                store.refreshAuthorization()
                store.invalidate()
                Task {
                    await NotificationScheduler.reschedule(store: store)
                    await feedSubscriptions.refreshIfNeeded(store: store)
                    await HomeyService.shared.sync(store: store)
                }
            } else if phase == .background {
                NotificationScheduler.scheduleBackgroundRefresh()
            }
        }
        #if os(iOS)
        .backgroundTask(.appRefresh(NotificationScheduler.refreshTaskID)) {
            let deadline = Date().addingTimeInterval(26)
            await NotificationScheduler.scheduleBackgroundRefresh()
            await NotificationScheduler.reschedule()
            // The same registered refresh task also checks Weekdot-managed ICS
            // subscriptions. Do the alert work first and leave a bounded
            // amount of time for feeds (iOS may end the task at any point).
            // Apple-owned webcal subscriptions are updated by the system.
            // Keep the schedule on Homey fresh (events added on other devices).
            if deadline.timeIntervalSinceNow > 12, !Task.isCancelled {
                await HomeyService.shared.sync(store: store)
            }
            let remaining = deadline.timeIntervalSinceNow
            if remaining > 5, !Task.isCancelled {
                await feedSubscriptions.refreshIfNeeded(store: store,
                                                        maxDuration: min(18, remaining - 2),
                                                        requestTimeout: min(7, remaining - 3))
            }
        }
        #endif
        #if os(macOS)
        // The unified compact macOS toolbar reduces the oversized title bar.
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1200, height: 800)
        .commands { WeekdotCommands(state: state) }
        #endif
    }

    /// Time Zone Override (like Apple Calendar): all times are shown in the chosen zone.
    /// Screenshot/demo mode (see ScreenshotMode): sample data, no permission prompts, open the requested screen.
    private func prepareScreenshot() {
        var settings = synced.settings
        settings.onboardingDone = true
        settings.useAppleCalendar = false
        settings.showWeather = false
        settings.timeZoneOverride = nil
        settings.defaultView = .week
        settings.weekLayout = .grid
        synced.settings = settings
        store.local.seedScreenshotDemo(calendar: settings.calendar)
        store.reload()
        let cal = settings.calendar
        switch ScreenshotMode.scene {
        case "month": state.mode = .month
        case "day": state.mode = .day
        case "year": state.mode = .year
        case "list": state.mode = .list
        case "timeline":
            state.mode = .week
            synced.settings.weekLayout = .timeline
        case "event":
            state.mode = .week
            let monday = cal.startOfWeek(for: Date())
            let items = store.events(from: cal.addingDays(3, to: monday), to: cal.addingDays(4, to: monday))
            state.detail = items.first { !$0.isAllDay && $0.title.contains("Champions") } ?? items.last
        case "settings":
            state.mode = .week
            state.sheet = .settings
        default:
            state.mode = .week
        }
    }

    private func applyTimeZone() {
        if let id = synced.settings.timeZoneOverride, let tz = TimeZone(identifier: id) {
            NSTimeZone.default = tz
        } else {
            NSTimeZone.default = TimeZone.autoupdatingCurrent
        }
    }

    private var colorScheme: ColorScheme? {
        switch synced.settings.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Opens the day of `date` and then the event with `eventID` once it has loaded
    /// (used by alerts and by widget rows), like Apple Calendar.
    private func openEvent(date: Date, eventID: String?) {
        // The notification may wake Weekdot before EventKit/CloudKit has loaded.
        // Navigate to the correct day immediately, then resolve the exact event.
        state.date = date
        state.mode = .day
        state.sheet = nil
        state.editor = nil
        Task { @MainActor in
            let cal = synced.settings.calendar
            let day = cal.startOfDay(for: date)
            for attempt in 0..<8 {
                if attempt > 0 {
                    try? await Task.sleep(for: .milliseconds(350))
                    store.reload()
                }
                let items = store.events(from: day, to: cal.addingDays(1, to: day))
                let match: EventItem? = {
                    guard let eventID, !eventID.isEmpty else { return nil }
                    return items.first(where: { $0.id == eventID })
                        ?? items.first(where: { eventID.hasPrefix($0.id) || $0.id.hasPrefix(eventID) })
                }()
                if let match {
                    state.detail = match
                    return
                }
            }
            // Never open an unrelated event when the ID is unavailable.
            // The correct day remains visible for the user.
        }
    }

    /// weekdot://today, weekdot://new, weekdot://day?d=<unix time>, weekdot://week, weekdot://month,
    /// weekdot://event?id=<event item id>&d=<unix time of its day> (used by widgets)
    private func handle(_ url: URL) {
        guard url.scheme == "weekdot" else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        switch url.host {
        case "new":
            state.editor = EditorRequest(start: state.suggestedStart(settings: synced.settings))
        case "day":
            if let t = comps?.queryItems?.first(where: { $0.name == "d" })?.value, let v = Double(t) {
                state.date = Date(timeIntervalSince1970: v)
            }
            state.mode = .day
        case "week":
            state.date = Date()
            state.mode = .week
        case "month":
            state.date = Date()
            state.mode = .month
        case "event":
            let q = comps?.queryItems ?? []
            let id = q.first(where: { $0.name == "id" })?.value
            if let t = q.first(where: { $0.name == "d" })?.value, let v = Double(t) {
                openEvent(date: Date(timeIntervalSince1970: v), eventID: id)
            } else {
                state.date = Date()
                state.mode = .day
            }
        default:
            state.date = Date()
        }
    }
}

#if os(macOS)
struct WeekdotCommands: Commands {
    @ObservedObject var state: AppState

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Event") { state.editor = EditorRequest(start: nil) }
                .keyboardShortcut("n", modifiers: [.command])
            Button("Go to Today") { state.date = Date() }
                .keyboardShortcut("t", modifiers: [.command])
            Button("Search") { state.sheet = .search }
                .keyboardShortcut("f", modifiers: [.command])
        }
        CommandGroup(before: .toolbar) {
            ForEach(Array(CalendarViewMode.allCases.enumerated()), id: \.element) { idx, mode in
                Button(LocalizedStringKey(mode.titleKey)) { state.mode = mode }
                    .keyboardShortcut(KeyEquivalent(Character(String(idx + 1))), modifiers: [.command])
            }
            Divider()
            Button("Previous") { state.pendingStep = -1 }
                .keyboardShortcut(.leftArrow, modifiers: [.command])
            Button("Next") { state.pendingStep = 1 }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
            Divider()
        }
    }
}
#endif
