import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Address-based, automatically refreshed waste collection integrations.
/// Providers are explicit; there is no blind probing of residents' addresses.
enum WasteCollectionProvider: String, CaseIterable, Identifiable, Codable {
    case afa, acv, alm, apn, afbar, circulus, cyclus, dar, akel, akird, akm, nfd, akom, akpm, akpu, rad, rd4, aknw, afrm, rov, rwm, svr, sudwest, akvnl, venray, akwr, akwl, akwrd, zrd, mont, prezero, arei, avx, avr, denbosch, gad, gemas, akdr, akgr, geh, aknk, akrt, gem, hkdh, hvc, kmoij, afw, afz, mba, remg, rewl, trapi, twm, aklbn, recbe, reno
    var id: String { rawValue }
    var title: String {
        switch self {
        case .afa: return "Afval App"
        case .acv: return "Afvalkalender ACV"
        case .alm: return "Afvalkalender Almere"
        case .apn: return "Alphen aan den Rijn"
        case .afbar: return "Afvalkalender BAR"
        case .circulus: return "Circulus"
        case .cyclus: return "Cyclus"
        case .dar: return "DAR"
        case .akel: return "Etten-Leur"
        case .akird: return "Irado"
        case .akm: return "Meerlanden"
        case .nfd: return "Noardeast-Fryslân"
        case .akom: return "Omrin"
        case .akpm: return "Peel en Maas"
        case .akpu: return "Purmerend"
        case .rad: return "RAD"
        case .rd4: return "RD4"
        case .aknw: return "Reinis"
        case .afrm: return "RMN"
        case .rov: return "ROVA"
        case .rwm: return "RWM"
        case .svr: return "Saver"
        case .sudwest: return "Súdwest-Fryslân"
        case .akvnl: return "Venlo"
        case .venray: return "Venray"
        case .akwr: return "Waalre"
        case .akwl: return "Westland"
        case .akwrd: return "Woerden"
        case .zrd: return "ZRD"
        case .mont: return "Montferland"
        case .prezero: return "PreZero"
        case .arei: return "Area Reiniging"
        case .avx: return "Avalex"
        case .avr: return "Avri"
        case .denbosch: return "Afvalstoffendienst 's-Hertogenbosch"
        case .gad: return "GAD Gooi en Vechtstreek"
        case .gemas: return "Assen"
        case .akdr: return "Drimmelen"
        case .akgr: return "Groningen"
        case .geh: return "Hellendoorn"
        case .aknk: return "Nijkerk"
        case .akrt: return "Tilburg"
        case .gem: return "Meppel"
        case .hkdh: return "Den Haag"
        case .hvc: return "HVC"
        case .kmoij: return "Oude IJsselstreek"
        case .afw: return "Mijn Afvalwijzer"
        case .afz: return "Mijn Afvalzaken"
        case .mba: return "Blink"
        case .remg: return "Recyclemanager"
        case .rewl: return "Waardlanden"
        case .trapi: return "TrashAPI Nederland"
        case .twm: return "Twente Milieu"
        case .aklbn: return "Limburg.NET"
        case .recbe: return "Recycle App"
        case .reno: return "Renovasjon Norway"
        }
    }
    var countryCode: String {
        switch self {
        case .afa: return "NL"
        case .acv: return "NL"
        case .alm: return "NL"
        case .apn: return "NL"
        case .afbar: return "NL"
        case .circulus: return "NL"
        case .cyclus: return "NL"
        case .dar: return "NL"
        case .akel: return "NL"
        case .akird: return "NL"
        case .akm: return "NL"
        case .nfd: return "NL"
        case .akom: return "NL"
        case .akpm: return "NL"
        case .akpu: return "NL"
        case .rad: return "NL"
        case .rd4: return "NL"
        case .aknw: return "NL"
        case .afrm: return "NL"
        case .rov: return "NL"
        case .rwm: return "NL"
        case .svr: return "NL"
        case .sudwest: return "NL"
        case .akvnl: return "NL"
        case .venray: return "NL"
        case .akwr: return "NL"
        case .akwl: return "NL"
        case .akwrd: return "NL"
        case .zrd: return "NL"
        case .mont: return "NL"
        case .prezero: return "NL"
        case .arei: return "NL"
        case .avx: return "NL"
        case .avr: return "NL"
        case .denbosch: return "NL"
        case .gad: return "NL"
        case .gemas: return "NL"
        case .akdr: return "NL"
        case .akgr: return "NL"
        case .geh: return "NL"
        case .aknk: return "NL"
        case .akrt: return "NL"
        case .gem: return "NL"
        case .hkdh: return "NL"
        case .hvc: return "NL"
        case .kmoij: return "NL"
        case .afw: return "NL"
        case .afz: return "NL"
        case .mba: return "NL"
        case .remg: return "NL"
        case .rewl: return "NL"
        case .trapi: return "NL"
        case .twm: return "NL"
        case .aklbn: return "BE"
        case .recbe: return "BE"
        case .reno: return "NO"
        }
    }
    var ximmio: (companyCode: String, host: String)? {
        switch self {
        case .acv: return ("f8e2844a-095e-48f9-9f98-71fceb51d2c3", "wasteapi.ximmio.com")
        case .alm: return ("53d8db94-7945-42fd-9742-9bbc71dbe4c1", "wasteapi.ximmio.com")
        case .akm: return ("800bf8d7-6dd1-4490-ba9d-b419d6dc8a45", "wasteprod2api.ximmio.com")
        case .rad: return ("13a2cad9-36d0-4b01-b877-efcb421a864d", "wasteapi2.ximmio.com")
        case .akvnl: return ("280affe9-1428-443b-895a-b90431b8ca31", "wasteapi.ximmio.com")
        case .akwrd: return ("06856f74-6826-4c6a-aabf-69bc9d20b5a6", "wasteprod2api.ximmio.com")
        case .arei: return ("adc418da-d19b-11e5-ab30-625662870761", "wasteapi.ximmio.com")
        case .avx: return ("f7a74ad1-fdbf-4a43-9f91-44644f4d4222", "wasteprod2api.ximmio.com")
        case .avr: return ("78cd4156-394b-413d-8936-d407e334559a", "wasteapi.ximmio.com")
        case .geh: return ("24434f5b-7244-412b-9306-3a2bd1e22bc1", "wasteapi.ximmio.com")
        case .gem: return ("b7a594c7-2490-4413-88f9-94749a3ec62a", "wasteapi.ximmio.com")
        case .mba: return ("252d30d0-2e74-469c-8f1e-c0e2e434eb58", "wasteprod2api.ximmio.com")
        case .rewl: return ("942abcf6-3775-400d-ae5d-7380d728b23c", "wasteapi.ximmio.com")
        case .twm: return ("8d97bb56-5afd-4cbc-a651-b4f7314264b4", "twentemilieuapi.ximmio.com")
        default: return nil
        }
    }
    var isLiveSupported: Bool {
        self == .circulus || [.afa, .akom, .afw, .kmoij, .recbe, .aklbn, .reno, .afbar, .afrm, .gemas, .akgr, .aknk, .akrt, .akdr, .mont].contains(self) || host != nil || ximmio != nil || self == .rov || self == .remg || self == .akird || self == .trapi || self == .rd4
    }
    var host: String? {
        switch self {
        case .afa: return nil
        case .acv: return nil
        case .alm: return nil
        case .apn: return "afvalkalender.alphenaandenrijn.nl"
        case .afbar: return nil
        case .circulus: return nil
        case .cyclus: return "cyclusnv.nl"
        case .dar: return "afvalkalender.dar.nl"
        case .akel: return "afval3xbeter.nl"
        case .akird: return nil
        case .akm: return nil
        case .nfd: return "offalkalinder.nl"
        case .akom: return nil
        case .akpm: return "afvalkalender.peelenmaas.nl"
        case .akpu: return "afvalkalender.purmerend.nl"
        case .rad: return nil
        case .rd4: return nil
        case .aknw: return "reinis.nl"
        case .afrm: return nil
        case .rov: return nil
        case .rwm: return "rwm.nl"
        case .svr: return "saver.nl"
        case .sudwest: return "afvalkalender.sudwestfryslan.nl"
        case .akvnl: return nil
        case .venray: return "afvalkalender.venray.nl"
        case .akwr: return "afvalkalender.waalre.nl"
        case .akwl: return "inzamelkalender.hvcgroep.nl"
        case .akwrd: return nil
        case .zrd: return "zrd.nl"
        case .mont: return nil
        case .prezero: return "inzamelwijzer.prezero.nl"
        case .arei: return nil
        case .avx: return nil
        case .avr: return nil
        case .denbosch: return "afvalstoffendienst.nl"
        case .gad: return "inzamelkalender.gad.nl"
        case .gemas: return nil
        case .akdr: return nil
        case .akgr: return nil
        case .geh: return nil
        case .aknk: return nil
        case .akrt: return nil
        case .gem: return nil
        case .hkdh: return "huisvuilkalender.denhaag.nl"
        case .hvc: return "inzamelkalender.hvcgroep.nl"
        case .kmoij: return nil
        case .afw: return nil
        case .afz: return "www.mijnafvalzaken.nl"
        case .mba: return nil
        case .remg: return nil
        case .rewl: return nil
        case .trapi: return nil
        case .twm: return nil
        case .aklbn: return nil
        case .recbe: return nil
        case .reno: return nil
        }
    }
}

