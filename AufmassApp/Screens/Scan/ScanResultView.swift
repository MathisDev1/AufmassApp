import SwiftUI

/// Zusammenfassung der Scan-Ergebnisse – Zwischenseite vor der Angebotserstellung
/// Wird aktuell noch nicht in den Hauptfluss eingebunden (vorbereitet für spätere Integration)
struct ScanResultView: View {

    let room: Room
    var onRescan: () -> Void = {}
    var onContinue: () -> Void = {}

    private let brandBlue = Color(red: 0.106, green: 0.227, blue: 0.361)

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // Erfolgs-Symbol
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)

                    Text("Scan abgeschlossen")
                        .font(.title.bold())

                    Text("Alle Flächen wurden erfolgreich berechnet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Messwert-Tabelle
                VStack(spacing: 0) {
                    tableHeader

                    let rows: [(String, String, String)] = [
                        ("Wandfläche netto",        formattedArea(room.wallAreaNet),    "m²"),
                        ("Wandfläche brutto",        formattedArea(room.wallAreaGross),  "m²"),
                        ("Abzug Türen",              formattedArea(room.doorArea),       "m²"),
                        ("Abzug Fenster",            formattedArea(room.windowArea),     "m²"),
                        ("Deckenfläche",             formattedArea(room.ceilingArea),    "m²"),
                        ("Bodenfläche",              formattedArea(room.floorArea),      "m²"),
                        ("Raumhöhe (Ø)",             formattedArea(room.roomHeight),     "m"),
                        ("Umfang (Sockelleisten)",   formattedArea(room.perimeterMeters),"lfm"),
                    ]

                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        let (label, value, unit) = row
                        tableRow(
                            label: label,
                            value: value,
                            unit: unit,
                            isEven: index % 2 == 0,
                            isBold: label.contains("netto")
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)

                // Anzahl erkannter Elemente
                HStack(spacing: 24) {
                    counterBadge(count: room.walls.count,   label: "Wände",   icon: "square.3.layers.3d")
                    counterBadge(count: room.doors.count,   label: "Türen",   icon: "door.left.hand.open")
                    counterBadge(count: room.windows.count, label: "Fenster", icon: "window.casement")
                }
                .padding(.horizontal)

                // Aktions-Buttons
                HStack(spacing: 12) {
                    Button {
                        onRescan()
                    } label: {
                        Text("Neu scannen")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(brandBlue, lineWidth: 1.5)
                            )
                            .foregroundStyle(brandBlue)
                    }

                    Button {
                        onContinue()
                    } label: {
                        Text("Weiter zum Angebot")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(brandBlue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Tabellen-Komponenten

    private var tableHeader: some View {
        HStack {
            Text("Kennwert")
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Wert")
                .font(.caption.bold())
                .frame(width: 70, alignment: .trailing)
            Text("Einheit")
                .font(.caption.bold())
                .frame(width: 45, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private func tableRow(label: String, value: String, unit: String, isEven: Bool, isBold: Bool) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .subheadline.bold() : .subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(isBold ? .subheadline.bold() : .subheadline)
                .frame(width: 70, alignment: .trailing)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 45, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isEven ? Color.clear : Color(.systemGray6).opacity(0.4))
    }

    // MARK: - Zähler-Badge

    private func counterBadge(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(brandBlue)
            Text("\(count)")
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Formatierung

    private func formattedArea(_ value: Float) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    NavigationStack {
        ScanResultView(room: Room.preview)
            .navigationTitle("Ergebnis")
            .navigationBarTitleDisplayMode(.inline)
    }
}
