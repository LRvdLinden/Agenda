import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Paging ("scrolling") with interactive buttons

/// Widgets cannot scroll, so the list widgets show pages of events. The current page is kept per widget
/// kind and size in the app group and falls back to the first page 10 minutes after the last tap or when
/// a new day starts.
enum WidgetPager {
    static let resetAfter: TimeInterval = 10 * 60

    static func familyKey(_ family: WidgetFamily) -> String { String(describing: family) }

    private static func key(_ kind: String, _ family: String) -> String { "weekdot.widgetPage.\(kind).\(family)" }

    /// The stored page and the moment it expires, or nil when the first page should be shown.
    static func state(kind: String, family: WidgetFamily, now: Date, calendar: Calendar) -> (page: Int, until: Date)? {
        let d = Weekdot.groupDefaults.dictionary(forKey: key(kind, familyKey(family)))
        guard let page = d?["page"] as? Int, page > 0, let t = d?["time"] as? Double else { return nil }
        let set = Date(timeIntervalSince1970: t)
        let nextMidnight = calendar.addingDays(1, to: calendar.startOfDay(for: set))
        let until = min(set.addingTimeInterval(resetAfter), nextMidnight)
        guard until > now else { return nil }
        return (page, until)
    }

    static func write(kind: String, family: String, page: Int) {
        Weekdot.groupDefaults.set(["page": max(0, page), "time": Date().timeIntervalSince1970],
                                  forKey: key(kind, family))
    }
}

/// Runs inside the widget extension when an arrow is tapped (does not open the app).
struct WidgetPageIntent: AppIntent {
    static let title: LocalizedStringResource = "Scroll to"
    static let openAppWhenRun: Bool = false
    static let isDiscoverable: Bool = false

    @Parameter(title: "Name") var kind: String
    @Parameter(title: "View") var family: String
    @Parameter(title: "Scroll to") var page: Int

    init() {}

    init(kind: String, family: String, page: Int) {
        self.kind = kind
        self.family = family
        self.page = page
    }

    func perform() async throws -> some IntentResult {
        WidgetPager.write(kind: kind, family: family, page: page)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        return .result()
    }
}

// MARK: - Agenda model

/// An event placed on the day where the widget lists it.
struct DayEvent: Identifiable, Hashable {
    let day: Date
    let item: EventItem
    var id: String { item.id + "@" + String(Int(day.timeIntervalSince1970)) }
}

enum AgendaRow: Identifiable, Hashable {
    case header(Date)
    case event(DayEvent)

    var id: String {
        switch self {
        case .header(let d): return "h" + String(Int(d.timeIntervalSince1970))
        case .event(let e): return e.id
        }
    }
}

/// Fixed row heights so the widget knows how many rows fit (Apple-style compact sizes).
enum AgendaMetrics {
    static let header: CGFloat = 20
    static let event: CGFloat = 33
    static let allDay: CGFloat = 22
    static let footer: CGFloat = 22
}

enum Agenda {
    /// Upcoming events from `now`: per day the all-day events first, then timed events that haven't ended.
    /// Events that started earlier are listed on today.
    static func upcoming(_ items: [EventItem], now: Date, cal: Calendar, days: Int = 14) -> [DayEvent] {
        let today = cal.startOfDay(for: now)
        let horizon = cal.addingDays(days, to: today)
        var seen = Set<String>()
        var out: [DayEvent] = []
        for item in items where !item.isCompleted && !seen.contains(item.id) {
            let current = item.isAllDay ? item.end > today : (item.end > now || item.start >= now)
            guard current, item.start < horizon else { continue }
            seen.insert(item.id)
            out.append(DayEvent(day: max(today, cal.startOfDay(for: item.start)), item: item))
        }
        return out.sorted { a, b in
            if a.day != b.day { return a.day < b.day }
            if a.item.isAllDay != b.item.isAllDay { return a.item.isAllDay }
            if a.item.start != b.item.start { return a.item.start < b.item.start }
            return a.item.title < b.item.title
        }
    }

