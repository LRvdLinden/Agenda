import SwiftUI

/// Settings › Homey: sign in with the Homey account, pick a Homey and choose what Weekdot sends to it.
struct HomeySettingsView: View {
    @EnvironmentObject private var store: CalendarStore
    @ObservedObject private var homey = HomeyService.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 11).fill(Color.weekdotRed))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekdot for Homey").font(.headline)
                        Text("Start Flows when an event begins or ends, before an appointment, or with today's agenda.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if !homey.isConfigured {
                Section {
                    Label("The Homey connection is not set up in this version of Weekdot.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            } else if !homey.isSignedIn {
                Section {
                    Button {
                        Task { await homey.signIn() }
                    } label: {
                        Label("Sign In with Homey", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .disabled(homey.isBusy)
                } footer: {
                    Text("Sign in with your Homey account and choose your Homey. Weekdot then sends your events of the coming 8 days to the Weekdot app on your Homey.")
                }
            } else {
                Section {
                    if homey.homeys.isEmpty, let sel = homey.selected {
                        LabeledContent("Homey", value: sel.name)
                    } else {
                        Picker("Homey", selection: Binding(
                            get: { homey.selected?.id ?? "" },
                            set: { id in
                                if let h = homey.homeys.first(where: { $0.id == id }) { Task { await homey.choose(h) } }
                            })) {
                            if homey.selected == nil { Text("Choose…").tag("") }
                            ForEach(homey.homeys) { h in
                                Text(h.isCloud ? "\(h.name) (Homey Cloud)" : h.name).tag(h.id)
                            }
                        }
                    }
                    if homey.appInstalled == false {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("The Weekdot app is not installed on this Homey yet.", systemImage: "arrow.down.app")
                                .foregroundStyle(.orange)
                            Button("Install Weekdot on Homey") { openURL(HomeyService.homeyAppStoreURL) }
                        }
                    }
                    if let last = homey.lastSync {
                        LabeledContent("Last Update", value: last.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Events Sent", value: "\(homey.lastSyncCount)")
                    }
                    Button {
                        Task { await homey.sync(store: store, force: true) }
                    } label: {
                        HStack {
                            Label("Update Now", systemImage: "arrow.triangle.2.circlepath")
                            if homey.isBusy { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(!homey.isLinked || homey.isBusy)
                } header: {
                    Text("Your Homey")
                } footer: {
                    Text("Weekdot updates Homey when your events change, when you open the app and now and then in the background.")
                }

                Section {
                    Toggle("Hide Details", isOn: $homey.hideDetails)
                } footer: {
                    Text("Sends only the times, with “Busy” as the title, without places or emoji.")
                }

                Section {
                    ForEach(store.allChoices.filter { !$0.isBirthday }) { c in
                        Toggle(isOn: Binding(
                            get: { !homey.excludedCalendarIDs.contains(c.id) },
                            set: { on in
                                if on { homey.excludedCalendarIDs.remove(c.id) } else { homey.excludedCalendarIDs.insert(c.id) }
                            })) {
                            HStack(spacing: 8) {
                                Circle().fill(Color(hex: c.colorHex) ?? .weekdotRed).frame(width: 10, height: 10)
                                Text(c.title)
                            }
                        }
                    }
                } header: {
                    Text("Calendars Sent to Homey")
                }

                Section {
                    Button("Sign Out of Homey", role: .destructive) { homey.signOut() }
                }
            }

            if let error = homey.lastError {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }

            Section {
                Link(destination: HomeyService.homeyAppStoreURL) {
                    Label("Weekdot in the Homey App Store", systemImage: "arrow.up.right.square")
                }
            } footer: {
                Text("Your events go only to your own Homey, through Homey's own connection. Weekdot does not keep a copy.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Homey")
        .task {
            guard homey.isSignedIn else { return }
            try? await homey.loadHomeys()
            if homey.selected != nil { await homey.checkApp() }
        }
    }
}
