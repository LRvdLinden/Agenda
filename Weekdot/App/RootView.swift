import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var synced: SyncedStore
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if store.hasAccess || synced.settings.onboardingDone {
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

/// Splash: continues from the launch screen (same icon, same place). The seven day dots light up
/// one by one, today's dot stays lit, and the tagline slides in.
struct SplashView: View {
    @EnvironmentObject private var synced: SyncedStore
    @State private var activeDot: Int?
    @State private var todayDot: Int?
    @State private var showText = false
    @State private var lifted = false

    private let logoSize: CGFloat = 150

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            WeekdotMark(activeDot: activeDot, todayDot: todayDot)
                .frame(width: logoSize, height: logoSize)
                .shadow(color: .black.opacity(lifted ? 0.22 : 0), radius: lifted ? 22 : 0, y: lifted ? 12 : 0)
                .scaleEffect(lifted ? 1.04 : 1)
                .offset(y: showText ? -30 : 0)
            VStack(spacing: 6) {
                Text("Your week at a glance")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.weekdotRed)
            }
            .offset(y: showText ? 92 : 112)
            .opacity(showText ? 1 : 0)
        }
        .ignoresSafeArea()
        .task { await run() }
    }

    private func run() async {
        let cal = synced.settings.calendar
        let today = max(0, min(6, cal.dayDistance(from: cal.startOfWeek(for: Date()), to: Date())))
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { lifted = true }
        try? await Task.sleep(nanoseconds: 150_000_000)
        for i in 0..<7 {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { activeDot = i }
            try? await Task.sleep(nanoseconds: 75_000_000)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            activeDot = nil
            todayDot = today
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) { showText = true }
    }
}

struct PermissionView: View {
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var synced: SyncedStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            WeekdotMark()
                .frame(width: 120, height: 120)
            VStack(spacing: 10) {
                Text("Welcome to Weekdot")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Weekdot has its own calendars that sync through iCloud. You can also show the calendars you already use in the Calendar app: iCloud, Google, Outlook, Exchange and subscriptions.")
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
            VStack(spacing: 12) {
                if store.isDenied {
                    Button {
                        openSystemSettings()
                    } label: {
                        Text("Allow Calendar Access in Settings").frame(maxWidth: 360).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button {
                        Task {
                            await store.requestAccess()
                            finish()
                        }
                    } label: {
                        Text("Also Use the Calendar App").frame(maxWidth: 360).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                Button {
                    synced.settings.useAppleCalendar = false
                    finish()
                } label: {
                    Text("Only Weekdot Calendars").frame(maxWidth: 360).padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Text("You can change this later in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func finish() {
        synced.settings.onboardingDone = true
        store.reload()
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