    /// Splits the list into pages that fit `budget` points. Each page starts with a day header
    /// (except for today when `headerForToday` is false).
    static func paginate(_ list: [DayEvent], budget: CGFloat, today: Date, headerForToday: Bool) -> [[AgendaRow]] {
        var pages: [[AgendaRow]] = []
        var page: [AgendaRow] = []
        var used: CGFloat = 0
        var lastDay: Date?
        func cost(_ e: DayEvent, after last: Date?) -> CGFloat {
            let header = e.day != last && (headerForToday || e.day != today)
            return (header ? AgendaMetrics.header : 0) + (e.item.isAllDay ? AgendaMetrics.allDay : AgendaMetrics.event)
        }
        for e in list {
            if !page.isEmpty && used + cost(e, after: lastDay) > budget {
                pages.append(page)
                page = []
                used = 0
                lastDay = nil
            }
            used += cost(e, after: lastDay)
            if e.day != lastDay && (headerForToday || e.day != today) { page.append(.header(e.day)) }
            page.append(.event(e))
            lastDay = e.day
        }
        if !page.isEmpty { pages.append(page) }
        return pages
    }

    static func eventCount(_ rows: [AgendaRow]) -> Int {
        rows.reduce(0) { n, r in if case .event = r { return n + 1 } else { return n } }
    }

    /// Days in `range` that have at least one event (start of day).
    static func busyDays(_ items: [EventItem], from: Date, to: Date, cal: Calendar) -> Set<Date> {
        var days = Set<Date>()
        for item in items where item.end > from && item.start < to {
            var d = cal.startOfDay(for: max(item.start, from))
            let last = item.end > item.start ? item.end.addingTimeInterval(-1) : item.end
            var n = 0
            while d <= last && d < to && n < 45 {
                days.insert(d)
                d = cal.addingDays(1, to: d)
                n += 1
            }
        }
        return days
    }

    static func dayLabel(_ day: Date, today: Date, cal: Calendar) -> String {
        if day == today { return String(localized: "Today") }
        if day == cal.addingDays(1, to: today) { return String(localized: "Tomorrow") }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

enum WidgetLink {
    static func event(_ e: DayEvent) -> URL {
        var c = URLComponents()
        c.scheme = "weekdot"
        c.host = "event"
        c.queryItems = [URLQueryItem(name: "id", value: e.item.id),
                        URLQueryItem(name: "d", value: String(Int(e.day.timeIntervalSince1970)))]
        return c.url ?? today
    }

    static func day(_ d: Date) -> URL {
        URL(string: "weekdot://day?d=\(Int(d.timeIntervalSince1970))") ?? today
    }

    static let today = URL(string: "weekdot://today")!
    static let month = URL(string: "weekdot://month")!
}

// MARK: - Building blocks

extension EventItem {
    var widgetColor: Color { Color(hex: colorHex) ?? .weekdotRed }
}

/// Red weekday above a big day number, like Apple Calendar's widgets.
struct WidgetDateHeader: View {
    let date: Date
    var numberSize: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(date.formatted(.dateTime.weekday(.wide)))
                .textCase(.uppercase)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.weekdotRed)
                .widgetAccentable()
                .lineLimit(1)
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: numberSize, weight: .regular))
                .lineLimit(1)
        }
    }
}

/// Coloured calendar bar, title and "time · location".
struct WidgetEventRow: View {
    let item: EventItem
    var prefix: String? = nil
    var showLocation = true

    private var subtitle: String {
        var parts: [String] = []
        if let prefix { parts.append(prefix) }
        parts.append(Fmt.timeRange(item))
        if showLocation, let loc = item.location, !loc.isEmpty { parts.append(loc) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(item.widgetColor)
                .frame(width: 3.5)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(item.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .strikethrough(item.isDeclined)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 1.5)
        .frame(height: AgendaMetrics.event, alignment: .leading)
    }
}

/// All-day event as a coloured pill.
struct WidgetAllDayPill: View {
    let item: EventItem
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        let full = renderingMode == .fullColor
        Text(item.displayTitle)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .foregroundStyle(full ? (ColorHex.isLight(item.colorHex) ? Color.black : Color.white) : Color.primary)
            .padding(.horizontal, 7)
            .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(full ? item.widgetColor : Color.primary.opacity(0.18))
                    .widgetAccentable()
            }
            .frame(height: AgendaMetrics.allDay)
    }
}

