import Foundation

/// Published sports calendars. Links are downloaded as ICS by Weekdot itself;
/// nothing here starts the Apple Calendar application.
struct SportsFeed: Identifiable {
    enum Kind: Equatable { case motorsport, competition, club }

    let name: String
    let url: String
    let kind: Kind
    let source: String
    let website: String?

    var id: String { url }
    var logoURL: URL? {
        guard let website else { return nil }
        var c = URLComponents(string: "https://www.google.com/s2/favicons")
        c?.queryItems = [URLQueryItem(name: "domain", value: website), URLQueryItem(name: "sz", value: "128")]
        return c?.url
    }
}

enum SportsCatalog {
    private static let footballSource = "matchcalendar.football"

    private static func competition(_ name: String, _ slug: String) -> SportsFeed {
        SportsFeed(name: name,
                   url: "https://matchcalendar.football/competition/\(slug)/\(slug).ics?src=competition",
                   kind: .competition, source: footballSource, website: competitionLogoSite(slug))
    }

    private static func club(_ name: String, _ slug: String, _ website: String) -> SportsFeed {
        SportsFeed(name: name,
                   url: "https://matchcalendar.football/team/\(slug)/\(slug).ics?src=team",
                   kind: .club, source: footballSource, website: website)
    }

    private static func competitionLogoSite(_ slug: String) -> String? {
        switch slug {
        case "eredivisie": return "eredivisie.nl"
        case "knvb-beker": return "knvb.nl"
        case "champions-league", "europa-league", "conference-league", "nations-league": return "uefa.com"
        case "bundesliga": return "bundesliga.com"
        case "premier-league": return "premierleague.com"
        case "la-liga": return "laliga.com"
        default: return nil
        }
    }

    static let motorsport: [SportsFeed] = [
        SportsFeed(name: "Formula 1 · all sessions", url: "https://agenda-abonnement.nl/formule1.ics",
                   kind: .motorsport, source: "agenda-abonnement.nl", website: "formula1.com"),
        SportsFeed(name: "Formula 1 · races & qualifying", url: "https://agenda-abonnement.nl/formula1.ics",
                   kind: .motorsport, source: "agenda-abonnement.nl", website: "formula1.com")
    ]

    static func competitions(country: String) -> [SportsFeed] {
        let global = [competition("UEFA Champions League", "champions-league")]
        switch country {
        case "NL": return [competition("Eredivisie", "eredivisie"),
                           competition("KNVB Beker", "knvb-beker")] + global
        case "GB": return [competition("Premier League", "premier-league"),
                           competition("EFL Championship", "championship")] + global
        case "DE": return [competition("Bundesliga", "bundesliga")] + global
        case "ES": return [competition("La Liga", "la-liga")] + global
        case "IT": return [competition("Serie A", "serie-a")] + global
        case "FR": return [competition("Ligue 1", "ligue-1")] + global
        case "PT": return [competition("Primeira Liga", "primeira-liga")] + global
        case "TR": return [competition("Süper Lig", "super-lig")] + global
        case "US", "CA": return [competition("Major League Soccer", "major-league-soccer")] + global
        default: return global
        }
    }

