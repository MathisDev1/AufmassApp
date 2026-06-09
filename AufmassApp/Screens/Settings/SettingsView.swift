import SwiftUI

/// Firmeninformationen und App-Einstellungen
struct SettingsView: View {
    // TODO: Vollständige Firmeninfos und Preiskonfiguration
    @AppStorage("companyName") private var companyName: String = ""
    @AppStorage("ownerName")   private var ownerName:   String = ""
    @AppStorage("street")      private var street:      String = ""
    @AppStorage("city")        private var city:        String = ""
    @AppStorage("phone")       private var phone:       String = ""
    @AppStorage("email")       private var email:       String = ""
    @AppStorage("vatId")       private var vatId:       String = ""
    @AppStorage("iban")        private var iban:        String = ""

    var body: some View {
        Form {
            Section("Firma") {
                LabeledContent("Firmenname") {
                    TextField("Malerbetrieb GmbH", text: $companyName)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Inhaber") {
                    TextField("Max Mustermann", text: $ownerName)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Adresse") {
                LabeledContent("Straße") {
                    TextField("Musterstraße 1", text: $street)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Stadt / PLZ") {
                    TextField("12345 Musterstadt", text: $city)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Kontakt") {
                LabeledContent("Telefon") {
                    TextField("+49 ...", text: $phone)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("E-Mail") {
                    TextField("info@firma.de", text: $email)
                        .keyboardType(.emailAddress)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Steuer & Bank") {
                LabeledContent("USt-IdNr.") {
                    TextField("DE123456789", text: $vatId)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("IBAN") {
                    TextField("DE00 0000 0000 0000 0000 00", text: $iban)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                Button("Beispieldaten laden") {
                    let preview = CompanyInfo.preview
                    companyName = preview.companyName
                    ownerName   = preview.ownerName
                    street      = preview.street
                    city        = preview.city
                    phone       = preview.phone
                    email       = preview.email
                    vatId       = preview.vatId
                    iban        = preview.iban
                }
                .foregroundStyle(.blue)
            }
        }
        .navigationTitle("Einstellungen")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
