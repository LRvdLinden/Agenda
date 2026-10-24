import Foundation
import CoreLocation

/// Daily forecast above the days (optional). Uses the free Open-Meteo forecast with the
/// approximate location of the device; nothing is stored or sent elsewhere.
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
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

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

    func refreshIfNeeded(settings: AppSettings) async {
        guard settings.showWeather else { days = [:]; return }
        let unit = resolvedUnit(settings)
        if let last = lastFetch, Date().timeIntervalSince(last) < 3 * 3600, lastUnit == unit, !days.isEmpty { return }
        guard let loc = await currentLocation() else { return }
        let lat = String(format: "%.2f", loc.coordinate.latitude)
        let lon = String(format: "%.2f", loc.coordinate.longitude)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=16"
            + (unit == "F" ? "&temperature_unit=fahrenheit" : "")
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            var map: [String: Day] = [:]
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            let cal = Calendar(identifier: .gregorian)
            for (i, ds) in decoded.daily.time.enumerated() {
                guard let d = f.date(from: ds), i < decoded.daily.weather_code.count else { continue }
                map[Self.key(d, cal)] = Day(symbol: Self.symbol(decoded.daily.weather_code[i]),
                                            max: decoded.daily.temperature_2m_max[safe: i] ?? 0,
                                            min: decoded.daily.temperature_2m_min[safe: i] ?? 0,
                                            unit: unit)
            }
            days = map
            lastFetch = Date()
            lastUnit = unit
        } catch {
            // Weather is a nice-to-have; fail silently.
        }
    }

    private func resolvedUnit(_ s: AppSettings) -> String {
        switch s.temperatureUnit {
        case .celsius: return "C"
        case .fahrenheit: return "F"
        case .system: return Locale.current.measurementSystem == .us ? "F" : "C"
        }
    }

    private func currentLocation() async -> CLLocation? {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
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

    private struct Response: Decodable {
        struct Daily: Decodable {
            let time: [String]
            let weather_code: [Int]
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
        }
        let daily: Daily
    }

    /// WMO weather codes → SF Symbols.
    static func symbol(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