    static func clubs(country: String) -> [SportsFeed] {
        switch country {
        case "NL": return [
            club("Ajax", "ajax", "ajax.nl"),
            club("PSV Eindhoven", "psv-eindhoven", "psv.nl"),
            club("Feyenoord", "feyenoord", "feyenoord.com"),
            club("NEC Nijmegen", "nec-nijmegen", "necnijmegen.nl"),
            club("AZ Alkmaar", "az-alkmaar", "az.nl"),
            club("FC Twente", "twente", "fctwente.nl"),
            club("FC Utrecht", "utrecht", "fcutrecht.nl"),
            club("FC Groningen", "groningen", "fcgroningen.nl"),
            club("SC Heerenveen", "heerenveen", "sc-heerenveen.nl"),
            club("Sparta Rotterdam", "sparta-rotterdam", "sparta-rotterdam.nl"),
            club("Go Ahead Eagles", "go-ahead-eagles", "ga-eagles.nl"),
            club("PEC Zwolle", "pec-zwolle", "peczwolle.nl"),
            club("Fortuna Sittard", "fortuna-sittard", "fortunasittard.nl"),
            club("ADO Den Haag", "ado-den-haag", "adodenhaag.nl"),
            club("Excelsior", "excelsior", "sbvexcelsior.nl"),
            club("Willem II", "willem-ii", "willem-ii.nl"),
            club("Cambuur", "cambuur", "cambuur.nl"),
            club("Telstar", "telstar", "sctelstar.nl")
        ]
        case "GB": return [
            club("Arsenal", "arsenal", "arsenal.com"),
            club("Chelsea", "chelsea", "chelseafc.com"),
            club("Liverpool", "liverpool", "liverpoolfc.com"),
            club("Manchester United", "manchester-united", "manutd.com"),
            club("Manchester City", "manchester-city", "mancity.com"),
            club("Tottenham Hotspur", "tottenham-hotspur", "tottenhamhotspur.com"),
            club("Newcastle United", "newcastle-united", "newcastleunited.com"),
            club("Aston Villa", "aston-villa", "avfc.co.uk"),
            club("Everton", "everton", "evertonfc.com"),
            club("Leeds United", "leeds", "leedsunited.com")
        ]
        case "DE": return [
            club("Bayern München", "bayern-munchen", "fcbayern.com"),
            club("Borussia Dortmund", "borussia-dortmund", "bvb.de"),
            club("Bayer Leverkusen", "bayer-leverkusen", "bayer04.de"),
            club("RB Leipzig", "rb-leipzig", "rbleipzig.com"),
            club("Eintracht Frankfurt", "eintracht-frankfurt", "eintracht.de"),
            club("VfB Stuttgart", "vfb-stuttgart", "vfb.de")
        ]
        case "ES": return [
            club("Real Madrid", "real-madrid", "realmadrid.com"),
            club("FC Barcelona", "barcelona", "fcbarcelona.com"),
            club("Atlético Madrid", "atletico-madrid", "atleticodemadrid.com"),
            club("Athletic Club", "athletic-club", "athletic-club.eus"),
            club("Real Sociedad", "real-sociedad", "realsociedad.eus"),
            club("Villarreal", "villarreal", "villarrealcf.es")
        ]
        case "IT": return [
            club("Inter", "inter", "inter.it"),
            club("AC Milan", "ac-milan", "acmilan.com"),
            club("Juventus", "juventus", "juventus.com"),
            club("AS Roma", "roma", "asroma.com"),
            club("Napoli", "napoli", "sscnapoli.it"),
            club("Lazio", "lazio", "sslazio.it")
        ]
        case "FR": return [
            club("Paris Saint-Germain", "paris-saint-germain", "psg.fr"),
            club("Olympique Marseille", "marseille", "om.fr"),
            club("Olympique Lyon", "lyon", "ol.fr"),
            club("AS Monaco", "monaco", "asmonaco.com"),
            club("LOSC Lille", "lille", "losc.fr")
        ]
        case "PT": return [
            club("Benfica", "benfica", "slbenfica.pt"),
            club("FC Porto", "fc-porto", "fcporto.pt"),
            club("Sporting CP", "sporting-cp", "sporting.pt"),
            club("Braga", "braga", "scbraga.pt")
        ]
        case "TR": return [
            club("Galatasaray", "galatasaray", "galatasaray.org"),
            club("Fenerbahçe", "fenerbahce", "fenerbahce.org"),
            club("Beşiktaş", "besiktas", "bjk.com.tr"),
            club("Trabzonspor", "trabzonspor", "trabzonspor.org.tr")
        ]
        case "US", "CA": return [
            club("Los Angeles FC", "los-angeles-fc", "lafc.com"),
            club("Inter Miami", "inter-miami", "intermiamicf.com"),
            club("LA Galaxy", "los-angeles-galaxy", "lagalaxy.com"),
            club("Seattle Sounders", "seattle-sounders", "soundersfc.com"),
            club("New York City FC", "new-york-city", "newyorkcityfc.com"),
            club("Toronto FC", "toronto-fc", "torontofc.ca"),
            club("Vancouver Whitecaps", "vancouver-whitecaps", "whitecapsfc.com")
        ]
        default: return []
        }
    }
}
