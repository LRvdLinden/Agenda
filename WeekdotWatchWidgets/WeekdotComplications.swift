import WidgetKit
import SwiftUI
import EventKit

/// Apple Watch complications (watch face): next event, today's date and the week at a glance.
@main
struct WeekdotComplications: WidgetBundle {
    var body: some Widget {
        NextEventComplication()
        TodayScheduleComplication()
        CountdownComplication()
        RemainingTodayComplication()
        DateComplication()
        WeekNumberComplication()
        WeekComplication()
        ThreeWeeksComplication()
        LaunchComplication()
    }
}

// MARK: - Data

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let items: [EventItem]
    let firstWeekday: Int

    /// The event that is on now or comes next (timed events first, today's all-day events otherwise).
    var next: EventItem? {
        let timed = items.filter { !$0.isAllDay && $0.end > date }.sorted { $0.start < $1.start }
        if let t = timed.first { return t }
        return items.first { $0.isAllDay && Calendar.current.isDate($0.start, inSameDayAs: date) }
    }

    func count(on day: Date, calendar cal: Calendar) -> Int {
        let start = cal.startOfDay(for: day)
        let end = cal.addingDays(1, to: start)
        return items.filter { $0.overlaps(dayStart: start, dayEnd: end) }.count
    }
}

enum ComplicationData {
    static func load(from start: Date, days: Int) -> (items: [EventItem], firstWeekday: Int) {
        let settings = StyleBook.settingsFromGroup()
        let cal = settings.calendar
        let end = cal.addingDays(days, to: start)
        let snap = WidgetSnapshot.load()
        var items = (snap?.items ?? []).filter { $0.end > start && $0.start < end }
        // Apple Calendar events are read live on the watch when allowed; Weekdot's own events come from the
        // snapshot the watch app writes.
        if EventFetcher.hasFullAccess && (snap?.appleEnabled ?? settings.useAppleCalendar) {
            items = items.filter { $0.isLocal }
            let store = EKEventStore()
            items += EventFetcher.fetch(store: store, from: start, to: end,
                                        hidden: EventFetcher.hiddenCalendars(store: store, settings: settings),
                                        book: StyleBook.fromGroup(),
                                        showDeclined: settings.showDeclined)
        }
        items.sort { $0.start < $1.start }
        return (items, snap?.firstWeekday ?? cal.firstWeekday)
    }
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        let now = Date()
        let sample = EventItem(id: "sample", eventIdentifier: "sample", styleKey: "sample",
                               title: String(localized: "New Event"), location: nil,
                               start: now.addingTimeInterval(3600), end: now.addingTimeInterval(7200), isAllDay: false,
                               calendarID: "", calendarTitle: "", colorHex: "#E8352F", emoji: nil,
                               isRecurring: false, canEdit: false)
        return ComplicationEntry(date: now, items: [sample], firstWeekday: Calendar.current.firstWeekday)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        let cal = StyleBook.settingsFromGroup().calendar
        let data = ComplicationData.load(from: cal.startOfWeek(for: Date()), days: 14)
        completion(ComplicationEntry(date: Date(), items: data.items, firstWeekday: data.firstWeekday))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let cal = StyleBook.settingsFromGroup().calendar
        let now = Date()
        let data = ComplicationData.load(from: cal.startOfWeek(for: now), days: 14)
        // A new entry at every event start/end in the next day and at midnight, so "next" stays right.
        var dates: Set<Date> = [now]
        let horizon = now.addingTimeInterval(24 * 3600)
        for item in data.items where !item.isAllDay {
            if item.start > now && item.start < horizon { dates.insert(item.start) }
            if item.end > now && item.end < horizon { dates.insert(item.end) }
        }
        let midnight = cal.addingDays(1, to: cal.startOfDay(for: now))
        dates.insert(midnight)
        // Every 5 minutes for the next two hours, so countdown rings and "in 25 min" stay current.
        let step = cal.date(bySetting: .second, value: 0, of: now) ?? now
        for i in 1...24 { dates.insert(step.addingTimeInterval(TimeInterval(i * 300))) }
        let entries = dates.sorted().prefix(70).map {
            ComplicationEntry(date: $0, items: data.items, firstWeekday: data.firstWeekday)
        }
        completion(Timeline(entries: Array(entries), policy: .after(min(now.addingTimeInterval(30 * 60), midnight))))
    }
}

// MARK: - Next event

struct NextEventComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotNextEvent", provider: ComplicationProvider()) { entry in
            NextEventView(entry: entry)
        }
        .configurationDisplayName(Text("Up Next"))
        .description(Text("Your next events."))
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner])
    }
}

