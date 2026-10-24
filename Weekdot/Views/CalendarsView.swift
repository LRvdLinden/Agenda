import SwiftUI
import EventKit

/// Manage calendars: Weekdot's own calendars (synced with iCloud) and, optionally, the calendars of the
/// Apple Calendar app. Every calendar can get its own colour, sets switch groups of calendars.
struct CalendarsView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showNew = false
    @State private var showSubscribe = false
    @State private var showHolidays = false
    @State private var showAccounts = false
    @State private var newSetName = ""
    @State private var askSetName = false
    @State private var editing: CalendarChoice?

    private var appleGroups: [(String, [CalendarChoice])] {
        let apple = store.allChoices.filter { !$0.isLocal }
        let groups = Dictionary(grouping: apple) { $0.sourceTitle }
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

                Section {
                    ForEach(store.allChoices.filter(\.isLocal)) { c in
                        CalendarRow(choice: c, visible: store.isVisible(id: c.id),
                                    toggle: { store.setVisible(id: c.id, !store.isVisible(id: c.id)) },
                                    edit: { editing = c })
                    }
                    Button { showNew = true } label: { Label("New Calendar", systemImage: "plus.circle") }
                } header: {
                    Text("Weekdot")
                } footer: {
                    Text("Weekdot's own calendars. They sync through iCloud on all your devices, also without the Calendar app.")
                }

                if store.appleEnabled {
                    ForEach(appleGroups, id: \.0) { source, list in
                        Section(source) {
                            ForEach(list) { c in
                                CalendarRow(choice: c, visible: store.isVisible(id: c.id),
                                            toggle: { store.setVisible(id: c.id, !store.isVisible(id: c.id)) },
                                            edit: { editing = c })
                            }
                        }
                    }
                } else {
                    Section {
                        Button {
                            Task { await store.requestAccess() }
                        } label: {
                            Label("Connect Apple Calendar", systemImage: "link")
                        }
                    } footer: {
                        Text("Also show your iCloud, Google, Outlook and Exchange calendars from the Calendar app.")
                    }
                }

                Section {
                    Button { showSubscribe = true } label: { Label("Subscribe to Calendar", systemImage: "antenna.radiowaves.left.and.right") }
                    Button { showHolidays = true } label: { Label("Holidays & Smart Calendars", systemImage: "sparkles") }
                    if store.appleEnabled {
                        Button { showAccounts = true } label: { Label("Add Account (Google, Outlook …)", systemImage: "person.crop.circle.badge.plus") }
                    }
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
            .sheet(isPresented: $showNew) { CalendarEditView(choice: nil) }
            .sheet(item: $editing) { c in CalendarEditView(choice: c) }
            .sheet(isPresented: $showSubscribe) { SubscribeView() }
            .sheet(isPresented: $showHolidays) { HolidayCalendarsView() }
            .sheet(isPresented: $showAccounts) { AddAccountInfoView() }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }
}

private struct CalendarRow: View {
    let choice: CalendarChoice
    let visible: Bool
    let toggle: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color(hex: choice.colorHex) ?? .gray).frame(width: 22, height: 22)
                        if visible {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    .opacity(visible ? 1 : 0.35)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(choice.title)
                        if choice.isSubscription {
                            Text("Subscription").font(.caption).foregroundStyle(.secondary)
                        } else if choice.isBirthday {
                            Text("Birthdays from Contacts").font(.caption).foregroundStyle(.secondary)
                        } else if !choice.writable {
                            Text("Read only").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: edit) {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
        }
    }
}

/// New calendar (Weekdot or an Apple account) or edit name/colour of an existing one.
struct CalendarEditView: View {
    let choice: CalendarChoice?

    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var synced: SyncedStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var colorHex: String? = "#E8352F"
    @State private var account = "weekdot"
    @State private var askDelete = false

    private var apple: EKCalendar? { choice.flatMap { $0.isLocal ? nil : store.calendar(withID: $0.id) } }
    private var localCal: WDCalendar? { choice.flatMap { store.local.calendar(withID: $0.id) } }
    private var canRename: Bool { choice == nil || choice?.isLocal == true || (apple?.allowsContentModifications ?? false) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $title)
                        .disabled(!canRename)
                } footer: {
                    if !canRename {
                        Text("The name of this calendar can't be changed here. The colour is kept by Weekdot.")
                    }
                }
                Section("Color") {
                    ColorPaletteRow(selection: $colorHex)
                        .padding(.vertical, 4)
                }
                if choice == nil {
                    Section {
                        Picker("Account", selection: $account) {
                            Text("Weekdot (iCloud)").tag("weekdot")
                            ForEach(store.sourcesForNewCalendars, id: \.sourceIdentifier) { s in
                                Text(s.sourceType == .local ? String(localized: "On this device") : s.title)
                                    .tag(s.sourceIdentifier)
                            }
                        }
                    } footer: {
                        Text("Weekdot calendars sync through iCloud on all your devices with Weekdot.")
                    }
                } else if let c = choice {
                    Section {
                        LabeledContent("Account", value: c.isLocal ? String(localized: "Weekdot (iCloud)") : c.sourceTitle)
                    }
                    if c.isLocal || (apple.map { $0.allowsContentModifications || $0.type == .subscription } ?? false) {
                        Section {
                            Button("Delete Calendar", role: .destructive) { askDelete = true }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(choice == nil ? Text("New Calendar") : Text("Edit Calendar"))
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
                    if let l = localCal { store.local.deleteCalendar(l); dismiss() }
                    else if let a = apple, store.deleteCalendar(a) { dismiss() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
        .onAppear {
            if let c = choice {
                title = c.title
                colorHex = c.colorHex
            }
        }
    }

    private func save() {
        let hex = colorHex ?? "#E8352F"
        let name = title.trimmingCharacters(in: .whitespaces)
        if let l = localCal {
            store.local.updateCalendar(l, title: name, colorHex: hex)
            synced.calendarColors.removeValue(forKey: l.calendarID)
            dismiss()
        } else if let a = apple {
            if store.updateCalendar(a, title: name, colorHex: hex) { dismiss() }
        } else if choice == nil {
            if account == "weekdot" {
                store.local.createCalendar(title: name, colorHex: hex)
                dismiss()
            } else if let source = store.sourcesForNewCalendars.first(where: { $0.sourceIdentifier == account }) {
                if store.createCalendar(title: name, colorHex: hex, source: source) != nil { dismiss() }
            }
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
                    Text("Paste the link of a calendar (.ics) — for example sports schedules, school holidays or a shared calendar. The Calendar app adds the subscription and Weekdot shows it right away.")
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
                Text("Weekdot uses the accounts of the Calendar app. Add Google, Outlook, Exchange, Yahoo or CalDAV once and all its calendars appear in Weekdot automatically.")
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
