import Foundation

struct SmartAmountParser {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter
    }()

    static func parse(_ input: String) -> Double? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        guard !cleaned.isEmpty else { return nil }

        let valueString = cleaned.replacingOccurrences(of: "৳", with: "")
            .replacingOccurrences(of: "tk", with: "")

        if valueString.hasSuffix("k") {
            let numberPart = valueString.dropLast()
                .replacingOccurrences(of: ",", with: "")
            guard let val = Double(numberPart) else { return nil }
            return val * 1000.0
        }

        let numberPart = valueString.replacingOccurrences(of: ",", with: "")
        return Double(numberPart)
    }

    static func formatCurrency(_ amount: Double) -> String {
        let isInteger = amount.truncatingRemainder(dividingBy: 1) == 0
        currencyFormatter.maximumFractionDigits = isInteger ? 0 : 2
        currencyFormatter.minimumFractionDigits = 0
        
        let formattedNumber = currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
        return "৳\(formattedNumber)"
    }
}