struct NextEventView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(URL(string: "weekdot://today"))
    }

    @ViewBuilder private var content: some View {
        let next = entry.next
        switch family {
        case .accessoryRectangular:
            if let e = next {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: e.colorHex) ?? .weekdotRed)
                        .frame(width: 4)
                        .widgetAccentable()
                    VStack(alignment: .leading, spacing: 1) {
                        Text(e.displayTitle)
                            .font(.headline)
                            .lineLimit(1)
                            .widgetAccentable()
                        Text(when(e))
                            .font(.caption)
                            .lineLimit(1)
                        if let loc = e.location, !loc.isEmpty {
                            Text(loc)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: "Weekdot").font(.headline).foregroundStyle(Color.weekdotRed).widgetAccentable()
                    Text("No events").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .accessoryInline:
            if let e = next {
                Text(e.isAllDay ? e.displayTitle : Fmt.time(e.start) + " " + e.displayTitle)
            } else {
                Text("No events")
            }
        case .accessoryCorner:
            Image(systemName: "calendar")
                .font(.title3)
                .widgetAccentable()
                .widgetLabel {
                    if let e = next {
                        Text(e.isAllDay ? e.displayTitle : Fmt.time(e.start) + " " + e.displayTitle)
                    } else {
                        Text("No events")
                    }
                }
        default: // circular: time of the next event, or the date
            ZStack {
                AccessoryWidgetBackground()
                if let e = next, !e.isAllDay {
                    VStack(spacing: 0) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .widgetAccentable()
                        Text(e.start, format: .dateTime.hour().minute())
                            .font(.system(size: 13, weight: .bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .padding(4)
                } else {
                    DayDateFace(date: entry.date)
                }
            }
        }
    }

    private func when(_ e: EventItem) -> String {
        if e.isAllDay { return String(localized: "All-day") }
        if e.start <= entry.date { return String(localized: "Now") + " – " + Fmt.time(e.end) }
        let cal = Calendar.current
        if cal.isDate(e.start, inSameDayAs: entry.date) { return Fmt.timeRange(e) }
        return e.start.formatted(.dateTime.weekday(.abbreviated)) + " " + Fmt.timeRange(e)
    }
}

// MARK: - Date

struct DateComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotDate", provider: ComplicationProvider()) { entry in
            DateComplicationView(entry: entry)
        }
        .configurationDisplayName(Text("Today"))
        .description(Text("Today's day and date."))
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct DayDateFace: View {
    let date: Date

    var body: some View {
        VStack(spacing: -2) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.weekdotRed)
                .widgetAccentable()
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 22, weight: .semibold))
        }
    }
}

struct DateComplicationView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) private var family

    private var cal: Calendar { Calendar.current }
    private func day(_ offset: Int) -> Date { cal.addingDays(offset, to: cal.startOfDay(for: entry.date)) }
    private func weekdayShort(_ d: Date) -> String {
        d.formatted(.dateTime.weekday(.abbreviated)).replacingOccurrences(of: ".", with: "").uppercased()
    }
    private func num(_ d: Date) -> String { d.formatted(.dateTime.day()) }

    /// A day number in a rounded tile (SF Symbol "23.square.fill"), like the tiles on Apple's Date complication.
    private func dayTile(_ offset: Int) -> Text {
        let n = cal.component(.day, from: day(offset))
        let tile = Text(Image(systemName: "\(n).square.fill"))
        return offset == 0
            ? tile.foregroundStyle(Color.white)
            : tile.foregroundStyle(Color.white.opacity(0.45))
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            case .accessoryCorner:
                // Same as Apple's Date complication: the weekday big in the corner, and yesterday · today ·
                // tomorrow as small number tiles along the edge, today always in the middle and brighter.
                Text(weekdayShort(entry.date))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .widgetLabel {
                        dayTile(-1) + Text(verbatim: " ") + dayTile(0) + Text(verbatim: " ") + dayTile(1)
                    }
            case .accessoryRectangular:
                // Five days with today in the middle, highlighted.
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.date.formatted(.dateTime.weekday(.wide).month(.wide)).capitalized)
                        .font(.headline)
                        .foregroundStyle(Color.weekdotRed)
                        .widgetAccentable()
                        .lineLimit(1)
                    HStack(spacing: 3) {
                        ForEach(-2...2, id: \.self) { i in
                            let d = day(i)
                            VStack(spacing: 1) {
                                Text(weekdayShort(d).prefix(2))
                                    .font(.system(size: 9, weight: .semibold))
                                Text(num(d))
                                    .font(.system(size: 15, weight: i == 0 ? .heavy : .medium, design: .rounded))
                            }
                            .foregroundStyle(i == 0 ? Color.white : Color.primary.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(i == 0 ? Color.weekdotRed : Color.white.opacity(0.12))
                                    .widgetAccentable(i == 0)
                            }
                        }
                    }
                }
            default:
                ZStack {
                    AccessoryWidgetBackground()
                    DayDateFace(date: entry.date)
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://today"))
    }
}

// MARK: - Week

/// Seven days with a dot per busy day — the Weekdot look on the watch face.
struct WeekComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotWeek", provider: ComplicationProvider()) { entry in
            WeekComplicationView(entry: entry)
        }
        .configurationDisplayName(Text("Week"))
        .description(Text("Seven days at a glance."))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct WeekComplicationView: View {
    let entry: ComplicationEntry

    private var weekCalendar: Calendar {
        var cal = StyleBook.settingsFromGroup().calendar
        cal.firstWeekday = entry.firstWeekday
        return cal
    }

    var body: some View {
        let cal = weekCalendar
        let days = cal.days(from: cal.startOfWeek(for: entry.date), count: 7)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.date.formatted(.dateTime.month(.wide))).font(.headline).widgetAccentable()
                Spacer()
                Text("Week \(cal.weekNumber(entry.date))").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let today = cal.isDate(day, inSameDayAs: entry.date)
                    let n = entry.count(on: day, calendar: cal)
                    VStack(spacing: 2) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 13, weight: today ? .heavy : .regular))
                            .foregroundStyle(today ? Color.weekdotRed : .primary)
                            .widgetAccentable(today)
                        Circle()
                            .fill(n > 0 ? Color.weekdotRed : Color.clear)
                            .frame(width: 5, height: 5)
                            .widgetAccentable()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://week"))
    }
}
