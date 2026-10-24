import SwiftUI
import EventKit

struct MainView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var weather: WeatherService

    private var settings: AppSettings { synced.settings }
    private var cal: Calendar { settings.calendar }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .simultaneousGesture(swipeGesture)
            }
            .overlay(alignment: .bottom) { bottomOverlay }
            .toolbar { toolbarContent }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
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
        .onChange(of: settings) { _, _ in store.invalidate() }
        .task(id: weatherKey) { await weather.refreshIfNeeded(settings: settings) }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
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
            Picker("View", selection: $state.mode) {
                ForEach(CalendarViewMode.allCases) { m in
                    Text(LocalizedStringKey(m.titleKey)).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var title: String {
        switch state.mode {
        case .year: return state.date.formatted(.dateTime.year())
        case .day: return state.date.formatted(.dateTime.day().month(.wide).year())
        case .week:
            let start = state.weekStart(settings: settings)
            let end = cal.addingDays(settings.clampedDayCount - 1, to: start)
            if cal.isDate(start, equalTo: end, toGranularity: .month) { return Fmt.monthYear(start) }
            return start.formatted(.dateTime.month(.abbreviated)) + " – " + end.formatted(.dateTime.month(.abbreviated).year())
        default: return Fmt.monthYear(state.date)
        }
    }

    private var subtitle: String? {
        switch state.mode {
        case .day:
            return state.date.formatted(.dateTime.weekday(.wide)) + " · " + String(localized: "Week \(cal.weekNumber(state.date))")
        case .week:
            return String(localized: "Week \(cal.weekNumber(state.weekStart(settings: settings)))")
        default:
            return nil
        }
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        switch state.mode {
        case .day:
            TimeGridView(days: [cal.startOfDay(for: state.date)])
        case .week:
            TimeGridView(days: cal.days(from: state.weekStart(settings: settings), count: settings.clampedDayCount))
        case .month:
            MonthView(month: state.date)
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
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { state.sheet = .calendars } label: {
                Label("Calendars", systemImage: "calendar.badge.checkmark")
            }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button { state.sheet = .search } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
            Button { state.sheet = .settings } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Menu {
                Button {
                    state.editor = EditorRequest(start: state.suggestedStart(settings: settings))
                } label: { Label("New Event", systemImage: "plus") }
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
                Button { state.sheet = .templates } label: { Label("Manage Templates", systemImage: "square.on.square") }
            } label: {
                Label("Add", systemImage: "plus")
            } primaryAction: {
                state.editor = EditorRequest(start: state.suggestedStart(settings: settings))
            }
        }
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
        case .resize(let end): store.resize(change.item, toEnd: end)
        case .delete: store.delete(change.item, span: span)
        }
        state.pendingChange = nil
    }
}
