import SwiftUI
import EventKit

/// Manage the calendars that come from the Calendar app: show/hide, colours, new calendars,
/// subscriptions, holiday calendars and calendar sets.
struct CalendarsView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showNew = false
    @State private var showSubscribe = false
    @State private var showHolidays = false
    @State private var showAccounts = false
    @State private var newSetName = ""
    @State private var askSetName = false
    @State private var editing: EKCalendar?

    private var grouped: [(String, [EKCalendar])] {
        let groups = Dictionary(grouping: store.calendars) { $0.source.title }
        return groups.keys.sorted { a, b in
            if a.lowercased().contains("icloud") != b.lowercased().contains("icloud") { return a.lowercased().contains("icloud") }
            return a < b
        }
        .map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(synced.sets) { set in
                        Button { store.apply(set: set) } label: {
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                Text(set.name)
                                Spacer()
                                Text("\(set.calendarIDs.count)").foregroundStyle(.secondary)
                                if synced.settings.activeSetID == set.id {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { idx in synced.sets.remove(atOffsets: idx) }
                    Button { askSetName = true } label: {
                        Label("Save Current Selection as Set", systemImage: "plus.square.on.square")
                    }
                    Button { store.showAllCalendars() } label: {
                        Label("Show All Calendars", systemImage: "eye")
                    }
                } header: {
                    Text("Calendar Sets")
                } footer: {
                    Text("Switch quickly between groups of calendars, for example Work and Family.")
                }

                ForEach(grouped, id: \.0) { source, calendars in
                    Section(source) {
                        ForEach(calendars, id: \.calendarIdentifier) { c in
                            CalendarRow(calendar: c, visible: store.isVisible(c),
                                        toggle: { store.setVisible(c, !store.isVisible(c)) },
                                        edit: { editing = c })
                        }
                    }
                }

                Section {
                    Button { showNew = true } label: { Label("New Calendar", systemImage: "plus.circle") }
                    Button { showSubscribe = true } label: { Label("Subscribe to Calendar", systemImage: "antenna.radiowaves.left.and.right") }
                    Button { showHolidays = true } label: { Label("Holidays & Smart Calendars", systemImage: "sparkles") }
                    Button { showAccounts = true } label: { Label("Add Account (Google, Outlook …)", systemImage: "person.crop.circle.badge.plus") }
                } footer: {
                    Text("Sevn shows every calendar from the Calendar app. Changes are saved in your accounts and synced with iCloud.")
                }
            }
            .navigationTitle(Text("Calendars"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("New Calendar Set", isPresented: $askSetName) {
                TextField("Name", text: $newSetName)
                Button("Save") {
                    let name = newSetName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let set = CalendarSet(name: name, calendarIDs: store.visibleCalendarIDs)
                    synced.sets.append(set)
                    synced.settings.activeSetID = set.id
                    newSetName = ""
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The calendars that are visible now are saved in this set.")
            }
            .sheet(isPresented: $showNew) { CalendarEditView(calendar: nil) }
            .sheet(item: Binding(get: { editing.map(CalendarRef.init) }, set: { editing = $0?.calendar })) { ref in
                CalendarEditView(calendar: ref.calendar)
            }
            .sheet(isPresented: $showSubscribe) { SubscribeView() }
            .sheet(isPresented: $showHolidays) { HolidayCalendarsView() }
            .sheet(isPresented: $showAccounts) { AddAccountInfoView() }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }
}

struct CalendarRef: Identifiable {
    let calendar: EKCalendar
    var id: String { calendar.calendarIdentifier }
}

private struct CalendarRow: View {
    let calendar: EKCalendar
    let visible: Bool
    let toggle: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color(cgColor: calendar.cgColor)).frame(width: 22, height: 22)
                        if visible {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    .opacity(visible ? 1 : 0.35)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(calendar.title)
                        if calendar.type == .subscription {
                            Text("Subscription").font(.caption).foregroundStyle(.secondary)
                        } else if calendar.type == .birthday {
                            Text("Birthdays from Contacts").font(.caption).foregroundStyle(.secondary)
                        } else if !calendar.allowsContentModifications {
                            Text("Read only").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if calendar.type != .birthday {
                Button(action: edit) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct CalendarEditView: View {
    let calendar: EKCalendar?

    @EnvironmentObject private var store: CalendarStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var colorHex: String? = "#E8352F"
    @State private var sourceID = ""
    @State private var askDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $title)
                }
                Section("Color") {
                    ColorPaletteRow(selection: $colorHex)
                        .padding(.vertical, 4)
                }
                if calendar == nil {
                    Section {
                        Picker("Account", selection: $sourceID) {
                            ForEach(store.sourcesForNewCalendars, id: \.sourceIdentifier) { s in
                                Text(s.sourceType == .local ? String(localized: "On this device") : s.title)
                                    .tag(s.sourceIdentifier)
                            }
                        }
                    } footer: {
                        Text("Choose iCloud to have the calendar on all your devices.")
                    }
                } else if let c = calendar {
                    Section {
                        LabeledContent("Account", value: c.source.title)
                    }
                    if c.allowsContentModifications || c.type == .subscription {
                        Section {
                            Button("Delete Calendar", role: .destructive) { askDelete = true }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(calendar == nil ? Text("New Calendar") : Text("Edit Calendar"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this calendar and all its events?", isPresented: $askDelete,
                                titleVisibility: .visible) {
                Button("Delete Calendar", role: .destructive) {
                    if let c = calendar, store.deleteCalendar(c) { dismiss() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
        .onAppear {
            if let c = calendar {
                title = c.title
                colorHex = ColorHex.from(cgColor: c.cgColor)
            } else {
                sourceID = store.sourcesForNewCalendars.first?.sourceIdentifier ?? ""
            }
        }
    }

    private func save() {
        let hex = colorHex ?? "#E8352F"
        if let c = calendar {
            if store.updateCalendar(c, title: title, colorHex: hex) { dismiss() }
        } else if let source = store.sourcesForNewCalendars.first(where: { $0.sourceIdentifier == sourceID }) {
            if store.createCalendar(title: title, colorHex: hex, source: source) != nil { dismiss() }
        }
    }
}

struct SubscribeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var urlText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("webcal:// or https:// …ics", text: $urlText)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                } footer: {
                    Text("Paste the link of a calendar (.ics) — for example sports schedules, school holidays or a shared calendar. The Calendar app adds the subscription and Sevn shows it right away.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Subscribe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Subscribe") {
                        if let url = SmartCalendars.webcalURL(from: urlText) { openURL(url); dismiss() }
                    }
                    .disabled(SmartCalendars.webcalURL(from: urlText) == nil)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 260)
        #endif
    }
}

struct HolidayCalendarsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(SmartCalendars.holidays, id: \.id) { h in
                        Button {
                            if let url = h.url { openURL(url) }
                        } label: {
                            HStack {
                                Text(h.flag)
                                Text(h.localizedName)
                                Spacer()
                                Image(systemName: "plus.circle").foregroundStyle(Color.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Public Holidays")
                } footer: {
                    Text("Tap a country to subscribe. Weather is shown in the week view when you turn it on in Settings.")
                }
            }
            .navigationTitle(Text("Smart Calendars"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
    }
}

struct AddAccountInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Sevn uses the accounts of the Calendar app. Add Google, Outlook, Exchange, Yahoo or CalDAV once and all its calendars appear in Sevn automatically.")
                #if os(iOS)
                Text("iPhone and iPad: Settings › Apps › Calendar › Calendar Accounts › Add Account.")
                    .foregroundStyle(.secondary)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Text("Open Settings").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                #else
                Text("Mac: open the Calendar app › Calendar › Add Account…")
                    .foregroundStyle(.secondary)
                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                } label: {
                    Text("Open Calendar").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                #endif
                Spacer()
            }
            .padding(24)
            .navigationTitle(Text("Add Account"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 320)
        #endif
    }
}
