import SwiftUI
import EventKit

enum RepeatRule: String, CaseIterable, Identifiable {
    case never, daily, weekdays, weekly, biweekly, monthly, yearly, custom
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Every Day"
        case .weekdays: return "Every Weekday"
        case .weekly: return "Every Week"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Every Month"
        case .yearly: return "Every Year"
        case .custom: return "Custom"
        }
    }

    static func from(_ rule: EKRecurrenceRule?) -> RepeatRule {
        guard let r = rule else { return .never }
        switch (r.frequency, r.interval) {
        case (.daily, 1): return .daily
        case (.weekly, 1):
            if let days = r.daysOfTheWeek, days.count == 5,
               Set(days.map { $0.dayOfTheWeek.rawValue }) == Set([2, 3, 4, 5, 6]) { return .weekdays }
            if (r.daysOfTheWeek?.count ?? 0) <= 1 { return .weekly }
            return .custom
        case (.weekly, 2): return (r.daysOfTheWeek?.count ?? 0) <= 1 ? .biweekly : .custom
        case (.monthly, 1): return r.setPositions == nil ? .monthly : .custom
        case (.yearly, 1): return .yearly
        default: return .custom
        }
    }

    func makeRule(end: Date?) -> EKRecurrenceRule? {
        let recurrenceEnd = end.map { EKRecurrenceEnd(end: $0) }
        switch self {
        case .never, .custom: return nil
        case .daily: return EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: recurrenceEnd)
        case .weekly: return EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: recurrenceEnd)
        case .biweekly: return EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: recurrenceEnd)
        case .monthly: return EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: recurrenceEnd)
        case .yearly: return EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: recurrenceEnd)
        case .weekdays:
            let days: [EKWeekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: 1,
                                    daysOfTheWeek: days.map { EKRecurrenceDayOfWeek($0) },
                                    daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil,
                                    daysOfTheYear: nil, setPositions: nil, end: recurrenceEnd)
        }
    }
}

struct EventDraft: Equatable {
    var title = ""
    var location = ""
    var notes = ""
    var url = ""
    var isAllDay = false
    var start = Date()
    var end = Date().addingTimeInterval(3600)
    var calendarID: String?
    var repeatRule: RepeatRule = .never
    var hasRepeatEnd = false
    var repeatEnd = Date().addingTimeInterval(86400 * 30)
    var alarms: [Int] = []
    var emoji = ""
    var colorHex: String?
}

let alarmChoices: [Int] = [0, 5, 10, 15, 30, 60, 120, 1440, 2880, 10080]

struct EventEditorView: View {
    let request: EditorRequest

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = EventDraft()
    @State private var original = EventDraft()
    @State private var event: EKEvent?
    @State private var loaded = false
    @State private var askSpan = false
    @State private var askDelete = false
    @State private var showEmoji = false
    @State private var templateName = ""
    @State private var askTemplateName = false
    @FocusState private var titleFocused: Bool

    private var isNew: Bool { request.item == nil }
    private var cal: Calendar { synced.settings.calendar }

