import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var weather: WeatherService
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var s: Binding<AppSettings> { $synced.settings }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.hasAccess {
                        Toggle("Show Calendar App Calendars", isOn: s.useAppleCalendar)
                    } else {
                        Button {
                            Task { await store.requestAccess() }
                        } label: {
                            Label("Connect Apple Calendar", systemImage: "link")
                        }
                    }
                    Toggle("Show Birthdays", isOn: s.showBirthdays)
                    Toggle("Show Reminders", isOn: Binding(get: { synced.settings.showReminders }, set: { v in
                        synced.settings.showReminders = v
                        if v && !store.hasReminderAccess { Task { await store.requestReminderAccess() } }
                        store.invalidate()
                    }))
                    Button { state.sheet = .calendars } label: {
                        Label("Manage Calendars", systemImage: "calendar.badge.checkmark")
                    }
                } header: {
                    Text("Calendars")
                } footer: {
                    Text("Weekdot's own calendars always sync through iCloud. Calendar App calendars (iCloud, Google, Outlook, Exchange) sync through their accounts.")
                }

                Section("Views") {
                    Picker("Start View", selection: s.defaultView) {
                        ForEach(CalendarViewMode.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                    }
                    Picker("Week Layout", selection: s.weekLayout) {
                        ForEach(WeekLayout.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                    }
                    Stepper(value: s.multiDayCount, in: 2...6) {
                        LabeledContent("Days in Multiple Days View", value: "\(synced.settings.clampedMultiDayCount)")
                    }
                    Stepper(value: s.multiWeekCount, in: 2...4) {
                        LabeledContent("Weeks in Multiple Weeks View", value: "\(synced.settings.clampedMultiWeekCount)")
                    }
                    Picker("Week Starts On", selection: s.firstWeekday) {
                        Text("Automatic").tag(0)
                        ForEach(1...7, id: \.self) { d in
                            Text(Calendar.current.standaloneWeekdaySymbols[d - 1].capitalized).tag(d)
                        }
                    }
                    Toggle("Week Numbers", isOn: s.showWeekNumbers)
                    Picker("Alternate Calendar", selection: s.alternateCalendar) {
                        Text("Off").tag("none")
                        ForEach(AltCalendar.all, id: \.self) { id in Text(AltCalendar.name(id)).tag(id) }
                    }
                    NavigationLink {
                        TimeZonePickerView(selection: s.timeZoneOverride)
                    } label: {
                        LabeledContent("Time Zone Override", value: synced.settings.timeZoneOverride
                            .flatMap { TimeZone(identifier: $0) }
                            .map { $0.localizedName(for: .generic, locale: .current) ?? $0.identifier } ?? String(localized: "Off"))
                    }
                    Toggle("Shade Weekends", isOn: s.shadeWeekends)
                    Toggle("Show Declined Events", isOn: s.showDeclined)
                    Toggle("Busy Days in Year View", isOn: s.showYearHeatmap)
                }

                Section("Appearance") {
                    Picker("Appearance", selection: s.appearance) {
                        ForEach(AppearanceMode.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                    }
                    Picker("Event Style", selection: s.eventStyle) {
                        ForEach(EventStyleMode.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                    }
                    VStack(alignment: .leading) {
                        LabeledContent("Text Size", value: "\(Int(synced.settings.textScale * 100))%")
                        Slider(value: s.textScale, in: 0.8...1.4, step: 0.05)
                    }
                    VStack(alignment: .leading) {
                        LabeledContent("Hour Height", value: "\(Int(synced.settings.hourHeight))")
                        Slider(value: s.hourHeight, in: 26...160, step: 2)
                    }
                    Picker("Scroll to", selection: s.dayStartHour) {
                        ForEach(0..<24, id: \.self) { h in Text(Fmt.hourLabel(h)).tag(h) }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                        ColorPaletteRow(selection: s.accentHex, allowNone: false)
                        if synced.settings.accentHex != nil {
                            Button("Use Weekdot Red") { synced.settings.accentHex = nil }
                                .font(.footnote)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("New Events") {
                    Picker("Default Duration", selection: s.defaultDurationMinutes) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { Text(Fmt.duration(minutes: $0)).tag($0) }
                    }
                    Picker("Default Alert", selection: s.defaultAlarmMinutes) {
                        Text("None").tag(-1)
                        ForEach(alarmChoices, id: \.self) { Text(Fmt.alarm(minutes: $0)).tag($0) }
                    }
                    Picker("Default Alert for All-Day Events", selection: s.defaultAllDayAlarmMinutes) {
                        Text("None").tag(Int?.none)
                        ForEach(allDayAlarmChoices, id: \.self) { Text(Fmt.allDayAlarm(minutes: $0)).tag(Optional($0)) }
                    }
                    Picker("Birthdays", selection: s.birthdayAlarmMinutes) {
                        Text("None").tag(Int?.none)
                        ForEach(allDayAlarmChoices, id: \.self) { Text(Fmt.allDayAlarm(minutes: $0)).tag(Optional($0)) }
                    }
                    Picker("Default Calendar", selection: s.defaultCalendarID) {
                        CalendarPickerContent(choices: store.writableChoices, allowAutomatic: true)
                    }
                    Toggle("Location Suggestions", isOn: s.locationSuggestions)
                    Picker("Drag Steps", selection: s.snapMinutes) {
                        ForEach([5, 10, 15, 30, 60], id: \.self) { Text(Fmt.duration(minutes: $0)).tag($0) }
                    }
                    Toggle("Suggest From Earlier Events", isOn: s.autofillFromHistory)
                }

                Section {
                    Toggle("Weekdot Alerts for All Calendars", isOn: s.alertsForAllCalendars)
                        .disabled(!store.appleEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Alerts for Weekdot calendars always arrive as notifications. Turn this on to also get alerts for Apple Calendar events from Weekdot. The Calendar app may then alert as well.")
                }

                Section {
                    NavigationLink { TemplatesView() } label: {
                        Label("Templates", systemImage: "square.on.square")
                    }
                    NavigationLink { RulesView() } label: {
                        Label("Colour & Emoji Rules", systemImage: "wand.and.stars")
                    }
                }

                Section {
                    Toggle("Weather in Week View", isOn: s.showWeather)
                    if synced.settings.showWeather {
                        Picker("Temperature", selection: s.temperatureUnit) {
                            ForEach(TemperatureUnit.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                        }
                    }
                } header: {
                    Text("Weather")
                } footer: {
                    Text("Uses your approximate location. Forecast by Open-Meteo.")
                }

                Section {
                    LabeledContent("iCloud") {
                        if synced.iCloudAvailable {
                            Label("On", systemImage: "checkmark.icloud").foregroundStyle(.green)
                        } else {
                            Label("Off", systemImage: "xmark.icloud").foregroundStyle(.secondary)
                        }
                    }
                    if let last = synced.lastSync {
                        LabeledContent("Last Sync", value: last.formatted(date: .abbreviated, time: .shortened))
                    }
                    Button { synced.syncNow(); store.reload() } label: {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    Text("Events sync through your calendar accounts. Weekdot's own settings, templates, sets, rules, colours and emoji sync through iCloud on all your devices.")
                }

                Section {
                    LabeledContent("Language", value: Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? "")
                    #if os(iOS)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: {
                        Label("Change App Language", systemImage: "globe")
                    }
                    #endif
                } header: {
                    Text("Language")
                } footer: {
                    #if os(macOS)
                    Text("Weekdot follows the language of your device. Choose another language in System Settings › General › Language & Region › Applications.")
                    #else
                    Text("Weekdot follows the language of your device. You can pick another language for Weekdot only.")
                    #endif
                }

                Section {
                    LabeledContent("Version", value: Weekdot.version)
                    Link(destination: Weekdot.website) { Label("Website", systemImage: "safari") }
                    Link(destination: Weekdot.supportURL) { Label("Help & Support", systemImage: "questionmark.circle") }
                    Link(destination: Weekdot.privacyURL) { Label("Privacy", systemImage: "hand.raised") }
                } header: {
                    Text("About Weekdot")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Settings"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
    }
}
