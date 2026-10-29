import SwiftUI

extension CalendarStore {
    /// Moves an event and offers Undo.
    func moveUndoable(_ item: EventItem, toStart newStart: Date, state: AppState) {
        let oldStart = item.start
        guard move(item, toStart: newStart) else { return }
        var moved = item
        let duration = item.end.timeIntervalSince(item.start)
        moved.start = newStart
        moved.end = newStart.addingTimeInterval(duration)
        moved.id = item.eventIdentifier + "|" + String(Int(newStart.timeIntervalSince1970))
        state.offerUndo(String(localized: "Event moved")) { [weak self] in
            _ = self?.move(moved, toStart: oldStart)
        }
    }
}

/// Quick Add: type a sentence like "Lunch with Sam tomorrow at 1 pm" and Weekdot finds the date.
struct QuickAddView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    private var parsed: (title: String, start: Date, end: Date, allDay: Bool) {
        QuickAddParser.parse(text, fallback: state.suggestedStart(settings: synced.settings),
                             duration: synced.settings.defaultDurationMinutes, calendar: synced.settings.calendar)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Lunch with Sam tomorrow at 1 pm", text: $text, axis: .vertical)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(add)
                } footer: {
                    Text("Type what and when. Weekdot recognises dates and times.")
                }
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section {
                        let p = parsed
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.title.isEmpty ? String(localized: "New Event") : p.title).font(.headline)
                            Text(p.allDay
                                 ? p.start.formatted(date: .complete, time: .omitted) + " · " + String(localized: "All-day")
                                 : p.start.formatted(date: .complete, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(store.calendarTitle(store.defaultCalendarID))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("More Options…") {
                            let p = parsed
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                state.editor = EditorRequest(start: p.start, allDay: p.allDay)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Quick Add"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add).disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true } }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 300)
        #endif
    }

    private func add() {
        let p = parsed
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var d = LocalEventData()
        d.title = p.title.isEmpty ? String(localized: "New Event") : p.title
        d.isAllDay = p.allDay
        d.start = p.start
        d.end = p.allDay ? p.start : p.end
        let s = synced.settings
        if p.allDay { d.alarms = s.defaultAllDayAlarmMinutes.map { [$0] } ?? [] }
        else if s.defaultAlarmMinutes >= 0 { d.alarms = [s.defaultAlarmMinutes] }
        if store.saveEvent(d, calendarID: store.defaultCalendarID, existing: nil, span: .thisEvent) {
            state.date = p.start
            state.showToast(String(localized: "Event added"))
            dismiss()
        }
    }
}

enum QuickAddParser {
    static func parse(_ text: String, fallback: Date, duration: Int, calendar: Calendar)
        -> (title: String, start: Date, end: Date, allDay: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let match = detector.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let date = match.date,
              let range = Range(match.range, in: trimmed) else {
            return (trimmed, fallback, fallback.addingTimeInterval(TimeInterval(duration * 60)), false)
        }
        var title = trimmed
        title.removeSubrange(range)
        title = title.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let matched = String(trimmed[range])
        let h = calendar.component(.hour, from: date), m = calendar.component(.minute, from: date)
        let explicitTime = matched.range(of: #"\d{1,2}[:.h]\d{2}|\d\s?(am|pm|uur|u\b)|\b(at|om|um|à|a las)\s+\d"#,
                                         options: [.regularExpression, .caseInsensitive]) != nil
        // NSDataDetector uses 12:00 for dates without a time
        let hasTime = explicitTime || !((h == 12 || h == 0) && m == 0)
        if !hasTime {
            let day = calendar.startOfDay(for: date)
            return (title, day, day, true)
        }
        let dur = match.duration > 0 ? match.duration : TimeInterval(duration * 60)
        return (title, date, date.addingTimeInterval(dur), false)
    }
}

/// Date navigation shared by iPhone, iPad and Mac. The selected date is not
/// committed until the checkmark/Go button is pressed.
struct GoToDateView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var synced: SyncedStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                            .foregroundStyle(.secondary)
                    }
                    #if os(iOS)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    #else
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    #endif
                    HStack {
                        Text("Week")
                        Spacer()
                        Text("\(synced.settings.calendar.weekNumber(date))")
                    }
                    Button("Today") { date = Date() }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(Text("Go to Date"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        withAnimation { state.date = date }
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel(Text("Go"))
                }
            }
            .onAppear { date = state.date }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 400)
        #endif
    }
}
