import SwiftUI

/// Circulus requires an address-bound website session. The downloaded .ics file
/// is a snapshot, not a public authenticated-free subscription endpoint.
struct CirculusImportView: View {
    var initialCountryCode: String = "NL"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showImporter = false
    @State private var selectedProvider: WasteCollectionProvider = .circulus
    @State private var selectedCountry = "NL"
    @State private var postcode = ""
    @State private var houseNumber = ""
    @State private var street = ""
    @State private var city = ""
    @State private var countyID = ""
    @State private var providerKey = ""
    @State private var errorMessage: String?
    @EnvironmentObject private var subscriptions: FeedSubscriptionManager
    @EnvironmentObject private var store: CalendarStore

    private let addressURL = URL(string: "https://mijn.circulus.nl/uw-adres?returnUrl=https%3A%2F%2Fmijn.circulus.nl%2Fafvalkalender%2F")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack(alignment: .bottomLeading) {
                        Image("PhotoWaste")
                            .resizable().scaledToFill().frame(height: 180).clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.78)],
                                       startPoint: .top, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Circulus").font(.title.bold())
                            Text("Personal Waste Calendar").font(.headline)
                        }.foregroundStyle(.white).padding(18)
                    }
                    .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("Automatisch bijgewerkte afvalkalender")
                        .font(.headline)
                    Text("Kies je afvalophaler en voer je postcode en huisnummer in. Weekdot haalt de ophaaldagen op en controleert automatisch op wijzigingen.")
                        .foregroundStyle(.secondary)
                    Picker("Land", selection: $selectedCountry) {
                        Text("🇳🇱 Nederland").tag("NL")
                        Text("🇧🇪 België").tag("BE")
                        Text("🇳🇴 Noorwegen").tag("NO")
                    }
                    .onChange(of: selectedCountry) { _, country in
                        if let first = WasteCollectionProvider.allCases.first(where: { $0.countryCode == country }) { selectedProvider = first }
                    }
                    Picker("Afvalophaler", selection: $selectedProvider) {
                        ForEach(WasteCollectionProvider.allCases.filter { $0.countryCode == selectedCountry }) { provider in
                            Text(provider.title).tag(provider)
                        }
                    }
                    TextField(selectedCountry == "NL" ? "Postcode (bijv. 1234AB)" : "Postcode", text: $postcode)
                    TextField("Huisnummer (incl. toevoeging)", text: $houseNumber)
                    if selectedProvider == .aklbn || selectedProvider == .reno || selectedProvider == .recbe {
                        TextField("Straat", text: $street)
                        if selectedProvider == .aklbn { TextField("Gemeente", text: $city) }
                    }
                    if selectedProvider == .reno {
                        TextField("Gemeentenummer", text: $countyID)
                        SecureField("Renovasjon API-sleutel", text: $providerKey)
                    }
                    Button {
                        Task {
                            do {
                                var address = try WasteCollectionAddress(provider: selectedProvider,
                                    postcode: postcode, houseNumber: houseNumber)
                                address.street = street; address.city = city
                                address.countyID = countyID; address.apiKey = providerKey
                                try await subscriptions.subscribeWaste(address: address, store: store)
                                dismiss()
                            } catch { errorMessage = error.localizedDescription }
                        }
                    } label: {
                        Label("Voeg live afvalkalender toe", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(subscriptions.isBusy || postcode.isEmpty || houseNumber.isEmpty || (!selectedProvider.isLiveSupported))
                    if !selectedProvider.isLiveSupported {
                        Text("Deze aanbieder is opgenomen in de catalogus. Een live koppeling is voor deze aanbieder nog niet beschikbaar.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if subscriptions.isBusy { ProgressView("Afvalkalender ophalen…") }
                    Divider()
                    Text("Eenmalige ICS-import (zonder automatische updates)")
                        .font(.headline)
                    Button { openURL(addressURL) } label: {
                        Label("Open Circulus", systemImage: "arrow.up.right.square")
                    }
                    Button { showImporter = true } label: {
                        Label("Importeer gedownload ICS-bestand", systemImage: "square.and.arrow.down")
                    }
                    Text("Bestaande eenmalige imports worden niet automatisch live; voeg daarvoor hierboven een adresgebonden abonnement toe. Beschikbaarheid hangt af van de aanbieder.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                selectedCountry = ["NL", "BE", "NO"].contains(initialCountryCode) ? initialCountryCode : "NL"
                if let first = WasteCollectionProvider.allCases.first(where: { $0.countryCode == selectedCountry }) { selectedProvider = first }
            }
            .navigationTitle("Waste Collection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Afvalkalender", isPresented: Binding(get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .sheet(isPresented: $showImporter) {
                SubscribeView(suggestedName: "Circulus · Waste Collection", category: "waste", countryCode: "NL")
            }
        }
    }
}
