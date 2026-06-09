import Foundation

/// Art der Fläche, auf die eine Leistung angewandt wird
enum SurfaceType: String, Codable, CaseIterable {
    case wall    = "Wand"
    case ceiling = "Decke"
    case floor   = "Boden"
}

/// Eine Leistungsposition mit Preis pro Einheit
struct ServiceItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var pricePerM2: Double
    var surfaceType: SurfaceType
    var isSelected: Bool
    var isCustom: Bool
    /// Wenn true, wird der Preis pro Laufmeter (Umfang) statt pro m² berechnet
    var isPerLinearMeter: Bool

    init(
        id: UUID = UUID(),
        name: String,
        pricePerM2: Double,
        surfaceType: SurfaceType,
        isSelected: Bool = false,
        isCustom: Bool = false,
        isPerLinearMeter: Bool = false
    ) {
        self.id = id
        self.name = name
        self.pricePerM2 = pricePerM2
        self.surfaceType = surfaceType
        self.isSelected = isSelected
        self.isCustom = isCustom
        self.isPerLinearMeter = isPerLinearMeter
    }

    // MARK: - Maler-Standardleistungen

    static let malerDefaults: [ServiceItem] = [
        ServiceItem(name: "Wände streichen (1×)",   pricePerM2: 8.00,  surfaceType: .wall),
        ServiceItem(name: "Wände streichen (2×)",   pricePerM2: 14.00, surfaceType: .wall),
        ServiceItem(name: "Tapete entfernen",        pricePerM2: 6.00,  surfaceType: .wall),
        ServiceItem(name: "Tapete neu kleben",       pricePerM2: 18.00, surfaceType: .wall),
        ServiceItem(name: "Decke streichen (1×)",   pricePerM2: 10.00, surfaceType: .ceiling),
        ServiceItem(name: "Decke streichen (2×)",   pricePerM2: 16.00, surfaceType: .ceiling),
        ServiceItem(name: "Grundierung auftragen",   pricePerM2: 4.00,  surfaceType: .wall),
        ServiceItem(name: "Sockelleisten streichen", pricePerM2: 3.50,  surfaceType: .wall, isPerLinearMeter: true),
    ]

    // MARK: - Fliesen-Standardleistungen

    static let fliesenDefaults: [ServiceItem] = [
        ServiceItem(name: "Bodenfliesen legen (Standard)", pricePerM2: 35.00, surfaceType: .floor),
        ServiceItem(name: "Wandfliesen legen (Standard)",  pricePerM2: 42.00, surfaceType: .wall),
        ServiceItem(name: "Bodenfliesen legen (Premium)",  pricePerM2: 55.00, surfaceType: .floor),
        ServiceItem(name: "Wandfliesen legen (Premium)",   pricePerM2: 65.00, surfaceType: .wall),
        ServiceItem(name: "Fugen verfüllen",               pricePerM2: 8.00,  surfaceType: .floor),
        ServiceItem(name: "Fliesenkleber inkl. Auftragen", pricePerM2: 12.00, surfaceType: .floor),
        ServiceItem(name: "Altfliesen entfernen",          pricePerM2: 15.00, surfaceType: .floor),
    ]

    static var preview: ServiceItem {
        ServiceItem(name: "Wände streichen (2×)", pricePerM2: 14.00, surfaceType: .wall, isSelected: true)
    }
}
