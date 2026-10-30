import Foundation
import CoreLocation
import WeatherKit

/// Native Apple WeatherKit forecast. No third-party weather provider is used.
/// WeatherKit authentication requires Apple-side App ID service enablement and
/// a newly generated provisioning profile that carries the entitlement.
@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    struct Day {
        let symbol: String
        let max: Double
        let min: Double
        let unit: String
        var maxText: String { "\(Int(max.rounded()))°" }
    }

    @Published private(set) var days: [String: Day] = [:]
    private let manager = CLLocationManager()
    private var lastFetch: Date?
    private var lastUnit: String?
    private var lastLocationKey: String?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    @Published private(set) var statusMessage: String? = nil
    @Published private(set) var lastUpdated: Date? = nil
    @Published var manualCity: String = UserDefaults.standard.string(forKey: "weekdot.weather.manualCity") ?? "" {
        didSet {
            UserDefaults.standard.set(manualCity, forKey: "weekdot.weather.manualCity")
            lastFetch = nil
            days = [:]
            statusMessage = nil
        }
    }
    @Published private(set) var isLoading = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    private static func key(_ d: Date, _ cal: Calendar) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    func forecast(for day: Date, calendar: Calendar) -> Day? {
        days[Self.key(day, calendar)]
    }

    func refreshIfNeeded(settings: AppSettings, force: Bool = false) async {
        guard settings.showWeather else { days = [:]; statusMessage = nil; return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let unit = resolvedUnit(settings)
        let locationKey = manualCity.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !force, let last = lastFetch, Date().timeIntervalSince(last) < 3 * 3600,
           lastUnit == unit, lastLocationKey == locationKey, !days.isEmpty { return }
        let loc: CLLocation?
        if !manualCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loc = await locationForManualCity()
        } else {
            loc = await currentLocation()
        }
        guard let loc else {
            statusMessage = String(localized: "Weather location unavailable. Enter your town under Settings → Weather, or allow location access.")
            return
        }
        do {
            // Request only the daily subset: avoid unnecessary WeatherKit calls
            // and make the authentication failure explicit to the user.
            let forecast = try await WeatherKit.WeatherService.shared.weather(for: loc, including: .daily)
            let temperatureUnit: UnitTemperature = unit == "F" ? .fahrenheit : .celsius
            let calendar = settings.calendar
            var map: [String: Day] = [:]
            for day in forecast.forecast {
                map[Self.key(day.date, calendar)] = Day(
                    symbol: day.symbolName,
                    max: day.highTemperature.converted(to: temperatureUnit).value,
                    min: day.lowTemperature.converted(to: temperatureUnit).value,
                    unit: unit)
            }
            guard !map.isEmpty else {
                statusMessage = String(localized: "Apple Weather returned no daily forecast. Please try again later.")
                return
            }
            days = map
            sourceName = "Apple Weather"
            statusMessage = nil
            lastFetch = Date()
            lastUpdated = lastFetch
            lastUnit = unit
            lastLocationKey = locationKey
        } catch {
            // Short, user-facing text; the technical details only go to the log.
            print("Weekdot weather:", error)
            statusMessage = String(localized: "The weather forecast is not available right now. Try again later.")
            // Do not pretend that an authorization failure was fixed or switch
            // to an unrelated third-party service.
            sourceName = "Apple Weather"
        }
    }

    @Published private(set) var sourceName = "Apple Weather"

    private func resolvedUnit(_ s: AppSettings) -> String {
        switch s.temperatureUnit {
        case .celsius: return "C"
        case .fahrenheit: return "F"
        case .system: return Locale.current.measurementSystem == .us ? "F" : "C"
        }
    }

    private func locationForManualCity() async -> CLLocation? {
        let name = manualCity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        do {
            let places = try await CLGeocoder().geocodeAddressString(name)
            return places.first?.location
        } catch {
            statusMessage = String(localized: "Town not found. Check the spelling or use your device location.")
            return nil
        }
    }

    private func currentLocation() async -> CLLocation? {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            for _ in 0..<12 {
                if manager.authorizationStatus != .notDetermined { break }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        let status = manager.authorizationStatus
        #if os(macOS)
        guard status == .authorizedAlways || status == .authorized else { return nil }
        #else
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return nil }
        #endif
        if let loc = manager.location, Date().timeIntervalSince(loc.timestamp) < 6 * 3600 { return loc }
        return await withCheckedContinuation { cont in
            locationContinuation = cont
            manager.requestLocation()
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 7_000_000_000)
                guard let self, let waiting = self.locationContinuation else { return }
                self.locationContinuation = nil
                waiting.resume(returning: self.manager.location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last
        Task { @MainActor in
            self.locationContinuation?.resume(returning: loc)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

}
