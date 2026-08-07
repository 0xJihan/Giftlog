import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ExportService {
    static func generateCSV(entries: [GiftEntry]) -> String {
        var csv = "ID,Name,Amount (BDT),Address,Note,Date,Time\n"
        for entry in entries {
            let id = entry.id.uuidString
            let name = escapeCSV(entry.name)
            let amount = String(format: "%.2f", entry.amount)
            let address = escapeCSV(entry.address)
            let note = escapeCSV(entry.note)
            let date = escapeCSV(entry.formattedDate)
            let time = escapeCSV(entry.formattedTime)
            csv += "\(id),\(name),\(amount),\(address),\(note),\(date),\(time)\n"
        }
        return csv
    }

    private static func escapeCSV(_ text: String) -> String {
        var escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    static func generateJSON(entries: [GiftEntry]) -> Data? {
        struct JSONEntry: Encodable {
            let id: String
            let name: String
            let amount: Double
            let formattedAmount: String
            let address: String
            let note: String
            let timestamp: String
        }

        let isoFormatter = ISO8601DateFormatter()
        let items = entries.map { entry in
            JSONEntry(
                id: entry.id.uuidString,
                name: entry.name,
                amount: entry.amount,
                formattedAmount: entry.formattedAmount,
                address: entry.address,
                note: entry.note,
                timestamp: isoFormatter.string(from: entry.timestamp)
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(items)
    }

    @MainActor
    static func exportCSV(entries: [GiftEntry]) {
        let csvString = generateCSV(entries: entries)

        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.nameFieldStringValue = "Wedding_Gift_Log_\(formattedCurrentDate()).csv"
            panel.canCreateDirectories = true
            panel.title = "Export Gift Log as CSV"

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    showErrorAlert(message: "Failed to save CSV: \(error.localizedDescription)")
                }
            }
        }
    }

    @MainActor
    static func exportJSON(entries: [GiftEntry]) {
        guard let jsonData = generateJSON(entries: entries) else { return }

        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "Wedding_Gift_Log_\(formattedCurrentDate()).json"
            panel.canCreateDirectories = true
            panel.title = "Export Gift Log as JSON"

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                do {
                    try jsonData.write(to: url)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    showErrorAlert(message: "Failed to save JSON: \(error.localizedDescription)")
                }
            }
        }
    }

    @MainActor
    static func exportPDF(entries: [GiftEntry]) {
        let pdfData = generatePDFData(entries: entries)

        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "Wedding_Gift_Log_\(formattedCurrentDate()).pdf"
            panel.canCreateDirectories = true
            panel.title = "Export Gift Log as PDF"

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                do {
                    try pdfData.write(to: url)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    showErrorAlert(message: "Failed to save PDF: \(error.localizedDescription)")
                }
            }
        }
    }

    @MainActor
    static func generatePDFData(entries: [GiftEntry]) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40

        let totalAmount = entries.reduce(0.0) { $0 + $1.amount }
        let highestGift = entries.map { $0.amount }.max() ?? 0
        let averageGift = entries.isEmpty ? 0 : totalAmount / Double(entries.count)

        let pdfRenderer = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfRenderer as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

        let headerHeight: CGFloat = 180
        let rowHeight: CGFloat = 22
        let tableHeaderHeight: CGFloat = 40
        let contentWidth = pageWidth - margin * 2
        let rowsPerFirstPage = Int((pageHeight - margin - headerHeight - tableHeaderHeight - margin) / rowHeight)
        let rowsPerSubsequentPage = Int((pageHeight - margin * 2 - tableHeaderHeight) / rowHeight)

        var currentEntryIndex = 0
        var pageNumber = 0

        while currentEntryIndex < sortedEntries.count || pageNumber == 0 {
            pageNumber += 1
            pdfContext.beginPDFPage(nil)

            let nsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = nsContext

            if pageNumber == 1 {
                drawHeader(context: pdfContext, rect: CGRect(x: margin, y: pageHeight - margin - 50, width: contentWidth, height: 50))
                drawSummaryCards(context: pdfContext, y: pageHeight - margin - 145,
                                 totalAmount: totalAmount, guestCount: entries.count,
                                 highestGift: highestGift, averageGift: averageGift,
                                 contentWidth: contentWidth, margin: margin)
            }

            let tableTop = pageNumber == 1 ? (pageHeight - margin - headerHeight) : (pageHeight - margin)
            drawTableHeader(context: pdfContext, y: tableTop, margin: margin, contentWidth: contentWidth)

            let maxRows = pageNumber == 1 ? rowsPerFirstPage : rowsPerSubsequentPage
            let startY = tableTop - tableHeaderHeight

            for rowOffset in 0..<maxRows {
                guard currentEntryIndex < sortedEntries.count else { break }
                let entry = sortedEntries[currentEntryIndex]
                let rowY = startY - CGFloat(rowOffset) * rowHeight

                if rowY < margin + 30 { break }

                let isEvenRow = currentEntryIndex % 2 == 0
                drawTableRow(context: pdfContext, entry: entry, index: currentEntryIndex + 1,
                             y: rowY, margin: margin, contentWidth: contentWidth, isEven: isEvenRow)
                currentEntryIndex += 1
            }

            drawFooter(context: pdfContext, pageNumber: pageNumber, margin: margin,
                        pageWidth: pageWidth, totalEntries: entries.count, totalAmount: totalAmount)

            NSGraphicsContext.current = nil
            pdfContext.endPDFPage()

            if currentEntryIndex >= sortedEntries.count { break }
        }

        pdfContext.closePDF()
        return pdfRenderer as Data
    }

    private static func drawHeader(context: CGContext, rect: CGRect) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        let title = NSAttributedString(string: "Wedding Reception Gift Log", attributes: titleAttrs)
        title.draw(at: NSPoint(x: rect.minX, y: rect.minY + 18))

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short

        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.darkGray
        ]
        let subtitle = NSAttributedString(string: "Generated on \(dateFormatter.string(from: Date()))", attributes: subtitleAttrs)
        subtitle.draw(at: NSPoint(x: rect.minX, y: rect.minY))

        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: rect.minX, y: rect.minY - 6))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY - 6))
        context.strokePath()
    }

    private static func drawSummaryCards(context: CGContext, y: CGFloat,
                                          totalAmount: Double, guestCount: Int,
                                          highestGift: Double, averageGift: Double,
                                          contentWidth: CGFloat, margin: CGFloat) {
        let cardWidth = (contentWidth - 30) / 4
        let cardHeight: CGFloat = 52
        let cardY = y

        let cards: [(String, String, NSColor)] = [
            ("Total Amount", SmartAmountParser.formatCurrency(totalAmount), NSColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1)),
            ("Total Guests", "\(guestCount)", NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)),
            ("Highest Gift", SmartAmountParser.formatCurrency(highestGift), NSColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1)),
            ("Average Gift", SmartAmountParser.formatCurrency(averageGift), NSColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1))
        ]

        for (index, card) in cards.enumerated() {
            let cardX = margin + CGFloat(index) * (cardWidth + 10)
            let cardRect = CGRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight)

            let bgPath = NSBezierPath(roundedRect: cardRect, xRadius: 8, yRadius: 8)
            card.2.withAlphaComponent(0.08).setFill()
            bgPath.fill()
            card.2.withAlphaComponent(0.4).setStroke()
            bgPath.lineWidth = 0.5
            bgPath.stroke()

            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: NSColor.darkGray
            ]
            let label = NSAttributedString(string: card.0, attributes: labelAttrs)
            label.draw(at: NSPoint(x: cardX + 10, y: cardY + cardHeight - 18))

            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: card.2
            ]
            let value = NSAttributedString(string: card.1, attributes: valueAttrs)
            value.draw(at: NSPoint(x: cardX + 10, y: cardY + 6))
        }
    }

    private static func drawTableHeader(context: CGContext, y: CGFloat, margin: CGFloat, contentWidth: CGFloat) {
        let headerRect = CGRect(x: margin, y: y - 6 - 24, width: contentWidth, height: 24)
        let bgPath = NSBezierPath(roundedRect: headerRect, xRadius: 4, yRadius: 4)
        NSColor(white: 0.94, alpha: 1).setFill()
        bgPath.fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: NSColor.darkGray
        ]
        let textY = y - 6 - 20

        NSAttributedString(string: "#", attributes: attrs).draw(at: NSPoint(x: margin + 8, y: textY))
        NSAttributedString(string: "GUEST NAME", attributes: attrs).draw(at: NSPoint(x: margin + 40, y: textY))
        NSAttributedString(string: "AMOUNT", attributes: attrs).draw(at: NSPoint(x: margin + 230, y: textY))
        NSAttributedString(string: "ADDRESS", attributes: attrs).draw(at: NSPoint(x: margin + 330, y: textY))
        NSAttributedString(string: "TIME", attributes: attrs).draw(at: NSPoint(x: margin + contentWidth - 50, y: textY))

        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y - 34))
        context.addLine(to: CGPoint(x: margin + contentWidth, y: y - 34))
        context.strokePath()
    }

    private static func drawTableRow(context: CGContext, entry: GiftEntry, index: Int,
                                      y: CGFloat, margin: CGFloat, contentWidth: CGFloat, isEven: Bool) {
        if isEven {
            let rowRect = CGRect(x: margin, y: y - 6, width: contentWidth, height: 20)
            NSColor(white: 0.97, alpha: 1).setFill()
            context.fill(rowRect)
        }

        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.black
        ]
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.black
        ]
        let amountAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1)
        ]
        let dimAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.gray
        ]

        NSAttributedString(string: "\(index)", attributes: normalAttrs).draw(at: NSPoint(x: margin + 8, y: y - 2))
        NSAttributedString(string: entry.name, attributes: boldAttrs).draw(in: CGRect(x: margin + 40, y: y - 2, width: 180, height: 16))
        NSAttributedString(string: entry.formattedAmount, attributes: amountAttrs).draw(at: NSPoint(x: margin + 230, y: y - 2))
        let addressText = entry.address.isEmpty ? "-" : entry.address
        NSAttributedString(string: addressText, attributes: dimAttrs).draw(in: CGRect(x: margin + 330, y: y - 2, width: 140, height: 16))
        NSAttributedString(string: entry.formattedTime, attributes: normalAttrs).draw(at: NSPoint(x: margin + contentWidth - 50, y: y - 2))
    }

    private static func drawFooter(context: CGContext, pageNumber: Int, margin: CGFloat,
                                     pageWidth: CGFloat, totalEntries: Int, totalAmount: Double) {
        let footerY: CGFloat = margin - 10

        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: footerY + 14))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: footerY + 14))
        context.strokePath()

        let leftAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: NSColor.gray
        ]
        let leftText = NSAttributedString(string: "GiftLog • \(totalEntries) entries • \(SmartAmountParser.formatCurrency(totalAmount)) total", attributes: leftAttrs)
        leftText.draw(at: NSPoint(x: margin, y: footerY))

        let rightAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: NSColor.gray
        ]
        let pageText = NSAttributedString(string: "Page \(pageNumber)", attributes: rightAttrs)
        let pageTextSize = pageText.size()
        pageText.draw(at: NSPoint(x: pageWidth - margin - pageTextSize.width, y: footerY))
    }

    private static func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
