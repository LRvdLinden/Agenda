import AuthenticationServices
import CryptoKit
import Foundation
import Security
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Links Weekdot to the user's Homey (Athom) and sends the coming days to the Weekdot app on that Homey.
///
/// Flow: sign in with the Homey account (Athom OAuth) → pick a Homey → Weekdot sends a schedule of the next
/// 8 days to the Homey app `nl.lrvdlinden.weekdot` (`POST /api/app/nl.lrvdlinden.weekdot/schedule`).
/// The Homey app sets its own timers from that schedule, so Flows run on time even when the iPhone sleeps.
///
/// The Athom API client (client ID + secret, created at https://tools.developer.homey.app → Web API clients,
/// callback URL https://weekdot.com/homey/callback/) is read from `HomeyClient.plist` in the app bundle.
/// The repository is private, so `Weekdot/HomeyClient.plist` is committed (template: `Config/HomeyClient.example.plist`).
@MainActor
final class HomeyService: NSObject, ObservableObject {
    static let shared = HomeyService()

    static let homeyAppID = "nl.lrvdlinden.weekdot"
    static let homeyAppStoreURL = URL(string: "https://homey.app/en-nl/app/nl.lrvdlinden.weekdot/Weekdot/test/")!
    static let redirectURI = "https://weekdot.com/homey/callback/"
    private static let callbackScheme = "weekdot"
    private static let cloud = "https://api.athom.com"

    struct HomeyInfo: Codable, Hashable, Identifiable {
        var id: String
        var name: String
        var platform: String?
        var localUrlSecure: String?
        var remoteUrl: String?

        var isCloud: Bool { platform == "cloud" }
    }

    struct Tokens: Codable {
        var access: String
        var refresh: String
        var expires: Date
    }

    enum HomeyError: LocalizedError {
        case notConfigured, cancelled, signedOut, noHomey, appMissing, server(Int), bad, homey(Int, String), rescope, alreadyLinked

        var errorDescription: String? {
            switch self {
            case .notConfigured: return String(localized: "The Homey connection is not set up in this version of Weekdot.")
            case .cancelled: return nil
            case .signedOut: return String(localized: "Sign in to Homey again.")
            case .noHomey: return String(localized: "Choose your Homey first.")
            case .appMissing: return String(localized: "Install the Weekdot app on your Homey first.")
            case .server(let code): return String(localized: "Homey could not be reached (\(String(code))). Try again later.")
            case .bad: return String(localized: "Homey sent an unexpected answer. Try again later.")
            case .homey(let code, let message): return "Homey (\(code)): \(message)"
            case .rescope: return String(localized: "Homey gave Weekdot too few permissions. Sign in with Homey again.")
            case .alreadyLinked: return String(localized: "This Homey is already linked with another Weekdot. Unlink it in the settings of the Weekdot app on your Homey.")
            }
        }
    }

    @Published private(set) var homeys: [HomeyInfo] = []
    @Published private(set) var selected: HomeyInfo?
    @Published private(set) var lastSync: Date?
    @Published private(set) var lastSyncCount = 0
    @Published private(set) var appInstalled: Bool?
    @Published var lastError: String?
    /// Steps of the last connection attempt (shown under "Details" in Settings › Homey).
    @Published private(set) var steps: [String] = []
    private func step(_ text: String) { steps.append(text) }
    @Published private(set) var isBusy = false
    @Published private(set) var isSignedIn = false

    /// Send "Busy" instead of titles, places and emoji.
    @Published var hideDetails: Bool {
        didSet { defaults.set(hideDetails, forKey: Key.hideDetails); forceNextSync() }
    }
    /// Calendars that are not sent to Homey.
    @Published var excludedCalendarIDs: Set<String> {
        didSet { defaults.set(Array(excludedCalendarIDs), forKey: Key.excluded); forceNextSync() }
    }

    private enum Key {
        static let selected = "weekdot.homey.selected"
        static let lastSync = "weekdot.homey.lastSync"
        static let digest = "weekdot.homey.digest"
        static let hideDetails = "weekdot.homey.hideDetails"
        static let excluded = "weekdot.homey.excluded"
        static let tokens = "homey.tokens"
    }

