import WidgetKit
import SwiftUI
import EventKit

@main
struct WeekdotWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayIconWidget()
        UpNextWidget()
        WeekWidget()
    }
}

// MARK: - Data

struct WeekdotEntry: TimelineEntry {
    let date: Date
    let items: [EventItem]
    let firstWeekday: Int
}

enum WidgetData {
    static func load(from start: Date, days: Int) -> (items: [EventItem], firstWeekday: Int) {
        let settings = StyleBook.settingsFromGroup()
        let cal = settings.calendar
        let end = cal.addingDays(days, to: start)
        if EventFetcher.hasFullAccess {
            let store = EKEventStore()
            let items = EventFetcher.fetch(store: store, from: start, to: end,
                                           hidden: Set(settings.hiddenCalendarIDs), book: StyleBook.fromGroup(),
                                           showDeclined: settings.showDeclined)
            return (items, cal.firstWeekday)
        }
        let snap = WidgetSnapshot.load()
        let items = (snap?.items ?? []).filter { $0.end > start && $0.start < end }
        return (items, snap?.firstWeekday ?? cal.firstWeekday)
    }

    static var calendar: Calendar { StyleBook.settingsFromGroup().calendar }
}

struct WeekdotProvider: TimelineProvider {
    var days: Int = 8

    func placeholder(in context: Context) -> WeekdotEntry {
        WeekdotEntry(date: Date(), items: [], firstWeekday: Calendar.current.firstWeekday)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekdotEntry) -> Void) {
        let cal = WidgetData.calendar
        let data = WidgetData.load(from: cal.startOfWeek(for: Date()), days: days + 7)
        completion(WeekdotEntry(date: Date(), items: data.items, firstWeekday: data.firstWeekday))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekdotEntry>) -> Void) {
        let cal = WidgetData.calendar
        let now = Date()
        let data = WidgetData.load(from: cal.startOfWeek(for: now), days: days + 7)
        // entries: now, every event start/end in the next 24 h, and the next two midnights (date flips)
        var dates: Set<Date> = [now]
        let horizon = now.addingTimeInterval(24 * 3600)
        for item in data.items where !item.isAllDay {
            if item.start > now && item.start < horizon { dates.insert(item.start) }
            if item.end > now && item.end < horizon { dates.insert(item.end) }
        }
        let midnight = cal.addingDays(1, to: cal.startOfDay(for: now))
        dates.insert(midnight)
        dates.insert(cal.addingDays(1, to: midnight))
        let entries = dates.sorted().prefix(40).map {
            WeekdotEntry(date: $0, items: data.items, firstWeekday: data.firstWeekday)
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
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.system(size: 24, weight: .heavy))
            }
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryInline:
            Text(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .containerBackground(for: .widget) { Color.clear }
        #endif
        default:
            WeekdotIconFace(date: entry.date, cornerFraction: 0)
                .containerBackground(for: .widget) { scheme == .dark ? Color.weekdotBlack : Color.white }
                .widgetURL(URL(string: "weekdot://today"))
        }
    }
}

// MARK: - Up next

struct UpNextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotUpNext", provider: WeekdotProvider(days: 8)) { entry in
            UpNextView(entry: entry)
        }
        .configurationDisplayName(Text("Up Next"))
        .description(Text("Your next events."))
        .supportedFamilies(UpNextWidget.families)
    }

    static var families: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .systemMedium, .accessoryRectangular]
        #else
        return [.systemSmall, .systemMedium]
        #endif
    }
}

struct UpNextView: View {
    let entry: WeekdotEntry
    @Environment(\.widgetFamily) private var family

    private var upcoming: [EventItem] {
        let cal = Calendar.autoupdatingCurrent
        let endOfTomorrow = cal.addingDays(2, to: cal.startOfDay(for: entry.date))
        return entry.items
            .filter { $0.end > entry.date && $0.start < endOfTomorrow }
            .sorted { a, b in
                if a.isAllDay != b.isAllDay { return !a.isAllDay && cal.isDateInToday(a.start) }
                return a.start < b.start
            }
    }

    var body: some View {
        Group {
            #if os(iOS)
            if family == .accessoryRectangular {
                if let next = upcoming.first {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(next.displayTitle).font(.headline).lineLimit(1)
                        Text(Fmt.timeRange(next)).font(.caption)
                        if let loc = next.location { Text(loc).font(.caption).lineLimit(1) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No more events today").font(.caption)
                }
            } else {
                list
            }
            #else
            list
            #endif
        }
        .containerBackground(for: .widget) { Color("WidgetBackground") }
        .widgetURL(URL(string: "weekdot://today"))
    }

    private var list: some View {
        let max = family == .systemSmall ? 3 : 4
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.weekdotRed)
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.weekdotRed)
                Spacer()
            }
            if upcoming.isEmpty {
                Text("No more events today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(upcoming.prefix(max)) { item in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(hex: item.colorHex) ?? .weekdotRed)
                        .frame(width: 3)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.displayTitle).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Text(Calendar.autoupdatingCurrent.isDateInToday(item.start) || item.start < entry.date
                             ? Fmt.timeRange(item)
                             : String(localized: "Tomorrow") + " · " + Fmt.timeRange(item))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(height: 28)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Week

struct WeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotWeek", provider: WeekdotProvider(days: 8)) { entry in
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

    var body: some View {
        var cal = Calendar.autoupdatingCurrent
        cal.firstWeekday = entry.firstWeekday
        let start = cal.startOfWeek(for: entry.date)
        let days = cal.days(from: start, count: 7)
        let maxItems = family == .systemLarge ? 9 : 3
        return HStack(alignment: .top, spacing: 3) {
            ForEach(days, id: \.self) { day in
                let s = cal.startOfDay(for: day)
                let e = cal.addingDays(1, to: s)
                let items = entry.items.filter { $0.overlaps(dayStart: s, dayEnd: e) }
                let isToday = cal.isDateInToday(day)
                Link(destination: URL(string: "weekdot://day?d=\(Int(s.timeIntervalSince1970))")!) {
                    VStack(spacing: 3) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday ? Color.weekdotRed : .secondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 13, weight: isToday ? .heavy : .medium))
                            .foregroundStyle(isToday ? Color.white : .primary)
                            .frame(width: 22, height: 22)
                            .background { if isToday { Circle().fill(Color.weekdotRed) } }
                        ForEach(items.prefix(maxItems)) { item in
                            Text(item.displayTitle)
                                .font(.system(size: 9, weight: .medium))
                                .lineLimit(family == .systemLarge ? 2 : 1)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color(hex: item.colorHex) ?? .weekdotRed))
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
                    .background(isToday ? Color.weekdotRed.opacity(0.07) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .containerBackground(for: .widget) { Color("WidgetBackground") }
    }
}
