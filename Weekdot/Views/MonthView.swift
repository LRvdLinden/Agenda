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
