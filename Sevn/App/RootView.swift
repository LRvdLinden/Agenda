import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: CalendarStore
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if store.hasAccess {
                    MainView()
                } else {
                    PermissionView()
                }
            }
            .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.06)))
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_750_000_000)
            withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
        }
    }
}

/// Splash: continues from the launch screen (same logo, same place), runs a wave over the
/// week boxes, marks today, then brings in the name and tagline.
struct SplashView: View {
    @EnvironmentObject private var synced: SyncedStore
    @State private var pulsing: Int?
    @State private var highlight: Int?
    @State private var showText = false

    private let logoSize: CGFloat = 220

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            SevnMark(pulsing: pulsing, highlight: highlight)
                .frame(width: logoSize, height: logoSize)
                .offset(y: showText ? -54 : 0)
            VStack(spacing: 6) {
                Text("Sevn")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Your week at a glance")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .offset(y: showText ? 96 : 120)
            .opacity(showText ? 1 : 0)
        }
        .ignoresSafeArea()
        .task { await run() }
    }

    private func run() async {
        let cal = synced.settings.calendar
        let today = cal.dayDistance(from: cal.startOfWeek(for: Date()), to: Date())
        try? await Task.sleep(nanoseconds: 120_000_000)
        for i in 0..<7 {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) { pulsing = i }
            try? await Task.sleep(nanoseconds: 70_000_000)
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            pulsing = nil
            highlight = max(0, min(6, today))
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { showText = true }
    }
}

struct PermissionView: View {
    @EnvironmentObject private var store: CalendarStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            SevnMark()
                .frame(width: 120, height: 120)
            VStack(spacing: 10) {
                Text("Welcome to Sevn")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Sevn works with the calendars you already use in the Calendar app: iCloud, Google, Outlook, Exchange and subscriptions. Everything stays in sync through your accounts and iCloud.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(symbol: "calendar", text: "Day, week, month and year views")
                FeatureRow(symbol: "face.smiling", text: "Colours and emoji for your events")
                FeatureRow(symbol: "doc.on.doc", text: "Templates, copy & paste and drag & drop")
                FeatureRow(symbol: "icloud", text: "Synced on iPhone, iPad, Mac and Apple Watch")
            }
            .frame(maxWidth: 420)
            Spacer()
            if store.isDenied {
                Text("Sevn has no access to your calendars. Allow full access in Settings.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    openSystemSettings()
                } label: {
                    Text("Open Settings").frame(maxWidth: 360).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    Task { await store.requestAccess() }
                } label: {
                    Text("Continue").frame(maxWidth: 360).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") { openURL(url) }
        #endif
    }
}

private struct FeatureRow: View {
    let symbol: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
            Text(text)
            Spacer(minLength: 0)
        }
    }
}
