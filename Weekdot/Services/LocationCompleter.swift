import Foundation
import MapKit

/// Address and place suggestions from Apple Maps while typing a location.
@MainActor
final class LocationCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    struct Result: Identifiable {
        let title: String
        let subtitle: String
        let completion: MKLocalSearchCompletion
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

    func clear() { results = [] }

    /// Full Apple Maps text for a suggestion: "Name, street, postcode city" (or the address alone).
    func resolve(_ r: Result) async -> String {
        let fallback = r.subtitle.isEmpty ? r.title : r.title + ", " + r.subtitle
        guard let item = try? await MKLocalSearch(request: MKLocalSearch.Request(completion: r.completion)).start().mapItems.first else {
            return fallback
        }
        let pm = item.placemark
        var parts: [String] = []
        let street = [pm.thoroughfare, pm.subThoroughfare].compactMap { $0 }.joined(separator: " ")
        if !street.isEmpty { parts.append(street) }
        let city = [pm.postalCode, pm.locality].compactMap { $0 }.joined(separator: " ")
        if !city.isEmpty { parts.append(city) }
        if let country = pm.country { parts.append(country) }
        let address = parts.joined(separator: ", ")
        if let name = item.name, !name.isEmpty, !address.hasPrefix(name), name != street {
            return address.isEmpty ? name : name + ", " + address
        }
        return address.isEmpty ? fallback : address
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let list = completer.results
        Task { @MainActor in
            self.results = list.map { Result(title: $0.title, subtitle: $0.subtitle, completion: $0) }
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.results = [] }
    }
}
