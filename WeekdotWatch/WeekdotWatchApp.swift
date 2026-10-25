import SwiftUI

@main
struct WeekdotWatchApp: App {
    @StateObject private var synced = SyncedStore.shared
    @StateObject private var store = CalendarStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastCrash: String? = WatchCrashReport.take()

    init() {
        WatchCrashReport.install()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let lastCrash {
                    WatchCrashView(report: lastCrash) { self.lastCrash = nil }
                } else {
                    WatchRootView()
                }
            }
            .environmentObject(synced)
            .environmentObject(store)
            .tint(Color.weekdotRed)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                synced.syncNow()
                store.refreshAuthorization()
                store.invalidate()
            }
        }
    }
}

struct WatchRootView: View {
    @EnvironmentObject private var store: CalendarStore

    var body: some View {
        if store.hasAccess || !store.synced.settings.useAppleCalendar || !store.local.calendars.isEmpty {
            // Plain navigation (no vertical page view): the day, with a link to the week.
            NavigationStack {
                WatchDayView()
            }
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    WeekdotMark()
                        .frame(width: 64, height: 64)
                    Text("Weekdot")
                        .font(.headline)
                    Text("Allow access to your calendars to see your events.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Continue") {
                        Task { await store.requestAccess() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}

/// Today (or the selected day) with a 7-day strip on top.
struct WatchDayView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @State private var selected = Date()

    var body: some View {
        let cal = synced.settings.calendar
        let weekStart = cal.startOfWeek(for: selected)
        let _ = store.revision
        let items = store.events(on: selected, calendar: cal)
            List {
                Section {
                    HStack(spacing: 2) {
                        ForEach(cal.days(from: weekStart, count: 7), id: \.self) { day in
                            let isSel = cal.isDate(day, inSameDayAs: selected)
                            let isToday = cal.isDateInToday(day)
                            Button { selected = day } label: {
                                VStack(spacing: 1) {
                                    Text(day.formatted(.dateTime.weekday(.narrow)))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Text(day.formatted(.dateTime.day()))
                                        .font(.system(size: 13, weight: isSel ? .bold : .regular))
                                        .foregroundStyle(isSel ? Color.white : (isToday ? Color.weekdotRed : .primary))
                                        .frame(width: 20, height: 20)
                                        .background { if isSel { Circle().fill(Color.weekdotRed) } }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                if items.isEmpty {
                    Text("No events")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(items) { item in
                        NavigationLink { WatchEventDetail(item: item) } label: { WatchEventRow(item: item) }
                    }
                }
                Section {
                    if !cal.isDateInToday(selected) {
                        Button { selected = Date() } label: { Label("Today", systemImage: "calendar") }
                    }
                    NavigationLink { WatchWeekView() } label: { Label("Week", systemImage: "list.bullet") }
                }
            }
            .navigationTitle(Text(selected.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))))

    }
}

/// The coming 7 days as a list.
struct WatchWeekView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore

    var body: some View {
        let cal = synced.settings.calendar
        let start = cal.startOfDay(for: Date())
        let _ = store.revision
        let byDay = store.eventsByDay(from: start, days: 7, calendar: cal)
            List {
                ForEach(cal.days(from: start, count: 7), id: \.self) { day in
                    Section {
                        let items = byDay[day] ?? []
                        if items.isEmpty {
                            Text("Free").font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(items) { item in
                            NavigationLink { WatchEventDetail(item: item) } label: { WatchEventRow(item: item) }
                        }
                    } header: {
                        Text(cal.isDateInToday(day) ? String(localized: "Today") : day.formatted(.dateTime.weekday(.wide).day()))
                    }
                }
            }
            .navigationTitle(Text("Week"))
    }
}

struct WatchEventRow: View {
    let item: EventItem

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: item.colorHex) ?? .weekdotRed)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                Text(Fmt.timeRange(item))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct WatchEventDetail: View {
    let item: EventItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.displayTitle).font(.headline)
                Text(item.start.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                Text(Fmt.timeRange(item))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let loc = item.location {
                    Label(loc, systemImage: "mappin.and.ellipse").font(.footnote)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: item.colorHex) ?? .weekdotRed).frame(width: 8, height: 8)
                    Text(item.calendarTitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}


/// Saves the reason of a crash (uncaught exception) so the next launch can show it — on Apple Watch there is
/// no other easy way to see why the app stopped.
enum WatchCrashReport {
    static var url: URL {
        (FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory).appendingPathComponent("weekdot-last-crash.txt")
    }

    static func install() {
        NSSetUncaughtExceptionHandler { exception in
            var text = exception.name.rawValue + "\n" + (exception.reason ?? "") + "\n\n"
            text += exception.callStackSymbols.prefix(40).joined(separator: "\n")
            try? text.data(using: .utf8)?.write(to: WatchCrashReport.url, options: .atomic)
        }
    }

    /// The saved report (once), then it is removed.
    static func take() -> String? {
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return text
    }
}

struct WatchCrashView: View {
    let report: String
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: "Weekdot stopped last time")
                    .font(.headline)
                Text(verbatim: report)
                    .font(.system(size: 10, design: .monospaced))
                Button("Continue", action: onContinue)
            }
        }
    }
}
