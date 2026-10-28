import SwiftUI

/// App-wide constants for Weekdot.
enum Weekdot {
    static let bundleID = "nl.lrvdlinden.weekdot"
    /// Same app group on every platform (macOS 15+ supports "group." identifiers with a provisioning profile).
    static let appGroup = "group.nl.lrvdlinden.weekdot"
    static let website = URL(string: "https://weekdot.com/")!
    static let privacyURL = URL(string: "https://weekdot.com/privacy/")!
    static let supportURL = URL(string: "https://weekdot.com/support/")!

    static var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    /// Shared UserDefaults (app group) so widgets can read settings and the event snapshot.
    static var groupDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var groupContainer: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
}

extension Color {
    static let weekdotRed = Color(red: 232 / 255, green: 53 / 255, blue: 47 / 255)
    static let weekdotBlack = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)

    /// Creates a color from "#RRGGBB" or "RRGGBB".
    init?(hex: String?) {
        guard var s = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self = Color(red: Double((v >> 16) & 0xFF) / 255,
                     green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255)
    }

    /// "#RRGGBB" for this color (sRGB).
    var hexString: String {
        let r = resolve(in: EnvironmentValues())
        func c(_ f: Float) -> Int { max(0, min(255, Int((f * 255).rounded()))) }
        return String(format: "#%02X%02X%02X", c(r.red), c(r.green), c(r.blue))
    }
}

enum ColorHex {
    static func from(cgColor: CGColor?) -> String {
        guard let cg = cgColor,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let conv = cg.converted(to: space, intent: .defaultIntent, options: nil),
              let comps = conv.components, comps.count >= 3 else { return "#E8352F" }
        func c(_ f: CGFloat) -> Int { max(0, min(255, Int((f * 255).rounded()))) }
        return String(format: "#%02X%02X%02X", c(comps[0]), c(comps[1]), c(comps[2]))
    }

    static func cgColor(_ hex: String) -> CGColor {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt32(s, radix: 16) ?? 0xE8352F
        return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                       green: CGFloat((v >> 8) & 0xFF) / 255,
                       blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    /// True for light colours (dark text reads better on them).
    static func isLight(_ hex: String?) -> Bool {
        guard var s = hex else { return false }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return false }
        let r = Double((v >> 16) & 0xFF), g = Double((v >> 8) & 0xFF), b = Double(v & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 165
    }

}
