import SwiftUI

/// Alert choice like Apple Calendar: a row per alert ("Alert", "Second Alert") that opens a list with
/// None, At time of event, 5/15/30 min, 1 hour, 1 day … plus a travel-time option and a custom alert.
struct AlarmRows: View {
    @Binding var alarms: [Int]
    let isAllDay: Bool
    let location: String

    var body: some View {
        NavigationLink {
            AlarmChoiceList(selection: slot(0), isAllDay: isAllDay, location: location, allowNone: true)
        } label: {
            LabeledContent("Alert", value: label(alarms.first))
        }
        if !alarms.isEmpty {
            NavigationLink {
                AlarmChoiceList(selection: slot(1), isAllDay: isAllDay, location: location, allowNone: true)
            } label: {
                LabeledContent("Second Alert", value: label(alarms.count > 1 ? alarms[1] : nil))
            }
        }
    }

    private func label(_ m: Int?) -> String {
        guard let m else { return String(localized: "None") }
        return isAllDay ? Fmt.allDayAlarm(minutes: m) : Fmt.alarm(minutes: m)
    }

    /// Binding to alert number `i` (nil = none). Clearing the first alert moves the second one up.
    private func slot(_ i: Int) -> Binding<Int?> {
        Binding(get: { alarms.count > i ? alarms[i] : nil }, set: { v in
            var list = alarms
            if let v {
                if list.count > i { list[i] = v } else { list.append(v) }
            } else if list.count > i {
                list.remove(at: i)
            }
            var seen = Set<Int>()
            alarms = list.filter { seen.insert($0).inserted }
        })
    }
}

struct AlarmChoiceList: View {
    @Binding var selection: Int?
    let isAllDay: Bool
    let location: String
    var allowNone = true

    @Environment(\.dismiss) private var dismiss
    @State private var travel: Int?

    private var choices: [Int] { isAllDay ? [-540, 900, 2340, 9540] : [0, 5, 15, 30, 60, 120, 1440, 2880, 10080] }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    CustomAlarmView(selection: $selection, isAllDay: isAllDay, onDone: { dismiss() })
                } label: {
                    Text("Custom Alert")
                }
            }
            Section {
                if allowNone { row(nil, Text("None")) }
                ForEach(rowsWithTravel, id: \.self) { m in
                    if isTravelRow(m), let t = travel {
                        Button { pick(m) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Fmt.alarm(minutes: m)).foregroundStyle(.primary)
                                    Label(String(localized: "\(Int(t)) min from current location"), systemImage: "car.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selection == m { Image(systemName: "checkmark").foregroundStyle(Color.accentColor).fontWeight(.semibold) }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        row(m, Text(isAllDay ? Fmt.allDayAlarm(minutes: m) : Fmt.alarm(minutes: m)))
                    }
                }
                if let s = selection, !rowsWithTravel.contains(s) {
                    row(s, Text(isAllDay ? Fmt.allDayAlarm(minutes: s) : Fmt.alarm(minutes: s)))
                }
            }
        }
        .navigationTitle(Text("Alert"))
        .task(id: location) {
            guard !isAllDay, !location.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            travel = await TravelService.shared.travelMinutes(to: location)
        }
    }

    /// The fixed choices plus "leave now" travel time (placed in time order), like Apple Calendar.
    private var rowsWithTravel: [Int] {
        var list = choices
        if let t = travel, !isAllDay, !list.contains(t) { list.append(t) }
        return list.sorted()
    }

    private func isTravelRow(_ m: Int) -> Bool { travel == m && !choices.contains(m) }

    private func row(_ m: Int?, _ title: Text) -> some View {
        Button { pick(m) } label: {
            HStack {
                title.foregroundStyle(.primary)
                Spacer()
                if selection == m { Image(systemName: "checkmark").foregroundStyle(Color.accentColor).fontWeight(.semibold) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func pick(_ m: Int?) {
        selection = m
        dismiss()
    }
}

/// Any number of minutes, hours, days or weeks before (timed events), or a day + time (all-day events).
struct CustomAlarmView: View {
    @Binding var selection: Int?
    let isAllDay: Bool
    var onDone: () -> Void

    enum Unit: Int, CaseIterable, Identifiable {
        case minutes = 1, hours = 60, days = 1440, weeks = 10080
        var id: Int { rawValue }
        var titleKey: String {
            switch self {
            case .minutes: return "Minutes"
            case .hours: return "Hours"
            case .days: return "Days"
            case .weeks: return "Weeks"
            }
        }
    }

    @State private var amount = 10
    @State private var unit: Unit = .minutes
    @State private var daysBefore = 0
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        Form {
            if isAllDay {
                Section {
                    Stepper(value: $daysBefore, in: 0...60) {
                        LabeledContent("Days Before", value: "\(daysBefore)")
                    }
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
            } else {
                Section {
                    Stepper(value: $amount, in: 1...999) {
                        LabeledContent("Amount", value: "\(amount)")
                    }
                    Picker("Unit", selection: $unit) {
                        ForEach(Unit.allCases) { Text(LocalizedStringKey($0.titleKey)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(Fmt.alarm(minutes: amount * unit.rawValue))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("Custom Alert"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if isAllDay {
                        let m = Calendar.current.minutesSinceStartOfDay(time)
                        selection = daysBefore == 0 ? -m : daysBefore * 1440 - m
                    } else {
                        selection = amount * unit.rawValue
                    }
                    onDone()
                }
            }
        }
    }
}
