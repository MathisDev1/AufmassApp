import Foundation

/// Einzelne Wand mit Breite (horizontal) und Höhe in Metern
struct WallSurface: Codable, Identifiable {
    var id: UUID = UUID()
    var width: Float
    var height: Float
    var area: Float { width * height }
}

/// Öffnung (Tür oder Fenster) mit Breite und Höhe in Metern
struct Opening: Codable, Identifiable {
    var id: UUID = UUID()
    var width: Float
    var height: Float
    var area: Float { width * height }
}

/// Gescannter Raum mit allen berechneten Flächen
struct Room: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var scannedAt: Date
    var walls: [WallSurface]
    var doors: [Opening]
    var windows: [Opening]

    /// Gesamte Wandfläche ohne Abzüge
    var wallAreaGross: Float {
        walls.reduce(0) { $0 + $1.area }
    }

    /// Summe aller Türflächen
    var doorArea: Float {
        doors.reduce(0) { $0 + $1.area }
    }

    /// Summe aller Fensterflächen
    var windowArea: Float {
        windows.reduce(0) { $0 + $1.area }
    }

    /// Netto-Wandfläche nach Abzug aller Öffnungen
    var wallAreaNet: Float {
        max(0, wallAreaGross - doorArea - windowArea)
    }

    /// Deckenfläche als Näherung: längere Wandseiten × kürzere Wandseiten
    var ceilingArea: Float {
        guard walls.count >= 2 else { return walls.first.map { $0.width * $0.width } ?? 0 }
        let widths = walls.map { $0.width }.sorted(by: >)
        let half = widths.count / 2
        let longSide = widths.prefix(half).reduce(0, +) / Float(half)
        let shortSide = widths.suffix(widths.count - half).reduce(0, +) / Float(widths.count - half)
        return longSide * shortSide
    }

    /// Bodenfläche entspricht der Deckenfläche
    var floorArea: Float { ceilingArea }

    /// Durchschnittliche Raumhöhe über alle Wände
    var roomHeight: Float {
        guard !walls.isEmpty else { return 0 }
        return walls.map { $0.height }.reduce(0, +) / Float(walls.count)
    }

    /// Umfang des Raumes (Summe aller Wandbreiten) für Sockelleisten in lfm
    var perimeterMeters: Float {
        walls.reduce(0) { $0 + $1.width }
    }

    static var preview: Room {
        Room(
            id: UUID(),
            name: "Wohnzimmer",
            scannedAt: Date(),
            walls: [
                WallSurface(width: 4.5, height: 2.6),
                WallSurface(width: 3.8, height: 2.6),
                WallSurface(width: 4.5, height: 2.6),
                WallSurface(width: 3.8, height: 2.6)
            ],
            doors: [Opening(width: 0.9, height: 2.1)],
            windows: [Opening(width: 1.2, height: 1.2), Opening(width: 1.2, height: 1.2)]
        )
    }
}
