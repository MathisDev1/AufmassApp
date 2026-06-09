import Foundation

/// Eine berechnete Angebotsposition aus Leistung × Fläche
struct QuoteItem: Codable, Identifiable {
    var id: UUID = UUID()
    var serviceItem: ServiceItem
    var appliedArea: Double
    var totalPrice: Double

    /// Einheit je nach Abrechnungsart (m² oder lfm für Sockelleisten)
    var unitDescription: String {
        serviceItem.isPerLinearMeter ? "lfm" : "m²"
    }

    static var preview: QuoteItem {
        QuoteItem(
            serviceItem: ServiceItem.preview,
            appliedArea: 42.5,
            totalPrice: 595.0
        )
    }
}
