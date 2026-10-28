import SwiftUI
import EventKit

struct MainView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var weather: WeatherService
    @State private var selectedTab: WeekdotTab = .views
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private enum WeekdotTab: Hashable { case views, add, settings }

    private var settings: AppSettings { synced.settings }
    private var cal: Calendar { settings.calendar }

    var body: some View {
        Group {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                nativeTabs
            } else {
                calendarScreen
            }
            #else
            calendarScreen
            #endif
        }
        .sheet(item: $state.editor) { req in
            EventEditorView(request: req)
                .environmentObject(synced).environmentObject(store).environmentObject(state)
        }
        .sheet(item: $state.detail) { item in
            EventDetailView(item: item)
                .environmentObject(synced).environmentObject(store).environmentObject(state)
        }
        .sheet(item: $state.sheet) { sheet in
            Group {
                switch sheet {
                case .calendars: CalendarsView()
                case .search: SearchView()
                case .settings: SettingsView()
                case .templates: NavigationStack { TemplatesView() }
                case .rules: NavigationStack { RulesView() }
                case .quickAdd: QuickAddView().presentationDetents([.medium])
                case .goToDate: GoToDateView().presentationDetents([.medium, .large])
                }
            }
            .environmentObject(synced).environmentObject(store).environmentObject(state).environmentObject(weather)
        }
        .confirmationDialog("This is a repeating event.", isPresented: pendingBinding, titleVisibility: .visible,
                            presenting: state.pendingChange) { change in
            Button("This Event Only") { apply(change, span: .thisEvent) }
            Button("All Future Events") { apply(change, span: .futureEvents) }
            Button("Cancel", role: .cancel) { store.invalidate() }
        }
        .onChange(of: state.pendingStep) { _, v in
            guard v != 0 else { return }
            state.step(v, settings: settings)
            state.pendingStep = 0
        }
        .onChange(of: state.mode) { _, _ in
            // Shortcut/deep-link view changes should always reveal the calendar.
            selectedTab = .views
        }
        .onChange(of: state.detail?.id) { _, id in
            if id != nil { selectedTab = .views }
        }
        .onChange(of: settings) { _, _ in store.invalidate() }
        .task(id: weatherKey) { await weather.refreshIfNeeded(settings: settings) }
        .task(id: store.revision) {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await NotificationScheduler.reschedule(store: store)
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
    }

    #if os(iOS)
    /// Like Samen: native iOS tabs hold their own screen and selection state.
    /// Keep labels accessible but not visibly printed beneath the three icons.
    private var nativeTabs: some View {
        TabView(selection: $selectedTab) {
            calendarScreen
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                        .accessibilityLabel(Text("Views"))
                }
                .tag(WeekdotTab.views)

            AddHubView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityLabel(Text("Add"))
                }
                .tag(WeekdotTab.add)

            SettingsView(showsDoneButton: false)
                .tabItem {
                    Image(systemName: "gearshape")
                        .accessibilityLabel(Text("Settings"))
                }
                .tag(WeekdotTab.settings)
        }
        .tint(Color.accentColor)
        .toolbarBackground(.visible, for: .tabBar)
    }
    #endif

    private var calendarScreen: some View {
        NavigationStack {
            calendarSurface
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button { state.sheet = .calendars } label: {
                        Label("Calendars", systemImage: "calendar.badge.checkmark")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { state.sheet = .search } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    @ViewBuilder private var calendarSurface: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            calendarBody
        } else {
            calendarBody.safeAreaInset(edge: .bottom, spacing: 0) { bottomNavigation }
        }
        #else
        calendarBody.safeAreaInset(edge: .bottom, spacing: 0) { bottomNavigation }
        #endif
    }

    private var calendarBody: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .simultaneousGesture(swipeGesture)
        }
        .overlay(alignment: .bottom) { bottomOverlay }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Button { state.sheet = .goToDate } label: {
                        HStack(spacing: 4) {
                            Text(title)
                                .font(.title2.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Go to Date"))
                    HStack(spacing: 9) {
                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        #if os(iOS)
                        if horizontalSizeClass == .compact {
                            Menu {
                                viewModeButtons
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: state.mode.symbol)
                                    Text(LocalizedStringKey(state.mode.titleKey))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.10), in: Capsule())
                            }
                            .accessibilityLabel(Text("Views"))
                        }
                        #endif
                    }
                }
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Button { state.step(-1, settings: settings) } label: {
                        Image(systemName: "chevron.left").frame(width: 30, height: 30)
                    }
                    .accessibilityLabel(Text("Previous"))
                    Button("Today") { state.goToday() }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    Button { state.step(1, settings: settings) } label: {
                        Image(systemName: "chevron.right").frame(width: 30, height: 30)
                    }
                    .accessibilityLabel(Text("Next"))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var title: String {
        switch state.mode {
        case .year: return state.date.formatted(.dateTime.year())
        case .day: return state.date.formatted(.dateTime.day().month(.wide).year())
        case .days:
            return dateRangeTitle(start: state.date, count: settings.clampedMultiDayCount)
        case .week:
            let start = state.weekStart(settings: settings)
            let end = cal.addingDays(6, to: start)
            if cal.isDate(start, equalTo: end, toGranularity: .month) { return Fmt.monthYear(start) }
            return start.formatted(.dateTime.month(.abbreviated)) + " – " + end.formatted(.dateTime.month(.abbreviated).year())
        case .weeks:
            return dateRangeTitle(start: state.weekStart(settings: settings), count: 7 * settings.clampedMultiWeekCount)
        default: return Fmt.monthYear(state.date)
        }
    }

    private func dateRangeTitle(start: Date, count: Int) -> String {
        let end = cal.addingDays(count - 1, to: start)
        let first = start.formatted(.dateTime.day().month(.abbreviated))
        let last = end.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(first) – \(last)"
    }

    private var subtitle: String? {
        switch state.mode {
        case .day:
            return state.date.formatted(.dateTime.weekday(.wide)) + " · " + String(localized: "Week \(cal.weekNumber(state.date))")
        case .week, .weeks:
            return String(localized: "Week \(cal.weekNumber(state.weekStart(settings: settings)))")
        case .days:
            return String(localized: "\(settings.clampedMultiDayCount) days")
        default:
            return nil
        }
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        switch state.mode {
        case .day:
            TimeGridView(days: [cal.startOfDay(for: state.date)])
        case .days:
            TimeGridView(days: cal.days(from: cal.startOfDay(for: state.date), count: settings.clampedMultiDayCount))
        case .week:
            let days = cal.days(from: state.weekStart(settings: settings), count: 7)
            if settings.weekLayout == .grid {
                WeekGridView(days: days)
            } else {
                TimeGridView(days: days)
            }
        case .weeks:
            CompactCalendarView(anchor: state.date, weekCount: settings.clampedMultiWeekCount)
        case .month:
            CompactCalendarView(anchor: state.date, weekCount: nil)
        case .year:
            YearView(year: state.date)
        case .list:
            AgendaListView(from: state.date)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { v in
                guard !state.isDraggingEvent else { return }
                let dx = v.translation.width, dy = v.translation.height
                guard abs(dx) > 90, abs(dx) > abs(dy) * 2 else { return }
                state.step(dx < 0 ? 1 : -1, settings: settings)
            }
    }

    @ViewBuilder private var bottomOverlay: some View {
        VStack(spacing: 8) {
            if let clip = state.clipboard {
                HStack(spacing: 10) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Tap a time or day to paste “\(clip.title)”")
                        .font(.subheadline)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Button("Done") { state.clipboard = nil }
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if let undo = state.undo {
                HStack(spacing: 12) {
                    Text(undo.text).font(.subheadline.weight(.medium))
                    Button("Undo") {
                        undo.perform()
                        state.undo = nil
                    }
                    .font(.subheadline.weight(.bold))
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if let toast = state.toast {
                Text(toast)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 12)
        .animation(.snappy, value: state.clipboard?.id)
        .animation(.snappy, value: state.toast)
        .animation(.snappy, value: state.undo?.id)
    }

    // MARK: Bottom navigation for the main calendar actions.

    private var bottomNavigation: some View {
        HStack {
            Spacer(minLength: 0)
            floatingNavigation
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    /// A centred, floating glass capsule rather than a full-width attached bar.
    @ViewBuilder private var floatingNavigation: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            navigationActions
                .glassEffect()
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        } else {
            navigationActions
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.7))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
    }

    private var navigationActions: some View {
        HStack(spacing: 8) {
            Menu {
                viewModeButtons
            } label: {
                navigationLabel("Views", symbol: "rectangle.3.group")
                    .foregroundStyle(Color.accentColor)
            }
            Menu {
                Button {
                    state.editor = EditorRequest(start: state.suggestedStart(settings: settings))
                } label: { Label("New Event", systemImage: "plus") }
                Button { state.sheet = .quickAdd } label: { Label("Quick Add", systemImage: "text.badge.plus") }
                if !synced.templates.isEmpty {
                    Section("Templates") {
                        ForEach(synced.templates) { t in
                            Button {
                                state.editor = EditorRequest(start: nil, template: t)
                            } label: {
                                Text(((t.emoji ?? "").isEmpty ? "" : (t.emoji ?? "") + " ") + t.name)
                            }
                        }
                    }
                }
                Button { state.sheet = .templates } label: {
                    Label("Manage Templates", systemImage: "square.on.square")
                }
            } label: {
                navigationLabel("Add", symbol: "plus.circle.fill")
                    .foregroundStyle(Color.accentColor)
            }
            Button { state.sheet = .settings } label: {
                navigationLabel("Settings", symbol: "gearshape")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var viewModeButtons: some View {
        ForEach(CalendarViewMode.allCases) { mode in
            Button { withAnimation(.snappy) { state.mode = mode } } label: {
                Label {
                    Text(LocalizedStringKey(mode.titleKey))
                } icon: {
                    Image(systemName: state.mode == mode ? "checkmark.circle.fill" : mode.symbol)
                }
            }
        }
    }

    private func navigationLabel(_ title: LocalizedStringKey, symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .medium))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(Text(title))
    }

    // MARK: Helpers

    private var weatherKey: String {
        "\(settings.showWeather)-\(settings.temperatureUnit.rawValue)"
    }

    private var pendingBinding: Binding<Bool> {
        Binding(get: { state.pendingChange != nil }, set: { if !$0 { state.pendingChange = nil } })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { store.lastError != nil }, set: { if !$0 { store.lastError = nil } })
    }

    private func apply(_ change: PendingChange, span: EKSpan) {
        switch change.kind {
        case .move(let date, let allDay): store.move(change.item, toStart: date, allDay: allDay, span: span)
        case .resize(let end): store.resize(change.item, toEnd: end, span: span)
        case .delete: store.delete(change.item, span: span)
        }
        state.pendingChange = nil
    }
}
