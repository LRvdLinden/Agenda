import SwiftUI

/// Events the user hid in Weekdot (read-only events that were "deleted" or replaced by an edited copy).
/// Each one can be shown again.
struct HiddenEventsView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore

    private var entries: [HiddenEvent] {
        synced.hiddenEvents.values.sorted {
            ($0.start ?? .distantFuture, $0.title) < ($1.start ?? .distantFuture, $1.title)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title.isEmpty ? String(localized: "Event Series") : entry.title)
                                .font(.body)
                            if let start = entry.start {
                                Text(start.formatted(date: .abbreviated, time: .shortened))
                                    .font(.footnote).foregroundStyle(.secondary)
                            } else {
                                Text("All events in this series")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            if !entry.calendarTitle.isEmpty {
                                Text(entry.calendarTitle).font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Button("Show") { store.unhide(entry) }
                            .buttonStyle(.bordered)
                    }
                    .swipeActions {
                        Button("Show") { store.unhide(entry) }.tint(.accentColor)
                    }
                }
            } footer: {
                Text("Events you deleted from a read-only calendar, or replaced with an edited Weekdot copy, are hidden here. Show them to see them in your calendar again.")
            }
            if entries.count > 1 {
                Section {
                    Button("Show All") {
                        for e in entries { store.unhide(e) }
                    }
                }
            }
        }
        .navigationTitle("Hidden Events")
    }
}
