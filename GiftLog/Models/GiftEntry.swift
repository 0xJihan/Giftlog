import Foundation
import SwiftData

@Model
final class GiftEntry: Identifiable {
    var id: UUID
    var name: String
    var amount: Double
    var address: String
    var note: String
    var timestamp: Date

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        address: String = "",
        note: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amount = amount
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.timestamp = timestamp
    }

    var formattedAmount: String {
        SmartAmountParser.formatCurrency(amount)
    }

    var formattedTime: String {
        Self.timeFormatter.string(from: timestamp)
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: timestamp)
    }
}
