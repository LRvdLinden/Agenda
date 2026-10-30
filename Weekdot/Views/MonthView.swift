import SwiftUI

struct MonthView: View {
    let month: Date

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState

    private var settings: AppSettings { synced.settings }
    private var cal: Calendar { settings.calendar }

    var body: some View {
        let grid = cal.monthGrid(for: month)
        let _ = store.revision
        let byDay = store.eventsByDay(from: grid.first ?? month, days: grid.count, calendar: cal)
        let weeks = stride(from: 0, to: grid.count, by: 7).map { Array(grid[$0..<min($0 + 7, grid.count)]) }
        let numberWidth: CGFloat = settings.showWeekNumbers ? 26 : 0

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if settings.showWeekNumbers { Color.clear.frame(width: numberWidth, height: 1) }
                ForEach(Array(cal.orderedShortWeekdays().enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            .fixedSize(horizontal: false, vertical: true)
            Divider()
            GeometryReader { geo in
                let rowHeight = geo.size.height / CGFloat(max(weeks.count, 1))
                VStack(spacing: 0) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        HStack(spacing: 0) {
                            if settings.showWeekNumbers, let first = week.first {
                                Button { state.open(day: first, mode: .week) } label: {
                                    Text("\(cal.weekNumber(first))")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: numberWidth, height: rowHeight, alignment: .top)
                                        .padding(.top, 8)
                                }
                                .buttonStyle(.plain)
                            }
                            ForEach(week, id: \.self) { day in
                                MonthCell(day: day, inMonth: cal.isDate(day, equalTo: month, toGranularity: .month),
                                          items: byDay[cal.startOfDay(for: day)] ?? [], height: rowHeight)
                            }
                        }
                        .frame(height: rowHeight)
                        Divider()
                    }
                }
            }
        }
    }
}

private struct MonthCell: View {
    let day: Date
    let inMonth: Bool
    let items: [EventItem]
    let height: CGFloat

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var weather: WeatherService

    var body: some View {
        let cal = synced.settings.calendar
        let isToday = cal.isDateInToday(day)
        let scale = CGFloat(synced.settings.textScale)
        let maxLines = max(0, Int((height - 28) / (16 * scale)))
        let shown = items.count > maxLines ? max(0, maxLines - 1) : items.count
        VStack(alignment: .leading, spacing: 1) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 12 * scale, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? Color.white : (inMonth ? Color.primary : Color.secondary.opacity(0.6)))
                .frame(minWidth: 21, minHeight: 21)
                .background { if isToday { Circle().fill(Color.accentColor) } }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 3)
            if let alt = AltCalendar.label(for: day, id: synced.settings.alternateCalendar) {
                Text(alt)
                    .font(.system(size: 8 * scale))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            if synced.settings.showWeather, let dayWeather = weather.forecast(for: day, calendar: cal) {
                HStack(spacing: 2) {
                    Image(systemName: dayWeather.symbol)
                        .symbolRenderingMode(.multicolor)
                    Text(dayWeather.maxText)
                }
                .font(.system(size: 9 * scale))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.secondary)
            }
            ForEach(items.prefix(shown)) { item in
                EventChip(item: item, compact: true, showTime: true)
                    .onTapGesture { state.detail = item }
                    .draggable(item.id)
                    .contextMenu { EventContextMenu(item: item) }
            }
            if items.count > shown {
                Text("+\(items.count - shown)")
                    .font(.system(size: 10 * scale, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 3)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(synced.settings.shadeWeekends && cal.isWeekend(day) ? Color.primary.opacity(0.035) : Color.clear)
        .opacity(inMonth ? 1 : 0.55)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            state.editor = EditorRequest(start: cal.date(on: day, minutes: 9 * 60))
        }
        .onTapGesture {
            if let clip = state.clipboard {
                let minutes = clip.isAllDay ? 0 : cal.minutesSinceStartOfDay(clip.start)
                if store.copy(clip, toStart: cal.date(on: day, minutes: minutes)) {
                    state.showToast(String(localized: "Pasted"))
                }
            } else {
                state.open(day: day)
            }
        }
        .contextMenu {
            Button { state.editor = EditorRequest(start: cal.date(on: day, minutes: 9 * 60)) } label: {
                Label("New Event", systemImage: "plus")
            }
            Button { state.editor = EditorRequest(start: cal.startOfDay(for: day), allDay: true) } label: {
                Label("New All-Day Event", systemImage: "sun.max")
            }
            Button { state.open(day: day) } label: { Label("Open Day", systemImage: "calendar.day.timeline.left") }
            Button { state.open(day: day, mode: .week) } label: { Label("Open Week", systemImage: "calendar") }
        }
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first, let item = items.first(where: { $0.id == id }) ?? findItem(id) else { return false }
            let minutes = item.isAllDay ? 0 : cal.minutesSinceStartOfDay(item.start)
            let target = cal.date(on: day, minutes: minutes)
            if item.isRecurring {
                state.pendingChange = PendingChange(item: item, kind: .move(target, nil))
            } else {
                store.moveUndoable(item, toStart: target, state: state)
            }
            return true
        }
    }

    private func findItem(_ id: String) -> EventItem? {
        let cal = synced.settings.calendar
        let grid = cal.monthGrid(for: day)
        guard let first = grid.first else { return nil }
        let all = store.events(from: first, to: cal.addingDays(grid.count, to: first))
        return all.first { $0.id == id }
    }
}

