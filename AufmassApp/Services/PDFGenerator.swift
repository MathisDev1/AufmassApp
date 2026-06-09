import UIKit

/// Generiert ein professionelles DIN-A4-Angebots-PDF mit Core Graphics
struct PDFGenerator {

    // MARK: - Konstanten

    private static let pageWidth:  CGFloat = 595.2
    private static let pageHeight: CGFloat = 841.8
    private static let margin:     CGFloat = 40.0
    private static var contentWidth: CGFloat { pageWidth - 2 * margin }

    private static let darkBlue  = UIColor(red: 0.106, green: 0.227, blue: 0.361, alpha: 1) // #1B3A5C
    private static let tableGray = UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1) // #F3F4F6
    private static let rowAlt    = UIColor(red: 0.976, green: 0.980, blue: 0.984, alpha: 1)
    private static let textGray  = UIColor(red: 0.45,  green: 0.45,  blue: 0.45,  alpha: 1)

    // Tabellen-Spalten (x-Position, ab linkem Rand = margin)
    private static let colPos:         CGFloat = 40   // Breite 30
    private static let colDesc:        CGFloat = 70   // Breite 215
    private static let colMenge:       CGFloat = 285  // Breite 60
    private static let colEinheit:     CGFloat = 345  // Breite 50
    private static let colEinzelpreis: CGFloat = 395  // Breite 80
    private static let colGesamt:      CGFloat = 475  // Breite 80, rechte Kante = 555
    private static let tableRight:     CGFloat = 555

    // MARK: - Formatter

    private static func currencyString(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

    private static func areaString(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: date)
    }

    // MARK: - Zeichnen-Hilfsmethoden

    private static func drawText(
        _ text: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor = .black,
        alignment: NSTextAlignment = .left,
        maxWidth: CGFloat? = nil
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let width = maxWidth ?? contentWidth
        let rect = CGRect(x: point.x, y: point.y, width: width, height: 200)
        (text as NSString).draw(in: rect, withAttributes: attrs)
    }

    private static func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        return ceil(boundingRect.height)
    }

    private static func drawLine(from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat = 0.5) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        color.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    private static func fillRect(_ rect: CGRect, color: UIColor) {
        color.setFill()
        UIRectFill(rect)
    }

    // MARK: - Öffentliche API

    /// Erzeugt das vollständige Angebots-PDF als Data (Seite 1: Angebot, Seite 2: Aufmaß)
    static func generate(quote: Quote, company: CompanyInfo) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            drawPage1(quote: quote, company: company)

            ctx.beginPage()
            drawPage2(room: quote.room)
        }
    }

    // MARK: - Seite 1: Angebot

    private static func drawPage1(quote: Quote, company: CompanyInfo) {
        var y: CGFloat = margin

        // ── Kopfzeile ──────────────────────────────────────────────────────────
        let nameFont    = UIFont.boldSystemFont(ofSize: 16)
        let addrFont    = UIFont.systemFont(ofSize: 10)
        let titleFont   = UIFont.boldSystemFont(ofSize: 24)
        let metaFont    = UIFont.systemFont(ofSize: 10)

        // Firmenname links
        drawText(company.companyName, at: CGPoint(x: margin, y: y), font: nameFont)

        // "ANGEBOT" rechts oben
        let titleRect = CGRect(x: margin, y: y, width: contentWidth, height: 34)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: darkBlue,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle(); p.alignment = .right; return p
            }()
        ]
        ("ANGEBOT" as NSString).draw(in: titleRect, withAttributes: titleAttrs)

        y += 22

        // Firmenadresse links
        let addrLines = [company.street, company.city, company.phone, company.email]
            .filter { !$0.isEmpty }
        for line in addrLines {
            drawText(line, at: CGPoint(x: margin, y: y), font: addrFont, color: textGray)
            y += 13
        }

        // Angebotsmeta rechts (neben Adresse)
        let metaY: CGFloat = margin + 22
        let metaRight: CGFloat = tableRight
        let metaWidth: CGFloat = 200

        let metaLines: [(String, String)] = [
            ("Nr.:",        quote.quoteNumber),
            ("Datum:",      dateString(quote.createdAt)),
            ("Gültig bis:", dateString(quote.validUntil))
        ]
        var metaYCursor = metaY
        for (label, value) in metaLines {
            let lineText = "\(label) \(value)"
            let x = metaRight - metaWidth
            drawText(lineText, at: CGPoint(x: x, y: metaYCursor), font: metaFont, alignment: .right, maxWidth: metaWidth)
            metaYCursor += 13
        }

        y = max(y, metaYCursor) + 8

        // ── Trennlinie ─────────────────────────────────────────────────────────
        drawLine(from: CGPoint(x: margin, y: y), to: CGPoint(x: tableRight, y: y), color: darkBlue, width: 1.5)
        y += 12

        // ── Empfänger-Block ────────────────────────────────────────────────────
        let recipFont   = UIFont.systemFont(ofSize: 11)
        let recipBold   = UIFont.boldSystemFont(ofSize: 11)

        drawText("An:", at: CGPoint(x: margin, y: y), font: recipFont, color: textGray)
        y += 14

        if !quote.customerName.isEmpty {
            drawText(quote.customerName, at: CGPoint(x: margin, y: y), font: recipBold)
            y += 14
        }
        if !quote.customerAddress.isEmpty {
            let addrH = textHeight(quote.customerAddress, font: recipFont, width: 220)
            drawText(quote.customerAddress, at: CGPoint(x: margin, y: y), font: recipFont, maxWidth: 220)
            y += addrH + 4
        }

        if !quote.projectAddress.isEmpty && quote.projectAddress != quote.customerAddress {
            y += 4
            drawText("Bauvorhaben:", at: CGPoint(x: margin, y: y), font: recipFont, color: textGray)
            y += 13
            let projH = textHeight(quote.projectAddress, font: recipFont, width: 260)
            drawText(quote.projectAddress, at: CGPoint(x: margin, y: y), font: recipFont, maxWidth: 260)
            y += projH + 4
        }

        y += 12

        // ── Tabelle ────────────────────────────────────────────────────────────
        let headerFont = UIFont.boldSystemFont(ofSize: 9)
        let cellFont   = UIFont.systemFont(ofSize: 9)
        let rowHeight: CGFloat = 18

        // Tabellenkopf
        fillRect(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight), color: tableGray)
        drawTableRow(
            pos: "Pos.", desc: "Beschreibung", menge: "Menge",
            einheit: "Einheit", einzelpreis: "Einzelpreis", gesamt: "Gesamtpreis",
            y: y + 4, font: headerFont, color: .black
        )
        y += rowHeight

        // Positionen
        for (index, item) in quote.items.enumerated() {
            if index % 2 == 1 {
                fillRect(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight), color: rowAlt)
            }
            let posNum    = "\(index + 1)"
            let menge     = areaString(item.appliedArea)
            let einzelp   = currencyString(item.serviceItem.pricePerM2)
            let gesamt    = currencyString(item.totalPrice)
            drawTableRow(
                pos: posNum, desc: item.serviceItem.name, menge: menge,
                einheit: item.unitDescription, einzelpreis: einzelp, gesamt: gesamt,
                y: y + 4, font: cellFont, color: .black
            )
            y += rowHeight
        }

        // ── Zwischensumme und MwSt ─────────────────────────────────────────────
        y += 6
        drawLine(from: CGPoint(x: margin, y: y), to: CGPoint(x: tableRight, y: y), color: .lightGray, width: 0.5)
        y += 8

        let summaryFont = UIFont.systemFont(ofSize: 10)
        let summaryBold = UIFont.boldSystemFont(ofSize: 10)
        let summaryX: CGFloat = colEinzelpreis
        let summaryWidth: CGFloat = tableRight - colEinzelpreis

        let vatPercent = Int(quote.vatRate * 100)

        drawSummaryRow("Zwischensumme netto:", value: currencyString(quote.subtotalNet),
                       x: summaryX, y: y, width: summaryWidth, font: summaryFont)
        y += 15

        drawSummaryRow("Zzgl. \(vatPercent)% MwSt.:", value: currencyString(quote.vatAmount),
                       x: summaryX, y: y, width: summaryWidth, font: summaryFont)
        y += 6

        drawLine(from: CGPoint(x: summaryX, y: y), to: CGPoint(x: tableRight, y: y), color: darkBlue, width: 1)
        y += 6

        drawSummaryRow("Gesamtbetrag brutto:", value: currencyString(quote.totalGross),
                       x: summaryX, y: y, width: summaryWidth, font: summaryBold)
        y += 25

        // ── Zahlungsbedingungen ────────────────────────────────────────────────
        if !quote.notes.isEmpty {
            let notesFont = UIFont.systemFont(ofSize: 9)
            drawText(quote.notes, at: CGPoint(x: margin, y: y), font: notesFont, color: textGray, maxWidth: contentWidth)
            y += textHeight(quote.notes, font: notesFont, width: contentWidth) + 8
        }

        let termsFont = UIFont.systemFont(ofSize: 9)
        // Zahlungsbedingungen aus CompanyInfo
        let termsText = "Zahlungsbedingungen: \(company.paymentTermsText)"
        drawText(termsText, at: CGPoint(x: margin, y: y), font: termsFont, color: textGray, maxWidth: contentWidth)

        // ── Fußzeile ───────────────────────────────────────────────────────────
        let footerY: CGFloat = pageHeight - margin - 16
        drawLine(from: CGPoint(x: margin, y: footerY - 6), to: CGPoint(x: tableRight, y: footerY - 6),
                 color: .lightGray, width: 0.5)

        let footerFont = UIFont.systemFont(ofSize: 8)
        var footerParts: [String] = []
        if !company.companyName.isEmpty { footerParts.append(company.companyName) }
        if !company.iban.isEmpty        { footerParts.append("IBAN: \(company.iban)") }
        if !company.vatId.isEmpty       { footerParts.append("USt-IdNr.: \(company.vatId)") }
        if !company.bankName.isEmpty    { footerParts.append(company.bankName) }
        let footerText = footerParts.joined(separator: "  |  ")
        drawText(footerText, at: CGPoint(x: margin, y: footerY),
                 font: footerFont, color: textGray, alignment: .center, maxWidth: contentWidth)
    }

    private static func drawTableRow(
        pos: String, desc: String, menge: String, einheit: String,
        einzelpreis: String, gesamt: String,
        y: CGFloat, font: UIFont, color: UIColor
    ) {
        let rightAlign: NSTextAlignment = .right
        drawText(pos,          at: CGPoint(x: colPos,         y: y), font: font, color: color, maxWidth: 28)
        drawText(desc,         at: CGPoint(x: colDesc,        y: y), font: font, color: color, maxWidth: 210)
        drawText(menge,        at: CGPoint(x: colMenge,       y: y), font: font, color: color, alignment: rightAlign, maxWidth: 55)
        drawText(einheit,      at: CGPoint(x: colEinheit,     y: y), font: font, color: color, maxWidth: 48)
        drawText(einzelpreis,  at: CGPoint(x: colEinzelpreis, y: y), font: font, color: color, alignment: rightAlign, maxWidth: 75)
        drawText(gesamt,       at: CGPoint(x: colGesamt,      y: y), font: font, color: color, alignment: rightAlign, maxWidth: 80)
    }

    private static func drawSummaryRow(
        _ label: String, value: String,
        x: CGFloat, y: CGFloat, width: CGFloat, font: UIFont
    ) {
        let half = width / 2
        drawText(label, at: CGPoint(x: x, y: y), font: font, alignment: .left,  maxWidth: half)
        drawText(value, at: CGPoint(x: x, y: y), font: font, alignment: .right, maxWidth: width)
    }

    // MARK: - Seite 2: Aufmaß-Übersicht

    private static func drawPage2(room: Room) {
        var y: CGFloat = margin

        let titleFont   = UIFont.boldSystemFont(ofSize: 16)
        let headerFont  = UIFont.boldSystemFont(ofSize: 10)
        let cellFont    = UIFont.systemFont(ofSize: 10)
        let rowHeight: CGFloat = 22
        let col1Width: CGFloat = 280
        let col2X:    CGFloat  = margin + col1Width + 20

        // Titel
        drawText("Aufmaß-Übersicht", at: CGPoint(x: margin, y: y), font: titleFont, color: darkBlue)
        y += 28

        drawText("Raum: \(room.name)", at: CGPoint(x: margin, y: y), font: UIFont.systemFont(ofSize: 11))
        y += 16
        let scanDate = dateString(room.scannedAt)
        drawText("Scanndatum: \(scanDate)", at: CGPoint(x: margin, y: y),
                 font: UIFont.systemFont(ofSize: 10), color: textGray)
        y += 20

        // Tabellenkopf
        fillRect(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight), color: tableGray)
        drawText("Kenngröße",    at: CGPoint(x: margin + 4, y: y + 5), font: headerFont)
        drawText("Wert",         at: CGPoint(x: col2X,      y: y + 5), font: headerFont)
        drawText("Einheit",      at: CGPoint(x: col2X + 80, y: y + 5), font: headerFont)
        y += rowHeight

        // Aufmaß-Zeilen
        let aufmassRows: [(String, String, String)] = [
            ("Wandfläche brutto",      areaString(Double(room.wallAreaGross)), "m²"),
            ("Abzug Türen",            areaString(Double(room.doorArea)),      "m²"),
            ("Abzug Fenster",          areaString(Double(room.windowArea)),    "m²"),
            ("Wandfläche netto",       areaString(Double(room.wallAreaNet)),   "m²"),
            ("Deckenfläche",           areaString(Double(room.ceilingArea)),   "m²"),
            ("Bodenfläche",            areaString(Double(room.floorArea)),     "m²"),
            ("Raumhöhe (Durchschnitt)", areaString(Double(room.roomHeight)),   "m"),
            ("Umfang (Sockelleisten)", areaString(Double(room.perimeterMeters)), "lfm"),
        ]

        for (index, row) in aufmassRows.enumerated() {
            let (label, value, unit) = row
            if index % 2 == 1 {
                fillRect(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight), color: rowAlt)
            }
            let isBold = label.contains("netto") || label.contains("brutto")
            let font = isBold ? UIFont.boldSystemFont(ofSize: 10) : cellFont
            drawText(label, at: CGPoint(x: margin + 4, y: y + 5), font: font)
            drawText(value, at: CGPoint(x: col2X,      y: y + 5), font: font)
            drawText(unit,  at: CGPoint(x: col2X + 80, y: y + 5), font: cellFont, color: textGray)
            y += rowHeight
        }

        // Anzahl Wände / Türen / Fenster
        y += 16
        let detailFont = UIFont.systemFont(ofSize: 9)
        drawText("Wände: \(room.walls.count)   Türen: \(room.doors.count)   Fenster: \(room.windows.count)",
                 at: CGPoint(x: margin, y: y), font: detailFont, color: textGray)
    }
}
