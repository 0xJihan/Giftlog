import Foundation
import AppKit
import SwiftUI
import PDFKit
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
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "Wedding_Gift_Log_\(formattedCurrentDate()).csv"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? csvString.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    @MainActor
    static func exportJSON(entries: [GiftEntry]) {
        guard let jsonData = generateJSON(entries: entries) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Wedding_Gift_Log_\(formattedCurrentDate()).json"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? jsonData.write(to: url)
            }
        }
    }
    
    @MainActor
    static func exportPDF(entries: [GiftEntry]) {
        let pdfData = generatePDFData(entries: entries)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Wedding_Gift_Log_\(formattedCurrentDate()).pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? pdfData.write(to: url)
            }
        }
    }

    @MainActor
    static func generatePDFData(entries: [GiftEntry]) -> Data {
        let printView = NSHostingView(rootView: PDFSummaryView(entries: entries))
        let targetWidth: CGFloat = 612
        let fitSize = printView.fittingSize
        printView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: max(fitSize.height, 792))
        
        return printView.dataWithPDF(inside: printView.bounds)
    }

    private static func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct PDFSummaryView: View {
    let entries: [GiftEntry]

    var totalAmount: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wedding Reception Gift Log")
                        .font(.system(size: 22, weight: .bold))
                    Text("Generated on \(Date().formatted(date: .long, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Entries: \(entries.count)")
                        .font(.system(size: 12, weight: .medium))
                    Text("Total Amount: \(SmartAmountParser.formatCurrency(totalAmount))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.bottom, 8)

            Divider()

            HStack {
                Text("#").frame(width: 30, alignment: .leading)
                Text("Name").frame(width: 160, alignment: .leading)
                Text("Amount").frame(width: 100, alignment: .trailing)
                Text("Address").frame(width: 180, alignment: .leading)
                Text("Time").frame(width: 70, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Text("\(index + 1)")
                            .frame(width: 30, alignment: .leading)
                        Text(entry.name)
                            .frame(width: 160, alignment: .leading)
                            .lineLimit(1)
                        Text(entry.formattedAmount)
                            .frame(width: 100, alignment: .trailing)
                            .font(.system(.body, design: .monospaced))
                        Text(entry.address.isEmpty ? "-" : entry.address)
                            .frame(width: 180, alignment: .leading)
                            .lineLimit(1)
                        Text(entry.formattedTime)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(size: 11))
                    
                    if index < entries.count - 1 {
                        Divider().opacity(0.3)
                    }
                }
            }

            Spacer()
        }
        .padding(32)
        .frame(width: 612)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }
}
