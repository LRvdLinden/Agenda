import SwiftUI

/// Inspect the current raw provider response without exposing session cookies or address credentials.
struct WasteSubscriptionDetailView: View {
    let subscription: FeedSubscription
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @EnvironmentObject private var store: CalendarStore
    @Environment(\.dismiss) private var dismiss
    @State private var items: [ICSFeedParser.Entry] = []
    @State private var prefix = ""
    @State private var suffix = ""
    @State private var failure: String?
    @State private var loading = false
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Agenda-tekst") {
                    TextField("Tekst vóór afvalsoort", text: $prefix)
                    TextField("Tekst achter afvalsoort", text: $suffix)
                    Text("Voorbeeld: " + prefix + (items.first?.title ?? "Papier") + suffix)
                        .font(.footnote).foregroundStyle(.secondary)
                    Button(saving ? "Opslaan…" : "Opslaan en agenda bijwerken") {
                        Task {
                            saving = true
                            defer { saving = false }
                            do { try await subscriptions.saveWasteTitleFormat(id: subscription.id, prefix: prefix, suffix: suffix, store: store) }
                            catch { failure = error.localizedDescription }
                        }
                    }.disabled(saving || loading)
                }
                Section("Ontvangen ophaaldagen (originele providertekst)") {
                    if loading { ProgressView("Ophaaldagen ophalen…") }
                    if let failure { Text(failure).foregroundStyle(.red).font(.caption) }
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                Text(item.start.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(prefix + item.title + suffix).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if items.isEmpty && !loading { Text("Er zijn nog geen ophaaldagen opgehaald.").foregroundStyle(.secondary) }
                    Button("Opnieuw ophalen") { Task { await fetch() } }.disabled(loading)
                }
            }
            .navigationTitle(subscription.title)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Gereed") { dismiss() } } }
            .onAppear {
                prefix = subscriptions.wasteTitlePrefixes[subscription.id.uuidString] ?? ""
                suffix = subscriptions.wasteTitleSuffixes[subscription.id.uuidString] ?? ""
            }
            .task { await fetch() }
        }
    }
    private func fetch() async {
        loading = true; failure = nil
        defer { loading = false }
        do { items = try await subscriptions.previewWaste(id: subscription.id) }
        catch { failure = error.localizedDescription }
    }
}
