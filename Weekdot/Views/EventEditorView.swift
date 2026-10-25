import SwiftUI
import EventKit

/// Alert offsets in minutes before the start (timed events).
let alarmChoices: [Int] = [0, 5, 10, 15, 30, 60, 120, 1440, 2880, 10080]
/// Alerts for all-day events: negative = on the day at that time after midnight, positive = before midnight.
let allDayAlarmChoices: [Int] = [-540, 900, 2340, 9540]
let travelChoices: [Int] = [0, 5, 15, 30, 60, 90, 120]

struct EventEditorView: View {
    let request: EditorRequest

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = LocalEventData()
    @State private var original = LocalEventData()
    @State private var calendarID: String?
    @State private var originalCalendarID: String?
    @State private var loaded = false
    @State private var askSpan = false
    @State private var askDelete = false
    @State private var showEmoji = false
    @State private var templateName = ""
    @State private var askTemplateName = false
    @State private var newInvitee = ""
    @StateObject private var places = LocationCompleter()
    @FocusState private var titleFocused: Bool
    @FocusState private var locationFocused: Bool
    @State private var showPlaces = false
    @State private var pickingPlace = false

    private var isNew: Bool { request.item == nil }
    private var cal: Calendar { synced.settings.calendar }
    private var isReadOnlySource: Bool { request.item.map { !$0.canEdit && !$0.isLocal } ?? false }

