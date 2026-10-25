import WidgetKit
import SwiftUI

// More complications, matching what Apple Calendar and other calendar apps offer on the watch face:
// today's schedule, a countdown to the next event, what's left today, the week number, three weeks at a
// glance and a plain Weekdot launcher. Every one also works in the Smart Stack.

extension ComplicationEntry {
    /// Higher in the Smart Stack shortly before and during an event.
    var relevance: TimelineEntryRelevance? {
        guard let e = next, !e.isAllDay else { return TimelineEntryRelevance(score: 5) }
        let minutes = e.start.timeIntervalSince(date) / 60
        if minutes <= 0 { return TimelineEntryRelevance(score: 80, duration: e.end.timeIntervalSince(date)) }
        if minutes <= 60 { return TimelineEntryRelevance(score: 100, duration: e.start.timeIntervalSince(date)) }
        return TimelineEntryRelevance(score: 20)
    }

    var calendar: Calendar {
        var cal = StyleBook.settingsFromGroup().calendar
        cal.firstWeekday = firstWeekday
        return cal
    }

    /// Today's events that haven't ended yet (timed), in order.
    var remainingToday: [EventItem] {
        let cal = calendar
        let start = cal.startOfDay(for: date)
        let end = cal.addingDays(1, to: start)
        return items.filter { $0.overlaps(dayStart: start, dayEnd: end) && ($0.isAllDay || $0.end > date) }
            .sorted { a, b in
                if a.isAllDay != b.isAllDay { return !a.isAllDay }
                return a.start < b.start
            }
    }

    var todayTotal: Int { count(on: date, calendar: calendar) }

    /// Minutes until the next timed event starts (0 while it is on), nil without one.
    var minutesToNext: Int? {
        guard let e = next, !e.isAllDay else { return nil }
        return max(0, Int((e.start.timeIntervalSince(date) / 60).rounded(.up)))
    }
}

/// "25m", "1h 10m", "Now".
private func shortCountdown(_ minutes: Int) -> String {
    if minutes <= 0 { return String(localized: "Now") }
    if minutes < 60 { return "\(minutes)m" }
    let h = minutes / 60, m = minutes % 60
    return m == 0 ? "\(h)h" : "\(h)h \(m)m"
}

// MARK: - Today's schedule

struct TodayScheduleComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotTodaySchedule", provider: ComplicationProvider()) { entry in
            TodayScheduleView(entry: entry)
        }
        .configurationDisplayName(Text("Day"))
        .description(Text("Your next events."))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct TodayScheduleView: View {
    let entry: ComplicationEntry

    var body: some View {
        let list = Array(entry.remainingToday.prefix(3))
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated).day()).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.weekdotRed)
                    .widgetAccentable()
                Spacer(minLength: 0)
                if !list.isEmpty {
                    Text("\(entry.remainingToday.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            if list.isEmpty {
                Text("No more events today")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(list) { e in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: e.colorHex) ?? .weekdotRed)
                            .frame(width: 5, height: 5)
                            .widgetAccentable()
                        Text(e.isAllDay ? String(localized: "All-day") : Fmt.time(e.start))
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                        Text(e.displayTitle)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://today"))
    }
}

// MARK: - Countdown

