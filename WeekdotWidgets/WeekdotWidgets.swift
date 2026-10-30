import WidgetKit
import SwiftUI
import EventKit

@main
struct WeekdotWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayIconWidget()
        UpNextWidget()
        ListWidget()
        MonthWidget()
        WeekWidget()
    }
}

// MARK: - Data

struct WeekdotEntry: TimelineEntry {
    let date: Date
    let items: [EventItem]
    let firstWeekday: Int
    /// Page of the list widgets (0 = first).
    var page: Int = 0
    var calendar: Calendar = Calendar.autoupdatingCurrent
}

enum WidgetData {
    static func load(from start: Date, to end: Date) -> (items: [EventItem], firstWeekday: Int) {
        let settings = StyleBook.settingsFromGroup()
        let cal = settings.calendar
        let snap = WidgetSnapshot.load()
        var items = (snap?.items ?? []).filter { $0.end > start && $0.start < end }
        // Apple events are read live when possible (fresher); Weekdot's own events come from the snapshot.
        if EventFetcher.hasFullAccess && (snap?.appleEnabled ?? settings.useAppleCalendar) {
            items = items.filter { $0.isLocal }
            items += EventFetcher.fetch(store: EKEventStore(), from: start, to: end,
                                        hidden: Set(settings.hiddenCalendarIDs), book: StyleBook.fromGroup(),
                                        showDeclined: settings.showDeclined)
            items.sort { $0.start < $1.start }
        }
        return (items, snap?.firstWeekday ?? cal.firstWeekday)
    }

    static var calendar: Calendar { StyleBook.settingsFromGroup().calendar }
}

struct WeekdotProvider: TimelineProvider {
    enum Span { case week, upcoming, month }

    let kind: String
    var span: Span = .upcoming

    private func range(_ cal: Calendar, now: Date) -> (Date, Date) {
        let today = cal.startOfDay(for: now)
        switch span {
        case .week:
            let start = cal.startOfWeek(for: now)
            return (start, cal.addingDays(15, to: start))
        case .upcoming:
            return (today, cal.addingDays(15, to: today))
        case .month:
            let grid = cal.monthGrid(for: now)
            let start = min(grid.first ?? today, today)
            let end = max(cal.addingDays(1, to: grid.last ?? today), cal.addingDays(15, to: today))
            return (start, end)
        }
    }

    func placeholder(in context: Context) -> WeekdotEntry {
        WeekdotEntry(date: Date(), items: [], firstWeekday: Calendar.current.firstWeekday)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekdotEntry) -> Void) {
        let cal = WidgetData.calendar
        let now = Date()
        let r = range(cal, now: now)
        let data = WidgetData.load(from: r.0, to: r.1)
        completion(WeekdotEntry(date: now, items: data.items, firstWeekday: data.firstWeekday, calendar: cal))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekdotEntry>) -> Void) {
        let cal = WidgetData.calendar
        let now = Date()
        let r = range(cal, now: now)
        let data = WidgetData.load(from: r.0, to: r.1)
        let paging = WidgetPager.state(kind: kind, family: context.family, now: now, calendar: cal)
        // Entries: now, every event start/end in the next 24 h, the next two midnights (date flips)
        // and the moment a scrolled list returns to its first page.
        var dates: Set<Date> = [now]
        let horizon = now.addingTimeInterval(24 * 3600)
        for item in data.items where !item.isAllDay {
            if item.start > now && item.start < horizon { dates.insert(item.start) }
            if item.end > now && item.end < horizon { dates.insert(item.end) }
        }
        let midnight = cal.addingDays(1, to: cal.startOfDay(for: now))
        dates.insert(midnight)
        dates.insert(cal.addingDays(1, to: midnight))
        if let paging { dates.insert(paging.until) }
        let entries = dates.sorted().prefix(40).map { d in
            WeekdotEntry(date: d, items: data.items, firstWeekday: data.firstWeekday,
                         page: paging.map { d < $0.until ? $0.page : 0 } ?? 0, calendar: cal)
        }
        let refresh = min(now.addingTimeInterval(30 * 60), midnight)
        completion(Timeline(entries: Array(entries), policy: .after(refresh)))
    }
}

