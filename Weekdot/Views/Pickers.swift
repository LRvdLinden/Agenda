import SwiftUI

// MARK: - Shared pickers

struct ColorPaletteRow: View {
    @Binding var selection: String?
    var allowNone: Bool = false

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 9), spacing: 10) {
            if allowNone {
                Button { selection = nil } label: {
                    ZStack {
                        Circle().strokeBorder(Color.secondary, lineWidth: 1.5)
                        Image(systemName: "calendar").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    .frame(width: 28, height: 28)
                    .overlay { if selection == nil { Circle().strokeBorder(Color.primary, lineWidth: 2.5).padding(-4) } }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Calendar Color"))
            }
            ForEach(ColorHex.palette, id: \.self) { hex in
                Button { selection = hex } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if selection?.uppercased() == hex.uppercased() {
                                Circle().strokeBorder(Color.primary, lineWidth: 2.5).padding(-4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var custom = ""

    static let groups: [(String, [String])] = [
        ("Popular", ["📅", "⭐️", "❗️", "✅", "📌", "🎉", "🎂", "🎁", "❤️", "👥", "💼", "📞", "💻", "📝", "📚", "🎓"]),
        ("Health & Sport", ["🏋️", "🏃", "🚴", "🏊", "⚽️", "🎾", "🧘", "🦷", "🩺", "💊", "🏥", "💇"]),
        ("Food & Fun", ["🍽️", "🥪", "☕️", "🍕", "🍷", "🍺", "🎬", "🎵", "🎮", "🎨", "📷", "🛍️"]),
        ("Travel & Home", ["✈️", "🚆", "🚗", "🏖️", "🏕️", "🏠", "🧹", "🛠️", "🌱", "🐶", "🐱", "👶"]),
        ("Nature & Weather", ["☀️", "🌧️", "❄️", "🌙", "🌈", "🔥", "🌸", "🍂", "🎄", "🎃", "🐣", "🌍"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        TextField("Type any emoji", text: $custom)
                            .textFieldStyle(.roundedBorder)
                        Button("Use") {
                            if let first = custom.first { selection = String(first); dismiss() }
                        }
                        .disabled(custom.isEmpty)
                    }
                    ForEach(Self.groups, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey(group.0)).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(group.1, id: \.self) { e in
                                    Button {
                                        selection = e
                                        dismiss()
                                    } label: {
                                        Text(e).font(.system(size: 28))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(Text("Emoji"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Remove") { selection = ""; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}
