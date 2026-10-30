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

    @State private var pickingWeek = false

    private var selectedWeek: Binding<Int> {
        Binding(get: { synced.settings.calendar.component(.weekOfYear, from: date) },
                set: { week in
                    let calendar = synced.settings.calendar
                    let year = calendar.component(.yearForWeekOfYear, from: date)
                    let weekday = calendar.component(.weekday, from: date)
                    var components = DateComponents()
                    components.yearForWeekOfYear = year
                    components.weekOfYear = week
                    components.weekday = weekday
                    if let chosen = calendar.date(from: components),
                       calendar.component(.weekOfYear, from: chosen) == week {
                        date = chosen
                    }
                })
    }

    private var numberOfWeeks: Int {
        let calendar = synced.settings.calendar
        let year = calendar.component(.yearForWeekOfYear, from: date)
        var components = DateComponents()
        components.yearForWeekOfYear = year
        components.weekOfYear = 1
        components.weekday = calendar.firstWeekday
        guard let first = calendar.date(from: components),
              let range = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: first) else { return 52 }
        return range.count
    }

    var body: some View {
        NavigationStack {
            #if os(macOS)
            macDateContent
                .navigationTitle(Text("Go to Date"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button { confirm() } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                        }
                        .accessibilityLabel(Text("Go"))
                    }
                }
            #else
            Form {
                Section {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                            .foregroundStyle(.secondary)
                    }
                    if pickingWeek {
                        Picker("Week", selection: selectedWeek) {
                            ForEach(1...numberOfWeeks, id: \.self) { week in
                                Text("Week \(week)").tag(week)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Text("Week"))
                    } else {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                    Button {
                        withAnimation { pickingWeek.toggle() }
                    } label: {
                        HStack {
                            Text("Week")
                            Spacer()
                            Text("\(synced.settings.calendar.weekNumber(date))")
                            Image(systemName: pickingWeek ? "checkmark.circle.fill" : "chevron.up.chevron.down")
                                .font(.footnote)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Select a week number"))
                    Button("Today") { date = Date() }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(Text("Go to Date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { confirm() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel(Text("Go"))
                }
            }
            #endif
        }
        .onAppear { date = state.date }
        #if os(macOS)
        .frame(minWidth: 690, idealWidth: 850, minHeight: 300, idealHeight: 335)
        #endif
    }

    private func confirm() {
        withAnimation { state.date = date }
        dismiss()
    }

    #if os(macOS)
    private var macDateContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Text("Go to Date").font(.headline)
                Spacer()
                Button { confirm() } label: {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(Text("Go"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            VStack(spacing: 0) {
                HStack {
                    Text("Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                Divider().padding(.horizontal, 14).padding(.top, 8)
                HStack(alignment: .center, spacing: 4) {
                    macWheel(.day)
                    macWheel(.month)
                    macWheel(.year)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                Divider().padding(.horizontal, 14)
                HStack {
                    Text("Week")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        pickingWeek.toggle()
                    } label: {
                        Text("\(synced.settings.calendar.weekNumber(date))")
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption)
                .padding(14)
                if pickingWeek {
                    Picker("Week", selection: selectedWeek) {
                        ForEach(1...numberOfWeeks, id: \.self) { week in
                            Text("Week \(week)").tag(week)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
            .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 13))
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Button("Today") { date = Date() }
                .buttonStyle(.bordered)
                .padding(.top, 10)
            Spacer(minLength: 8)
        }
    }

    private enum WheelPart { case day, month, year }

    private func macWheel(_ part: WheelPart) -> some View {
        VStack(spacing: 0) {
            ForEach(-2...2, id: \.self) { offset in
                Button {
                    if offset != 0 { shift(part, by: offset) }
                } label: {
                    Text(wheelText(part, offset: offset))
                        .font(.system(size: offset == 0 ? 16 : 13, weight: offset == 0 ? .semibold : .regular))
                        .foregroundStyle(offset == 0 ? Color.primary : Color.secondary.opacity(0.58))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 25)
                        .background(offset == 0 ? Color.primary.opacity(0.10) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .disabled(offset == 0)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func shift(_ part: WheelPart, by offset: Int) {
        let component: Calendar.Component
        switch part {
        case .day: component = .day
        case .month: component = .month
        case .year: component = .year
        }
        date = Calendar.current.date(byAdding: component, value: offset, to: date) ?? date
    }

    private func wheelText(_ part: WheelPart, offset: Int) -> String {
        let component: Calendar.Component
        switch part {
        case .day: component = .day
        case .month: component = .month
        case .year: component = .year
        }
        let value = Calendar.current.date(byAdding: component, value: offset, to: date) ?? date
        switch part {
        case .day: return value.formatted(.dateTime.day())
        case .month: return value.formatted(.dateTime.month(.wide))
        case .year: return value.formatted(.dateTime.year())
        }
    }
    #endif
}
