import SwiftUI

/// The user chooses where the subscription is managed. Apple Calendar's own
/// subscription updates even when Weekdot is closed; the direct Weekdot mirror
/// remains available and can opportunistically refresh in the background.
struct SubscriptionChoice: Identifiable {
    let title: String
    let link: String
    let category: String
    let countryCode: String?

    var id: String { link }
}

enum SystemCalendarSubscription {
    /// Apple Calendar registers webcal:// URLs. No public EventKit API can
    /// silently register an OS-managed calendar subscription on our behalf.
    static func webcalURL(for text: String) -> URL? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var parts = URLComponents(string: value),
              let scheme = parts.scheme?.lowercased(),
              ["https", "http", "webcal"].contains(scheme),
              let host = parts.host, host.contains("."),
              parts.user == nil, parts.password == nil else { return nil }
        parts.scheme = "webcal"
        return parts.url
    }
}

struct SubscriptionMethodView: View {
    let choice: SubscriptionChoice

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @State private var errorText: String?
    @State private var isOpeningApple = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(choice.title)
                        .font(.headline)
                    Text("Select how to subscribe. Apple Calendar can keep an actual subscription updated independently of Weekdot.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if subscriptions.isSubscribed(to: choice.link) {
                        Text("This feed is already copied by Weekdot. Remove its direct copy after adding it to Apple Calendar to avoid duplicate events.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    Button {
                        openInAppleCalendar()
                    } label: {
                        Label("Add to Apple Calendar · automatic updates", systemImage: "calendar.badge.plus")
                    }
                    .disabled(isOpeningApple || subscriptions.isBusy)
                } footer: {
                    Text("Apple Calendar asks you to confirm the subscription. Choose iCloud so the subscribed calendar appears on your other Apple devices. Weekdot displays it when Apple Calendar access is enabled.")
                }

                Section {
                    Button {
                        Task {
                            do {
                                try await subscriptions.subscribe(title: choice.title, link: choice.link,
                                                                  category: choice.category,
                                                                  countryCode: choice.countryCode,
                                                                  store: store)
                                dismiss()
                            } catch { errorText = error.localizedDescription }
                        }
                    } label: {
                        Label("Subscribe directly in Weekdot", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(isOpeningApple || subscriptions.isBusy || subscriptions.isSubscribed(to: choice.link))
                    if subscriptions.isBusy { ProgressView("Adding calendar…") }
                } footer: {
                    Text("Weekdot copies the events to a separate writable Apple calendar. It checks for changes when opened and during background refresh opportunities, which iOS does not guarantee.")
                }

                if let url = SystemCalendarSubscription.webcalURL(for: choice.link) {
                    Section {
                        ShareLink(item: url) {
                            Label("Share Subscription Link", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text("Calendar Subscription"))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .alert("Subscription Error", isPresented: Binding(get: { errorText != nil },
                                                               set: { if !$0 { errorText = nil } })) {
                Button("OK", role: .cancel) { errorText = nil }
            } message: { Text(errorText ?? "") }
        }
    }

    private func openInAppleCalendar() {
        guard let url = SystemCalendarSubscription.webcalURL(for: choice.link) else {
            errorText = String(localized: "Use a valid HTTPS or webcal calendar link.")
            return
        }
        isOpeningApple = true
        Task {
            // This permission is for Weekdot's display only. Apple Calendar's
            // subscription itself can still be created without it.
            if !store.hasAccess { await store.requestAccess() }
            if store.hasAccess {
                store.synced.settings.useAppleCalendar = true
                store.reload()
            }
            isOpeningApple = false
            openURL(url) { accepted in
                if accepted { dismiss() }
                else { errorText = String(localized: "Could not open Apple Calendar. Use Share Subscription Link instead.") }
            }
        }
    }
}
