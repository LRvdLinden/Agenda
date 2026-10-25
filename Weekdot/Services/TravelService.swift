import Foundation
import MapKit
import CoreLocation

/// Apple Maps helpers: find a place for an address, travel time from the current location,
/// and open directions in the Maps app. No keys or secrets are needed for MapKit in native apps.
@MainActor
final class TravelService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = TravelService()

    struct Place: Equatable {
        let coordinate: CLLocationCoordinate2D
        let name: String
        static func == (a: Place, b: Place) -> Bool {
            a.coordinate.latitude == b.coordinate.latitude && a.coordinate.longitude == b.coordinate.longitude && a.name == b.name
        }
    }

    private let manager = CLLocationManager()
    private var placeCache: [String: Place] = [:]
    private var etaCache: [String: (minutes: Int, at: Date)] = [:]

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var canUseLocation: Bool {
        let s = manager.authorizationStatus
        #if os(macOS)
        return s == .authorizedAlways || s == .authorized
        #else
        return s == .authorizedWhenInUse || s == .authorizedAlways
        #endif
    }

    func requestPermissionIfNeeded() {
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
    }

    /// Finds the place for an address or place name (Apple Maps search).
    func place(for address: String) async -> Place? {
        let key = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        if let hit = placeCache[key] { return hit }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = key
        if let item = try? await MKLocalSearch(request: request).start().mapItems.first {
            let p = Place(coordinate: item.placemark.coordinate, name: item.name ?? key)
            placeCache[key] = p
            return p
        }
        if let pm = try? await CLGeocoder().geocodeAddressString(key).first, let c = pm.location?.coordinate {
            let p = Place(coordinate: c, name: pm.name ?? key)
            placeCache[key] = p
            return p
        }
        return nil
    }

    /// Driving time in minutes from the current location (nil without location permission or route).
    func travelMinutes(to address: String) async -> Int? {
        let key = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if let hit = etaCache[key], Date().timeIntervalSince(hit.at) < 600 { return hit.minutes }
        requestPermissionIfNeeded()
        guard canUseLocation, let p = await place(for: key) else { return nil }
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: p.coordinate))
        request.transportType = .automobile
        guard let eta = try? await MKDirections(request: request).calculateETA() else { return nil }
        let minutes = max(1, Int((eta.expectedTravelTime / 60).rounded()))
        etaCache[key] = (minutes, Date())
        return minutes
    }

    /// Opens Apple Maps with a route from the current location to the event's address.
    func openDirections(to address: String) async {
        let item: MKMapItem
        if let p = await place(for: address) {
            item = MKMapItem(placemark: MKPlacemark(coordinate: p.coordinate))
            item.name = address
        } else {
            return
        }
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
}
