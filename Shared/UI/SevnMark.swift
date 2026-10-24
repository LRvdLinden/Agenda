import SwiftUI

/// The Sevn logo (same drawing as the app icon): a red calendar card with binder rings and the
/// app's week grid. The splash uses `pulsing` (a wave over the day boxes) and `highlight` (today).
struct SevnMark: View {
    /// nil = follow light / dark mode.
    var dark: Bool? = nil
    /// Index of the box that is briefly pressed in (wave animation).
    var pulsing: Int? = nil
    /// Index of the box drawn as "today" (0 = first day of the week … 6).
    var highlight: Int? = nil
    @Environment(\.colorScheme) private var colorScheme

    private struct Box { let x0, y0, x1, y1, r: CGFloat }

    private static let boxes: [Box] = {
        let gx0: CGFloat = 244, gx1: CGFloat = 780, gy0: CGFloat = 356, gy1: CGFloat = 780, gap: CGFloat = 22
        let colw = (gx1 - gx0 - gap) / 2
        let rowh = (gy1 - gy0 - 2 * gap) / 3
        var list: [Box] = []
        for i in 0..<3 {
            let top = gy0 + CGFloat(i) * (rowh + gap)
            list.append(Box(x0: gx0, y0: top, x1: gx0 + colw, y1: top + rowh, r: 20))
        }
        let rx0 = gx0 + colw + gap
        for i in 0..<2 {
            let top = gy0 + CGFloat(i) * (rowh + gap)
            list.append(Box(x0: rx0, y0: top, x1: gx1, y1: top + rowh, r: 20))
        }
        let top = gy0 + 2 * (rowh + gap)
        let half = (rowh - gap / 2) / 2
        list.append(Box(x0: rx0, y0: top, x1: gx1, y1: top + half, r: 16))
        list.append(Box(x0: rx0, y0: top + half + gap / 2, x1: gx1, y1: top + rowh, r: 16))
        return list
    }()

    var body: some View {
        let isDark = dark ?? (colorScheme == .dark)
        let hole: Color = isDark ? .sevnBlack : .white
        let ring: Color = isDark ? .white : Color(red: 24 / 255, green: 24 / 255, blue: 32 / 255)
        GeometryReader { geo in
            let k = min(geo.size.width, geo.size.height) / 1024
            ZStack(alignment: .topLeading) {
                rect(188, 236, 836, 836, 104, k).fill(Color.sevnRed)
                    .frame(width: 648 * k, height: 600 * k).offset(x: 188 * k, y: 236 * k)
                ForEach([360.0, 664.0], id: \.self) { rx in
                    RoundedRectangle(cornerRadius: 26 * k, style: .continuous)
                        .fill(ring)
                        .frame(width: 52 * k, height: 124 * k)
                        .offset(x: (CGFloat(rx) - 26) * k, y: 176 * k)
                }
                ForEach(Array(Self.boxes.enumerated()), id: \.offset) { i, b in
                    RoundedRectangle(cornerRadius: b.r * k, style: .continuous)
                        .fill(i == highlight ? todayFill(isDark) : hole)
                        .frame(width: (b.x1 - b.x0) * k, height: (b.y1 - b.y0) * k)
                        .scaleEffect(i == pulsing ? 0.78 : 1)
                        .offset(x: b.x0 * k, y: b.y0 * k)
                }
            }
            .frame(width: 1024 * k, height: 1024 * k, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func todayFill(_ dark: Bool) -> Color {
        dark ? Color(red: 0.42, green: 0.12, blue: 0.11) : Color(red: 1, green: 0.86, blue: 0.85)
    }

    private func rect(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ r: CGFloat, _ k: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: r * k, style: .continuous)
    }
}
