import Foundation

/// Firmeninformationen für Angebote und Rechnungen
struct CompanyInfo: Codable {
    var companyName: String
    var ownerName: String
    var street: String
    var city: String
    var phone: String
    var email: String
    var website: String
    var taxId: String
    var vatId: String
    var bankName: String
    var iban: String
    var bic: String
    /// Zahlungsziel in Tagen
    var paymentDays: Int
    var paymentTermsText: String

    init(
        companyName: String = "",
        ownerName: String = "",
        street: String = "",
        city: String = "",
        phone: String = "",
        email: String = "",
        website: String = "",
        taxId: String = "",
        vatId: String = "",
        bankName: String = "",
        iban: String = "",
        bic: String = "",
        paymentDays: Int = 14,
        paymentTermsText: String = "Zahlbar innerhalb von 14 Tagen ohne Abzug."
    ) {
        self.companyName = companyName
        self.ownerName = ownerName
        self.street = street
        self.city = city
        self.phone = phone
        self.email = email
        self.website = website
        self.taxId = taxId
        self.vatId = vatId
        self.bankName = bankName
        self.iban = iban
        self.bic = bic
        self.paymentDays = paymentDays
        self.paymentTermsText = paymentTermsText
    }

    static var preview: CompanyInfo {
        CompanyInfo(
            companyName: "Malerbetrieb Mustermann GmbH",
            ownerName: "Hans Mustermann",
            street: "Handwerkerstraße 42",
            city: "28195 Bremen",
            phone: "+49 421 123456",
            email: "info@malerbetrieb-mustermann.de",
            website: "www.malerbetrieb-mustermann.de",
            taxId: "61/234/56789",
            vatId: "DE123456789",
            bankName: "Sparkasse Bremen",
            iban: "DE12 2905 0101 0012 3456 78",
            bic: "SBREDE22",
            paymentDays: 14,
            paymentTermsText: "Zahlbar innerhalb von 14 Tagen ohne Abzug."
        )
    }
}
