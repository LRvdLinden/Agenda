import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let day = startOfDay(for: date)
        let wd = component(.weekday, from: day)
        let diff = (wd - firstWeekday + 7) % 7
        return self.date(byAdding: .day, value: -diff, to: day) ?? day
    }

    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }

    func startOfYear(for date: Date) -> Date {
        self.date(from: dateComponents([.year], from: date)) ?? startOfDay(for: date)
    }

    func addingDays(_ n: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: n, to: date) ?? date
    }

    func days(from start: Date, count: Int) -> [Date] {
        (0..<max(0, count)).map { addingDays($0, to: start) }
    }

    /// The 6×7 (or 5×7) grid of days shown for a month.
    func monthGrid(for date: Date) -> [Date] {
        let first = startOfMonth(for: date)
        let gridStart = startOfWeek(for: first)
        let daysInMonth = range(of: .day, in: .month, for: first)?.count ?? 30
        let lead = dayDistance(from: gridStart, to: first)
        let weeks = Int(ceil(Double(lead + daysInMonth) / 7.0))
        return days(from: gridStart, count: max(5, weeks) * 7)
    }

    func dayDistance(from a: Date, to b: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: a), to: startOfDay(for: b)).day ?? 0
    }

    func isWeekend(_ date: Date) -> Bool { isDateInWeekend(date) }

    func weekNumber(_ date: Date) -> Int { component(.weekOfYear, from: date) }

    /// Weekday symbols ordered to start at `firstWeekday`.
    func orderedShortWeekdays(veryShort: Bool = false) -> [String] {
        let symbols = veryShort ? veryShortStandaloneWeekdaySymbols : shortStandaloneWeekdaySymbols
        return (0..<7).map { symbols[(firstWeekday - 1 + $0) % 7] }
    }

    func minutesSinceStartOfDay(_ date: Date) -> Int {
        let c = dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    func date(on day: Date, minutes: Int) -> Date {
        self.date(byAdding: .minute, value: minutes, to: startOfDay(for: day)) ?? day
    }
}

enum Fmt {
    static func time(_ d: Date) -> String { d.formatted(date: .omitted, time: .shortened) }

    static func timeRange(_ e: EventItem) -> String {
        if e.isAllDay { return String(localized: "All-day") }
        return "\(time(e.start)) – \(time(e.end))"
    }

    static func dayTitle(_ d: Date) -> String {
        d.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    static func monthYear(_ d: Date) -> String {
        d.formatted(.dateTime.month(.wide).year())
    }

    static func hourLabel(_ hour: Int) -> String {
        var c = DateComponents()
        c.hour = hour
        let d = Calendar.current.date(from: c) ?? Date()
        return d.formatted(.dateTime.hour())
    }

    static func duration(minutes: Int) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = minutes >= 60 ? [.hour, .minute] : [.minute]
        f.unitsStyle = .abbreviated
        return f.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)m"
    }

    /// Alerts of all-day events: negative = on the day at that time, positive = days before at a time.
    static func allDayAlarm(minutes: Int) -> String {
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: Date())
        if minutes <= 0 {
            let t = time(midnight.addingTimeInterval(TimeInterval(-minutes * 60)))
            return String(localized: "On day of event (\(t))")
        }
        let days = Int(ceil(Double(minutes) / 1440))
        let t = time(midnight.addingTimeInterval(TimeInterval((days * 1440 - minutes) * 60)))
        if days == 1 { return String(localized: "1 day before (\(t))") }
        if days == 7 { return String(localized: "1 week before (\(t))") }
        return String(localized: "\(days) days before (\(t))")
    }

    static func alarm(minutes: Int) -> String {
        if minutes == 0 { return String(localized: "At time of event") }
        let f = DateComponentsFormatter()
        f.allowedUnits = [.day, .hour, .minute]
        f.unitsStyle = .full
        f.maximumUnitCount = 2
        let s = f.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
        return String(localized: "\(s) before")
    }
}