    private let defaults = UserDefaults.standard
    private var tokens: Tokens? { didSet { isSignedIn = tokens != nil } }
    private var session: (base: URL, token: String, homeyID: String)?
    private var pendingSync: Task<Void, Never>?
    /// Weekdot's calendar store, so a schedule can be sent right after linking.
    weak var calendarStore: CalendarStore?
    private var authSession: ASWebAuthenticationSession?

    private override init() {
        hideDetails = UserDefaults.standard.bool(forKey: Key.hideDetails)
        excludedCalendarIDs = Set(UserDefaults.standard.stringArray(forKey: Key.excluded) ?? [])
        super.init()
        tokens = Keychain.read(Key.tokens).flatMap { try? JSONDecoder().decode(Tokens.self, from: $0) }
        // property observers don't run inside init, so set the signed-in state here too
        // (without this Weekdot asked to sign in again after every restart)
        isSignedIn = tokens != nil
        selected = defaults.data(forKey: Key.selected).flatMap { try? JSONDecoder().decode(HomeyInfo.self, from: $0) }
        lastSync = defaults.object(forKey: Key.lastSync) as? Date
    }

    // MARK: Configuration

    private struct ClientConfig { let id: String; let secret: String }

    private static let client: ClientConfig? = {
        guard let url = Bundle.main.url(forResource: "HomeyClient", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any],
              let id = dict["ClientID"] as? String, let secret = dict["ClientSecret"] as? String,
              !id.isEmpty, !secret.isEmpty, !id.hasPrefix("YOUR_") else { return nil }
        return ClientConfig(id: id, secret: secret)
    }()

    var isConfigured: Bool { Self.client != nil }
    /// Sending only needs the chosen Homey and the link key (public endpoints), not a valid Homey sign-in.
    var isLinked: Bool { selected != nil }

    // MARK: Sign in

    /// Opens the Homey sign-in page; afterwards the user's Homeys are loaded.
    func signIn() async {
        guard let client = Self.client else { lastError = HomeyError.notConfigured.errorDescription; return }
        lastError = nil
        let state = UUID().uuidString
        var comps = URLComponents(string: Self.cloud + "/oauth2/authorise")!
        comps.queryItems = [
            .init(name: "client_id", value: client.id),
            .init(name: "redirect_uri", value: Self.redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "authorization_type", value: "code"),
            .init(name: "state", value: state),
        ]
        do {
            let callback = try await authenticate(url: comps.url!)
            let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard items.first(where: { $0.name == "state" })?.value == state,
                  let code = items.first(where: { $0.name == "code" })?.value else { throw HomeyError.bad }
            isBusy = true
            do {
                try await exchange(["grant_type": "authorization_code", "code": code, "authorization_code": code,
                                    "redirect_uri": Self.redirectURI])
                try await loadHomeys()
            } catch {
                isBusy = false
                throw error
            }
            isBusy = false
            // one Homey: use it right away (and send the schedule)
            if homeys.count == 1, let only = homeys.first { await choose(only) }
        } catch HomeyError.cancelled {
        } catch {
            lastError = error.localizedDescription
        }
    }

    func signOut() {
        tokens = nil
        session = nil
        selected = nil
        homeys = []
        appInstalled = nil
        lastSync = nil
        Keychain.delete(Key.tokens)
        
        for k in [Key.selected, Key.lastSync, Key.digest] { defaults.removeObject(forKey: k) }
    }

    /// The user's Homeys (Homey Pro and Homey Cloud).
    func loadHomeys() async throws {
        let data = try await cloudRequest("GET", "/user/me")
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = obj["homeys"] as? [[String: Any]] else { throw HomeyError.bad }
        homeys = list.compactMap { h in
            guard let id = (h["_id"] as? String) ?? (h["id"] as? String) else { return nil }
            return HomeyInfo(id: id, name: (h["name"] as? String) ?? "Homey", platform: h["platform"] as? String,
                             localUrlSecure: h["localUrlSecure"] as? String, remoteUrl: h["remoteUrl"] as? String)
        }
        // keep the chosen Homey's addresses up to date (they can change)
        if let sel = selected, let fresh = homeys.first(where: { $0.id == sel.id }) { store(selected: fresh) }
    }

