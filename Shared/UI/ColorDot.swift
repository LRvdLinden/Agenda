import SwiftUI
#if os(iOS) || os(macOS)
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A coloured dot as a non-template image. Menus and pickers tint SF Symbols with the accent colour,
/// so a symbol can't show each calendar's own colour there; a rendered image keeps its colour.
enum ColorDot {
    #if canImport(UIKit)
    private static var cache: [String: UIImage] = [:]
    #elseif canImport(AppKit)
    private static var cache: [String: NSImage] = [:]
    #endif

    static func image(_ hex: String, size: CGFloat = 12) -> Image {
        let key = hex.uppercased() + "-\(Int(size))"
        #if canImport(UIKit)
        if let img = cache[key] { return Image(uiImage: img) }
        let r = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let img = r.image { ctx in
            UIColor(cgColor: ColorHex.cgColor(hex)).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }.withRenderingMode(.alwaysOriginal)
        cache[key] = img
        return Image(uiImage: img)
        #elseif canImport(AppKit)
        if let img = cache[key] { return Image(nsImage: img) }
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSColor(cgColor: ColorHex.cgColor(hex))?.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        img.isTemplate = false
        cache[key] = img
        return Image(nsImage: img)
        #endif
    }
}

/// Calendar picker grouped per account, with each calendar's real colour.
struct CalendarPickerContent: View {
    let choices: [CalendarChoice]
    var allowAutomatic: Bool = false

    private var groups: [(String, [CalendarChoice])] {
        var order: [String] = []
        var map: [String: [CalendarChoice]] = [:]
        for c in choices {
            if map[c.sourceTitle] == nil { order.append(c.sourceTitle) }
            map[c.sourceTitle, default: []].append(c)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    var body: some View {
        if allowAutomatic {
            Text("Automatic").tag(String?.none)
        }
        ForEach(groups, id: \.0) { source, list in
            Section(source) {
                ForEach(list) { c in
                    Label {
                        Text(c.title)
                    } icon: {
                        ColorDot.image(c.colorHex)
                    }
                    .tag(Optional(c.id))
                }
            }
        }
    }
}
#endif