struct WidgetDayHeader: View {
    let day: Date
    let today: Date
    let cal: Calendar

    var body: some View {
        Text(Agenda.dayLabel(day, today: today, cal: cal))
            .textCase(.uppercase)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(day == today ? AnyShapeStyle(Color.weekdotRed) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
            .widgetAccentable(day == today)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
            .frame(height: AgendaMetrics.header, alignment: .bottomLeading)
    }
}

/// Small up/down chevrons that page through the list.
struct WidgetPagerButtons: View {
    let kind: String
    let family: WidgetFamily
    let page: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: 6) {
            arrow("chevron.up", target: page - 1, enabled: page > 0, label: Text("Previous"))
            arrow("chevron.down", target: page + 1, enabled: page + 1 < pageCount, label: Text("Next"))
        }
    }

    @ViewBuilder
    private func arrow(_ symbol: String, target: Int, enabled: Bool, label: Text) -> some View {
        let icon = Image(systemName: symbol)
            .font(.system(size: 11, weight: .bold))
            .frame(width: 26, height: 20)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
        if enabled {
            Button(intent: WidgetPageIntent(kind: kind, family: WidgetPager.familyKey(family), page: target)) {
                icon.foregroundStyle(Color.weekdotRed)
            }
            .buttonStyle(.plain)
            .widgetAccentable()
            .accessibilityLabel(label)
        } else {
            icon.foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }
}

/// A list of upcoming events that fills the space it gets and pages with arrows when there is more.
struct WidgetAgendaList: View {
    let entry: WeekdotEntry
    let kind: String
    var headerForToday = true
    /// Leave today's all-day events out (they're shown elsewhere in the widget).
    var skipTodayAllDay = false
    /// Only today's events (the "Today's Events" widget).
    var todayOnly = false
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geo in
            content(height: geo.size.height)
        }
    }

    private func content(height: CGFloat) -> some View {
        let cal = entry.calendar
        let today = cal.startOfDay(for: entry.date)
        var list = Agenda.upcoming(entry.items, now: entry.date, cal: cal)
        if skipTodayAllDay { list.removeAll { $0.day == today && $0.item.isAllDay } }
        if todayOnly { list.removeAll { $0.day != today } }
        var pages = Agenda.paginate(list, budget: height, today: today, headerForToday: headerForToday)
        if pages.count > 1 {
            pages = Agenda.paginate(list, budget: height - AgendaMetrics.footer, today: today,
                                    headerForToday: headerForToday)
        }
        let page = min(max(0, entry.page), max(0, pages.count - 1))
        let rows = pages.isEmpty ? [] : pages[page]
        let shown = pages.prefix(page + 1).reduce(0) { $0 + Agenda.eventCount($1) }
        let remaining = list.count - shown
        return VStack(alignment: .leading, spacing: 0) {
            if rows.isEmpty {
                Text(list.isEmpty && !todayOnly ? LocalizedStringKey("No events") : LocalizedStringKey("No more events today"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            ForEach(rows) { row in
                switch row {
                case .header(let d):
                    WidgetDayHeader(day: d, today: today, cal: cal)
                case .event(let e):
                    Link(destination: WidgetLink.event(e)) {
                        if e.item.isAllDay {
                            WidgetAllDayPill(item: e.item)
                        } else {
                            WidgetEventRow(item: e.item)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if pages.count > 1 {
                HStack(spacing: 4) {
                    if remaining > 0 {
                        Text("+\(remaining) more")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    WidgetPagerButtons(kind: kind, family: family, page: page, pageCount: pages.count)
                }
                .frame(height: AgendaMetrics.footer, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
