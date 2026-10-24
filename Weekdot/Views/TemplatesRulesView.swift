import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing: EventTemplate?

    var body: some View {
        List {
            Section {
                ForEach(synced.templates) { t in
                    Button { editing = t } label: {
                        HStack(spacing: 12) {
                            Text((t.emoji ?? "").isEmpty ? "📅" : (t.emoji ?? ""))
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.name).font(.body.weight(.medium))
                                Text(t.isAllDay ? String(localized: "All-day") : Fmt.duration(minutes: t.durationMinutes))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Circle().fill(Color(hex: t.colorHex) ?? .clear).frame(width: 12, height: 12)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { synced.templates.remove(atOffsets: $0) }
                .onMove { synced.templates.move(fromOffsets: $0, toOffset: $1) }
            } footer: {
                Text("Templates appear under the + button and at the top of a new event.")
            }
        }
        .navigationTitle(Text("Templates"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editing = EventTemplate(name: "", title: "", durationMinutes: synced.settings.defaultDurationMinutes)
                } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(item: $editing) { t in
            TemplateEditView(template: t) { updated in
                if let i = synced.templates.firstIndex(where: { $0.id == updated.id }) {
                    synced.templates[i] = updated
                } else {
                    synced.templates.append(updated)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}

struct TemplateEditView: View {
    @State var template: EventTemplate
    var onSave: (EventTemplate) -> Void
    @EnvironmentObject private var store: CalendarStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEmoji = false

    private var emojiBinding: Binding<String> {
        Binding(get: { template.emoji ?? "" }, set: { template.emoji = $0.isEmpty ? nil : $0 })
    }

    private var hasStartTime: Binding<Bool> {
        Binding(get: { template.startMinutes != nil }, set: { template.startMinutes = $0 ? 9 * 60 : nil })
    }

    private var startTime: Binding<Date> {
        Binding(get: {
            Calendar.current.date(on: Date(), minutes: template.startMinutes ?? 9 * 60)
        }, set: {
            template.startMinutes = Calendar.current.minutesSinceStartOfDay($0)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $template.name)
                    HStack {
                        Button { showEmoji = true } label: {
                            Text((template.emoji ?? "").isEmpty ? "🙂" : (template.emoji ?? ""))
                                .opacity((template.emoji ?? "").isEmpty ? 0.35 : 1)
                        }
                        .buttonStyle(.plain)
                        TextField("Event Title", text: $template.title)
                    }
                    TextField("Location", text: $template.location)
                }
                Section {
                    Toggle("All-day", isOn: $template.isAllDay)
                    if !template.isAllDay {
                        Stepper(value: $template.durationMinutes, in: 5...1440, step: 15) {
                            LabeledContent("Duration", value: Fmt.duration(minutes: template.durationMinutes))
                        }
                        Toggle("Fixed Start Time", isOn: hasStartTime)
                        if template.startMinutes != nil {
                            DatePicker("Start", selection: startTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    Picker("Calendar", selection: $template.calendarID) {
                        Text("Default").tag(String?.none)
                        ForEach(store.writableChoices) { c in
                            Text(c.title).tag(Optional(c.id))
                        }
                    }
                }
                Section("Alerts") {
                    ForEach(alarmChoices, id: \.self) { m in
                        Button {
                            if template.alarmMinutes.contains(m) { template.alarmMinutes.removeAll { $0 == m } }
                            else { template.alarmMinutes.append(m); template.alarmMinutes.sort() }
                        } label: {
                            HStack {
                                Text(Fmt.alarm(minutes: m))
                                Spacer()
                                if template.alarmMinutes.contains(m) {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Color") {
                    ColorPaletteRow(selection: $template.colorHex, allowNone: true).padding(.vertical, 4)
                }
                Section {
                    TextField("Notes", text: $template.notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Template"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if template.name.trimmingCharacters(in: .whitespaces).isEmpty { template.name = template.title }
                        onSave(template)
                        dismiss()
                    }
                    .disabled(template.name.isEmpty && template.title.isEmpty)
                }
            }
            .sheet(isPresented: $showEmoji) { EmojiPickerView(selection: emojiBinding) }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
        #endif
    }
}

struct RulesView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing: StyleRule?

    var body: some View {
        List {
            Section {
                ForEach(synced.rules) { r in
                    Button { editing = r } label: {
                        HStack(spacing: 12) {
                            Text((r.emoji ?? "").isEmpty ? "•" : (r.emoji ?? "")).font(.title3).frame(width: 30)
                            Text(r.keyword)
                            Spacer()
                            if let c = Color(hex: r.colorHex) { Circle().fill(c).frame(width: 14, height: 14) }
                            if !r.enabled { Text("Off").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { synced.rules.remove(atOffsets: $0); store.invalidate() }
                .onMove { synced.rules.move(fromOffsets: $0, toOffset: $1); store.invalidate() }
            } footer: {
                Text("Events whose title contains the word automatically get this emoji and/or colour. The first matching rule wins.")
            }
        }
        .navigationTitle(Text("Colour & Emoji Rules"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            ToolbarItem(placement: .primaryAction) {
                Button { editing = StyleRule(keyword: "") } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(item: $editing) { rule in
            RuleEditView(rule: rule) { updated in
                if let i = synced.rules.firstIndex(where: { $0.id == updated.id }) { synced.rules[i] = updated }
                else { synced.rules.append(updated) }
                store.invalidate()
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}

struct RuleEditView: View {
    @State var rule: StyleRule
    var onSave: (StyleRule) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showEmoji = false

    private var emojiBinding: Binding<String> {
        Binding(get: { rule.emoji ?? "" }, set: { rule.emoji = $0.isEmpty ? nil : $0 })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Word in the title", text: $rule.keyword)
                    Toggle("Enabled", isOn: $rule.enabled)
                }
                Section("Emoji") {
                    Button { showEmoji = true } label: {
                        HStack {
                            Text((rule.emoji ?? "").isEmpty ? String(localized: "None") : (rule.emoji ?? ""))
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Section("Color") {
                    ColorPaletteRow(selection: $rule.colorHex, allowNone: true).padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Rule"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(rule); dismiss() }
                        .disabled(rule.keyword.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showEmoji) { EmojiPickerView(selection: emojiBinding) }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 420)
        #endif
    }
}

struct SearchView: View {
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [EventItem] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(results) { item in
                    Button {
                        dismiss()
                        state.open(day: item.start)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { state.detail = item }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.start.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            EventRow(item: item)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay {
                if !query.isEmpty && results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, prompt: Text("Search events"))
            .task(id: query) {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                results = store.search(query)
            }
            .navigationTitle(Text("Search"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }
}