/// Only needs the date: flips at midnight in the user's time zone.
struct DateProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekdotEntry { WeekdotEntry(date: Date(), items: [], firstWeekday: 2) }

    func getSnapshot(in context: Context, completion: @escaping (WeekdotEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekdotEntry>) -> Void) {
        let cal = Calendar.autoupdatingCurrent
        let now = Date()
        var entries = [WeekdotEntry(date: now, items: [], firstWeekday: cal.firstWeekday)]
        var d = cal.startOfDay(for: now)
        for _ in 0..<7 {
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            entries.append(WeekdotEntry(date: d, items: [], firstWeekday: cal.firstWeekday))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Today icon

struct TodayIconWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotTodayIcon", provider: DateProvider()) { entry in
            TodayIconView(entry: entry)
        }
        .configurationDisplayName(Text("Today"))
        .description(Text("The Weekdot icon with today's day and date."))
        .contentMarginsDisabled()
        .supportedFamilies(TodayIconWidget.families)
    }

    static var families: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .accessoryCircular, .accessoryInline]
        #else
        return [.systemSmall]
        #endif
    }
}

struct TodayIconView: View {
    let entry: WeekdotEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        switch family {
        #if os(iOS)
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .widgetAccentable()
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.system(size: 24, weight: .semibold))
            }
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
            .widgetURL(WidgetLink.today)
        case .accessoryInline:
            Text(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(WidgetLink.today)
        #endif
        default:
            WeekdotIconFace(date: entry.date, cornerFraction: 0)
                .containerBackground(for: .widget) { scheme == .dark ? Color.weekdotBlack : Color.white }
                .widgetURL(WidgetLink.today)
        }
    }
}

// MARK: - Up Next (small, medium, Lock Screen)

struct UpNextWidget: Widget {
    static let kind = "WeekdotUpNext"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: UpNextWidget.kind, provider: WeekdotProvider(kind: UpNextWidget.kind)) { entry in
            UpNextView(entry: entry)
        }
        .configurationDisplayName(Text("Up Next"))
        .description(Text("Your next events."))
        .supportedFamilies(UpNextWidget.families)
    }

    static var families: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]
        #else
        return [.systemSmall, .systemMedium]
        #endif
    }
}

struct UpNextView: View {
    let entry: WeekdotEntry
    @Environment(\.widgetFamily) private var family

    private var cal: Calendar { entry.calendar }
    private var today: Date { cal.startOfDay(for: entry.date) }
    private var upcoming: [DayEvent] { Agenda.upcoming(entry.items, now: entry.date, cal: cal) }

    var body: some View {
        switch family {
        #if os(iOS)
        case .accessoryRectangular:
            rectangular
                .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            inline
                .containerBackground(for: .widget) { Color.clear }
        #endif
        case .systemMedium:
            medium
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        default:
            small
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        }
    }