    func choose(_ homey: HomeyInfo) async {
        store(selected: homey)
        session = nil
        
        appInstalled = nil
        forceNextSync()
        await checkApp()
        // send the coming days right away, so the Homey app shows "linked" immediately
        if appInstalled == true, let store = calendarStore { await sync(store: store, force: true) }
    }

    private func store(selected h: HomeyInfo) {
        selected = h
        defaults.set(try? JSONEncoder().encode(h), forKey: Key.selected)
    }

    /// Is the Weekdot app installed on the chosen Homey?
    func checkApp() async {
        do {
            _ = try await publicRequest("GET", "/ping")
            step("✓ Weekdot app found on this Homey")
            appInstalled = true
            lastError = nil
        } catch HomeyError.appMissing {
            appInstalled = false
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: Sync

    private func forceNextSync() { defaults.removeObject(forKey: Key.digest) }

    /// Sends the schedule a little later, so a burst of changes becomes one update.
    func syncSoon(store: CalendarStore) {
        guard isLinked, !ScreenshotMode.isActive else { return }
        pendingSync?.cancel()
        pendingSync = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.sync(store: store)
        }
    }

    /// Sends the next 8 days to Homey. Skipped when nothing changed and the last update is recent.
    func sync(store: CalendarStore, force: Bool = false) async {
        calendarStore = store
        guard isLinked, !ScreenshotMode.isActive else { return }
        if isBusy {
            // still busy (e.g. right after signing in): try again shortly
            if force { Task { try? await Task.sleep(nanoseconds: 1_500_000_000); await self.sync(store: store, force: true) } }
            return
        }
        if force { steps = [] }
        let payload = makePayload(store: store)
        guard let body = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else { return }
        // compare without the "sentAt" time
        var stable = payload
        stable.removeValue(forKey: "sentAt")
        let digestData = (try? JSONSerialization.data(withJSONObject: stable, options: [.sortedKeys])) ?? body
        let digest = SHA256.hash(data: digestData).map { String(format: "%02x", $0) }.joined()
        if !force, defaults.string(forKey: Key.digest) == digest,
           let last = lastSync, Date().timeIntervalSince(last) < 3 * 3600 { return }
        isBusy = true
        defer { isBusy = false }
        #if os(iOS)
        let bg = UIApplication.shared.beginBackgroundTask(withName: "Weekdot Homey")
        defer { UIApplication.shared.endBackgroundTask(bg) }
        #endif
        do {
            step("→ \((payload["events"] as? [Any])?.count ?? 0) events")
            try await sendSchedule(payload)
            step("✓ Homey app received the schedule")
            appInstalled = true
            lastSync = Date()
            lastSyncCount = (payload["events"] as? [Any])?.count ?? 0
            lastError = nil
            defaults.set(lastSync, forKey: Key.lastSync)
            defaults.set(digest, forKey: Key.digest)
        } catch HomeyError.appMissing {
            appInstalled = false
            step("✗ Weekdot app not found on this Homey (404)")
        } catch {
            lastError = error.localizedDescription
            step("✗ " + error.localizedDescription)
        }
    }

    // MARK: Link with the Weekdot Homey app
    //
    // Homey gives Web API clients no rights on an app's own endpoints (only homey.app.readonly), so the sign-in is
    // used only to find the user's Homey and its addresses. Weekdot talks to the Weekdot Homey app through its
    // public endpoints (like the Apple Health app does): Weekdot makes a secret key, registers it once with
    // POST /pair (the first key wins; "Unlink" in the Homey app settings clears it), and every schedule is sent
    // with that key. The key is shared through iCloud Keychain, so iPhone, iPad and Mac use the same link.

    private func linkKey() -> String {
        guard let h = selected else { return "" }
        let account = "homey.link." + h.id
        if let d = Keychain.read(account, synchronizable: true), let k = String(data: d, encoding: .utf8), !k.isEmpty { return k }
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let key = bytes.map { String(format: "%02x", $0) }.joined()
        Keychain.write(Data(key.utf8), for: account, synchronizable: true)
        return key
    }

    /// Public endpoint of the Weekdot Homey app (no Homey token): local address first, then Homey's cloud address.
    private func publicRequest(_ method: String, _ path: String, json: [String: Any]? = nil) async throws -> Data {
        guard let h = selected else { throw HomeyError.noHomey }
        var bases = [h.localUrlSecure, h.remoteUrl].compactMap { $0 }.compactMap(URL.init(string:))
        if bases.isEmpty, let u = URL(string: "https://\(h.id).connect.athom.com") { bases = [u] }
        var lastError: Error = HomeyError.server(0)
        for (i, base) in bases.enumerated() {
            var req = URLRequest(url: base.appendingPathComponent("api/app/\(Self.homeyAppID)" + path))
            req.httpMethod = method
            req.timeoutInterval = i == 0 && bases.count > 1 ? 4 : 25
            if let json {
                req.httpBody = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                if (200..<300).contains(code) { return data }
                if code == 404 { throw HomeyError.appMissing }
                let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
                let message = (obj as? [String: Any]).flatMap { ($0["error"] as? String) ?? ($0["message"] as? String) }
                    ?? (obj as? String) ?? String(data: data.prefix(200), encoding: .utf8) ?? ""
                if message.contains("already_linked") { throw HomeyError.alreadyLinked }
                throw message.isEmpty ? HomeyError.server(code) : HomeyError.homey(code, message)
            } catch let e as HomeyError {
                throw e   // Homey answered: don't try the other address
            } catch {
                step("… \(base.host ?? "Homey"): \(error.localizedDescription)")
                lastError = error
            }
        }
        throw lastError
    }

    private func sendSchedule(_ payload: [String: Any]) async throws {
        let key = linkKey()
        _ = try await publicRequest("POST", "/pair", json: ["key": key, "device": Self.deviceName])
        step("✓ Linked with the Weekdot Homey app")
        var withKey = payload
        withKey["key"] = key
        _ = try await publicRequest("POST", "/schedule", json: withKey)
    }

    private func makePayload(store: CalendarStore) -> [String: Any] {
        let cal = store.synced.settings.calendar
        let from = cal.startOfDay(for: Date())
        let to = cal.addingDays(8, to: from)
        let iso = ISO8601DateFormatter()
        let day = DateFormatter()
        day.calendar = Calendar(identifier: .gregorian)
        day.locale = Locale(identifier: "en_US_POSIX")
        day.timeZone = cal.timeZone
        day.dateFormat = "yyyy-MM-dd"
        let busy = String(localized: "Busy")

        let items = store.events(from: from, to: to).filter {
            !$0.isReminder && !$0.isDeclined && !excludedCalendarIDs.contains($0.calendarID)
        }
        let events: [[String: Any]] = items.map { e in
            // all-day: first day and the day after the last day (like iCalendar)
            let lastDay = cal.startOfDay(for: max(e.start, e.end.addingTimeInterval(-1)))
            var ev: [String: Any] = [
                "id": e.id,
                "start": iso.string(from: e.start),
                "end": iso.string(from: e.end),
                "allDay": e.isAllDay,
                "startDay": day.string(from: cal.startOfDay(for: e.start)),
                "endDay": day.string(from: cal.addingDays(1, to: lastDay)),
                "calendarId": e.calendarID,
                "calendar": e.calendarTitle,
                "color": e.colorHex,
                "free": e.isFree,
            ]
            if hideDetails {
                ev["title"] = busy
            } else {
                ev["title"] = e.title
                if let emoji = e.emoji, !emoji.isEmpty { ev["emoji"] = emoji }
                if let loc = e.location, !loc.isEmpty { ev["location"] = loc }
                if e.travelMinutes > 0 { ev["travelMinutes"] = e.travelMinutes }
            }
            return ev
        }
        let calendars: [[String: Any]] = store.allChoices
            .filter { !excludedCalendarIDs.contains($0.id) }
            .map { ["id": $0.id, "title": $0.title, "color": $0.colorHex] }
        return [
            "version": 1,
            "app": "Weekdot",
            "appVersion": Weekdot.version,
            "device": Self.deviceName,
            "sentAt": iso.string(from: Date()),
            "timeZone": cal.timeZone.identifier,
            "language": Locale.current.language.languageCode?.identifier ?? "en",
            "from": iso.string(from: from),
            "to": iso.string(from: to),
            "calendars": calendars,
            "events": events,
        ]
    }

    private static var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        return "Weekdot"
        #endif
    }

