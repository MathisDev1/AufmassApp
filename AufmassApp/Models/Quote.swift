import Foundation

/// Vollständiges Angebot mit Raumdaten, Positionen und Kundendaten
struct Quote: Codable, Identifiable {
    var id: UUID = UUID()
    var quoteNumber: String
    var createdAt: Date
    var validUntil: Date
    var customerName: String
    var customerAddress: String
    var projectAddress: String
    var notes: String
    var room: Room
    var items: [QuoteItem]
    var vatRate: Double = 0.19

    init(
        id: UUID = UUID(),
        quoteNumber: String = Quote.generateQuoteNumber(),
        createdAt: Date = Date(),
        validUntil: Date? = nil,
        customerName: String = "",
        customerAddress: String = "",
        projectAddress: String = "",
        notes: String = "",
        room: Room,
        items: [QuoteItem] = [],
        vatRate: Double = 0.19
    ) {
        self.id = id
        self.quoteNumber = quoteNumber
        self.createdAt = createdAt
        self.validUntil = validUntil ?? Calendar.current.date(byAdding: .day, value: 30, to: createdAt)!
        self.customerName = customerName
        self.customerAddress = customerAddress
        self.projectAddress = projectAddress
        self.notes = notes
        self.room = room
        self.items = items
        self.vatRate = vatRate
    }

    // MARK: - Berechnete Preise

    /// Netto-Zwischensumme aller Positionen
    var subtotalNet: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    /// Mehrwertsteuerbetrag
    var vatAmount: Double {
        subtotalNet * vatRate
    }

    /// Gesamtbetrag brutto inklusive MwSt.
    var totalGross: Double {
        subtotalNet + vatAmount
    }

    // MARK: - Hilfsfunktionen

    /// Generiert eine Angebotsnummer im Format ANG-YYYY-XXXX
    static func generateQuoteNumber() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let random = Int.random(in: 1000...9999)
        return "ANG-\(year)-\(random)"
    }

    static var preview: Quote {
        let room = Room.preview
        let items = [
            QuoteItem(
                serviceItem: ServiceItem(name: "Wände streichen (2×)", pricePerM2: 14.00, surfaceType: .wall, isSelected: true),
                appliedArea: Double(room.wallAreaNet),
                totalPrice: Double(room.wallAreaNet) * 14.00
            ),
            QuoteItem(
                serviceItem: ServiceItem(name: "Decke streichen (1×)", pricePerM2: 10.00, surfaceType: .ceiling, isSelected: true),
                appliedArea: Double(room.ceilingArea),
                totalPrice: Double(room.ceilingArea) * 10.00
            )
        ]
        return Quote(
            quoteNumber: "ANG-2026-4711",
            customerName: "Max Mustermann",
            customerAddress: "Musterstraße 12\n12345 Musterstadt",
            projectAddress: "Baustelle Hauptstraße 5\n12345 Musterstadt",
            notes: "Bitte Termin vorab abstimmen.",
            room: room,
            items: items
        )
    }
}
