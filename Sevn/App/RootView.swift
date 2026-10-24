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
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
        }
    }
}

/// Animated splash: continues seamlessly from the launch screen (red background, Sevn icon).
struct SplashView: View {
    @State private var appear = false

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            VStack(spacing: 22) {
                SevnIconFace(style: .white)
                    .frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                    .scaleEffect(appear ? 1 : 0.86)
                Text("Sevn")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                Text("Your week at a glance")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { appear = true }
        }
    }
}

struct PermissionView: View {
    @EnvironmentObject private var store: CalendarStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            SevnIconFace()
                .frame(width: 110, height: 110)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
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
