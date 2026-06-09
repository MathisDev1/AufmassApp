import SwiftUI
import UIKit

/// Vorschau und Export des generierten Angebots-PDFs
struct PDFPreviewView: View {
    let quote: Quote

    @State private var showingShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        // TODO: PDFKit-Viewer einbauen
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("PDF-Vorschau")
                    .font(.title2.bold())
                Text("Angebots-Nr. \(quote.quoteNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(quote.totalGross, format: .currency(code: "EUR"))
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
            }

            Button {
                let company = loadCompanyInfo()
                pdfData = PDFGenerator.generate(quote: quote, company: company)
                showingShareSheet = true
            } label: {
                Label("Teilen", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }

    /// Lädt Firmendaten aus UserDefaults oder gibt Beispieldaten zurück
    private func loadCompanyInfo() -> CompanyInfo {
        let defaults = UserDefaults.standard
        return CompanyInfo(
            companyName:      defaults.string(forKey: "companyName") ?? CompanyInfo.preview.companyName,
            ownerName:        defaults.string(forKey: "ownerName")   ?? CompanyInfo.preview.ownerName,
            street:           defaults.string(forKey: "street")      ?? CompanyInfo.preview.street,
            city:             defaults.string(forKey: "city")        ?? CompanyInfo.preview.city,
            phone:            defaults.string(forKey: "phone")       ?? CompanyInfo.preview.phone,
            email:            defaults.string(forKey: "email")       ?? CompanyInfo.preview.email,
            vatId:            defaults.string(forKey: "vatId")       ?? CompanyInfo.preview.vatId,
            iban:             defaults.string(forKey: "iban")        ?? CompanyInfo.preview.iban
        )
    }
}

/// UIKit-Share-Sheet für SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PDFPreviewView(quote: Quote.preview)
            .navigationTitle("PDF-Vorschau")
            .navigationBarTitleDisplayMode(.inline)
    }
}