    var body: some View {
        NavigationStack {
            Form {
                if isNew && request.duplicateOf == nil && !synced.templates.isEmpty { templatesSection }
                titleSection
                timeSection
                repeatSection
                calendarSection
                alertsSection
                inviteesSection
                lookSection
                notesSection
                if !isNew, request.item?.isReminder == false {
                    Section {
                        Button(role: .destructive) { askDelete = true } label: {
                            Label(isReadOnlySource ? "Hide Event" : "Delete Event", systemImage: "trash")
                                .frame(maxWidth: .infinity)
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
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { trySave() } label: { isNew ? Text("Add") : Text("Done") }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("This is a repeating event.", isPresented: $askSpan, titleVisibility: .visible) {
                Button("Save for This Event Only") { save(span: .thisEvent) }
                Button("Save for Future Events") { save(span: .futureEvents) }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete this event?", isPresented: $askDelete, titleVisibility: .visible) {
                if request.item?.isRecurring == true && !isReadOnlySource {
                    Button("Delete This Event Only", role: .destructive) { delete(.thisEvent) }
                    Button("Delete All Future Events", role: .destructive) { delete(.futureEvents) }
                } else {
                    Button(isReadOnlySource ? "Hide Event" : "Delete Event", role: .destructive) { delete(.thisEvent) }
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
        .frame(minWidth: 500, minHeight: 640)
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
                    .focused($locationFocused)
                    .onChange(of: draft.location) { _, v in
                        guard synced.settings.locationSuggestions, !pickingPlace else { return }
                        showPlaces = locationFocused
                        places.query = v
                    }
                if !draft.location.isEmpty {
                    Button { draft.location = ""; places.clear() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            if showPlaces && !places.results.isEmpty {
                ForEach(places.results.prefix(6)) { r in
                    Button {
                        pickingPlace = true
                        showPlaces = false
                        locationFocused = false
                        draft.location = r.subtitle.isEmpty ? r.title : r.title + ", " + r.subtitle
                        Task {
                            draft.location = await places.resolve(r)
                            places.clear()
                            pickingPlace = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill").font(.title3).foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(r.title).foregroundStyle(.primary)
                                if !r.subtitle.isEmpty { Text(r.subtitle).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
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

    private var allDayBinding: Binding<Bool> {
        Binding(get: { draft.isAllDay }, set: { v in
            withAnimation {
                draft.isAllDay = v
                if v {
                    draft.start = cal.startOfDay(for: draft.start)
                    draft.end = cal.startOfDay(for: max(draft.end, draft.start))
                    draft.alarms = synced.settings.defaultAllDayAlarmMinutes.map { [$0] } ?? []
                } else {
                    let s = cal.date(on: draft.start, minutes: 9 * 60)
                    draft.start = s
                    draft.end = s.addingTimeInterval(TimeInterval(synced.settings.defaultDurationMinutes * 60))
                    draft.alarms = synced.settings.defaultAlarmMinutes >= 0 ? [synced.settings.defaultAlarmMinutes] : []
                }
            }
        })
    }

    private var timeSection: some View {
        Section {
            Toggle("All-day", isOn: allDayBinding)
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
                NavigationLink {
                    TimeZonePickerView(selection: $draft.timeZoneID)
                } label: {
                    LabeledContent("Time Zone", value: draft.timeZoneID.flatMap { TimeZone(identifier: $0) }
                        .map { $0.localizedName(for: .generic, locale: .current) ?? $0.identifier } ?? String(localized: "Automatic"))
                }
                Picker("Travel Time", selection: $draft.travelMinutes) {
                    ForEach(travelChoices, id: \.self) { m in
                        Text(m == 0 ? String(localized: "None") : Fmt.duration(minutes: m)).tag(m)
                    }
                }
            }
        }
    }

    private var repeatSection: some View {
        Section {
            NavigationLink {
                RepeatEditorView(rule: $draft.recurrence, start: draft.start)
            } label: {
                LabeledContent("Repeat", value: draft.recurrence?.summary(calendar: cal) ?? String(localized: "Never"))
            }
        }
    }

    private var calendarSection: some View {
        Section {
            Picker("Calendar", selection: $calendarID) {
                CalendarPickerContent(choices: store.writableChoices)
            }
            Picker("Show As", selection: $draft.availability) {
                Text("Busy").tag("busy")
                Text("Free").tag("free")
            }
        } footer: {
            if isReadOnlySource {
                Text("The original calendar is read-only. Weekdot keeps your changed version in the calendar you choose and hides the original.")
            }
        }
    }

    private var alertsSection: some View {
        Section {
            AlarmRows(alarms: $draft.alarms, isAllDay: draft.isAllDay, location: draft.location)
        }
    }

    private var inviteesSection: some View {
        Section {
            ForEach(draft.invitees, id: \.self) { mail in
                HStack {
                    Image(systemName: "person.crop.circle").foregroundStyle(.secondary)
                    Text(mail)
                    Spacer()
                    Button { draft.invitees.removeAll { $0 == mail } } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            HStack {
                TextField("Add invitee (email)", text: $newInvitee)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onSubmit(addInvitee)
                Button("Add", action: addInvitee)
                    .disabled(!newInvitee.contains("@"))
            }
        } header: {
            Text("Invitees")
        } footer: {
            Text("After saving, open the event and tap Send Invitation to send it by mail or chat.")
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
        }
    }

    private var notesSection: some View {
        Section {
            HStack {
                Image(systemName: "link").foregroundStyle(.secondary)
                TextField("URL", text: $draft.urlString)
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
                    Label("Save as Template", systemImage: "square.on.square").font(.footnote)
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
        let defaults = synced.settings
        if let item = request.item ?? request.duplicateOf, var d = store.data(for: item) {
            if request.duplicateOf != nil {
                d.recurrence = nil
                if let s = request.start {
                    let dur = d.end.timeIntervalSince(d.start)
                    d.start = s
                    d.end = s.addingTimeInterval(dur)
                }
            }
            if d.isAllDay {
                // show the last day of an all-day event (stored with an exclusive end)
                d.end = max(cal.startOfDay(for: d.end.addingTimeInterval(-1)), cal.startOfDay(for: d.start))
            }
            draft = d
            let writable = store.writableChoices.contains { $0.id == item.calendarID }
            calendarID = writable ? item.calendarID : store.defaultCalendarID
            originalCalendarID = item.calendarID
        } else {
            var d = LocalEventData()
            let start = request.start ?? state.suggestedStart(settings: defaults)
            d.isAllDay = request.allDay
            d.start = request.allDay ? cal.startOfDay(for: start) : start
            d.end = request.allDay ? d.start : start.addingTimeInterval(TimeInterval(defaults.defaultDurationMinutes * 60))
            if request.allDay {
                d.alarms = defaults.defaultAllDayAlarmMinutes.map { [$0] } ?? []
            } else if defaults.defaultAlarmMinutes >= 0 {
                d.alarms = [defaults.defaultAlarmMinutes]
            }
            draft = d
            calendarID = store.defaultCalendarID
        }
        original = draft
        if let t = request.template { apply(template: t) }
        if isNew && request.duplicateOf == nil && request.template == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { titleFocused = true }
        }
    }

    private func apply(template t: EventTemplate) {
        draft.title = t.title
        draft.location = t.location
        draft.notes = t.notes
        draft.urlString = t.urlString
        draft.isAllDay = t.isAllDay
        let day = request.start ?? state.date
        let start: Date
        if let m = t.startMinutes { start = cal.date(on: day, minutes: m) }
        else if let s = request.start { start = s }
        else { start = state.suggestedStart(settings: synced.settings) }
        draft.start = t.isAllDay ? cal.startOfDay(for: start) : start
        draft.end = t.isAllDay ? draft.start : draft.start.addingTimeInterval(TimeInterval(t.durationMinutes * 60))
        if let id = t.calendarID, store.writableChoices.contains(where: { $0.id == id }) { calendarID = id }
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
        if let id = m.calendarID, store.writableChoices.contains(where: { $0.id == id }) { calendarID = id }
    }

    private func addInvitee() {
        let m = newInvitee.trimmingCharacters(in: .whitespaces)
        guard m.contains("@"), !draft.invitees.contains(m) else { return }
        draft.invitees.append(m)
        newInvitee = ""
    }

    // MARK: Saving

    private func trySave() {
        if let item = request.item, item.isRecurring, !isReadOnlySource, draft != original || calendarID != originalCalendarID {
            askSpan = true
        } else {
            save(span: .thisEvent)
        }
    }

    private func save(span: EKSpan) {
        var d = draft
        if d.isAllDay {
            // the editor works with the last day (inclusive); the store converts it per calendar type
            d.start = cal.startOfDay(for: d.start)
            d.end = cal.startOfDay(for: max(d.end, d.start))
        }
        if store.saveEvent(d, calendarID: calendarID, existing: request.item, span: span) {
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
            title: draft.title, location: draft.location, notes: draft.notes, urlString: draft.urlString,
            durationMinutes: max(5, Int(draft.end.timeIntervalSince(draft.start) / 60)),
            isAllDay: draft.isAllDay, alarmMinutes: draft.alarms, calendarID: calendarID,
            emoji: draft.emoji.isEmpty ? nil : draft.emoji, colorHex: draft.colorHex,
            startMinutes: draft.isAllDay ? nil : cal.minutesSinceStartOfDay(draft.start))
        synced.templates.append(t)
        state.showToast(String(localized: "Template saved"))
    }
}

// MARK: - Repeat

struct RepeatEditorView: View {
    @Binding var rule: RecurrenceSpec?
    let start: Date
    @EnvironmentObject private var synced: SyncedStore

    private enum EndMode: String, CaseIterable { case never, onDate, after }

    private var cal: Calendar { synced.settings.calendar }

    private var presets: [(String, RecurrenceSpec?)] {
        [("Never", nil), ("Every Day", .daily), ("Every Weekday", .weekdaysOnly), ("Every Week", .weekly),
         ("Every 2 Weeks", .biweekly), ("Every Month", .monthly), ("Every Year", .yearly)]
    }

    var body: some View {
        Form {
            Section {
                ForEach(presets, id: \.0) { title, spec in
                    Button {
                        rule = spec.map { var s = $0; s.endDate = rule?.endDate; s.count = rule?.count; return s }
                    } label: {
                        HStack {
                            Text(LocalizedStringKey(title)).foregroundStyle(.primary)
                            Spacer()
                            if isSelected(spec) { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Section("Custom") {
                Picker("Frequency", selection: freqBinding) {
                    ForEach(RecurrenceSpec.Frequency.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                }
                Stepper(value: intervalBinding, in: 1...99) {
                    LabeledContent("Every", value: intervalText)
                }
                if rule?.frequency == .weekly {
                    weekdayPicker
                }
                if rule?.frequency == .monthly {
                    Picker("On", selection: monthlyBinding) {
                        Text("Same day of the month").tag(RecurrenceSpec.MonthlyMode.dayOfMonth)
                        Text("Same weekday (e.g. 2nd Tuesday)").tag(RecurrenceSpec.MonthlyMode.nthWeekday)
                    }
                }
            }
            if rule != nil {
                Section("End Repeat") {
                    Picker("End Repeat", selection: endModeBinding) {
                        Text("Never").tag(EndMode.never)
                        Text("On Date").tag(EndMode.onDate)
                        Text("After").tag(EndMode.after)
                    }
                    .pickerStyle(.segmented)
                    if rule?.endDate != nil {
                        DatePicker("End Date", selection: endDateBinding, in: start..., displayedComponents: .date)
                    }
                    if rule?.count != nil {
                        Stepper(value: countBinding, in: 1...999) {
                            LabeledContent("Times", value: "\(rule?.count ?? 1)")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("Repeat"))
    }

    private func isSelected(_ spec: RecurrenceSpec?) -> Bool {
        guard let r = rule else { return spec == nil }
        guard let s = spec else { return false }
        return r.frequency == s.frequency && r.interval == s.interval && Set(r.weekdays) == Set(s.weekdays)
            && r.monthlyMode == s.monthlyMode
    }

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let wd = (cal.firstWeekday - 1 + i) % 7 + 1
                let on = rule?.weekdays.contains(wd) ?? false
                Button {
                    guard var r = rule else { return }
                    if on { r.weekdays.removeAll { $0 == wd } } else { r.weekdays.append(wd) }
                    rule = r
                } label: {
                    Text(cal.veryShortStandaloneWeekdaySymbols[wd - 1])
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(on ? Color.accentColor : Color.secondary.opacity(0.15)))
                        .foregroundStyle(on ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var intervalText: String {
        let n = rule?.interval ?? 1
        switch rule?.frequency ?? .weekly {
        case .daily: return n == 1 ? String(localized: "Day") : String(localized: "\(n) days")
        case .weekly: return n == 1 ? String(localized: "Week") : String(localized: "\(n) weeks")
        case .monthly: return n == 1 ? String(localized: "Month") : String(localized: "\(n) months")
        case .yearly: return n == 1 ? String(localized: "Year") : String(localized: "\(n) years")
        }
    }

    private var freqBinding: Binding<RecurrenceSpec.Frequency> {
        Binding(get: { rule?.frequency ?? .weekly }, set: { f in
            var r = rule ?? RecurrenceSpec()
            r.frequency = f
            if f != .weekly { r.weekdays = [] }
            rule = r
        })
    }

    private var intervalBinding: Binding<Int> {
        Binding(get: { rule?.interval ?? 1 }, set: { v in
            var r = rule ?? RecurrenceSpec()
            r.interval = v
            rule = r
        })
    }

    private var monthlyBinding: Binding<RecurrenceSpec.MonthlyMode> {
        Binding(get: { rule?.monthlyMode ?? .dayOfMonth }, set: { v in
            var r = rule ?? RecurrenceSpec(frequency: .monthly)
            r.monthlyMode = v
            rule = r
        })
    }

    private var endModeBinding: Binding<EndMode> {
        Binding(get: {
            if rule?.endDate != nil { return .onDate }
            if rule?.count != nil { return .after }
            return .never
        }, set: { m in
            guard var r = rule else { return }
            switch m {
            case .never: r.endDate = nil; r.count = nil
            case .onDate: r.count = nil; r.endDate = cal.date(byAdding: .month, value: 1, to: start)
            case .after: r.endDate = nil; r.count = 10
            }
            rule = r
        })
    }

    private var endDateBinding: Binding<Date> {
        Binding(get: { rule?.endDate ?? start }, set: { v in rule?.endDate = v })
    }

    private var countBinding: Binding<Int> {
        Binding(get: { rule?.count ?? 1 }, set: { v in rule?.count = v })
    }
}

// MARK: - Time zone

struct TimeZonePickerView: View {
    @Binding var selection: String?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var zones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.localizedCaseInsensitiveContains(query)
                || (TimeZone(identifier: $0)?.localizedName(for: .generic, locale: .current)?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        List {
            Button {
                selection = nil
                dismiss()
            } label: {
                HStack {
                    Text("Automatic").foregroundStyle(.primary)
                    Spacer()
                    if selection == nil { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            ForEach(zones, id: \.self) { id in
                Button {
                    selection = id
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(id.replacingOccurrences(of: "_", with: " ")).foregroundStyle(.primary)
                            if let name = TimeZone(identifier: id)?.localizedName(for: .generic, locale: .current) {
                                Text(name).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if selection == id { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .searchable(text: $query)
        .navigationTitle(Text("Time Zone"))
    }
}
