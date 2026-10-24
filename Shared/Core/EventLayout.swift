import Foundation

/// Positions timed events of one day side by side when they overlap.
struct LaidOutEvent: Identifiable {
    var item: EventItem
    var startMinutes: Int
    var endMinutes: Int
    var column: Int
    var columns: Int
    var id: String { item.id }
}

enum EventLayout {
    static func layout(_ items: [EventItem], day: Date, calendar: Calendar) -> [LaidOutEvent] {
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.addingDays(1, to: dayStart)
        var entries: [LaidOutEvent] = items
            .filter { !$0.isAllDay && $0.overlaps(dayStart: dayStart, dayEnd: dayEnd) }
            .map { item in
                let s = item.start < dayStart ? 0 : calendar.minutesSinceStartOfDay(item.start)
                let e = item.end >= dayEnd ? 24 * 60 : calendar.minutesSinceStartOfDay(item.end)
                return LaidOutEvent(item: item, startMinutes: s, endMinutes: max(e, s + 15), column: 0, columns: 1)
            }
            .sorted { ($0.startMinutes, -$0.endMinutes) < ($1.startMinutes, -$1.endMinutes) }

        var result: [LaidOutEvent] = []
        var cluster: [LaidOutEvent] = []
        var clusterEnd = -1

        func flush() {
            guard !cluster.isEmpty else { return }
            var columnEnds: [Int] = []
            for i in cluster.indices {
                if let col = columnEnds.firstIndex(where: { $0 <= cluster[i].startMinutes }) {
                    cluster[i].column = col
                    columnEnds[col] = cluster[i].endMinutes
                } else {
                    cluster[i].column = columnEnds.count
                    columnEnds.append(cluster[i].endMinutes)
                }
            }
            for i in cluster.indices { cluster[i].columns = columnEnds.count }
            result.append(contentsOf: cluster)
            cluster.removeAll()
        }

        for i in entries.indices {
            let e = entries[i]
            if e.startMinutes >= clusterEnd { flush(); clusterEnd = e.endMinutes }
            else { clusterEnd = max(clusterEnd, e.endMinutes) }
            cluster.append(e)
        }
        flush()
        entries = result
        return entries
    }
}
