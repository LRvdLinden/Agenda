import SwiftUI

struct YearView: View {
    let year: Date

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState

    var body: some View {
        let cal = synced.settings.calendar
        let start = cal.startOfYear(for: year)
        let dayCount = cal.range(of: .day, in: .year, for: start)?.count ?? 365
        let _ = store.revision
        let counts: [Date: Int] = synced.settings.showYearHeatmap
            ? store.eventsByDay(from: start, days: dayCount, calendar: cal).mapValues(\.count)
            : [:]
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 18)], spacing: 22) {
                ForEach(0..<12, id: \.self) { m in
                    let monthDate = cal.date(byAdding: .month, value: m, to: start) ?? start
                    MiniMonthView(month: monthDate, counts: counts)
                        .contentShape(Rectangle())
                        .onTapGesture { state.open(day: monthDate, mode: .month) }
                }
            }
            .padding(16)
        }
    }
}

struct MiniMonthView: View {
    let month: Date
    let counts: [Date: Int]
    @EnvironmentObject private var synced: SyncedStore

    var body: some View {
        let cal = synced.settings.calendar
        let grid = cal.monthGrid(for: month)
        let isCurrentMonth = cal.isDate(month, equalTo: Date(), toGranularity: .month)
        VStack(alignment: .leading, spacing: 6) {
            Text(month.formatted(.dateTime.month(.wide)))
                .font(.headline)
                .foregroundStyle(isCurrentMonth ? Color.accentColor : .primary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(Array(cal.orderedShortWeekdays(veryShort: true).enumerated()), id: \.offset) { _, s in
                    Text(s).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                }
                ForEach(grid, id: \.self) { day in
                    let inMonth = cal.isDate(day, equalTo: month, toGranularity: .month)
                    let isToday = cal.isDateInToday(day)
                    let n = counts[cal.startOfDay(for: day)] ?? 0
                    Text(inMonth ? day.formatted(.dateTime.day()) : "")
                        .font(.system(size: 10, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? Color.white : .primary)
                        .frame(maxWidth: .infinity, minHeight: 18)
                        .background {
                            if inMonth {
                                if isToday {
                                    Circle().fill(Color.accentColor)
                                } else if n > 0 {
                                    Circle().fill(Color.accentColor.opacity(min(0.12 + Double(n) * 0.1, 0.55)))
                                }
                            }
                        }
                }
            }
        }
    }
}
