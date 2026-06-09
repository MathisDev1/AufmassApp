import SwiftUI

/// Angebotskonfiguration nach dem Scan – Leistungen auswählen und Preis kalkulieren
struct QuoteView: View {
    let room: Room

    @State private var selectedServices: [ServiceItem] = ServiceItem.malerDefaults
    @State private var showingPDF = false
    @State private var generatedQuote: Quote?

    var body: some View {
        // TODO: Live-Kalkulation einbauen
        List {
            Section("Wandfläche netto: \(String(format: "%.1f", room.wallAreaNet)) m²") {
                ForEach($selectedServices) { $service in
                    HStack {
                        Toggle(isOn: $service.isSelected) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.name)
                                    .font(.body)
                                let unit = service.isPerLinearMeter ? "lfm" : "m²"
                                Text(String(format: "%.2f €/%@", service.pricePerM2, unit))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                let items = RoomCalculator.calculateQuoteItems(room: room, services: selectedServices)
                let subtotal = items.reduce(0) { $0 + $1.totalPrice }
                let vat = subtotal * 0.19

                HStack {
                    Text("Netto")
                    Spacer()
                    Text(subtotal, format: .currency(code: "EUR"))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("MwSt. 19 %")
                    Spacer()
                    Text(vat, format: .currency(code: "EUR"))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Gesamt brutto")
                        .font(.headline)
                    Spacer()
                    Text(subtotal + vat, format: .currency(code: "EUR"))
                        .font(.headline)
                }
            } header: {
                Text("Kalkulation")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                let items = RoomCalculator.calculateQuoteItems(room: room, services: selectedServices)
                generatedQuote = Quote(room: room, items: items)
                showingPDF = true
            } label: {
                Text("Angebot erstellen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
            .background(.regularMaterial)
        }
        .sheet(isPresented: $showingPDF) {
            if let quote = generatedQuote {
                NavigationStack {
                    PDFPreviewView(quote: quote)
                        .navigationTitle("PDF-Vorschau")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        QuoteView(room: Room.preview)
    }
}
