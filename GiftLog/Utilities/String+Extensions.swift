import Foundation

extension String {
    var cleanedAndCapitalizedName: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let components = trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { word -> String in
                let lower = word.lowercased()
                if lower == "md" || lower == "md." {
                    return "MD."
                }
                return word.capitalized
            }
        
        return components.joined(separator: " ")
    }

    var cleanedWhitespace: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
