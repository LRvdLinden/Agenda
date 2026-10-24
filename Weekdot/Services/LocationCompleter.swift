import Foundation
import MapKit

/// Place suggestions while typing a location (like Apple Calendar's location suggestions).
@MainActor
final class LocationCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    struct Result: Identifiable, Hashable {
        let title: String
        let subtitle: String
        var id: String { title + "|" + subtitle }
    }

    @Published var results: [Result] = []
    var query: String = "" {
        didSet {
            let q = query.trimmingCharacters(in: .whitespaces)
            if q.count < 2 { results = []; return }
            completer.queryFragment = q
        }
    }

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let list = completer.results.map { Result(title: $0.title, subtitle: $0.subtitle) }
        Task { @MainActor in self.results = list }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.results = [] }
    }
}
