import SwiftUI
import EventKit

struct EventDetailView: View {
    let item: EventItem

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var event: EKEvent?
    @State private var askDelete = false

    private var color: Color { Color(hex: item.colorHex) ?? .accentColor }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 6)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.displayTitle)
                                    .font(.title2.weight(.bold))
                                    .strikethrough(item.isDeclined)
                                Text(dateText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let rule = event?.recurrenceRules?.first {
                                    Label {
                                        Text(LocalizedStringKey(RepeatRule.from(rule).titleKey))
                                    } icon: { Image(systemName: "repeat") }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    LabeledContent {
                        Text(item.calendarTitle)
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                    if let loc = item.location {
                        Button { openMaps(loc) } label: {
                            Label(loc, systemImage: "mappin.and.ellipse")
                        }
                    }
                    if let url = event?.url {
                        Link(destination: url) {
                            Label(url.absoluteString, systemImage: "link").lineLimit(1)
                        }
                    }
                    if let alarms = event?.alarms, !alarms.isEmpty {
                        ForEach(Array(alarms.enumerated()), id: \.offset) { _, a in
                            Label(Fmt.alarm(minutes: Int((-a.relativeOffset / 60).rounded())), systemImage: "bell")
                        }
                    }
                }

                if let attendees = event?.attendees, !attendees.isEmpty {
                    Section("Invitees") {
                        ForEach(Array(attendees.enumerated()), id: \.offset) { _, a in
                            HStack {
                                Image(systemName: statusSymbol(a.participantStatus))
                                    .foregroundStyle(statusColor(a.participantStatus))
                                Text(a.name ?? a.url.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
                                Spacer()
                                if a.isCurrentUser { Text("You").foregroundStyle(.secondary) }
                            }
                        }
                    }
                }

                if let notes = event?.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes).textSelection(.enabled)
                    }
                }

                Section {
                    if item.canEdit {
                        Button { open(EditorRequest(item: item)) } label: { Label("Edit", systemImage: "pencil") }
                    }
                    Button { open(EditorRequest(start: item.start, duplicateOf: item)) } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Button {
                        state.clipboard = item
                        dismiss()
                    } label: { Label("Copy and Paste Elsewhere", systemImage: "doc.on.doc") }
                    Button { saveAsTemplate() } label: { Label("Save as Template", systemImage: "square.on.square") }
                    ShareLink(item: ICSExport.shareText(for: item, event: event),
                              subject: Text(item.title)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    if let file = ICSExport.file(for: event) {
                        ShareLink(item: file) {
                            Label("Share as Calendar File (.ics)", systemImage: "calendar.badge.plus")
                        }
                    }
                }

                if item.canEdit {
                    Section {
                        Button(role: .destructive) { askDelete = true } label: {
                            Label("Delete Event", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(Text("Event"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this event?", isPresented: $askDelete, titleVisibility: .visible) {
                if item.isRecurring {
                    Button("Delete This Event Only", role: .destructive) { delete(.thisEvent) }
                    Button("Delete All Future Events", role: .destructive) { delete(.futureEvents) }
                } else {
                    Button("Delete Event", role: .destructive) { delete(.thisEvent) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
        .onAppear { event = store.ekEvent(for: item) }
    }

    private var dateText: String {
        let cal = synced.settings.calendar
        if item.isAllDay {
            let lastDay = item.end.addingTimeInterval(-1)
            if cal.isDate(item.start, inSameDayAs: lastDay) || lastDay < item.start {
                return item.start.formatted(date: .complete, time: .omitted) + " · " + String(localized: "All-day")
            }
            return item.start.formatted(date: .abbreviated, time: .omitted) + " – " + lastDay.formatted(date: .abbreviated, time: .omitted)
        }
        if cal.isDate(item.start, inSameDayAs: item.end) {
            return item.start.formatted(date: .complete, time: .omitted) + "\n" + Fmt.time(item.start) + " – " + Fmt.time(item.end)
        }
        return item.start.formatted(date: .abbreviated, time: .shortened) + " –\n" + item.end.formatted(date: .abbreviated, time: .shortened)
    }

    private func open(_ req: EditorRequest) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { state.editor = req }
    }

    private func delete(_ span: EKSpan) {
        if store.delete(item, span: span) { dismiss() }
    }

    private func saveAsTemplate() {
        guard let e = event else { return }
        let cal = synced.settings.calendar
        let style = synced.styles[item.styleKey]
        synced.templates.append(EventTemplate(
            name: item.title, title: item.title, location: e.location ?? "", notes: e.notes ?? "",
            urlString: e.url?.absoluteString ?? "", durationMinutes: max(5, item.durationMinutes),
            isAllDay: item.isAllDay, alarmMinutes: (e.alarms ?? []).map { Int(-$0.relativeOffset / 60) },
            calendarID: item.calendarID, emoji: style?.emoji ?? item.emoji, colorHex: style?.colorHex,
            startMinutes: item.isAllDay ? nil : cal.minutesSinceStartOfDay(item.start)))
        state.showToast(String(localized: "Template saved"))
    }

    private func openMaps(_ location: String) {
        let q = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
        if let url = URL(string: "https://maps.apple.com/?q=\(q)") { openURL(url) }
    }

    private func statusSymbol(_ s: EKParticipantStatus) -> String {
        switch s {
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .tentative: return "questionmark.circle.fill"
        default: return "circle"
        }
    }

    private func statusColor(_ s: EKParticipantStatus) -> Color {
        switch s {
        case .accepted: return .green
        case .declined: return .red
        case .tentative: return .orange
        default: return .secondary
        }
    }
}

/// Text and .ics export for sharing events through Messages, WhatsApp, Mail …
enum ICSExport {
    static func shareText(for item: EventItem, event: EKEvent?) -> String {
        var lines = [item.displayTitle]
        if item.isAllDay {
            lines.append(item.start.formatted(date: .complete, time: .omitted))
        } else {
            lines.append(item.start.formatted(date: .complete, time: .omitted) + ", " + Fmt.time(item.start) + " – " + Fmt.time(item.end))
        }
        if let loc = item.location { lines.append("📍 " + loc) }
        if let url = event?.url { lines.append(url.absoluteString) }
        if let notes = event?.notes, !notes.isEmpty { lines.append(""); lines.append(notes) }
        return lines.joined(separator: "\n")
    }

    static func file(for event: EKEvent?) -> URL? {
        guard let e = event else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyyMMdd"
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: ";", with: "\\;")
                .replacingOccurrences(of: ",", with: "\\,").replacingOccurrences(of: "\n", with: "\\n")
        }
        var ics = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Sevn//Sevn Calendar//EN", "BEGIN:VEVENT",
                   "UID:\(UUID().uuidString)@sevn", "DTSTAMP:\(f.string(from: Date()))"]
        if e.isAllDay {
            ics.append("DTSTART;VALUE=DATE:\(df.string(from: e.startDate))")
            let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: e.endDate)) ?? e.endDate!
            ics.append("DTEND;VALUE=DATE:\(df.string(from: end))")
        } else {
            ics.append("DTSTART:\(f.string(from: e.startDate))")
            ics.append("DTEND:\(f.string(from: e.endDate))")
        }
        ics.append("SUMMARY:\(esc(e.title ?? ""))")
        if let l = e.location, !l.isEmpty { ics.append("LOCATION:\(esc(l))") }
        if let n = e.notes, !n.isEmpty { ics.append("DESCRIPTION:\(esc(n))") }
        if let u = e.url { ics.append("URL:\(u.absoluteString)") }
        ics += ["END:VEVENT", "END:VCALENDAR"]
        let safe = (e.title ?? "event").components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent((safe.isEmpty ? "event" : safe) + ".ics")
        do {
            try ics.joined(separator: "\r\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
