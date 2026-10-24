import SwiftUI

/// Week view as a grid of day boxes: Mon–Wed on the left, Thu–Fri on the right and the
/// weekend sharing the last box. Each box lists its events (all-day as bars, timed with a
/// coloured time label).
struct WeekGridView: View {
    let days: [Date]

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore

    private var cal: Calendar { synced.settings.calendar }

    var body: some View {
        let start = days.first.map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: Date())
        let _ = store.revision
        let byDay = store.eventsByDay(from: start, days: days.count, calendar: cal)
        GeometryReader { geo in
            if days.count == 7 {
                let rowH = geo.size.height / 3
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { i in
                            cell(days[i], byDay: byDay, height: rowH)
                        }
                    }
                    .frame(width: geo.size.width / 2)
                    separatorV
                    VStack(spacing: 0) {
                        cell(days[3], byDay: byDay, height: rowH)
                        cell(days[4], byDay: byDay, height: rowH)
                        cell(days[5], byDay: byDay, height: rowH / 2)
                        cell(days[6], byDay: byDay, height: rowH / 2)
                    }
                    .frame(width: geo.size.width / 2)
                }
            } else {
                // 1–6 days: two columns of equal boxes
                let perColumn = Int(ceil(Double(days.count) / 2))
                let rowH = geo.size.height / CGFloat(max(perColumn, 1))
                HStack(spacing: 0) {
                    ForEach(0..<(days.count > 1 ? 2 : 1), id: \.self) { col in
                        VStack(spacing: 0) {
                            ForEach(Array(days.enumerated()).filter { $0.offset / perColumn == col }, id: \.offset) { _, day in
                                cell(day, byDay: byDay, height: rowH)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(width: geo.size.width / CGFloat(days.count > 1 ? 2 : 1))
                        if col == 0 && days.count > 1 { separatorV }
                    }
                }
            }
        }
    }

    private var separatorV: some View {
        Rectangle().fill(Color.secondary.opacity(0.3)).frame(width: 0.5)
    }

    private func cell(_ day: Date, byDay: [Date: [EventItem]], height: CGFloat) -> some View {
        WeekDayBox(day: day, items: byDay[cal.startOfDay(for: day)] ?? [])
            .frame(height: height)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 0.5)
            }
    }
}

private struct WeekDayBox: View {
    let day: Date
    let items: [EventItem]

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @State private var contentHeight: CGFloat = 0
    @State private var boxHeight: CGFloat = 0

    private var cal: Calendar { synced.settings.calendar }
    private var scale: CGFloat { CGFloat(synced.settings.textScale) }

    var body: some View {
        let isToday = cal.isDateInToday(day)
        VStack(spacing: 0) {
            Text(day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
                 + (AltCalendar.label(for: day, id: synced.settings.alternateCalendar).map { "  ·  " + $0 } ?? ""))
                .font(.system(size: 12 * scale, weight: .semibold))
                .foregroundStyle(isToday ? Color.weekdotRed : Color.secondary)
                .lineLimit(1)
                .padding(.top, 3)
                .padding(.bottom, 2)
            // every box scrolls on its own when it has more events than fit
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(items) { item in
                        WeekGridEventRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { state.detail = item }
                            .contextMenu { EventContextMenu(item: item) }
                            .draggable(item.id)
                    }
                }
                .padding(.horizontal, 3)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GeometryReader { g in
                    Color.clear
                        .onAppear { contentHeight = g.size.height }
                        .onChange(of: g.size.height) { _, h in contentHeight = h }
                })
            }
            .scrollIndicators(.automatic)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(GeometryReader { g in
                Color.clear
                    .onAppear { boxHeight = g.size.height }
                    .onChange(of: g.size.height) { _, h in boxHeight = h }
            })
            .overlay(alignment: .bottomTrailing) {
                if contentHeight > boxHeight + 1 {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.weekdotRed)
                        .padding(3)
                        .allowsHitTesting(false)
                }
            }
        }
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(isToday ? Color.secondary.opacity(0.14) : (synced.settings.shadeWeekends && cal.isWeekend(day) ? Color.primary.opacity(0.03) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture { tapped() }
        .contextMenu {
            Button { state.editor = EditorRequest(start: cal.date(on: day, minutes: 9 * 60)) } label: {
                Label("New Event", systemImage: "plus")
            }
            Button { state.editor = EditorRequest(start: cal.startOfDay(for: day), allDay: true) } label: {
                Label("New All-Day Event", systemImage: "sun.max")
            }
            Button { state.open(day: day) } label: { Label("Open Day", systemImage: "calendar.day.timeline.left") }
        }
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            let weekStart = cal.startOfWeek(for: day)
            let all = store.events(from: cal.addingDays(-7, to: weekStart), to: cal.addingDays(14, to: weekStart))
            guard let item = all.first(where: { $0.id == id }) else { return false }
            let minutes = item.isAllDay ? 0 : cal.minutesSinceStartOfDay(item.start)
            let target = cal.date(on: day, minutes: minutes)
            if cal.isDate(target, inSameDayAs: item.start) { return false }
            if item.isRecurring {
                state.pendingChange = PendingChange(item: item, kind: .move(target, nil))
            } else {
                store.moveUndoable(item, toStart: target, state: state)
            }
            return true
        }
    }

    private func tapped() {
        if let clip = state.clipboard {
            let minutes = clip.isAllDay ? 0 : cal.minutesSinceStartOfDay(clip.start)
            if store.copy(clip, toStart: cal.date(on: day, minutes: minutes)) {
                state.showToast(String(localized: "Pasted"))
            }
        } else {
            state.open(day: day)
        }
    }
}

/// One event line in the week grid.
struct WeekGridEventRow: View {
    let item: EventItem
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore

    var body: some View {
        let color = Color(hex: item.colorHex) ?? .accentColor
        let onColor: Color = ColorHex.isLight(item.colorHex) ? .black : .white
        let scale = CGFloat(synced.settings.textScale)
        let size = 12.5 * scale
        Group {
            if item.isReminder {
                Button { store.toggleReminder(item) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(color)
                        Text(item.isAllDay ? item.title : Fmt.time(item.start) + " " + item.title)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                            .lineLimit(3)
                    }
                    .font(.system(size: size))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else if item.isAllDay {
                Text(item.displayTitle)
                    .font(.system(size: size))
                    .lineLimit(1)
                    .foregroundStyle(onColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 3, style: .continuous).fill(color))
            } else {
                Text("\(Text(Fmt.time(item.start)).foregroundStyle(onColor)) \(Text(item.displayTitle).foregroundStyle(item.isDeclined || item.isFree ? Color.secondary : Color.primary))\(Text(item.travelMinutes > 0 ? "  🚗 " + Fmt.duration(minutes: item.travelMinutes) : "").foregroundStyle(Color.secondary))")
                    .font(.system(size: size))
                    .lineLimit(4)
                    .background(alignment: .topLeading) {
                        // coloured box behind the time only
                        Text(Fmt.time(item.start))
                            .font(.system(size: size))
                            .foregroundStyle(.clear)
                            .padding(.horizontal, 1)
                            .background(RoundedRectangle(cornerRadius: 3, style: .continuous).fill(color))
                            .padding(.leading, -1)
                    }
                    .strikethrough(item.isDeclined)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(item.isDeclined ? 0.55 : 1)
    }
}
