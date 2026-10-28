import SwiftUI

// MARK: - Shared pickers

struct ColorPaletteRow: View {
    @Binding var selection: String?
    var allowNone: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ColorPicker("Custom Color", selection: customColor, supportsOpacity: false)
            if allowNone {
                Button { selection = nil } label: {
                    Label("Calendar Color", systemImage: selection == nil ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == nil ? Color.accentColor : Color.secondary)
            }
        }
    }

    private var customColor: Binding<Color> {
        Binding(
            get: { Color(hex: selection) ?? .weekdotRed },
            set: { selection = $0.hexString }
        )
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
