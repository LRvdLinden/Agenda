import SwiftUI
import EventKit

/// What the event editor should open with.
struct EditorRequest: Identifiable {
    let id = UUID()
    /// Existing event to edit.
    var item: EventItem? = nil
    /// Start for a new event (nil = next round hour).
    var start: Date? = nil
    var allDay: Bool = false
    var template: EventTemplate? = nil
    /// Prefill a new event as a copy of this one.
    var duplicateOf: EventItem? = nil
}

/// A drag/drop change waiting for "this event / future events" on a repeating event.
struct PendingChange: Identifiable {
    enum Kind { case move(Date, Bool?), resize(Date), delete }
    let id = UUID()
    var item: EventItem
    var kind: Kind
}

struct UndoAction: Identifiable {
    let id = UUID()
    let text: String
    let perform: () -> Void
}

enum AppSheet: String, Identifiable {
    case calendars, search, settings, templates, rules, quickAdd, goToDate
    var id: String { rawValue }
}

@MainActor
final class AppState: ObservableObject {
    @Published var mode: CalendarViewMode
    @Published var date: Date = Date()
    @Published var editor: EditorRequest?
    @Published var detail: EventItem?
    @Published var sheet: AppSheet?
    @Published var pendingChange: PendingChange?
    /// Copied event, waiting to be pasted in a time slot.
    @Published var clipboard: EventItem?
    /// +1 / -1 from keyboard commands.
    @Published var pendingStep: Int = 0
    @Published var isDraggingEvent = false
    @Published var toast: String?
    @Published var undo: UndoAction?

    init() {
        mode = SyncedStore.shared.settings.defaultView
    }

    func suggestedStart(settings: AppSettings) -> Date {
        let cal = settings.calendar
        let now = Date()
        let base = cal.isDate(date, inSameDayAs: now) ? now : cal.date(on: date, minutes: 9 * 60)
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: base)
        let hour = cal.date(from: comps) ?? base
        return cal.isDate(date, inSameDayAs: now) ? hour.addingTimeInterval(3600) : hour
    }

    /// First day shown in the week view: the start of the week for a 7-day week, otherwise the selected day.
    func weekStart(settings: AppSettings) -> Date {
        let cal = settings.calendar
        return settings.clampedDayCount == 7 ? cal.startOfWeek(for: date) : cal.startOfDay(for: date)
    }

    func step(_ direction: Int, settings: AppSettings) {
        let cal = settings.calendar
        withAnimation(.snappy(duration: 0.25)) {
            switch mode {
            case .day: date = cal.addingDays(direction, to: date)
            case .week: date = cal.addingDays(direction * settings.clampedDayCount, to: date)
            case .month: date = cal.date(byAdding: .month, value: direction, to: date) ?? date
            case .year: date = cal.date(byAdding: .year, value: direction, to: date) ?? date
            case .list: date = cal.addingDays(direction * 30, to: date)
            }
        }
    }

    func goToday() {
        withAnimation(.snappy(duration: 0.25)) { date = Date() }
    }

    func open(day: Date, mode newMode: CalendarViewMode = .day) {
        withAnimation(.snappy(duration: 0.25)) {
            date = day
            mode = newMode
        }
    }

    /// Shows a message with an Undo button for a few seconds.
    func offerUndo(_ text: String, _ perform: @escaping () -> Void) {
        let action = UndoAction(text: text, perform: perform)
        undo = action
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            if undo?.id == action.id { undo = nil }
        }
    }

    func showToast(_ text: String) {
        toast = text
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if toast == text { toast = nil }
        }
    }
}