    // MARK: Requests

    private func validAccessToken() async throws -> String {
        guard let t = tokens else { throw HomeyError.signedOut }
        if t.expires > Date().addingTimeInterval(60) { return t.access }
        try await exchange(["grant_type": "refresh_token", "refresh_token": t.refresh])
        guard let fresh = tokens else { throw HomeyError.signedOut }
        return fresh.access
    }

    /// Code or refresh token → access token (stored in the keychain).
    private func exchange(_ form: [String: String]) async throws {
        guard let client = Self.client else { throw HomeyError.notConfigured }
        var req = URLRequest(url: URL(string: Self.cloud + "/oauth2/token")!)
        req.httpMethod = "POST"
        let basic = Data("\(client.id):\(client.secret)".utf8).base64EncodedString()
        req.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let all = form.merging(["client_id": client.id, "client_secret": client.secret]) { a, _ in a }
        req.httpBody = all.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")" }
            .joined(separator: "&").data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code == 400 || code == 401 {
            if form["grant_type"] == "refresh_token" { signOut(); throw HomeyError.signedOut }
            throw HomeyError.server(code)
        }
        guard code == 200,
              let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = obj["access_token"] as? String else { throw HomeyError.server(code) }
        let refresh = (obj["refresh_token"] as? String) ?? tokens?.refresh ?? ""
        let expires = Date().addingTimeInterval((obj["expires_in"] as? Double) ?? 3600)
        let t = Tokens(access: access, refresh: refresh, expires: expires)
        tokens = t
        if let d = try? JSONEncoder().encode(t) { Keychain.write(d, for: Key.tokens) }
    }

    private func cloudRequest(_ method: String, _ path: String, retried: Bool = false) async throws -> Data {
        var req = URLRequest(url: URL(string: Self.cloud + path)!)
        req.httpMethod = method
        req.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code == 401, !retried, tokens != nil {
            tokens?.expires = .distantPast
            return try await cloudRequest(method, path, retried: true)
        }
        guard (200..<300).contains(code) else {
            let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let message = (obj as? [String: Any]).flatMap { ($0["error_description"] as? String) ?? ($0["error"] as? String) ?? ($0["message"] as? String) }
                ?? (obj as? String) ?? String(data: data.prefix(200), encoding: .utf8)
            if let message, !message.isEmpty { throw HomeyError.homey(code, message) }
            throw HomeyError.server(code)
        }
        return data
    }

    /// Logs in to the chosen Homey with a delegation token. Tries the local address first, then the cloud one.
    private func homeySession() async throws -> (base: URL, token: String) {
        guard let h = selected else { throw HomeyError.noHomey }
        if let s = session, s.homeyID == h.id { return (s.base, s.token) }
        let delegation: Data
        do {
            delegation = try await cloudRequest("POST", "/delegation/token?audience=homey")
            step("✓ Homey account (delegation token)")
        } catch {
            step("✗ Homey account: " + error.localizedDescription)
            throw error
        }
        guard let jwt = try JSONSerialization.jsonObject(with: delegation, options: [.fragmentsAllowed]) as? String
        else { throw HomeyError.bad }
        let bases = [h.localUrlSecure, h.remoteUrl].compactMap { $0 }.compactMap(URL.init(string:))
        var lastError: Error = HomeyError.server(0)
        for (i, base) in bases.enumerated() {
            var req = URLRequest(url: base.appendingPathComponent("api/manager/users/login"))
            req.httpMethod = "POST"
            req.timeoutInterval = i == 0 && bases.count > 1 ? 4 : 20
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["token": jwt])
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard code == 200,
                      let token = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? String
                else {
                    step("✗ \(base.host ?? "Homey"): login \(code) \(String(data: data.prefix(120), encoding: .utf8) ?? "")")
                    lastError = HomeyError.server(code); continue
                }
                step("✓ Logged in to \(base.host ?? "Homey")")
                session = (base, token, h.id)
                return (base, token)
            } catch {
                step("✗ \(base.host ?? "Homey"): \(error.localizedDescription)")
                lastError = error
            }
        }
        throw lastError
    }

    /// Calls the Weekdot app on the Homey (`/api/app/nl.lrvdlinden.weekdot/...`).
    @discardableResult
    private func appRequest(_ method: String, _ path: String, body: Data? = nil, auth: Bool = true) async throws -> Data {
        try await homeyRequest(method, "api/app/\(Self.homeyAppID)" + path, body: body, auth: auth)
    }

    /// A request to the chosen Homey. `auth: false` for the app's public endpoint: no token is sent, because a
    /// token without the needed scope makes Homey refuse even a public endpoint.
    private func homeyRequest(_ method: String, _ path: String, body: Data? = nil, auth: Bool = true, retried: Bool = false) async throws -> Data {
        let s = try await homeySession()
        var req = URLRequest(url: s.base.appendingPathComponent(path))
        req.httpMethod = method
        req.timeoutInterval = 25
        if auth { req.setValue("Bearer \(s.token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code == 401, !retried {
            session = nil
            return try await homeyRequest(method, path, body: body, auth: auth, retried: true)
        }
        if code == 404 { throw HomeyError.appMissing }
        if code == 403, String(data: data, encoding: .utf8)?.localizedCaseInsensitiveContains("scope") == true {
            // The sign-in was made before the API client had these permissions (scopes are fixed per sign-in).
            // Drop it, so the next "Sign In with Homey" gets a token with the current permissions.
            session = nil
            tokens = nil
            Keychain.delete(Key.tokens)
            step("✗ Sign-in has too few permissions; sign in again")
            throw HomeyError.rescope
        }
        guard (200..<300).contains(code) else {
            // show Homey's own error text (e.g. a missing permission) instead of only the number
            let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let message = (obj as? [String: Any]).flatMap { ($0["error"] as? String) ?? ($0["message"] as? String) }
                ?? (obj as? String) ?? String(data: data.prefix(200), encoding: .utf8)
            if let message, !message.isEmpty { throw HomeyError.homey(code, message) }
            throw HomeyError.server(code)
        }
        return data
    }

    // MARK: Web sign-in

    private func authenticate(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: Self.callbackScheme) { url, error in
                if let url { cont.resume(returning: url) }
                else if let e = error as? ASWebAuthenticationSessionError, e.code == .canceledLogin {
                    cont.resume(throwing: HomeyError.cancelled)
                } else { cont.resume(throwing: error ?? HomeyError.bad) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            authSession = session
            session.start()
        }
    }
}

extension HomeyService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            #if os(iOS)
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first ?? ASPresentationAnchor()
            #elseif os(macOS)
            return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
            #endif
        }
    }
}

/// Small keychain wrapper for the Homey tokens.
enum Keychain {
    private static let service = "nl.lrvdlinden.weekdot.homey"

    static func read(_ key: String, synchronizable: Bool = false) -> Data? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecAttrAccount as String: key, kSecReturnData as String: true,
                                kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!,
                                kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        return SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess ? out as? Data : nil
    }

    static func write(_ data: Data, for key: String, synchronizable: Bool = false) {
        delete(key, synchronizable: synchronizable)
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecAttrAccount as String: key, kSecValueData as String: data,
                                kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!,
                                kSecAttrAccessible as String: synchronizable ? kSecAttrAccessibleAfterFirstUnlock : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        SecItemAdd(q as CFDictionary, nil)
    }

    static func delete(_ key: String, synchronizable: Bool = false) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecAttrAccount as String: key,
                                kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!]
        SecItemDelete(q as CFDictionary)
    }
}