struct WasteCollectionAddress: Codable {
    let provider: WasteCollectionProvider
    let postcode: String
    let houseNumber: String
    var street: String = ""
    var city: String = ""
    var countyID: String = ""
    var apiKey: String = ""

    init(provider: WasteCollectionProvider, postcode: String, houseNumber: String) throws {
        let zip = postcode.uppercased().filter { !$0.isWhitespace }
        let number = houseNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (provider.countryCode == "NL" && zip.range(of: #"^[1-9][0-9]{3}[A-Z]{2}$"#, options: .regularExpression) != nil) || (provider.countryCode != "NL" && zip.count >= 4 && zip.count <= 8),
              number.range(of: #"^[1-9][0-9]{0,4}[A-Za-z0-9\-/ ]{0,10}$"#, options: .regularExpression) != nil else {
            throw WasteCollectionError.invalidAddress
        }
        self.provider = provider
        self.postcode = zip
        self.houseNumber = number
    }
}

enum WasteCollectionError: LocalizedError {
    case invalidAddress, addressNotFound, unavailable, unexpectedResponse, providerNotImplemented, sessionUnavailable, circulusStep(String), httpFailure(Int)
    var errorDescription: String? {
        switch self {
        case .invalidAddress: return "Controleer de postcode en het huisnummer."
        case .addressNotFound: return "Dit adres is niet gevonden bij de gekozen afvalophaler."
        case .unavailable: return "De afvalkalender is momenteel niet bereikbaar. Probeer later opnieuw."
        case .unexpectedResponse: return "De afvalophaler heeft de gegevens gewijzigd; automatisch verversen lukt tijdelijk niet."
        case .providerNotImplemented: return "Deze afvalophaler staat in de catalogus, maar heeft nog geen werkende directe koppeling in Weekdot."
        case .sessionUnavailable: return "Circulus heeft geen geldige adressessie verstrekt. Dit gebeurt vóór de controle van postcode en huisnummer."
        case .circulusStep(let step): return "Circulus: \(step)"
        case .httpFailure(let code): return "De afvalophaler gaf HTTP-fout \(code). Controleer het adres of probeer opnieuw."
        }
    }
}

struct WasteCollectionClient {
    /// Provider connectors based on the public Trashchecker implementations, independently written in Swift.
    func fetch(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        switch address.provider {
        case .circulus: return try await fetchCirculus(address)
        case .rov: return try await fetchROVA(address)
        case .remg: return try await fetchRecyclemanager(address)
        case .akird: return try await fetchIrado(address)
        case .trapi: return try await fetchTrashAPI(address)
        case .rd4: return try await fetchRD4(address)
        case .afbar, .afrm, .gemas, .akgr, .aknk, .akrt: return try await fetchBurgerportaal(address)
        case .afa: return try await fetchAfvalApp(address)
        case .akom: return try await fetchOmrin(address)
        case .mont: return try await fetchMontferland(address)
        case .akdr: return try await fetchDrimmelen(address)
        case .recbe: return try await fetchRecycleBE(address)
        case .aklbn: return try await fetchLimburgNET(address)
        case .reno: return try await fetchRenovasjon(address)
        case .afw: return try await fetchAfvalwijzer(address)
        case .kmoij: return try await fetchKliko(address)
        default:
            if let settings = address.provider.ximmio { return try await fetchXimmio(address, settings: settings) }
            guard address.provider.host != nil else { throw WasteCollectionError.providerNotImplemented }
            return try await fetchREST(address)
        }
    }

    private func request(_ url: URL, session: URLSession = .shared, method: String = "GET", body: Data? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 20
        request.setValue("application/json, */*", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WasteCollectionError.unavailable }
        guard (200...299).contains(http.statusCode) else { throw WasteCollectionError.httpFailure(http.statusCode) }
        guard data.count < 2_000_000 else { throw WasteCollectionError.unexpectedResponse }
        return data
    }

    private func json(_ data: Data) throws -> Any {
        do { return try JSONSerialization.jsonObject(with: data) }
        catch { throw WasteCollectionError.unexpectedResponse }
    }

    private func fetchREST(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        guard let host = address.provider.host else { throw WasteCollectionError.unavailable }
        func endpoint(_ path: String) throws -> URL {
            guard let url = URL(string: "https://\(host)\(path)") else { throw WasteCollectionError.unavailable }
            return url
        }
        let path = "\(address.postcode):\(address.houseNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? address.houseNumber)"
        guard let addresses = try json(await request(endpoint("/adressen/\(path)"))) as? [[String: Any]],
              let rawID = addresses.first?["bagid"] else { throw WasteCollectionError.addressNotFound }
        let bagID = String(describing: rawID)
        guard let kinds = try json(await request(endpoint("/rest/adressen/\(bagID)/afvalstromen"))) as? [[String: Any]] else {
            throw WasteCollectionError.unexpectedResponse
        }
        var labels: [String: String] = [:]
        for kind in kinds {
            let id = String(describing: kind["id"] ?? "")
            labels[id] = kind["page_title"] as? String ?? kind["title"] as? String ?? "Afval"
        }
        var entries: [ICSFeedParser.Entry] = []
        for year in [Calendar.current.component(.year, from: Date()), Calendar.current.component(.year, from: Date()) + 1] {
            guard let dates = try? json(await request(endpoint("/rest/adressen/\(bagID)/kalender/\(year)"))) as? [[String: Any]] else { continue }
            for row in dates {
                guard let raw = row["ophaaldatum"] as? String, let day = dayDate(raw) else { continue }
                let kind = String(describing: row["afvalstroom_id"] ?? "")
                entries.append(entry(label: labels[kind] ?? "Afval", date: day, provider: address.provider))
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    private func postJSON(_ url: URL, payload: [String: Any]) async throws -> Any {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw WasteCollectionError.unavailable }
        guard (200...299).contains(http.statusCode) else { throw WasteCollectionError.httpFailure(http.statusCode) }
        return try json(data)
    }

    private func fetchXimmio(_ address: WasteCollectionAddress, settings: (companyCode: String, host: String)) async throws -> [ICSFeedParser.Entry] {
        let base = "https://\(settings.host)/api/"
        guard let addressURL = URL(string: base + "FetchAdress"),
              let calendarURL = URL(string: base + "GetCalendar") else { throw WasteCollectionError.unavailable }
        let houseDigits = String(address.houseNumber.prefix(while: { $0.isNumber }))
        guard let number = Int(houseDigits) else { throw WasteCollectionError.invalidAddress }
        guard let addressJSON = try await postJSON(addressURL, payload: [
            "companyCode": settings.companyCode, "postCode": address.postcode, "houseNumber": number
        ]) as? [String: Any],
              let found = addressJSON["status"] as? Bool, found,
              let options = addressJSON["dataList"] as? [[String: Any]],
              let id = options.first?["UniqueId"] else { throw WasteCollectionError.addressNotFound }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let start = formatter.string(from: Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now)
        let end = formatter.string(from: Calendar.current.date(byAdding: .day, value: 180, to: now) ?? now)
        guard let calendarJSON = try await postJSON(calendarURL, payload: [
            "companyCode": settings.companyCode, "uniqueAddressID": id, "startDate": start, "endDate": end
        ]) as? [String: Any],
              let ok = calendarJSON["status"] as? Bool, ok,
              let result = calendarJSON["dataList"] as? [[String: Any]] else { throw WasteCollectionError.unexpectedResponse }
        var entries: [ICSFeedParser.Entry] = []
        for row in result {
            let label = row["_pickupTypeText"] as? String ?? "Afval"
            for date in row["pickupDates"] as? [String] ?? [] {
                if let day = dayDate(date) { entries.append(entry(label: label, date: day, provider: address.provider)) }
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    private func fetchROVA(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        var results: [ICSFeedParser.Entry] = []
        let digits = String(address.houseNumber.prefix(while: { $0.isNumber }))
        let addition = String(address.houseNumber.dropFirst(digits.count)).trimmingCharacters(in: .whitespaces)
        for year in [Calendar.current.component(.year, from: Date()), Calendar.current.component(.year, from: Date()) + 1] {
            var components = URLComponents(string: "https://www.rova.nl/api/waste-calendar/year")!
            components.queryItems = [URLQueryItem(name: "postalcode", value: address.postcode),
                                     URLQueryItem(name: "year", value: String(year)),
                                     URLQueryItem(name: "houseNumber", value: digits)]
                + (addition.isEmpty ? [] : [URLQueryItem(name: "addition", value: addition)])
                + ["residual_waste", "gft", "paper", "pruning_waste", "pmd", "best_bag", "christmas_trees"].map { URLQueryItem(name: "types[]", value: $0) }
            guard let url = components.url else { throw WasteCollectionError.unavailable }
            guard let jsonRows = try? json(await request(url)) as? [[String: Any]] else { continue }
            for item in jsonRows {
                guard let raw = item["date"] as? String, let date = dayDate(raw) else { continue }
                let waste = item["wasteType"] as? [String: Any]
                let name = waste?["title"] as? String ?? waste?["code"] as? String ?? "Afval"
                results.append(entry(label: name, date: date, provider: .rov))
            }
        }
        guard !results.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(results)
    }

    private func fetchRecyclemanager(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        var c = URLComponents(string: "https://vpn-wec-api.recyclemanager.nl/v2/calendars")!
        c.queryItems = [URLQueryItem(name: "postalcode", value: address.postcode), URLQueryItem(name: "number", value: address.houseNumber)]
        guard let url = c.url,
              let result = try json(await request(url)) as? [String: Any],
              let data = result["data"] as? [[String: Any]] else { throw WasteCollectionError.unexpectedResponse }
        var entries: [ICSFeedParser.Entry] = []
        for row in data {
            for occurrence in row["occurrences"] as? [[String: Any]] ?? [] {
                let title = occurrence["title"] as? String ?? "Afval"
                let from = occurrence["from"] as? [String: Any]
                if let dateString = from?["date"] as? String, let date = dayDate(dateString) {
                    entries.append(entry(label: title, date: date, provider: .remg))
                }
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    private func fetchIrado(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        var c = URLComponents(string: "https://www.irado.nl/wp-json/wsa/v1/location/address/calendar/pickups")!
        let number = String(address.houseNumber.prefix(while: { $0.isNumber }))
        c.queryItems = [URLQueryItem(name: "zipcode", value: address.postcode), URLQueryItem(name: "number", value: number)]
        guard let url = c.url,
              let result = try json(await request(url)) as? [String: Any],
              let calendarData = result["calendar_data"] as? [String: Any],
              let years = calendarData["pickups"] as? [String: Any] else { throw WasteCollectionError.unexpectedResponse }
        var entries: [ICSFeedParser.Entry] = []
        for (_, y) in years {
            guard let months = y as? [String: Any] else { continue }
            for (_, m) in months {
                guard let days = m as? [String: Any] else { continue }
                for (_, d) in days {
                    for item in d as? [[String: Any]] ?? [] {
                        guard let raw = item["date"] as? String,
                              let date = dayDate(raw),
                              let label = item["type"] as? String else { continue }
                        entries.append(entry(label: label, date: date, provider: .akird))
                    }
                }
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    // The Netherlands generic TrashAPI endpoint (independent of the other address APIs).
    private func fetchTrashAPI(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let digits = String(address.houseNumber.prefix(while: { $0.isNumber }))
        let suffix = String(address.houseNumber.dropFirst(digits.count)).trimmingCharacters(in: .whitespaces)
        var c = URLComponents(string: "https://trashapi.azurewebsites.net/trash")!
        c.queryItems = [
            URLQueryItem(name: "Location", value: ""),
            URLQueryItem(name: "ZipCode", value: address.postcode),
            URLQueryItem(name: "HouseNumber", value: digits),
            URLQueryItem(name: "HouseNumberSuffix", value: suffix),
            URLQueryItem(name: "DiftarCode", value: ""),
            URLQueryItem(name: "ShowWholeYear", value: "true"),
            URLQueryItem(name: "GetCleanprofsData", value: "false")
        ]
        guard let url = c.url,
              let items = try json(await request(url)) as? [[String: Any]] else { throw WasteCollectionError.unexpectedResponse }
        let entries = items.compactMap { row -> ICSFeedParser.Entry? in
            guard let raw = row["date"] as? String, let title = row["name"] as? String,
                  let date = dayDate(raw) else { return nil }
            return entry(label: title, date: date, provider: address.provider)
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    // RD4's dedicated calendar API, kept separate from ROVA's related format.
    private func fetchRD4(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let digits = String(address.houseNumber.prefix(while: { $0.isNumber }))
        let suffix = String(address.houseNumber.dropFirst(digits.count)).trimmingCharacters(in: .whitespaces)
        var entries: [ICSFeedParser.Entry] = []
        for year in [Calendar.current.component(.year, from: Date()), Calendar.current.component(.year, from: Date()) + 1] {
            var c = URLComponents(string: "https://data.rd4.nl/api/v1/waste-calendar")!
            c.queryItems = [
                URLQueryItem(name: "postal_code", value: "\(address.postcode.prefix(4)) \(address.postcode.suffix(2))"),
                URLQueryItem(name: "house_number", value: digits),
                URLQueryItem(name: "year", value: String(year))
            ] + (suffix.isEmpty ? [] : [URLQueryItem(name: "house_number_extension", value: suffix)])
                + ["residual_waste", "gft", "paper", "pruning_waste", "pmd", "best_bag", "christmas_trees"].map {
                    URLQueryItem(name: "types[]", value: $0)
                }
            guard let url = c.url else { throw WasteCollectionError.unavailable }
            guard let obj = try? json(await request(url)) as? [String: Any],
                  let data = obj["data"] as? [String: Any],
                  let items = data["items"] as? [[String: Any]],
                  let rows = items.first else { continue }
            for (_, value) in rows {
                guard let row = value as? [String: Any],
                      let raw = row["date"] as? String, let date = dayDate(raw) else { continue }
                let label = row["type"] as? String ?? "Afval"
                entries.append(entry(label: label, date: date, provider: address.provider))
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    /// Circulus uses a short-lived address session rather than a public, permanent ICS URL.
    /// The sequence mirrors the working Trashchecker flow: GET /login, retrieve CB_SESSION
    /// and its ___AT token, POST /register/zipcode.json, then GET /afvalkalender.json.
    /// Keep the cookies private to this request and do not persist session identifiers.
    private func fetchCirculus(_ address: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        // Use the cookie storage actually attached to the URLSession configuration;
        // a separate storage instance can remain empty despite a successful request.
        let session = URLSession(configuration: config)
        guard let cookieStore = config.httpCookieStorage else {
            throw WasteCollectionError.circulusStep("De sessie heeft geen cookieopslag.")
        }
        defer { session.invalidateAndCancel() }

        let loginURL = URL(string: "https://mijn.circulus.nl/login")!
        var loginRequest = URLRequest(url: loginURL)
        loginRequest.timeoutInterval = 20
        let (_, loginResponse) = try await session.data(for: loginRequest)
        guard let response = loginResponse as? HTTPURLResponse else {
            throw WasteCollectionError.circulusStep("Geen HTTP-antwoord bij het openen van /login.")
        }
        guard (200...399).contains(response.statusCode) else {
            throw WasteCollectionError.circulusStep("/login gaf HTTP \(response.statusCode).")
        }

        // URLSession may follow a redirect. The effective cookie storage and the
        // final response's Set-Cookie headers both need to be inspected.
        let responseHeaders = response.allHeaderFields.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String, let value = pair.value as? String { result[key] = value }
        }
        let parsedCookies = HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for: response.url ?? loginURL)
        let sessionCookies = (cookieStore.cookies(for: loginURL) ?? [])
            + (cookieStore.cookies(for: response.url ?? loginURL) ?? []) + parsedCookies
        guard let addressCookie = sessionCookies.first(where: { $0.name == "CB_SESSION" }) else {
            throw WasteCollectionError.circulusStep("/login gaf HTTP \(response.statusCode), maar geen CB_SESSION-cookie. De aanbieder kan de sessieaanmaak hebben gewijzigd.")
        }
        // Decode once: the session cookie may include percent-escaped separators.
        let cookieValue = addressCookie.value.removingPercentEncoding ?? addressCookie.value
        guard let tokenMarker = cookieValue.range(of: "___AT=") else {
            throw WasteCollectionError.circulusStep("CB_SESSION ontvangen, maar het authenticatietoken ontbreekt.")
        }
        let token = String(cookieValue[tokenMarker.upperBound...].split(separator: "&", maxSplits: 1).first ?? "")
        guard !token.isEmpty else {
            throw WasteCollectionError.circulusStep("Het authenticatietoken in CB_SESSION is leeg.")
        }

        let registerURL = URL(string: "https://mijn.circulus.nl/register/zipcode.json")!
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "authenticityToken", value: token),
            URLQueryItem(name: "zipCode", value: address.postcode),
            URLQueryItem(name: "number", value: address.houseNumber)
        ]
        guard let values = form.percentEncodedQuery else { throw WasteCollectionError.invalidAddress }
        // The upstream endpoint has historically accepted the parameters in the
        // query component of an HTTP POST; reproduce that first before trying
        // the conventional application/x-www-form-urlencoded POST body.
        var candidates: [URLRequest] = []
        var urlWithQuery = URLComponents(url: registerURL, resolvingAgainstBaseURL: false)!
        urlWithQuery.percentEncodedQuery = values
        if let queryURL = urlWithQuery.url {
            var queryRequest = URLRequest(url: queryURL)
            queryRequest.httpMethod = "POST"
            queryRequest.timeoutInterval = 20
            queryRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            candidates.append(queryRequest)
        }
        var formRequest = URLRequest(url: registerURL)
        formRequest.httpMethod = "POST"
        formRequest.httpBody = Data(values.utf8)
        formRequest.timeoutInterval = 20
        formRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        candidates.append(formRequest)

        var addressAccepted = false
        for request in candidates {
            do {
                let (data, res) = try await session.data(for: request)
                guard let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) else { continue }
                // A 200 response may still be an address-validation failure.
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if obj["success"] as? Bool == false || obj["valid"] as? Bool == false ||
                       obj["error"] != nil { continue }
                }
                // The registration normally installs a new CB_SESSION cookie.
                let postCookies = cookieStore.cookies(for: registerURL) ?? []
                if let newSession = postCookies.first(where: { $0.name == "CB_SESSION" }),
                   !newSession.value.isEmpty {
                    addressAccepted = true
                    break
                }
            } catch { continue }
        }
        guard addressAccepted else { throw WasteCollectionError.circulusStep("De adresregistratie bij /register/zipcode.json is afgewezen of gaf geen nieuwe sessie terug.") }

        var amsterdam = Calendar(identifier: .gregorian)
        amsterdam.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        let start = amsterdam.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let end = amsterdam.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = amsterdam
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = amsterdam.timeZone
        formatter.dateFormat = "yyyy-M-d"
        var range = URLComponents(string: "https://mijn.circulus.nl/afvalkalender.json")!
        range.queryItems = [URLQueryItem(name: "from", value: formatter.string(from: start)),
                            URLQueryItem(name: "till", value: formatter.string(from: end))]
        guard let calendarURL = range.url else { throw WasteCollectionError.unavailable }
        let payload = try await request(calendarURL, session: session)
        guard let object = try json(payload) as? [String: Any],
              let data = object["customData"] as? [String: Any],
              let response = data["response"] as? [String: Any],
              let garbage = response["garbage"] as? [[String: Any]] else {
            throw WasteCollectionError.unexpectedResponse
        }
        var entries: [ICSFeedParser.Entry] = []
        for group in garbage {
            let code = (group["code"] as? String ?? "Afval").uppercased()
            let name: String
            switch code {
            case "PAP": name = "Papier"
            case "RESTAFR", "REST": name = "Restafval"
            case "DROCODEV": name = "Plastic"
            case "ZWAKRA", "PMD": name = "PMD"
            case "GFT": name = "GFT"
            case "BEST", "BESTAFR": name = "Textiel"
            case "KERST": name = "Kerstboom"
            default: name = code
            }
            for item in group["dates"] as? [String] ?? [] {
                if let date = dayDate(item) { entries.append(entry(label: name, date: date, provider: .circulus)) }
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    private func url(_ base: String, _ parameters: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: base) else { throw WasteCollectionError.unavailable }
        components.queryItems = parameters
        guard let url = components.url else { throw WasteCollectionError.unavailable }
        return url
    }

    private func rows(_ raw: Any, dateKey: String, labelKey: String, provider: WasteCollectionProvider) -> [ICSFeedParser.Entry] {
        (raw as? [[String: Any]] ?? []).compactMap { item in
            guard let dateStr = item[dateKey] as? String, let day = dayDate(dateStr) else { return nil }
            return entry(label: item[labelKey] as? String ?? "Afval", date: day, provider: provider)
        }
    }

    private func fetchAfvalApp(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        // The provider's servlet returns semicolon-delimited collection information.
        let u = try url("https://dataservice.deafvalapp.nl/dataservice/DataServiceServlet", [
            .init(name: "type", value: "ANDROID"), .init(name: "service", value: "OPHAALSCHEMA"),
            .init(name: "land", value: "NL"), .init(name: "postcode", value: a.postcode),
            .init(name: "straatId", value: "0"), .init(name: "huisnr", value: a.houseNumber), .init(name: "huisnrtoev", value: "")])
        let text = String(decoding: try await request(u), as: UTF8.self)
        var result: [ICSFeedParser.Entry] = []
        for item in text.components(separatedBy: ";") {
            let components = item.components(separatedBy: "|")
            guard let date = components.compactMap({ dayDate($0.trimmingCharacters(in: .whitespacesAndNewlines)) }).first else { continue }
            let label = components.first(where: { !$0.isEmpty && dayDate($0) == nil }) ?? "Afval"
            result.append(entry(label: label, date: date, provider: a.provider))
        }
        guard !result.isEmpty else { throw WasteCollectionError.unexpectedResponse }
        return deduplicated(result)
    }

    private func fetchBurgerportaal(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let organisations: [WasteCollectionProvider: String] = [
            .afrm: "138204213564933597", .afbar: "138204213564933497", .gemas: "138204213565303512",
            .akgr: "452048812597326549", .aknk: "138204213565304094", .akrt: "452048812597339353"]
        guard let org = organisations[a.provider] else { throw WasteCollectionError.providerNotImplemented }
        let key = "AIzaSyA6NkRqJypTfP-cjWzrZNFJzPUbBaGjOdk"
        let signupURL = try url("https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser", [.init(name:"key",value:key)])
        guard let signup = try await postJSON(signupURL, payload: [:]) as? [String:Any],
              let refreshToken = signup["refreshToken"] as? String else { throw WasteCollectionError.sessionUnavailable }
        let authURL = try url("https://securetoken.googleapis.com/v1/token", [.init(name:"key",value:key)])
        let form = "grant_type=refresh_token&refresh_token=\(refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? refreshToken)"
        var req = URLRequest(url: authURL)
        req.httpMethod = "POST"; req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        req.httpBody = Data(form.utf8)
        let (tokenData, _) = try await URLSession.shared.data(for:req)
        guard let token = (try json(tokenData) as? [String:Any])?["access_token"] as? String else { throw WasteCollectionError.sessionUnavailable }
        func get(_ url: URL) async throws -> Any {
            var request = URLRequest(url:url)
            request.setValue(token,forHTTPHeaderField:"Authorization")
            request.setValue("application/json",forHTTPHeaderField:"Accept")
            let (data,response) = try await URLSession.shared.data(for:request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw WasteCollectionError.unavailable }
            return try json(data)
        }
        let addressURL = try url("https://europe-west3-burgerportaal-production.cloudfunctions.net/exposed/organisations/\(org)/address", [
            .init(name:"zipcode",value:a.postcode),.init(name:"housenumber",value:a.houseNumber)])
        guard let addresses = try await get(addressURL) as? [[String:Any]],
              let identifier = addresses.first?["addressId"] else { throw WasteCollectionError.addressNotFound }
        guard let calendarURL = URL(string:"https://europe-west3-burgerportaal-production.cloudfunctions.net/exposed/organisations/\(org)/address/\(identifier)/calendar") else { throw WasteCollectionError.unavailable }
        let result = rows(try await get(calendarURL), dateKey:"collectionDate", labelKey:"fraction", provider:a.provider)
        guard !result.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(result)
    }

    private func fetchOmrin(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let digits = String(a.houseNumber.prefix(while: { $0.isNumber }))
        guard let number = Int(digits) else { throw WasteCollectionError.invalidAddress }
        var payload: [String: Any] = ["Email": NSNull(), "Password": NSNull(),
            "PostalCode": a.postcode, "HouseNumber": number, "DeviceId": UUID().uuidString,
            "Platform": "iOS", "AppVersion": "1.0.0", "OsVersion": "iOS"]
        let suffix = String(a.houseNumber.dropFirst(digits.count)).trimmingCharacters(in: .whitespaces)
        if !suffix.isEmpty { payload["HouseNumberExtension"] = suffix }
        guard let login = try await postJSON(URL(string: "https://api.omrinafvalapp.nl/api/auth/login")!, payload: payload) as? [String: Any],
              let data = login["data"] as? [String: Any], let token = data["accessToken"] as? String else {
            throw WasteCollectionError.sessionUnavailable
        }
        var req = URLRequest(url: URL(string: "https://api.omrinafvalapp.nl/graphql")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["query": "query FetchCalendar { fetchCalendar { id date description type containerType placingTime state } }"])
        let (body, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw WasteCollectionError.unavailable }
        guard let root = try json(body) as? [String: Any], let responseData = root["data"] as? [String: Any] else { throw WasteCollectionError.unexpectedResponse }
        let items = responseData["fetchCalendar"] ?? []
        let result = rows(items, dateKey: "date", labelKey: "type", provider: a.provider)
        guard !result.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(result)
    }

    private func fetchMontferland(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let digits=String(a.houseNumber.prefix(while:{$0.isNumber}))
        let suffix=String(a.houseNumber.dropFirst(digits.count))
        let u=URL(string:"https://appapi.montferland.info/api/v1/garbage/\(a.postcode)/\(digits)/\(suffix)")!
        var req=URLRequest(url:u);req.setValue("77FE5F8B-9051-4B05-A525-C7CCCD42236F",forHTTPHeaderField:"authToken")
        let (data, response)=try await URLSession.shared.data(for:req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WasteCollectionError.unavailable }
        guard let d=try json(data) as? [String:Any] else { throw WasteCollectionError.unexpectedResponse }
        let result=rows(d["collections"] ?? [],dateKey:"collectionDate",labelKey:"fraction",provider:a.provider)
        guard !result.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(result)
    }

    private func fetchAfvalwijzer(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let u=URL(string:"https://www.mijnafvalwijzer.nl/nl/\(a.postcode)/\(a.houseNumber)")!
        let raw=String(decoding:try await request(u),as:UTF8.self)
        // Providers may switch HTML templates. Never invent dates from unrecognized HTML.
        let regex=try NSRegularExpression(pattern:#"(\d{1,2})\s+(januari|februari|maart|april|mei|juni|juli|augustus|september|oktober|november|december)\s+(\d{4})"#,options:.caseInsensitive)
        let months=["januari":1,"februari":2,"maart":3,"april":4,"mei":5,"juni":6,"juli":7,"augustus":8,"september":9,"oktober":10,"november":11,"december":12]
        var result:[ICSFeedParser.Entry]=[]
        for m in regex.matches(in:raw,range:NSRange(raw.startIndex...,in:raw)) {
            guard let r1=Range(m.range(at:1),in:raw),let r2=Range(m.range(at:2),in:raw),let r3=Range(m.range(at:3),in:raw),
                  let day=Int(raw[r1]),let month=months[String(raw[r2]).lowercased()],let year=Int(raw[r3]),
                  let date=Calendar.current.date(from:DateComponents(year:year,month:month,day:day)) else {continue}
            result.append(entry(label:"Afvalophaling",date:date,provider:a.provider))
        }
        guard !result.isEmpty else {throw WasteCollectionError.unexpectedResponse}
        return deduplicated(result)
    }

    private func fetchDrimmelen(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let number=String(a.houseNumber.prefix(while:{$0.isNumber}))
        let suffix=String(a.houseNumber.dropFirst(number.count))
        let boundary="WeekdotBoundary\(UUID().uuidString.replacingOccurrences(of:"-",with:""))"
        let fields=["postal_code":a.postcode,"house_number":number,"house_letter":suffix.isEmpty ? "null" : suffix]
        let body=fields.map { "--\(boundary)\r\nContent-Disposition: form-data; name=\"\($0.key)\"\r\n\r\n\($0.value)\r\n" }.joined()+"--\(boundary)--\r\n"
        var req=URLRequest(url:URL(string:"https://api.straatbeeld.online/v1/waste-calendar")!)
        req.httpMethod="POST";req.httpBody=Data(body.utf8)
        req.setValue("multipart/form-data; boundary=\(boundary)",forHTTPHeaderField:"Content-Type")
        req.setValue("https://drimmelen.afvalkalender.straatbeeld.online",forHTTPHeaderField:"Origin")
        let (data,_)=try await URLSession.shared.data(for:req)
        guard let root=try json(data) as? [String:Any],let years=root["collections"] as? [String:Any] else {throw WasteCollectionError.unexpectedResponse}
        var result:[ICSFeedParser.Entry]=[]
        for y in years.values {for m in (y as? [String:Any] ?? [:]).values {for d in m as? [[String:Any]] ?? [] {
            guard let dateInfo=d["date"] as? [String:Any],let raw=dateInfo["formatted"] as? String,let date=dayDate(raw) else {continue}
            for row in d["data"] as? [[String:Any]] ?? [] {result.append(entry(label:row["display_name"] as? String ?? "Afval",date:date,provider:a.provider))}
        }}}
        guard !result.isEmpty else {throw WasteCollectionError.addressNotFound}
        return deduplicated(result)
    }

    private func fetchKliko(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        let endpoint = "https://cp-oudeijsselstreek.klikocontainermanager.com/MyKliko/wasteCalendarJSON/454/\(a.postcode)/\(a.houseNumber)"
        guard let url = URL(string: endpoint) else { throw WasteCollectionError.invalidAddress }
        guard let root = try json(try await request(url)) as? [String: Any], let days = root["calendar"] as? [String: Any] else {
            throw WasteCollectionError.unexpectedResponse
        }
        var result: [ICSFeedParser.Entry] = []
        for (dateString, value) in days {
            guard let day = dayDate(dateString), let types = value as? [String: Any] else { continue }
            for type in types.keys { result.append(entry(label: type, date: day, provider: a.provider)) }
        }
        guard !result.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(result)
    }

    private func fetchRecycleBE(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        guard !a.street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw WasteCollectionError.invalidAddress }
        let base = "https://api.fostplus.be/recyclecms/public/v1"
        func retrieve(_ url: URL) async throws -> [String: Any] {
            var req = URLRequest(url: url)
            req.setValue("recycleapp.be", forHTTPHeaderField: "x-consumer")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw WasteCollectionError.unavailable }
            guard let obj = try json(data) as? [String: Any] else { throw WasteCollectionError.unexpectedResponse }
            return obj
        }
        let zips = try await retrieve(url(base + "/zipcodes", [.init(name: "q", value: a.postcode)]))
        guard let zipcode = (zips["items"] as? [[String: Any]])?.first, let zipcodeId = zipcode["id"] else { throw WasteCollectionError.addressNotFound }
        let streets = try await retrieve(url(base + "/streets", [.init(name: "q", value: a.street), .init(name: "zipcodes", value: String(describing: zipcodeId))]))
        guard let street = (streets["items"] as? [[String: Any]])?.first(where: { ($0["name"] as? String)?.localizedCaseInsensitiveCompare(a.street) == .orderedSame }),
              let streetId = street["id"] else { throw WasteCollectionError.addressNotFound }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; fmt.locale = Locale(identifier: "en_US_POSIX")
        let today = Date()
        let collections = try await retrieve(url(base + "/collections", [
            .init(name: "size", value: "100"), .init(name: "untilDate", value: fmt.string(from: today.addingTimeInterval(90 * 86400))),
            .init(name: "fromDate", value: fmt.string(from: today.addingTimeInterval(-7 * 86400))),
            .init(name: "houseNumber", value: a.houseNumber), .init(name: "streetId", value: String(describing: streetId)),
            .init(name: "zipcodeId", value: String(describing: zipcodeId))]))
        var entries: [ICSFeedParser.Entry] = []
        for item in collections["items"] as? [[String: Any]] ?? [] {
            guard item["type"] as? String == "collection", let raw = item["timestamp"] as? String,
                  let date = dayDate(raw), let fraction = item["fraction"] as? [String: Any],
                  let names = fraction["name"] as? [String: Any] else { continue }
            let label = (names["nl"] as? String) ?? (names["fr"] as? String) ?? "Afval"
            entries.append(entry(label: label, date: date, provider: a.provider))
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    private func fetchLimburgNET(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        guard !a.street.isEmpty && !a.city.isEmpty else { throw WasteCollectionError.invalidAddress }
        let base = "https://limburg.net/api-proxy/public"
        let towns = try json(try await request(url(base + "/afval-kalender/gemeenten/search", [.init(name: "query", value: a.city)])))
        guard let cityID = (towns as? [[String: Any]])?.first?["nisCode"] else { throw WasteCollectionError.addressNotFound }
        let roads = try json(try await request(url(base + "/afval-kalender/gemeente/\(cityID)/straten/search", [.init(name: "query", value: a.street)])))
        guard let streetID = (roads as? [[String: Any]])?.first?["nummer"] else { throw WasteCollectionError.addressNotFound }
        let numeric = String(a.houseNumber.prefix(while: { $0.isNumber }))
        let suffix = String(a.houseNumber.dropFirst(numeric.count))
        var entries: [ICSFeedParser.Entry] = []
        let calendar = Calendar(identifier: .gregorian)
        for offset in 0..<3 {
            guard let month = calendar.date(byAdding: .month, value: offset, to: Date()) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: month)
            let endpoint = base + "/kalender/\(cityID)/\(comps.year!)-\(comps.month!)"
            let result = try json(try await request(url(endpoint, [
                .init(name: "straatNummer", value: String(describing: streetID)), .init(name: "huisNummer", value: numeric),
                .init(name: "toevoeging", value: suffix)])))
            guard let obj = result as? [String: Any] else { continue }
            for item in obj["events"] as? [[String: Any]] ?? [] {
                let raw = (item["date"] as? String) ?? (item["datum"] as? String) ?? ""
                guard let day = dayDate(raw) else { continue }
                let label = (item["title"] as? String) ?? (item["name"] as? String) ?? "Afval"
                entries.append(entry(label: label, date: day, provider: a.provider))
            }
        }
        guard !entries.isEmpty else { throw WasteCollectionError.unexpectedResponse }
        return deduplicated(entries)
    }

    private func fetchRenovasjon(_ a: WasteCollectionAddress) async throws -> [ICSFeedParser.Entry] {
        guard !a.street.isEmpty && !a.countyID.isEmpty && !a.apiKey.isEmpty else { throw WasteCollectionError.invalidAddress }
        func load(_ path: URL) async throws -> Any {
            var req = URLRequest(url: path)
            req.setValue(a.countyID, forHTTPHeaderField: "Kommunenr")
            req.setValue(a.apiKey, forHTTPHeaderField: "RenovasjonAppKey")
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw WasteCollectionError.unavailable }
            return try json(data)
        }
        let fractions = try await load(URL(string: "https://api.renovasjonsselskapet.no/fraksjoner")!)
        var map: [Int: String] = [:]
        for row in fractions as? [[String: Any]] ?? [] {
            if let n = row["fraksjonId"] as? Int, let name = row["fraksjonNavn"] as? String { map[n] = name }
        }
        let endpoint = try url("https://api.renovasjonsselskapet.no/tommekalender", [
            .init(name: "postalCode", value: a.postcode), .init(name: "streetName", value: a.street),
            .init(name: "houseNumber", value: a.houseNumber), .init(name: "api-version", value: "2")])
        let events = try await load(endpoint)
        var entries: [ICSFeedParser.Entry] = []
        for row in events as? [[String: Any]] ?? [] {
            guard let raw = row["henteDato"] as? String, let date = dayDate(raw) else { continue }
            let name = (row["fraksjonNavn"] as? String) ?? map[row["fraksjonId"] as? Int ?? -1] ?? "Afval"
            entries.append(entry(label: name, date: date, provider: a.provider))
        }
        guard !entries.isEmpty else { throw WasteCollectionError.addressNotFound }
        return deduplicated(entries)
    }

    private func dayDate(_ raw: String) -> Date? {
        let prefix = String(raw.prefix(10))
        let parts = prefix.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, parts[0] > 2020 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    private func entry(label: String, date: Date, provider: WasteCollectionProvider) -> ICSFeedParser.Entry {
        let cal = Calendar(identifier: .gregorian)
        let day = cal.dateComponents([.year, .month, .day], from: date)
        let uid = "waste-\(provider.rawValue)-\(label)-\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
        let start = cal.startOfDay(for: date)
        return ICSFeedParser.Entry(uid: uid, title: label, start: start,
                                   end: cal.date(byAdding: .day, value: 1, to: start)!,
                                   isAllDay: true, location: "", details: provider.title, recurrence: nil)
    }

    private func deduplicated(_ entries: [ICSFeedParser.Entry]) -> [ICSFeedParser.Entry] {
        var ids = Set<String>()
        return entries.filter { ids.insert($0.uid).inserted }.sorted { $0.start < $1.start }
    }
}
