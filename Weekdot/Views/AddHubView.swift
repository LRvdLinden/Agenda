import SwiftUI

/// Native iOS Add tab, matching Samen's persistent tab navigation. The event
/// editor remains a sheet so its existing save/cancel flow is unchanged.
struct AddHubView: View {
    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        state.editor = EditorRequest(start: state.suggestedStart(settings: synced.settings))
                    } label: {
                        Label("New Event", systemImage: "calendar.badge.plus")
                            .font(.headline)
                            .frame(minHeight: 38)
                    }

                    Button { state.sheet = .quickAdd } label: {
                        Label("Quick Add", systemImage: "text.badge.plus")
                            .frame(minHeight: 38)
                    }

                    Button { state.sheet = .templates } label: {
                        Label("Manage Templates", systemImage: "square.on.square")
                            .frame(minHeight: 38)
                    }
                } header: {
                    Text("Add")
                } footer: {
                    Text("Create an event or use one of your own saved templates.")
                }

                Section("Templates") {
                    if synced.templates.isEmpty {
                        Text("Your saved templates will appear here. Weekdot does not include preloaded templates.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(synced.templates) { template in
                            Button {
                                state.editor = EditorRequest(start: nil, template: template)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.on.square")
                                        .foregroundStyle(Color.accentColor)
                                    Text(((template.emoji ?? "").isEmpty ? "" : (template.emoji ?? "") + " ") + template.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Add"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