struct CountdownComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotCountdown", provider: ComplicationProvider()) { entry in
            CountdownView(entry: entry)
        }
        .configurationDisplayName(Text("Countdown"))
        .description(Text("Time until your next event, with a ring that fills up in the last hour."))
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct CountdownView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let m = entry.minutesToNext
        let progress = m.map { 1 - min(60, Double($0)) / 60 } ?? 0
        let tint = Color(hex: entry.next?.colorHex) ?? .weekdotRed
        Group {
            switch family {
            case .accessoryInline:
                if let e = entry.next, let m {
                    Text(shortCountdown(m) + " · " + e.displayTitle)
                } else {
                    Text("No events")
                }
            case .accessoryCorner:
                Text(m.map(shortCountdown) ?? "–")
                    .font(.system(size: 18, weight: .semibold))
                    .widgetCurvesContent()
                    .widgetLabel {
                        Gauge(value: progress) { Text(entry.next?.displayTitle ?? "") }
                            .tint(tint)
                    }
            default:
                Gauge(value: progress) {
                    Image(systemName: "calendar")
                } currentValueLabel: {
                    Text(m.map(shortCountdown) ?? "–")
                        .minimumScaleFactor(0.5)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(tint)
                .widgetAccentable()
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://today"))
    }
}

// MARK: - Remaining today

struct RemainingTodayComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotRemaining", provider: ComplicationProvider()) { entry in
            RemainingTodayView(entry: entry)
        }
        .configurationDisplayName(Text("Remaining Today"))
        .description(Text("How many events are still to come today."))
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct RemainingTodayView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let leftCount = entry.remainingToday.count
        let totalCount = max(entry.todayTotal, leftCount)
        let done = totalCount == 0 ? 1 : Double(totalCount - leftCount) / Double(totalCount)
        Group {
            switch family {
            case .accessoryInline:
                Text("\(Int(leftCount)) of \(Int(totalCount)) events left")
            case .accessoryCorner:
                Text("\(leftCount)")
                    .font(.system(size: 20, weight: .semibold))
                    .widgetLabel {
                        Gauge(value: done) { Text("Today") }
                            .tint(Color.weekdotRed)
                    }
            default:
                Gauge(value: done) {
                    Text("Today")
                } currentValueLabel: {
                    Text("\(leftCount)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(Color.weekdotRed)
                .widgetAccentable()
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://today"))
    }
}

// MARK: - Week number

struct WeekNumberComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotWeekNumber", provider: ComplicationProvider()) { entry in
            WeekNumberView(entry: entry)
        }
        .configurationDisplayName(Text("Week Number"))
        .description(Text("The current week number."))
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct WeekNumberView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let n = entry.calendar.weekNumber(entry.date)
        Group {
            switch family {
            case .accessoryInline:
                Text("Week \(n)")
            case .accessoryCorner:
                Text("\(n)")
                    .font(.system(size: 22, weight: .semibold))
                    .widgetLabel { Text("Week \(n)") }
            default:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: -2) {
                        Text("Week")
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.weekdotRed)
                            .widgetAccentable()
                        Text("\(n)")
                            .font(.system(size: 22, weight: .semibold))
                    }
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://week"))
    }
}

// MARK: - Three weeks

struct ThreeWeeksComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotThreeWeeks", provider: ComplicationProvider()) { entry in
            ThreeWeeksView(entry: entry)
        }
        .configurationDisplayName(Text("Three Weeks"))
        .description(Text("This week and the next two, darker on busier days."))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct ThreeWeeksView: View {
    let entry: ComplicationEntry

    var body: some View {
        let cal = entry.calendar
        let start = cal.startOfWeek(for: entry.date)
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text(verbatim: "").frame(width: 16)
                ForEach(cal.days(from: start, count: 7), id: \.self) { d in
                    Text(d.formatted(.dateTime.weekday(.narrow)))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<3, id: \.self) { w in
                let weekStart = cal.addingDays(w * 7, to: start)
                HStack(spacing: 2) {
                    Text("\(cal.weekNumber(weekStart))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, alignment: .leading)
                    ForEach(cal.days(from: weekStart, count: 7), id: \.self) { d in
                        let n = entry.count(on: d, calendar: cal)
                        let today = cal.isDate(d, inSameDayAs: entry.date)
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.weekdotRed.opacity(n == 0 ? 0.12 : min(1, 0.3 + Double(n) * 0.18)))
                                .widgetAccentable()
                            Text(d.formatted(.dateTime.day()))
                                .font(.system(size: 9, weight: today ? .heavy : .regular))
                                .foregroundStyle(n >= 3 ? Color.white : .primary)
                        }
                        .overlay {
                            if today { RoundedRectangle(cornerRadius: 3).stroke(Color.primary, lineWidth: 1) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://week"))
    }
}

// MARK: - Launcher

struct LaunchComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekdotLaunch", provider: ComplicationProvider()) { entry in
            LaunchView(entry: entry)
        }
        .configurationDisplayName(Text(verbatim: "Weekdot"))
        .description(Text("Open Weekdot from your watch face."))
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

struct LaunchView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .accessoryCorner {
                dots(size: 4)
                    .widgetLabel { Text(verbatim: "Weekdot") }
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 3) {
                        dots(size: 4)
                        Text(entry.date.formatted(.dateTime.day()))
                            .font(.system(size: 18, weight: .bold))
                    }
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "weekdot://today"))
    }

    /// The seven Weekdot dots, today's one larger.
    private func dots(size: CGFloat) -> some View {
        let cal = entry.calendar
        let index = (cal.component(.weekday, from: entry.date) - cal.firstWeekday + 7) % 7
        return HStack(spacing: size * 0.6) {
            ForEach(0..<7, id: \.self) { i in
                Circle()
                    .fill(Color.weekdotRed)
                    .frame(width: i == index ? size * 1.6 : size, height: i == index ? size * 1.6 : size)
            }
        }
        .widgetAccentable()
    }
}