    // Small: date, then the next one or two events (or "No more events today" + tomorrow).
    private var small: some View {
        let list = upcoming
        let timedToday = list.filter { $0.day == today && !$0.item.isAllDay }
        let allDayToday = list.filter { $0.day == today && $0.item.isAllDay }
        let tomorrow = cal.addingDays(1, to: today)
        let firstTomorrow = list.first { $0.day == tomorrow && !$0.item.isAllDay } ?? list.first { $0.day == tomorrow }
        let target = timedToday.first ?? allDayToday.first ?? firstTomorrow
        return VStack(alignment: .leading, spacing: 4) {
            WidgetDateHeader(date: entry.date, numberSize: 28)
            if timedToday.isEmpty {
                ForEach(allDayToday.prefix(2)) { e in WidgetAllDayPill(item: e.item) }
                Text("No more events today")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if allDayToday.isEmpty, let e = firstTomorrow {
                    if e.item.isAllDay {
                        WidgetDayHeader(day: e.day, today: today, cal: cal)
                        WidgetAllDayPill(item: e.item)
                    } else {
                        WidgetEventRow(item: e.item, prefix: String(localized: "Tomorrow"), showLocation: false)
                    }
                }
            } else {
                if timedToday.count == 1, let e = allDayToday.first { WidgetAllDayPill(item: e.item) }
                ForEach(timedToday.prefix(2)) { e in WidgetEventRow(item: e.item, showLocation: false) }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(target.map { WidgetLink.event($0) } ?? WidgetLink.today)
    }

    // Medium: date column on the left, paged list of upcoming events on the right.
    private var medium: some View {
        let list = upcoming
        let allDayToday = list.filter { $0.day == today && $0.item.isAllDay }
        let noMoreToday = !list.contains { $0.day == today && !$0.item.isAllDay }
        let pillCount = noMoreToday ? 1 : 2
        return HStack(alignment: .top, spacing: 12) {
            Link(destination: WidgetLink.today) {
                VStack(alignment: .leading, spacing: 4) {
                    WidgetDateHeader(date: entry.date, numberSize: 34)
                    Spacer(minLength: 0)
                    if noMoreToday {
                        Text("No more events today")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    ForEach(allDayToday.prefix(pillCount)) { e in WidgetAllDayPill(item: e.item) }
                    if allDayToday.count > pillCount {
                        Text("+\(allDayToday.count - pillCount) more")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(width: 96, alignment: .leading)
            WidgetAgendaList(entry: entry, kind: UpNextWidget.kind, headerForToday: false, skipTodayAllDay: true)
        }
    }

    #if os(iOS)
    // Lock Screen: the next event, like Apple's Up Next.
    private var nextEvent: DayEvent? {
        let list = upcoming
        return list.first { !$0.item.isAllDay } ?? list.first
    }

    private var rectangular: some View {
        Group {
            if let e = nextEvent {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1).frame(width: 2.5, height: 12).widgetAccentable()
                        Text(e.item.displayTitle).font(.headline).lineLimit(1)
                    }
                    Text(e.day == today ? Fmt.timeRange(e.item)
                         : Agenda.dayLabel(e.day, today: today, cal: cal) + " · " + Fmt.timeRange(e.item))
                        .font(.caption)
                        .lineLimit(1)
                    if let loc = e.item.location, !loc.isEmpty {
                        Text(loc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .widgetURL(WidgetLink.event(e))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Up Next").font(.headline).widgetAccentable()
                    Text("No events").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .widgetURL(WidgetLink.today)
            }
        }
    }

    private var inline: some View {
        Group {
            if let e = nextEvent {
                if e.item.isAllDay {
                    Text(e.item.displayTitle)
                } else if e.day == today {
                    Text(Fmt.time(e.item.start) + " " + e.item.displayTitle)
                } else {
                    Text(Agenda.dayLabel(e.day, today: today, cal: cal) + " " + Fmt.time(e.item.start) + " "
                         + e.item.displayTitle)
                }
            } else {
                Text("No events")
            }
        }
        .widgetURL(nextEvent.map { WidgetLink.event($0) } ?? WidgetLink.today)
    }
    #endif
}

// MARK: - List (large)

struct ListWidget: Widget {
    static let kind = "WeekdotList"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ListWidget.kind, provider: WeekdotProvider(kind: ListWidget.kind)) { entry in
            ListWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("List"))
        .description(Text("Your next events."))
        .supportedFamilies([.systemLarge])
    }
}

struct ListWidgetView: View {
    let entry: WeekdotEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Link(destination: WidgetLink.today) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    WidgetDateHeader(date: entry.date, numberSize: 30)
                    Text(entry.date.formatted(.dateTime.month(.wide)))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
            WidgetAgendaList(entry: entry, kind: ListWidget.kind, headerForToday: true)
        }
        .containerBackground(for: .widget) { Color("WidgetBackground") }
    }
}

// MARK: - Month

struct MonthWidget: Widget {
    static let kind = "WeekdotMonth"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: MonthWidget.kind,
                            provider: WeekdotProvider(kind: MonthWidget.kind, span: .month)) { entry in
            MonthWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("Month"))
        .description(Text("This month at a glance."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MonthWidgetView: View {
    let entry: WeekdotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemLarge:
                VStack(alignment: .leading, spacing: 6) {
                    Link(destination: WidgetLink.month) { grid(large: true) }
                        .frame(height: 170)
                    Divider()
                    WidgetAgendaList(entry: entry, kind: MonthWidget.kind, headerForToday: true)
                }
            case .systemMedium:
                HStack(alignment: .top, spacing: 12) {
                    Link(destination: WidgetLink.month) { grid(large: false) }
                        .frame(width: 140)
                    WidgetAgendaList(entry: entry, kind: MonthWidget.kind, headerForToday: true)
                }
            default:
                grid(large: false)
                    .widgetURL(WidgetLink.month)
            }
        }
        .containerBackground(for: .widget) { Color("WidgetBackground") }
    }

    private func grid(large: Bool) -> some View {
        var cal = entry.calendar
        cal.firstWeekday = entry.firstWeekday
        let days = cal.monthGrid(for: entry.date)
        let busy = Agenda.busyDays(entry.items, from: days.first ?? entry.date,
                                   to: cal.addingDays(1, to: days.last ?? entry.date), cal: cal)
        return MiniMonthGrid(date: entry.date, cal: cal, days: days, busy: busy, large: large)
    }
}

/// Apple Calendar style month: red month name, weekday initials, today in a red circle, dots for busy days.
struct MiniMonthGrid: View {
    let date: Date
    let cal: Calendar
    let days: [Date]
    let busy: Set<Date>
    var large = false

