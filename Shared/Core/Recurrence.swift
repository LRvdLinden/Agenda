import Foundation
import EventKit

/// How an event repeats. Used for Weekdot's own events and mapped to/from EventKit rules.
struct RecurrenceSpec: Codable, Hashable {
    enum Frequency: String, Codable, CaseIterable, Identifiable {
        case daily, weekly, monthly, yearly
        var id: String { rawValue }
        var titleKey: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }

    enum MonthlyMode: String, Codable { case dayOfMonth, nthWeekday }

    var frequency: Frequency = .weekly
    var interval: Int = 1
    /// Weekdays for weekly repeats (1 = Sunday … 7 = Saturday). Empty = the event's own weekday.
    var weekdays: [Int] = []
    var monthlyMode: MonthlyMode = .dayOfMonth
    var endDate: Date? = nil
    var count: Int? = nil

    // MARK: Presets

    static let daily = RecurrenceSpec(frequency: .daily)
    static let weekly = RecurrenceSpec(frequency: .weekly)
    static let biweekly = RecurrenceSpec(frequency: .weekly, interval: 2)
    static let monthly = RecurrenceSpec(frequency: .monthly)
    static let yearly = RecurrenceSpec(frequency: .yearly)
    static let weekdaysOnly = RecurrenceSpec(frequency: .weekly, weekdays: [2, 3, 4, 5, 6])

    var isWeekdaysOnly: Bool { frequency == .weekly && interval == 1 && Set(weekdays) == Set([2, 3, 4, 5, 6]) }

    // MARK: Description

    func summary(calendar: Calendar = .current) -> String {
        var base: String
        switch (frequency, interval) {
        case (.daily, 1): base = String(localized: "Every Day")
        case (.weekly, 1) where isWeekdaysOnly: base = String(localized: "Every Weekday")
        case (.weekly, 1) where weekdays.count <= 1: base = String(localized: "Every Week")
        case (.weekly, 2) where weekdays.count <= 1: base = String(localized: "Every 2 Weeks")
        case (.monthly, 1): base = String(localized: "Every Month")
        case (.yearly, 1): base = String(localized: "Every Year")
        case (.daily, let n): base = String(localized: "Every \(n) days")
        case (.weekly, let n): base = n == 1 ? String(localized: "Every Week") : String(localized: "Every \(n) weeks")
        case (.monthly, let n): base = String(localized: "Every \(n) months")
        case (.yearly, let n): base = String(localized: "Every \(n) years")
        }
        if frequency == .weekly && weekdays.count > 1 && !isWeekdaysOnly {
            let names = weekdays.sorted { ((($0 - calendar.firstWeekday) + 7) % 7) < ((($1 - calendar.firstWeekday) + 7) % 7) }
                .map { calendar.shortWeekdaySymbols[$0 - 1] }
            base += " · " + names.joined(separator: ", ")
        }
        if let end = endDate {
            base += " · " + String(localized: "until \(end.formatted(date: .abbreviated, time: .omitted))")
        } else if let c = count {
            base += " · " + String(localized: "\(c) times")
        }
        return base
    }

    // MARK: EventKit

