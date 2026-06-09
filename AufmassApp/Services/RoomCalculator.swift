import Foundation

/// Berechnet Raumflächen und Angebotspreise aus Scanndaten
struct RoomCalculator {

    /// Erstellt einen Room aus rohen Scan-Daten
    static func calculate(
        walls: [WallSurface],
        doors: [Opening],
        windows: [Opening]
    ) -> Room {
        Room(
            id: UUID(),
            name: "Gescannter Raum",
            scannedAt: Date(),
            walls: walls,
            doors: doors,
            windows: windows
        )
    }

    /// Berechnet QuoteItems aus ausgewählten Leistungen und Raumdaten.
    /// Bei Sockelleisten wird der Umfang (lfm) statt der m²-Fläche verwendet.
    static func calculateQuoteItems(room: Room, services: [ServiceItem]) -> [QuoteItem] {
        services
            .filter { $0.isSelected }
            .map { service in
                let area: Double
                switch service.surfaceType {
                case .wall:
                    area = service.isPerLinearMeter
                        ? Double(room.perimeterMeters)
                        : Double(room.wallAreaNet)
                case .ceiling:
                    area = Double(room.ceilingArea)
                case .floor:
                    area = Double(room.floorArea)
                }
                let total = area * service.pricePerM2
                return QuoteItem(serviceItem: service, appliedArea: area, totalPrice: total)
            }
    }
}