    var body: some View {
        NavigationStack {
            Form {
                if isNew && request.duplicateOf == nil && !synced.templates.isEmpty {
                    templatesSection
                }
                titleSection
                timeSection
                repeatSection
                calendarSection
                alertsSection
                lookSection
                notesSection
                if !isNew, request.item?.canEdit == true {
                    Section {
                        Button(role: .destructive) { askDelete = true } label: {
                            Label("Delete Event", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNew ? Text("New Event") : Text("Edit Event"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { trySave() } label: { isNew ? Text("Add") : Text("Done") }
                        .fontWeight(.semibold)
                        .disabled(store.writableCalendars.isEmpty)
                }
            }
            .confirmationDialog("This is a repeating event.", isPresented: $askSpan, titleVisibility: .visible) {
                Button("Save for This Event Only") { save(span: .thisEvent) }
                Button("Save for Future Events") { save(span: .futureEvents) }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete this event?", isPresented: $askDelete, titleVisibility: .visible) {
                if request.item?.isRecurring == true {
                    Button("Delete This Event Only", role: .destructive) { delete(.thisEvent) }
                    Button("Delete All Future Events", role: .destructive) { delete(.futureEvents) }
                } else {
                    Button("Delete Event", role: .destructive) { delete(.thisEvent) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Save as Template", isPresented: $askTemplateName) {
                TextField("Name", text: $templateName)
                Button("Save") { saveTemplate() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showEmoji) {
                EmojiPickerView(selection: $draft.emoji)
                    .presentationDetents([.medium, .large])
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 620)
        #endif
        .onAppear(perform: load)
    }

    // MARK: Sections

    private var templatesSection: some View {
        Section("Templates") {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(synced.templates) { t in
                        Button { apply(template: t) } label: {
                            Text(((t.emoji ?? "").isEmpty ? "" : (t.emoji ?? "") + " ") + t.name)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var titleSection: some View {
        Section {
            HStack(spacing: 10) {
                Button { showEmoji = true } label: {
                    Text(draft.emoji.isEmpty ? "🙂" : draft.emoji)
                        .font(.title2)
                        .opacity(draft.emoji.isEmpty ? 0.35 : 1)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Emoji"))
                TextField("Title", text: $draft.title)
                    .font(.title3.weight(.semibold))
                    .focused($titleFocused)
                    .submitLabel(.done)
            }
            if synced.settings.autofillFromHistory && isNew {
                let suggestions = synced.suggestions(for: draft.title)
                if !suggestions.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.title) { m in
                                Button { apply(memory: m) } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.arrow.circlepath")
                                        Text(m.title)
                                    }
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            HStack {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
                TextField("Location", text: $draft.location)
            }
        }
    }

    /// Moving the start keeps the duration.
    private var startBinding: Binding<Date> {
        Binding(get: { draft.start }, set: { new in
            let duration = max(draft.end.timeIntervalSince(draft.start), 0)
            draft.start = new
            draft.end = new.addingTimeInterval(duration)
        })
    }

    private var timeSection: some View {
        Section {
            Toggle("All-day", isOn: $draft.isAllDay.animation())
            DatePicker("Starts", selection: startBinding,
                       displayedComponents: draft.isAllDay ? [.date] : [.date, .hourAndMinute])
            DatePicker("Ends", selection: $draft.end, in: draft.start...,
                       displayedComponents: draft.isAllDay ? [.date] : [.date, .hourAndMinute])
            if !draft.isAllDay {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90, 120, 180], id: \.self) { m in
                            let active = Int(draft.end.timeIntervalSince(draft.start) / 60) == m
                            Button { draft.end = draft.start.addingTimeInterval(TimeInterval(m * 60)) } label: {
                                Text(Fmt.duration(minutes: m))
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Capsule().fill(active ? Color.accentColor : Color.secondary.opacity(0.12)))
                                    .foregroundStyle(active ? Color.white : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var repeatSection: some View {
        Section {
            Picker("Repeat", selection: $draft.repeatRule) {
                ForEach(RepeatRule.allCases.filter { $0 != .custom || draft.repeatRule == .custom }) { r in
                    Text(LocalizedStringKey(r.titleKey)).tag(r)
                }
            }
            if draft.repeatRule != .never && draft.repeatRule != .custom {
                Toggle("End Repeat", isOn: $draft.hasRepeatEnd)
                if draft.hasRepeatEnd {
                    DatePicker("End Date", selection: $draft.repeatEnd, in: draft.start..., displayedComponents: .date)
                }
            }
        }
    }

    private var calendarSection: some View {
        Section {
            Picker("Calendar", selection: $draft.calendarID) {
                ForEach(store.writableCalendars, id: \.calendarIdentifier) { c in
                    Label {
                        Text(c.title)
                    } icon: {
                        Image(systemName: "circle.fill").foregroundStyle(Color(cgColor: c.cgColor))
                    }
                    .tag(Optional(c.calendarIdentifier))
                }
            }
        }
    }

    private var alertsSection: some View {
        Section("Alerts") {
            ForEach(draft.alarms, id: \.self) { m in
                HStack {
                    Image(systemName: "bell").foregroundStyle(.secondary)
                    Text(Fmt.alarm(minutes: m))
                    Spacer()
                    Button { draft.alarms.removeAll { $0 == m } } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            Menu {
                ForEach(alarmChoices.filter { !draft.alarms.contains($0) }, id: \.self) { m in
                    Button(Fmt.alarm(minutes: m)) { draft.alarms.append(m); draft.alarms.sort() }
                }
            } label: {
                Label("Add Alert", systemImage: "plus.circle")
            }
        }
    }

    private var lookSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Color").font(.subheadline).foregroundStyle(.secondary)
                ColorPaletteRow(selection: $draft.colorHex, allowNone: true)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Look")
        } footer: {
            Text("Emoji and colour are saved by Weekdot and synced through iCloud. Other calendar apps show the calendar colour.")
        }
    }

    private var notesSection: some View {
        Section {
            HStack {
                Image(systemName: "link").foregroundStyle(.secondary)
                TextField("URL", text: $draft.url)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
            }
            TextField("Notes", text: $draft.notes, axis: .vertical)
                .lineLimit(3...10)
        } footer: {
            HStack {
                Spacer()
                Button {
                    templateName = draft.title
                    askTemplateName = true
                } label: {
                    Label("Save as Template", systemImage: "square.on.square")
                        .font(.footnote)
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: Loading

    private func load() {
        guard !loaded else { return }
        loaded = true
        var d = EventDraft()
        let defaults = synced.settings
        if let item = request.item ?? request.duplicateOf, let e = store.ekEvent(for: item) {
            if request.item != nil { event = e }
            d.title = e.title ?? ""
            d.location = e.location ?? ""
            d.notes = e.notes ?? ""
            d.url = e.url?.absoluteString ?? ""
            d.isAllDay = e.isAllDay
            d.start = e.startDate
            d.end = e.endDate
            d.calendarID = e.calendar?.allowsContentModifications == true
                ? e.calendar.calendarIdentifier : store.defaultCalendar?.calendarIdentifier
            d.repeatRule = request.duplicateOf != nil ? .never : RepeatRule.from(e.recurrenceRules?.first)
            if let endDate = e.recurrenceRules?.first?.recurrenceEnd?.endDate {
                d.hasRepeatEnd = true
                d.repeatEnd = endDate
            }
            d.alarms = (e.alarms ?? []).map { Int((-$0.relativeOffset / 60).rounded()) }.filter { $0 >= 0 }.sorted()
            let style = synced.styles[item.styleKey]
            d.emoji = style?.emoji ?? ""
            d.colorHex = style?.colorHex
        } else {
            let start = request.start ?? state.suggestedStart(settings: defaults)
            d.isAllDay = request.allDay
            d.start = request.allDay ? cal.startOfDay(for: start) : start
            d.end = request.allDay ? d.start : start.addingTimeInterval(TimeInterval(defaults.defaultDurationMinutes * 60))
            d.calendarID = store.defaultCalendar?.calendarIdentifier
            if defaults.defaultAlarmMinutes >= 0 && !request.allDay { d.alarms = [defaults.defaultAlarmMinutes] }
        }
        draft = d
        original = d
        if let t = request.template { apply(template: t) }
        if isNew && request.duplicateOf == nil && request.template == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { titleFocused = true }
        }
    }

    private func apply(template t: EventTemplate) {
        draft.title = t.title
        draft.location = t.location
        draft.notes = t.notes
        draft.url = t.urlString
        draft.isAllDay = t.isAllDay
        let day = request.start ?? state.date
        let start: Date
        if let m = t.startMinutes { start = cal.date(on: day, minutes: m) }
        else if let s = request.start { start = s }
        else { start = state.suggestedStart(settings: synced.settings) }
        draft.start = t.isAllDay ? cal.startOfDay(for: start) : start
        draft.end = t.isAllDay ? draft.start : draft.start.addingTimeInterval(TimeInterval(t.durationMinutes * 60))
        if let id = t.calendarID, store.calendar(withID: id)?.allowsContentModifications == true { draft.calendarID = id }
        draft.alarms = t.alarmMinutes
        draft.emoji = t.emoji ?? ""
        draft.colorHex = t.colorHex
    }

    private func apply(memory m: TitleMemory) {
        draft.title = m.title
        if !m.location.isEmpty { draft.location = m.location }
        draft.isAllDay = m.isAllDay
        if !m.isAllDay { draft.end = draft.start.addingTimeInterval(TimeInterval(m.durationMinutes * 60)) }
        draft.alarms = m.alarmMinutes
        if let id = m.calendarID, store.calendar(withID: id)?.allowsContentModifications == true { draft.calendarID = id }
    }

    // MARK: Saving

    private func trySave() {
        if let e = event, e.hasRecurrenceRules, draft != original {
            askSpan = true
        } else {
            save(span: .thisEvent)
        }
    }

    private func save(span: EKSpan) {
        let e = event ?? EKEvent(eventStore: store.eventStore)
        e.title = draft.title.trimmingCharacters(in: .whitespaces).isEmpty
            ? String(localized: "New Event") : draft.title
        e.location = draft.location.isEmpty ? nil : draft.location
        e.notes = draft.notes.isEmpty ? nil : draft.notes
        e.url = URL(string: draft.url.trimmingCharacters(in: .whitespaces))
        e.isAllDay = draft.isAllDay
        e.startDate = draft.isAllDay ? cal.startOfDay(for: draft.start) : draft.start
        e.endDate = draft.isAllDay ? cal.startOfDay(for: max(draft.end, draft.start)) : max(draft.end, draft.start)
        if let c = store.calendar(withID: draft.calendarID) ?? store.defaultCalendar { e.calendar = c }
        if draft.repeatRule != .custom {
            for r in e.recurrenceRules ?? [] { e.removeRecurrenceRule(r) }
            if let rule = draft.repeatRule.makeRule(end: draft.hasRepeatEnd ? draft.repeatEnd : nil) {
                e.addRecurrenceRule(rule)
            }
        }
        for a in e.alarms ?? [] { e.removeAlarm(a) }
        for m in draft.alarms { e.addAlarm(EKAlarm(relativeOffset: TimeInterval(-m * 60))) }
        let style = EventStyle(emoji: draft.emoji.isEmpty ? nil : draft.emoji, colorHex: draft.colorHex)
        if store.save(e, span: span, style: style) {
            Haptics.lift()
            dismiss()
        }
    }

    private func delete(_ span: EKSpan) {
        guard let item = request.item else { return }
        if store.delete(item, span: span) { dismiss() }
    }

    private func saveTemplate() {
        let name = templateName.trimmingCharacters(in: .whitespaces)
        let t = EventTemplate(
            name: name.isEmpty ? (draft.title.isEmpty ? String(localized: "Template") : draft.title) : name,
            title: draft.title, location: draft.location, notes: draft.notes, urlString: draft.url,
            durationMinutes: max(5, Int(draft.end.timeIntervalSince(draft.start) / 60)),
            isAllDay: draft.isAllDay, alarmMinutes: draft.alarms, calendarID: draft.calendarID,
            emoji: draft.emoji.isEmpty ? nil : draft.emoji, colorHex: draft.colorHex,
            startMinutes: draft.isAllDay ? nil : cal.minutesSinceStartOfDay(draft.start))
        synced.templates.append(t)
        state.showToast(String(localized: "Template saved"))
    }
}

// MARK: - Shared pickers

struct ColorPaletteRow: View {
    @Binding var selection: String?
    var allowNone: Bool = false

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 9), spacing: 10) {
            if allowNone {
                Button { selection = nil } label: {
                    ZStack {
                        Circle().strokeBorder(Color.secondary, lineWidth: 1.5)
                        Image(systemName: "calendar").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    .frame(width: 28, height: 28)
                    .overlay { if selection == nil { Circle().strokeBorder(Color.primary, lineWidth: 2.5).padding(-4) } }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Calendar Color"))
            }
            ForEach(ColorHex.palette, id: \.self) { hex in
                Button { selection = hex } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if selection?.uppercased() == hex.uppercased() {
                                Circle().strokeBorder(Color.primary, lineWidth: 2.5).padding(-4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var custom = ""

    static let groups: [(String, [String])] = [
        ("Popular", ["📅", "⭐️", "❗️", "✅", "📌", "🎉", "🎂", "🎁", "❤️", "👥", "💼", "📞", "💻", "📝", "📚", "🎓"]),
        ("Health & Sport", ["🏋️", "🏃", "🚴", "🏊", "⚽️", "🎾", "🧘", "🦷", "🩺", "💊", "🏥", "💇"]),
        ("Food & Fun", ["🍽️", "🥪", "☕️", "🍕", "🍷", "🍺", "🎬", "🎵", "🎮", "🎨", "📷", "🛍️"]),
        ("Travel & Home", ["✈️", "🚆", "🚗", "🏖️", "🏕️", "🏠", "🧹", "🛠️", "🌱", "🐶", "🐱", "👶"]),
        ("Nature & Weather", ["☀️", "🌧️", "❄️", "🌙", "🌈", "🔥", "🌸", "🍂", "🎄", "🎃", "🐣", "🌍"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        TextField("Type any emoji", text: $custom)
                            .textFieldStyle(.roundedBorder)
                        Button("Use") {
                            if let first = custom.first { selection = String(first); dismiss() }
                        }
                        .disabled(custom.isEmpty)
                    }
                    ForEach(Self.groups, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey(group.0)).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(group.1, id: \.self) { e in
                                    Button {
                                        selection = e
                                        dismiss()
                                    } label: {
                                        Text(e).font(.system(size: 28))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(Text("Emoji"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Remove") { selection = ""; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}
