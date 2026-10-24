import SwiftUI
import EventKit
import MapKit

struct EventDetailView: View {
    let item: EventItem

    @EnvironmentObject private var synced: SyncedStore
    @EnvironmentObject private var store: CalendarStore
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var data: LocalEventData?
    @State private var ekEvent: EKEvent?
    @State private var askDelete = false
    @State private var coordinate: CLLocationCoordinate2D?

    private var color: Color { Color(hex: item.colorHex) ?? .accentColor }
    private var cal: Calendar { synced.settings.calendar }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 6)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.displayTitle)
                                .font(.title2.weight(.bold))
                                .strikethrough(item.isDeclined || item.isCompleted)
                            Text(dateText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let rule = data?.recurrence {
                                Label(rule.summary(calendar: cal), systemImage: "repeat")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let tz = data?.timeZoneID.flatMap({ TimeZone(identifier: $0) }), tz != TimeZone.current {
                                Label(tz.localizedName(for: .generic, locale: .current) ?? tz.identifier, systemImage: "globe")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if item.isReminder {
                    Section {
                        Button { store.toggleReminder(item); dismiss() } label: {
                            Label(item.isCompleted ? "Mark as Not Completed" : "Mark as Completed",
                                  systemImage: item.isCompleted ? "circle" : "checkmark.circle.fill")
                        }
                    }
                }

                Section {
                    LabeledContent {
                        Text(item.calendarTitle)
                    } label: {
                        Label(item.isReminder ? "List" : "Calendar", systemImage: "calendar")
                    }
                    if let d = data, d.availability == "free" {
                        LabeledContent { Text("Free") } label: { Label("Show As", systemImage: "circle.dashed") }
                    }
                    if item.travelMinutes > 0 {
                        LabeledContent { Text(Fmt.duration(minutes: item.travelMinutes)) } label: {
                            Label("Travel Time", systemImage: "car")
                        }
                    }
                    if let loc = item.location {
                        Button { openMaps(loc) } label: {
                            Label(loc, systemImage: "mappin.and.ellipse")
                        }
                    }
                    if let url = data.flatMap({ URL(string: $0.urlString) }), !(data?.urlString.isEmpty ?? true) {
                        Link(destination: url) {
                            Label(url.absoluteString, systemImage: "link").lineLimit(1)
                        }
                    }
                    if let alarms = data?.alarms, !alarms.isEmpty {
                        ForEach(alarms, id: \.self) { m in
                            Label(item.isAllDay ? Fmt.allDayAlarm(minutes: m) : Fmt.alarm(minutes: m), systemImage: "bell")
                        }
                    }
                }

                if let coordinate {
                    Section {
                        Map(initialPosition: .region(MKCoordinateRegion(center: coordinate,
                                                                         span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                            Marker(item.location ?? "", coordinate: coordinate).tint(color)
                        }
                        .frame(height: 170)
                        .listRowInsets(EdgeInsets())
                        .onTapGesture { if let loc = item.location { openMaps(loc) } }
                    }
                }

                inviteesSection

                if let notes = data?.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes).textSelection(.enabled)
                    }
                }

                if !item.isReminder {
                    Section {
                        Button { open(EditorRequest(item: item)) } label: { Label("Edit", systemImage: "pencil") }
                        Button { open(EditorRequest(start: item.start, duplicateOf: item)) } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        Button {
                            state.clipboard = item
                            dismiss()
                        } label: { Label("Copy and Paste Elsewhere", systemImage: "doc.on.doc") }
                        Button { saveAsTemplate() } label: { Label("Save as Template", systemImage: "square.on.square") }
                        ShareLink(item: ICSExport.shareText(for: item, data: data), subject: Text(item.title)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        if let d = data, let file = ICSExport.file(title: item.title, data: d) {
                            ShareLink(item: file) {
                                Label("Share as Calendar File (.ics)", systemImage: "calendar.badge.plus")
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) { askDelete = true } label: {
                            Label(item.canEdit ? "Delete Event" : "Hide Event", systemImage: item.canEdit ? "trash" : "eye.slash")
                        }
                    } footer: {
                        if !item.canEdit && !item.isLocal {
                            Text("This event comes from a read-only calendar. Editing keeps a changed copy in Weekdot.")
                        }
                    }
                }
            }
            .navigationTitle(Text("Event"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if !item.isReminder {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { open(EditorRequest(item: item)) }
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this event?", isPresented: $askDelete, titleVisibility: .visible) {
                if item.isRecurring && item.canEdit {
                    Button("Delete This Event Only", role: .destructive) { delete(.thisEvent) }
                    Button("Delete All Future Events", role: .destructive) { delete(.futureEvents) }
                } else {
                    Button(item.canEdit ? "Delete Event" : "Hide Event", role: .destructive) { delete(.thisEvent) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
        #endif
        .onAppear {
            data = store.data(for: item)
            ekEvent = store.ekEvent(for: item)
        }
        .task(id: item.location) { await geocode() }
    }

    @ViewBuilder private var inviteesSection: some View {
        if let attendees = ekEvent?.attendees, !attendees.isEmpty {
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
        } else if let d = data, !d.invitees.isEmpty {
            Section("Invitees") {
                ForEach(d.invitees, id: \.self) { mail in
                    Label(mail, systemImage: "person.crop.circle")
                }
                if let file = ICSExport.file(title: item.title, data: d, invite: true) {
                    ShareLink(item: file, subject: Text(item.title),
                              message: Text(ICSExport.shareText(for: item, data: d))) {
                        Label("Send Invitation", systemImage: "paperplane")
                    }
                }
            }
        }
    }

    private var dateText: String {
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
        let saved = data
        let item = self.item
        if store.delete(item, span: span) {
            if !item.isRecurring, var d = saved {
                if d.isAllDay { d.end = cal.startOfDay(for: d.end.addingTimeInterval(-1)) }
                let target = store.writableChoices.contains { $0.id == item.calendarID } ? item.calendarID : nil
                state.offerUndo(String(localized: "Event deleted")) { [store] in
                    _ = store.saveEvent(d, calendarID: target ?? store.defaultCalendarID, existing: nil, span: .thisEvent)
                }
            }
            dismiss()
        }
    }

    private func saveAsTemplate() {
        guard let d = data else { return }
        synced.templates.append(EventTemplate(
            name: item.title, title: item.title, location: d.location, notes: d.notes,
            urlString: d.urlString, durationMinutes: max(5, item.durationMinutes),
            isAllDay: item.isAllDay, alarmMinutes: d.alarms,
            calendarID: store.writableChoices.contains { $0.id == item.calendarID } ? item.calendarID : nil,
            emoji: item.emoji, colorHex: d.colorHex,
            startMinutes: item.isAllDay ? nil : cal.minutesSinceStartOfDay(item.start)))
        state.showToast(String(localized: "Template saved"))
    }

    private func geocode() async {
        guard let loc = item.location, !loc.isEmpty else { return }
        let geocoder = CLGeocoder()
        if let place = try? await geocoder.geocodeAddressString(loc).first, let c = place.location?.coordinate {
            coordinate = c
        }
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

/// Text and .ics export for sharing events and sending invitations.
enum ICSExport {
    static func shareText(for item: EventItem, data: LocalEventData?) -> String {
        var lines = [item.displayTitle]
        if item.isAllDay {
            lines.append(item.start.formatted(date: .complete, time: .omitted))
        } else {
            lines.append(item.start.formatted(date: .complete, time: .omitted) + ", " + Fmt.time(item.start) + " – " + Fmt.time(item.end))
        }
        if let loc = item.location { lines.append("📍 " + loc) }
        if let u = data?.urlString, !u.isEmpty { lines.append(u) }
        if let notes = data?.notes, !notes.isEmpty { lines.append(""); lines.append(notes) }
        return lines.joined(separator: "\n")
    }

    static func file(title: String, data d: LocalEventData, invite: Bool = false) -> URL? {
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
        var ics = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Weekdot//Weekdot Calendar//EN"]
        if invite { ics.append("METHOD:REQUEST") }
        ics += ["BEGIN:VEVENT", "UID:\(UUID().uuidString)@weekdot", "DTSTAMP:\(f.string(from: Date()))"]
        if d.isAllDay {
            ics.append("DTSTART;VALUE=DATE:\(df.string(from: d.start))")
            let end = max(d.end, Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: d.start)) ?? d.end)
            ics.append("DTEND;VALUE=DATE:\(df.string(from: end))")
        } else {
            ics.append("DTSTART:\(f.string(from: d.start))")
            ics.append("DTEND:\(f.string(from: d.end))")
        }
        ics.append("SUMMARY:\(esc(title))")
        if !d.location.isEmpty { ics.append("LOCATION:\(esc(d.location))") }
        if !d.notes.isEmpty { ics.append("DESCRIPTION:\(esc(d.notes))") }
        if !d.urlString.isEmpty { ics.append("URL:\(d.urlString)") }
        if let r = d.recurrence {
            var rule = "RRULE:FREQ=\(r.frequency.rawValue.uppercased());INTERVAL=\(r.interval)"
            if r.frequency == .weekly, !r.weekdays.isEmpty {
                let codes = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]
                rule += ";BYDAY=" + r.weekdays.sorted().map { codes[$0 - 1] }.joined(separator: ",")
            }
            if let c = r.count { rule += ";COUNT=\(c)" }
            if let e = r.endDate { rule += ";UNTIL=\(f.string(from: e))" }
            ics.append(rule)
        }
        if invite {
            for m in d.invitees { ics.append("ATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:\(m)") }
        }
        for m in d.alarms {
            ics += ["BEGIN:VALARM", "ACTION:DISPLAY", "DESCRIPTION:\(esc(title))",
                    "TRIGGER:\(m >= 0 ? "-" : "")PT\(abs(m))M", "END:VALARM"]
        }
        ics += ["END:VEVENT", "END:VCALENDAR"]
        let safe = title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent((safe.isEmpty ? "event" : safe) + ".ics")
        do {
            try ics.joined(separator: "\r\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
