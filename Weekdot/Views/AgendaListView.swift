import SwiftUI

/// Agenda / list view: the coming 60 days, grouped per day.
struct AgendaListView: View {
    let from: Date

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState

    var body: some View {
        let cal = synced.settings.calendar
        let start = cal.startOfDay(for: from)
        let _ = store.revision
        let byDay = store.eventsByDay(from: start, days: 60, calendar: cal)
        let days = byDay.keys.sorted()
        Group {
            if days.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar",
                                       description: Text("Nothing planned in the next 60 days."))
            } else {
                List {
                    ForEach(days, id: \.self) { day in
                        Section {
                            ForEach(byDay[day] ?? []) { item in
                                EventRow(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture { state.detail = item }
                                    .contextMenu { EventContextMenu(item: item) }
                            }
                        } header: {
                            HStack {
                                Text(Fmt.dayTitle(day))
                                if cal.isDateInToday(day) {
                                    Text("Today").foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct EventRow: View {
    let item: EventItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: item.colorHex) ?? .accentColor)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .font(.body.weight(.medium))
                    .strikethrough(item.isDeclined)
                HStack(spacing: 6) {
                    Text(Fmt.timeRange(item))
                    if let loc = item.location {
                        Text("·")
                        Text(loc).lineLimit(1)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if item.isRecurring {
                Image(systemName: "repeat").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .frame(minHeight: 40)
    }
}
