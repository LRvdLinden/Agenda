import SwiftUI

/// Day and week view: a time grid with one column per day (7 by default).
struct TimeGridView: View {
    let days: [Date]

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var weather: WeatherService

    @GestureState private var pinch: CGFloat = 1
    @State private var didScroll = false

    private let gutter: CGFloat = 48
    private var settings: AppSettings { synced.settings }
    private var cal: Calendar { settings.calendar }
    private var hourHeight: CGFloat { CGFloat(settings.hourHeight) * pinch }
    private var scale: CGFloat { CGFloat(settings.textScale) }

    var body: some View {
        let start = days.first.map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: Date())
        let end = cal.addingDays(days.count, to: start)
        let _ = store.revision
        let items = store.events(from: start, to: end)
        GeometryReader { geo in
            let colWidth = max(20, (geo.size.width - gutter) / CGFloat(max(days.count, 1)))
            VStack(spacing: 0) {
                dayHeader(colWidth: colWidth)
                allDayStrip(items: items, colWidth: colWidth)
                Divider()
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        grid(items: items, colWidth: colWidth)
                            .frame(width: geo.size.width, height: hourHeight * 24 + 16)
                    }
                    .scrollIndicators(.hidden)
                    .simultaneousGesture(pinchGesture)
                    .onAppear {
                        guard !didScroll else { return }
                        didScroll = true
                        DispatchQueue.main.async {
                            proxy.scrollTo("hour-\(scrollHour)", anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private var scrollHour: Int {
        let now = Date()
        if days.contains(where: { cal.isDate($0, inSameDayAs: now) }) {
            let h = cal.component(.hour, from: now)
            if h > settings.dayStartHour + 6 { return max(0, h - 2) }
        }
        return max(0, min(23, settings.dayStartHour))
    }

    // MARK: Header

    private func dayHeader(colWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Group {
                if settings.showWeekNumbers, let first = days.first {
                    Text("W\(cal.weekNumber(first))")
                        .font(.system(size: 11 * scale, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Color.clear
                }
            }
            .frame(width: gutter)
            ForEach(days, id: \.self) { day in
                let isToday = cal.isDateInToday(day)
                Button {
                    if days.count > 1 { state.open(day: day) }
                } label: {
                    VStack(spacing: 3) {
                        Text(day.formatted(.dateTime.weekday(colWidth < 44 ? .narrow : .abbreviated)))
                            .font(.system(size: 11 * scale, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(isToday ? Color.accentColor : .secondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 17 * scale, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.white : (cal.isWeekend(day) ? .secondary : .primary))
                            .frame(minWidth: 30, minHeight: 30)
                            .background {
                                if isToday { Circle().fill(Color.accentColor) }
                            }
                        if settings.showWeather, let w = weather.forecast(for: day, calendar: cal) {
                            HStack(spacing: 2) {
                                Image(systemName: w.symbol).symbolRenderingMode(.multicolor)
                                if colWidth > 52 { Text(w.maxText) }
                            }
                            .font(.system(size: 10 * scale, weight: .medium))
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: colWidth)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: All-day

    private func allDayStrip(items: [EventItem], colWidth: CGFloat) -> some View {
        let perDay: [[EventItem]] = days.map { day in
            let s = cal.startOfDay(for: day), e = cal.addingDays(1, to: s)
            return items.filter { $0.isAllDay && $0.overlaps(dayStart: s, dayEnd: e) }
        }
        let maxRows = min(3, perDay.map(\.count).max() ?? 0)
        return Group {
            if maxRows > 0 {
                HStack(alignment: .top, spacing: 0) {
                    Text("all-day")
                        .font(.system(size: 9 * scale, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: gutter, alignment: .center)
                        .padding(.top, 4)
                    ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                        VStack(spacing: 2) {
                            ForEach(perDay[idx].prefix(perDay[idx].count > 3 ? 2 : 3)) { item in
                                EventChip(item: item, compact: colWidth < 70)
                                    .onTapGesture { state.detail = item }
                                    .contextMenu { EventContextMenu(item: item) }
                            }
                            if perDay[idx].count > 3 {
                                Button { state.open(day: day) } label: {
                                    Text("+\(perDay[idx].count - 2)")
                                        .font(.system(size: 10 * scale, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 1.5)
                        .frame(width: colWidth)
                    }
                }
                .frame(height: CGFloat(maxRows) * 21 * scale + 6)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: Grid

    private func grid(items: [EventItem], colWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // weekend shading
            if settings.shadeWeekends {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                    if cal.isWeekend(day) && days.count > 1 {
                        Rectangle()
                            .fill(Color.primary.opacity(0.035))
                            .frame(width: colWidth, height: hourHeight * 24)
                            .offset(x: gutter + CGFloat(idx) * colWidth, y: 8)
                    }
                }
            }
            // hour lines + labels
            ForEach(0..<25, id: \.self) { h in
                HStack(spacing: 0) {
                    Text(h < 24 && h > 0 ? Fmt.hourLabel(h) : "")
                        .font(.system(size: 10 * scale, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: gutter - 6, alignment: .trailing)
                        .padding(.trailing, 6)
                        .offset(y: -6)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.22))
                        .frame(height: 0.5)
                }
                .frame(height: 1)
                .offset(y: CGFloat(h) * hourHeight + 8)
                .id("hour-\(h)")
            }
            // vertical day separators
            ForEach(1..<max(days.count, 1), id: \.self) { i in
                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 0.5, height: hourHeight * 24)
                    .offset(x: gutter + CGFloat(i) * colWidth, y: 8)
            }
            // tap targets (new event / paste)
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: colWidth, height: hourHeight * 24)
                    .onTapGesture { location in
                        tapped(day: day, y: location.y)
                    }
                    .offset(x: gutter + CGFloat(idx) * colWidth, y: 8)
            }
            // events
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                ForEach(EventLayout.layout(items, day: day, calendar: cal)) { laid in
                    let sub = colWidth / CGFloat(laid.columns)
                    let h = max(CGFloat(laid.endMinutes - laid.startMinutes) / 60 * hourHeight, 18)
                    EventBlockView(item: laid.item, height: h, width: sub - 2,
                                   onMove: { t in handleMove(laid.item, translation: t, colWidth: colWidth) },
                                   onResize: { dy in handleResize(laid.item, dy: dy, laid: laid, day: day) })
                        .offset(x: gutter + CGFloat(idx) * colWidth + CGFloat(laid.column) * sub + 1,
                                y: CGFloat(laid.startMinutes) / 60 * hourHeight + 8)
                }
            }
            // now line
            TimelineView(.periodic(from: .now, by: 60)) { context in
                if let idx = days.firstIndex(where: { cal.isDate($0, inSameDayAs: context.date) }) {
                    let y = CGFloat(cal.minutesSinceStartOfDay(context.date)) / 60 * hourHeight + 8
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.weekdotRed).frame(width: colWidth, height: 1.5)
                        Circle().fill(Color.weekdotRed).frame(width: 9, height: 9).offset(x: -4.5)
                    }
                    .offset(x: gutter + CGFloat(idx) * colWidth, y: y - 0.75)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: Interaction

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, s, _ in
                s = min(max(value.magnification, 0.5), 2.5)
            }
            .onEnded { value in
                let new = settings.hourHeight * Double(value.magnification)
                synced.settings.hourHeight = min(max(new, 26), 160)
            }
    }

    private func snapped(_ minutes: Int) -> Int {
        let s = max(5, settings.snapMinutes)
        return Int((Double(minutes) / Double(s)).rounded()) * s
    }

    private func tapped(day: Date, y: CGFloat) {
        let minutes = min(max(snapped(Int(y / hourHeight * 60)), 0), 24 * 60 - settings.snapMinutes)
        let date = cal.date(on: day, minutes: minutes)
        if let clip = state.clipboard {
            if store.copy(clip, toStart: date) { state.showToast(String(localized: "Pasted")) }
        } else {
            state.editor = EditorRequest(start: date)
        }
    }

    private func handleMove(_ item: EventItem, translation: CGSize, colWidth: CGFloat) {
        let dayDelta = Int((translation.width / colWidth).rounded())
        let minuteDelta = snapped(Int(translation.height / hourHeight * 60))
        guard dayDelta != 0 || minuteDelta != 0 else { return }
        let base = cal.addingDays(dayDelta, to: item.start)
        let newStart = cal.date(byAdding: .minute, value: minuteDelta, to: base) ?? base
        if item.isRecurring {
            state.pendingChange = PendingChange(item: item, kind: .move(newStart, nil))
        } else {
            store.move(item, toStart: newStart)
        }
    }

    private func handleResize(_ item: EventItem, dy: CGFloat, laid: LaidOutEvent, day: Date) {
        let minuteDelta = snapped(Int(dy / hourHeight * 60))
        guard minuteDelta != 0 else { return }
        let newEnd = item.end.addingTimeInterval(TimeInterval(minuteDelta * 60))
        if item.isRecurring {
            state.pendingChange = PendingChange(item: item, kind: .resize(newEnd))
        } else {
            store.resize(item, toEnd: newEnd)
        }
    }
}

// MARK: - Event block

struct EventBlockView: View {
    let item: EventItem
    let height: CGFloat
    let width: CGFloat
    var onMove: (CGSize) -> Void
    var onResize: (CGFloat) -> Void

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var state: AppState
    @GestureState private var drag: CGSize = .zero
    @GestureState private var resize: CGFloat = 0
    @State private var lifted = false

    private var scale: CGFloat { CGFloat(synced.settings.textScale) }
    private var color: Color { Color(hex: item.colorHex) ?? .accentColor }

    var body: some View {
        let mode = synced.settings.eventStyle
        let h = max(18, height + resize)
        VStack(alignment: .leading, spacing: 1) {
            Text(item.displayTitle)
                .font(.system(size: 11 * scale, weight: .semibold))
                .lineLimit(h > 40 ? 3 : 1)
                .strikethrough(item.isDeclined)
            if h > 34 {
                Text(Fmt.time(item.start))
                    .font(.system(size: 10.5 * scale))
                    .opacity(0.85)
            }
            if h > 56, let loc = item.location {
                Text(loc)
                    .font(.system(size: 10.5 * scale))
                    .lineLimit(1)
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(mode == .filled ? Color.white : Color.primary)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .frame(width: max(width, 8), height: h, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(mode == .filled ? color : (mode == .tinted ? color.opacity(0.2) : Color.clear))
        }
        .overlay(alignment: .leading) {
            if mode == .tinted {
                UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6, style: .continuous)
                    .fill(color)
                    .frame(width: 3)
            }
        }
        .overlay {
            if mode == .outlined {
                RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(color, lineWidth: 1.5)
            }
        }
        .overlay(alignment: .bottom) {
            if item.canEdit && h > 26 && lifted {
                Capsule().fill(color).frame(width: 22, height: 4).padding(.bottom, 2)
                    .gesture(resizeGesture)
            }
        }
        .opacity(item.isDeclined ? 0.5 : 1)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(drag == .zero ? 0 : 0.25), radius: 8, y: 4)
        .scaleEffect(drag == .zero ? 1 : 1.03)
        .offset(drag)
        .zIndex(drag == .zero ? 0 : 10)
        .onTapGesture { state.detail = item }
        .gesture(item.canEdit ? moveGesture : nil)
        .contextMenu { EventContextMenu(item: item) }
        #if os(macOS)
        .onHover { lifted = $0 }
        #else
        .onAppear { lifted = true }
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Double tap to open"))
    }

    #if os(macOS)
    private var moveGesture: AnyGesture<CGSize> {
        AnyGesture(
            DragGesture(minimumDistance: 4)
                .updating($drag) { v, s, _ in s = v.translation }
                .onChanged { _ in state.isDraggingEvent = true }
                .onEnded { v in
                    state.isDraggingEvent = false
                    onMove(v.translation)
                }
                .map { $0.translation }
        )
    }
    #else
    private var moveGesture: AnyGesture<CGSize> {
        AnyGesture(
            LongPressGesture(minimumDuration: 0.35)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .updating($drag) { value, s, _ in
                    if case .second(true, let d?) = value { s = d.translation }
                }
                .onChanged { value in
                    if case .second(true, _) = value, !state.isDraggingEvent {
                        state.isDraggingEvent = true
                        Haptics.lift()
                    }
                }
                .onEnded { value in
                    state.isDraggingEvent = false
                    if case .second(true, let d?) = value { onMove(d.translation) }
                }
                .map { value -> CGSize in
                    if case .second(true, let d?) = value { return d.translation }
                    return .zero
                }
        )
    }
    #endif

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($resize) { v, s, _ in s = v.translation.height }
            .onChanged { _ in state.isDraggingEvent = true }
            .onEnded { v in
                state.isDraggingEvent = false
                onResize(v.translation.height)
            }
    }
}

enum Haptics {
    static func lift() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}

// MARK: - Chip used in all-day rows, month and list

struct EventChip: View {
    let item: EventItem
    var compact: Bool = false
    var showTime: Bool = false
    @EnvironmentObject private var synced: SyncedStore

    var body: some View {
        let color = Color(hex: item.colorHex) ?? .accentColor
        let scale = CGFloat(synced.settings.textScale)
        let filled = item.isAllDay || synced.settings.eventStyle == .filled
        HStack(spacing: 3) {
            if !filled {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            if showTime && !item.isAllDay && !compact {
                Text(Fmt.time(item.start))
                    .font(.system(size: 9.5 * scale))
                    .foregroundStyle(filled ? Color.white.opacity(0.9) : .secondary)
            }
            Text(item.displayTitle)
                .font(.system(size: (compact ? 9.5 : 10.5) * scale, weight: .medium))
                .lineLimit(1)
                .strikethrough(item.isDeclined)
                .foregroundStyle(filled ? Color.white : .primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, filled ? 4 : 1)
        .frame(height: 15 * scale)
        .background {
            if filled { RoundedRectangle(cornerRadius: 4, style: .continuous).fill(color) }
        }
        .opacity(item.isDeclined ? 0.5 : 1)
        .contentShape(Rectangle())
    }
}

/// Context menu shared by all views.
struct EventContextMenu: View {
    let item: EventItem
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState

    var body: some View {
        Button { state.detail = item } label: { Label("Open", systemImage: "info.circle") }
        if item.canEdit {
            Button { state.editor = EditorRequest(item: item) } label: { Label("Edit", systemImage: "pencil") }
        }
        Button { state.editor = EditorRequest(start: item.start, duplicateOf: item) } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Button { state.clipboard = item } label: { Label("Copy", systemImage: "doc.on.doc") }
        if item.canEdit {
            Divider()
            Button(role: .destructive) {
                if item.isRecurring {
                    state.pendingChange = PendingChange(item: item, kind: .delete)
                } else {
                    store.delete(item)
                }
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
