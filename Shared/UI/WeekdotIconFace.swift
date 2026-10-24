import SwiftUI

/// The Weekdot icon drawn live: abbreviated weekday in a red label, the date in red below.
/// Uses the user's own calendar and time zone, so it always shows *their* today.
/// Used by the splash screen, the Mac Dock icon and the "Today" widget.
struct WeekdotIconFace: View {
    enum Style: String, CaseIterable { case white, black }

    var date: Date = Date()
    /// nil = follow light / dark mode (white tile in light mode, black tile in dark mode).
    var style: Style? = nil
    @Environment(\.colorScheme) private var colorScheme
    /// Corner radius as a fraction of the size (0 = square, e.g. for the widget background).
    var cornerFraction: CGFloat = 0.225

    private var resolvedStyle: Style { style ?? (colorScheme == .dark ? .black : .white) }
    private var background: Color { resolvedStyle == .white ? .white : .weekdotBlack }

    private var weekday: String {
        date.formatted(.dateTime.weekday(.abbreviated))
            .replacingOccurrences(of: ".", with: "")
            .uppercased()
    }

    private var day: String {
        String(Calendar.autoupdatingCurrent.component(.day, from: date))
    }

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: w * cornerFraction, style: .continuous)
                    .fill(background)
                VStack(spacing: 0) {
                    Text(weekday)
                        .font(.system(size: w * 0.105, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(background)
                        .padding(.horizontal, w * 0.04)
                        .frame(minWidth: w * 0.5, minHeight: w * 0.165, maxHeight: w * 0.165)
                        .background(Capsule().fill(Color.weekdotRed))
                        .padding(.top, w * 0.14)
                    Text(day)
                        .font(.system(size: w * 0.5, weight: .heavy))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.weekdotRed)
                        .frame(height: w * 0.52)
                        .padding(.top, w * 0.055)
                }
                .frame(width: w)
            }
            .frame(width: w, height: w)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date.formatted(date: .complete, time: .omitted)))
    }
}
