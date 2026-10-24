#if os(macOS)
import AppKit
import SwiftUI

/// On the Mac the Dock icon shows today's weekday and date (in the user's time zone) while Sevn runs,
/// and follows light / dark mode.
@MainActor
final class DockIconUpdater: ObservableObject {
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init() {
        update()
        let center = NotificationCenter.default
        for name in [Notification.Name.NSCalendarDayChanged, .NSSystemTimeZoneDidChange, NSLocale.currentLocaleDidChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.update() }
            })
        }
        observers.append(DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    self?.update()
                }
            })
        // safety net: re-check every 10 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
    }

    func update() {
        let dark = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let view = SevnIconFace(date: Date(), style: dark ? .black : .white, cornerFraction: 0.225)
            .frame(width: 412, height: 412)
            .padding(50)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
            .frame(width: 512, height: 512)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        if let image = renderer.nsImage {
            NSApp?.applicationIconImage = image
        }
    }
}
#endif
