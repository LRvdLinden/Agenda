import SwiftUI

@main
struct SevnApp: App {
    @StateObject private var synced = SyncedStore.shared
    @StateObject private var store = CalendarStore()
    @StateObject private var state = AppState()
    @StateObject private var weather = WeatherService()
    @Environment(\.scenePhase) private var scenePhase
    #if os(macOS)
    @StateObject private var dock = DockIconUpdater()
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(synced)
                .environmentObject(store)
                .environmentObject(state)
                .environmentObject(weather)
                .tint(Color(hex: synced.settings.accentHex) ?? Color.sevnRed)
                .preferredColorScheme(colorScheme)
                .onOpenURL { url in handle(url) }
                #if os(macOS)
                .frame(minWidth: 760, minHeight: 520)
                #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                synced.syncNow()
                store.refreshAuthorization()
                store.invalidate()
            }
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .commands { SevnCommands(state: state) }
        #endif
    }

    private var colorScheme: ColorScheme? {
        switch synced.settings.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// sevn://today, sevn://new, sevn://day?d=<unix time> (used by widgets)
    private func handle(_ url: URL) {
        guard url.scheme == "sevn" else { return }
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
        default:
            state.date = Date()
        }
    }
}

#if os(macOS)
struct SevnCommands: Commands {
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
