import Foundation

/// Demo / screenshot mode, used to make App Store and website screenshots automatically on CI.
///
/// Start the app with the launch arguments `-WDScreenshot <scene>` (scenes: week, month, day, year, list,
/// event, discover, sports, settings). Weekdot then uses an in-memory store with sample calendars, never asks
/// for permissions and opens the requested screen. Normal users never pass these arguments.
enum ScreenshotMode {
    /// The requested scene, or nil in normal use.
    static let scene: String? = {
        let value = UserDefaults.standard.string(forKey: "WDScreenshot")
        return (value?.isEmpty == false) ? value : nil
    }()

    static var isActive: Bool { scene != nil }

    /// Two-letter language of the running app, for the sample event titles.
    static var language: String {
        let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
        return samples[code] != nil ? code : "en"
    }

    struct Sample {
        let title: String
        let calendar: Int      // index into calendars
        let day: Int           // 0 = Monday of this week … 6 = Sunday
        let hour: Double
        let duration: Double   // hours; 0 = all-day
        let location: String
        let emoji: String
    }

    /// Calendars: (title per language, colour).
    static func calendars() -> [(String, String)] {
        let names: [String: [String]] = [
            "en": ["Work", "Personal", "Family", "Sports"],
            "nl": ["Werk", "Privé", "Gezin", "Sport"],
            "de": ["Arbeit", "Privat", "Familie", "Sport"],
            "fr": ["Travail", "Personnel", "Famille", "Sport"],
            "es": ["Trabajo", "Personal", "Familia", "Deporte"],
            "it": ["Lavoro", "Personale", "Famiglia", "Sport"],
        ]
        let n = names[language] ?? names["en"]!
        return [(n[0], "#007AFF"), (n[1], "#E8352F"), (n[2], "#34C759"), (n[3], "#FF9500")]
    }

    static func events() -> [Sample] {
        let t = samples[language] ?? samples["en"]!
        func s(_ i: Int, _ cal: Int, _ day: Int, _ hour: Double, _ dur: Double, _ loc: String = "", _ emoji: String = "") -> Sample {
            Sample(title: t[i], calendar: cal, day: day, hour: hour, duration: dur, location: loc, emoji: emoji)
        }
        return [
            s(0, 0, 0, 9, 0.5), s(1, 0, 0, 13, 1.5, "Studio 4"), s(2, 1, 0, 18, 1, "", "🏋️"),
            s(3, 0, 1, 10, 1), s(4, 2, 1, 15.5, 1, "", "⚽️"), s(5, 1, 1, 19.5, 2, "Bistro Zuid", "🍝"),
            s(6, 0, 2, 9, 1), s(7, 0, 2, 11, 1, "Zoom"), s(8, 1, 2, 17, 1, "", "🦷"),
            s(9, 2, 3, 0, 0, "", "🎂"), s(10, 0, 3, 14, 2), s(11, 3, 3, 20, 2, "", "🏟️"),
            s(12, 0, 4, 9.5, 1), s(13, 1, 4, 12.5, 1, "", "🥗"), s(14, 2, 4, 16, 1.5),
            s(15, 1, 5, 10, 2, "", "🚲"), s(16, 2, 5, 14, 3), s(17, 3, 5, 15, 2, "", "🏎️"),
            s(18, 2, 6, 11, 2, "", "🥞"), s(19, 1, 6, 17, 1.5),
        ]
    }

    private static let samples: [String: [String]] = [
        "en": ["Stand-up", "Design review", "Gym", "Team planning", "Football training", "Dinner with Sam",
               "Product sync", "Client call", "Dentist", "Emma's birthday", "Quarterly review", "Champions League",
               "1:1 with Lisa", "Lunch", "School pick-up", "Bike ride", "Zoo with the kids", "Grand Prix",
               "Brunch", "Movie night"],
        "nl": ["Stand-up", "Design review", "Sportschool", "Teamplanning", "Voetbaltraining", "Uit eten met Sam",
               "Productoverleg", "Klantgesprek", "Tandarts", "Verjaardag Emma", "Kwartaalreview", "Champions League",
               "1-op-1 met Lisa", "Lunch", "Kinderen ophalen", "Fietstocht", "Dierentuin met de kids", "Grand Prix",
               "Brunch", "Filmavond"],
        "de": ["Stand-up", "Design-Review", "Fitnessstudio", "Teamplanung", "Fußballtraining", "Abendessen mit Sam",
               "Produkt-Sync", "Kundentermin", "Zahnarzt", "Emmas Geburtstag", "Quartalsreview", "Champions League",
               "1:1 mit Lisa", "Mittagessen", "Kinder abholen", "Radtour", "Zoo mit den Kindern", "Grand Prix",
               "Brunch", "Filmabend"],
        "fr": ["Stand-up", "Revue design", "Salle de sport", "Planification", "Entraînement de foot", "Dîner avec Sam",
               "Point produit", "Appel client", "Dentiste", "Anniversaire d'Emma", "Revue trimestrielle", "Ligue des champions",
               "Point avec Lisa", "Déjeuner", "Sortie d'école", "Balade à vélo", "Zoo avec les enfants", "Grand Prix",
               "Brunch", "Soirée cinéma"],
        "es": ["Stand-up", "Revisión de diseño", "Gimnasio", "Planificación", "Entreno de fútbol", "Cena con Sam",
               "Reunión de producto", "Llamada con cliente", "Dentista", "Cumpleaños de Emma", "Revisión trimestral", "Champions League",
               "1:1 con Lisa", "Comida", "Recoger a los niños", "Paseo en bici", "Zoo con los niños", "Gran Premio",
               "Brunch", "Noche de cine"],
        "it": ["Stand-up", "Revisione design", "Palestra", "Pianificazione", "Allenamento calcio", "Cena con Sam",
               "Sync prodotto", "Chiamata cliente", "Dentista", "Compleanno di Emma", "Revisione trimestrale", "Champions League",
               "1:1 con Lisa", "Pranzo", "Prendere i bambini", "Giro in bici", "Zoo con i bambini", "Gran Premio",
               "Brunch", "Serata film"],
    ]
}