/// A genuinely compact calendar above the selected day's agenda. Used for both
/// the mini-month and the configurable multi-week view.
struct CompactCalendarView: View {
    let anchor: Date
    /// nil = full mini-month; otherwise show this many consecutive weeks.
    let weekCount: Int?

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @State private var selectedDay: Date?

    private var cal: Calendar { synced.settings.calendar }

    var body: some View {
        let dates = displayedDates
        let _ = store.revision
        let byDay = store.eventsByDay(from: dates.first ?? anchor, days: dates.count, calendar: cal)
        let rows = stride(from: 0, to: dates.count, by: 7).map {
            Array(dates[$0..<min($0 + 7, dates.count)])
        }
        let chosenDay = cal.startOfDay(for: selectedDay ?? anchor)
        let entries = byDay[chosenDay] ?? []

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if synced.settings.showWeekNumbers {
                    Color.clear.frame(width: 28, height: 1)
                }
                ForEach(Array(cal.orderedShortWeekdays().enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)

            ForEach(Array(rows.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    if synced.settings.showWeekNumbers, let first = week.first {
                        Text("\(cal.weekNumber(first))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .frame(width: 28)
                    }
                    ForEach(week, id: \.self) { day in
                        let key = cal.startOfDay(for: day)
                        let events = byDay[key] ?? []
                        let current = cal.isDate(key, inSameDayAs: chosenDay)
                        let inMonth = cal.isDate(day, equalTo: anchor, toGranularity: .month)
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { selectedDay = key }
                        } label: {
                            VStack(spacing: 4) {
                                Text(day.formatted(.dateTime.day()))
                                    .font(.subheadline.weight(current || cal.isDateInToday(day) ? .bold : .regular))
                                    .frame(width: 29, height: 29)
                                    .foregroundStyle(current ? Color.white : Color.primary)
                                    .background {
                                        if current {
                                            Circle().fill(Color.accentColor)
                                        } else if cal.isDateInToday(day) {
                                            Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
                                        }
                                    }
                                HStack(spacing: 3) {
                                    ForEach(events.prefix(3)) { event in
                                        Circle()
                                            .fill(Color(hex: event.colorHex) ?? .accentColor)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(height: 5)
                            }
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .opacity(weekCount == nil && !inMonth ? 0.4 : 1)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { state.open(day: day) } label: {
                                Label("Open Day", systemImage: "calendar.day.timeline.left")
                            }
                            Button { state.editor = EditorRequest(start: cal.date(on: day, minutes: 9 * 60)) } label: {
                                Label("New Event", systemImage: "plus")
                            }
                        }
                    }
                }
            }

            Divider().padding(.top, 10)

            HStack {
                Text(Fmt.dayTitle(chosenDay)).font(.headline)
                Spacer()
                Button { state.open(day: chosenDay) } label: {
                    Label("Open Day", systemImage: "arrow.up.right.square")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if entries.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar",
                                       description: Text("Nothing planned for this day."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { event in
                            Button { state.detail = event } label: {
                                EventRow(item: event)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 7)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 30)
                        }
                    }
                }
            }
        }
        .onChange(of: anchor) { _, _ in selectedDay = nil }
        .onChange(of: weekCount) { _, _ in selectedDay = nil }
    }

    private var displayedDates: [Date] {
        if let weekCount {
            return cal.days(from: cal.startOfWeek(for: anchor), count: max(2, min(4, weekCount)) * 7)
        }
        return cal.monthGrid(for: anchor)
    }
}