    private static let titleHeight: CGFloat = 15
    private static let weekdayHeight: CGFloat = 13

    var body: some View {
        GeometryReader { geo in
            let weeks = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
            let rowHeight = max(8, (geo.size.height - MiniMonthGrid.titleHeight - MiniMonthGrid.weekdayHeight)
                                / CGFloat(max(1, weeks.count)))
            let cellWidth = geo.size.width / 7
            let diameter = min(rowHeight, cellWidth * 0.95, large ? 26 : 20)
            let month = cal.component(.month, from: date)
            let today = cal.startOfDay(for: date)
            VStack(alignment: .leading, spacing: 0) {
                Text(date.formatted(.dateTime.month(.wide)))
                    .textCase(.uppercase)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.weekdotRed)
                    .widgetAccentable()
                    .lineLimit(1)
                    .padding(.leading, max(0, (cellWidth - diameter) / 2))
                    .frame(height: MiniMonthGrid.titleHeight, alignment: .topLeading)
                HStack(spacing: 0) {
                    ForEach(Array(cal.orderedShortWeekdays(veryShort: true).enumerated()), id: \.offset) { _, s in
                        Text(s)
                            .font(.system(size: large ? 10 : 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: MiniMonthGrid.weekdayHeight)
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { day in
                            cell(day, inMonth: cal.component(.month, from: day) == month,
                                 isToday: day == today, diameter: diameter)
                        }
                    }
                    .frame(height: rowHeight)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func cell(_ day: Date, inMonth: Bool, isToday: Bool, diameter: CGFloat) -> some View {
        let dot = busy.contains(day) && !isToday
        Text(day.formatted(.dateTime.day()))
            .font(.system(size: max(8, diameter * 0.6), weight: isToday ? .bold : .medium))
            .minimumScaleFactor(0.7)
            .foregroundStyle(isToday ? Color.white : Color.primary)
            .frame(width: diameter, height: diameter)
            .background {
                if isToday { Circle().fill(Color.weekdotRed).widgetAccentable() }
            }
            .overlay(alignment: .bottom) {
                if dot {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: large ? 4 : 3, height: large ? 4 : 3)
                        .offset(y: large ? 3 : 2)
                }
            }
            .opacity(inMonth ? 1 : 0)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Week

struct WeekWidget: Widget {
    static let kind = "WeekdotWeek"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WeekWidget.kind, provider: WeekdotProvider(kind: WeekWidget.kind, span: .week)) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("Week"))
        .description(Text("Seven days at a glance."))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct WeekWidgetView: View {
    let entry: WeekdotEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        var cal = entry.calendar
        cal.firstWeekday = entry.firstWeekday
        let start = cal.startOfWeek(for: entry.date)
        let days = cal.days(from: start, count: 7)
        let maxItems = family == .systemLarge ? 9 : 3
        let today = cal.startOfDay(for: entry.date)
        return HStack(alignment: .top, spacing: 3) {
            ForEach(days, id: \.self) { day in
                let s = cal.startOfDay(for: day)
                let e = cal.addingDays(1, to: s)
                let items = entry.items
                    .filter { $0.overlaps(dayStart: s, dayEnd: e) }
                    .sorted { a, b in a.isAllDay != b.isAllDay ? a.isAllDay : a.start < b.start }
                let isToday = s == today
                Link(destination: WidgetLink.day(s)) {
                    VStack(spacing: 3) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday ? AnyShapeStyle(Color.weekdotRed) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                            .widgetAccentable(isToday)
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 13, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.white : .primary)
                            .frame(width: 22, height: 22)
                            .background { if isToday { Circle().fill(Color.weekdotRed).widgetAccentable() } }
                        ForEach(items.prefix(maxItems)) { item in
                            chip(item)
                        }
                        if items.count > maxItems {
                            Text("+\(items.count - maxItems)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(isToday ? Color.weekdotRed.opacity(0.07) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .containerBackground(for: .widget) { Color("WidgetBackground") }
    }

    private func chip(_ item: EventItem) -> some View {
        let full = renderingMode == .fullColor
        return Text(item.displayTitle)
            .font(.system(size: 9, weight: .medium))
            .lineLimit(family == .systemLarge ? 2 : 1)
            .foregroundStyle(full ? (ColorHex.isLight(item.colorHex) ? Color.black : Color.white) : Color.primary)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(full ? item.widgetColor : Color.primary.opacity(0.18)))
    }
}
