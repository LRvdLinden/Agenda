import SwiftUI

/// The Sevn icon drawn in SwiftUI (same as the app icon): a tile with a red header band holding
/// seven day dots, and the name below. The splash animates the dots (`activeDot`) and marks today.
struct SevnMark: View {
    /// nil = follow light / dark mode.
    var dark: Bool? = nil
    /// Dot that is briefly enlarged (wave animation), 0…6.
    var activeDot: Int? = nil
    /// Dot drawn as "today" (0 = first day of the week … 6).
    var todayDot: Int? = nil
    var rounded: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = dark ?? (colorScheme == .dark)
        let tile: Color = isDark ? .sevnBlack : .white
        let word: Color = isDark ? .white : .sevnRed
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            let k = w / 1024
            ZStack(alignment: .top) {
                tile
                Color.sevnRed.frame(height: 318 * k)
                HStack(spacing: 38 * k) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle()
                            .fill(i == todayDot ? Color.yellow : (isDark ? Color.sevnBlack : Color.white))
                            .frame(width: 42 * k, height: 42 * k)
                            .scaleEffect(i == activeDot ? 1.6 : (i == todayDot ? 1.35 : 1))
                    }
                }
                .frame(height: 42 * k)
                .padding(.top, 138 * k)
                Text(verbatim: "Sevn")
                    .font(.system(size: w * 0.285, weight: .heavy))
                    .foregroundStyle(word)
                    .lineLimit(1)
                    .frame(width: w, height: 706 * k)
                    .offset(y: 308 * k)
            }
            .frame(width: w, height: w)
            .clipShape(RoundedRectangle(cornerRadius: rounded ? w * 0.225 : 0, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(Text(verbatim: "Sevn"))
    }
}