    init(frequency: Frequency = .weekly, interval: Int = 1, weekdays: [Int] = [], monthlyMode: MonthlyMode = .dayOfMonth,
         endDate: Date? = nil, count: Int? = nil) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.weekdays = weekdays
        self.monthlyMode = monthlyMode
        self.endDate = endDate
        self.count = count
    }

    init?(rule: EKRecurrenceRule?) {
        guard let r = rule else { return nil }
        switch r.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        @unknown default: frequency = .weekly
        }
        interval = max(1, r.interval)
        weekdays = (r.daysOfTheWeek ?? []).filter { $0.weekNumber == 0 }.map { $0.dayOfTheWeek.rawValue }
        monthlyMode = (r.frequency == .monthly && (r.daysOfTheWeek?.contains { $0.weekNumber != 0 } ?? false)) ? .nthWeekday : .dayOfMonth
        endDate = r.recurrenceEnd?.endDate
        let c = r.recurrenceEnd?.occurrenceCount ?? 0
        count = c > 0 ? c : nil
    }

    func ekRule(start: Date, calendar: Calendar = .current) -> EKRecurrenceRule {
        let end: EKRecurrenceEnd? = endDate.map { EKRecurrenceEnd(end: $0) } ?? count.map { EKRecurrenceEnd(occurrenceCount: $0) }
        let freq: EKRecurrenceFrequency
        switch frequency {
        case .daily: freq = .daily
        case .weekly: freq = .weekly
        case .monthly: freq = .monthly
        case .yearly: freq = .yearly
        }
        var days: [EKRecurrenceDayOfWeek]? = nil
        if frequency == .weekly, !weekdays.isEmpty {
            days = weekdays.compactMap { EKWeekday(rawValue: $0) }.map { EKRecurrenceDayOfWeek($0) }
        }
        if frequency == .monthly, monthlyMode == .nthWeekday {
            let wd = calendar.component(.weekday, from: start)
            let ordinal = calendar.component(.weekdayOrdinal, from: start)
            let week = ordinal >= 5 ? -1 : ordinal
            if let d = EKWeekday(rawValue: wd) { days = [EKRecurrenceDayOfWeek(d, weekNumber: week)] }
        }
        return EKRecurrenceRule(recurrenceWith: freq, interval: max(1, interval), daysOfTheWeek: days,
                                daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil,
                                daysOfTheYear: nil, setPositions: nil, end: end)
    }

    // MARK: Expansion (for Weekdot's own events)

    /// Start dates of all occurrences that may overlap [from, to).
    func occurrences(seriesStart: Date, duration: TimeInterval, from: Date, to: Date, excluded: Set<Date>,
                     calendar cal: Calendar) -> [Date] {
        var result: [Date] = []
        let windowStart = from.addingTimeInterval(-max(duration, 0))
        var produced = 0
        let limit = 3000
        let timeComps = cal.dateComponents([.hour, .minute, .second], from: seriesStart)

        func accept(_ d: Date) -> Bool {
            if let e = endDate, d > cal.date(bySettingHour: 23, minute: 59, second: 59, of: e) ?? e { return false }
            if let c = count, produced >= c { return false }
            return true
        }

        func emit(_ d: Date) {
            produced += 1
            if d >= windowStart && d < to && !excluded.contains(d) { result.append(d) }
        }

        switch frequency {
        case .daily:
            var i = 0
            while i < limit {
                guard let d = cal.date(byAdding: .day, value: interval * i, to: seriesStart) else { break }
                if d >= to { break }
                guard accept(d) else { break }
                emit(d)
                i += 1
            }
        case .weekly:
            let days = weekdays.isEmpty ? [cal.component(.weekday, from: seriesStart)] : weekdays
            let weekStart0 = cal.startOfWeek(for: seriesStart)
            var w = 0
            outer: while w < limit {
                guard let ws = cal.date(byAdding: .day, value: 7 * interval * w, to: weekStart0) else { break }
                if ws >= to { break }
                let ordered = days.sorted { ((($0 - cal.firstWeekday) + 7) % 7) < ((($1 - cal.firstWeekday) + 7) % 7) }
                for wd in ordered {
                    let offset = ((wd - cal.firstWeekday) + 7) % 7
                    guard let day = cal.date(byAdding: .day, value: offset, to: ws),
                          let d = cal.date(bySettingHour: timeComps.hour ?? 0, minute: timeComps.minute ?? 0,
                                           second: timeComps.second ?? 0, of: day) else { continue }
                    if d < seriesStart { continue }
                    if d >= to { break outer }
                    guard accept(d) else { break outer }
                    emit(d)
                }
                w += 1
            }
        case .monthly:
            let wd = cal.component(.weekday, from: seriesStart)
            let ordinal = cal.component(.weekdayOrdinal, from: seriesStart)
            let dayOfMonth = cal.component(.day, from: seriesStart)
            var i = 0
            while i < limit {
                guard let monthRef = cal.date(byAdding: .month, value: interval * i, to: cal.startOfMonth(for: seriesStart)) else { break }
                if monthRef >= to { break }
                var candidate: Date?
                if monthlyMode == .nthWeekday {
                    var comps = cal.dateComponents([.year, .month], from: monthRef)
                    comps.weekday = wd
                    comps.weekdayOrdinal = ordinal >= 5 ? -1 : ordinal
                    comps.hour = timeComps.hour; comps.minute = timeComps.minute; comps.second = timeComps.second
                    candidate = cal.date(from: comps)
                } else {
                    let days = cal.range(of: .day, in: .month, for: monthRef)?.count ?? 28
                    if dayOfMonth <= days {
                        var comps = cal.dateComponents([.year, .month], from: monthRef)
                        comps.day = dayOfMonth
                        comps.hour = timeComps.hour; comps.minute = timeComps.minute; comps.second = timeComps.second
                        candidate = cal.date(from: comps)
                    }
                }
                if let d = candidate, d >= seriesStart {
                    if d >= to { break }
                    guard accept(d) else { break }
                    emit(d)
                }
                i += 1
            }
        case .yearly:
            var i = 0
            while i < limit {
                guard let d = cal.date(byAdding: .year, value: interval * i, to: seriesStart) else { break }
                if d >= to { break }
                guard accept(d) else { break }
                emit(d)
                i += 1
            }
        }
        return result
    }
}
