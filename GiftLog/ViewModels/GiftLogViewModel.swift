import Foundation
import SwiftUI
import SwiftData
import Combine

enum FormField: Hashable {
    case name
    case amount
    case address
    case note
    case search
}

@MainActor
final class GiftLogViewModel: ObservableObject {
    @Published var nameInput: String = ""
    @Published var amountInput: String = ""
    @Published var addressInput: String = ""
    @Published var noteInput: String = ""

    @Published var searchText: String = ""
    
    @Published var isPrivacyEnabled: Bool = true
    @Published var activeFocusField: FormField? = .name
    
    @Published var showDuplicateAlert: Bool = false
    @Published var duplicateMessage: String = ""
    @Published var pendingSaveAction: (() -> Void)? = nil

    @Published var showUndoToast: Bool = false
    @Published var toastSavedName: String = ""
    @Published var toastSavedAmount: String = ""
    @Published var lastSavedEntryID: UUID? = nil
    @Published var lastSavedSnapshot: (name: String, amount: String, address: String, note: String)? = nil
    
    private var undoTimerTask: Task<Void, Never>? = nil

    @Published var editingEntry: GiftEntry? = nil
    @Published var showEditSheet: Bool = false

    @Published var showSaveSuccessCheck: Bool = false

    var parsedAmountPreview: Double? {
        SmartAmountParser.parse(amountInput)
    }

    var formattedAmountPreview: String? {
        guard let amount = parsedAmountPreview, amount > 0 else { return nil }
        return SmartAmountParser.formatCurrency(amount)
    }

    var isFormValid: Bool {
        let cleanName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return false }
        guard let amount = parsedAmountPreview, amount > 0 else { return false }
        return true
    }

    func addressSuggestions(from entries: [GiftEntry]) -> [String] {
        let query = addressInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        
        let allAddresses = Set(entries.map { $0.address.cleanedWhitespace }.filter { !$0.isEmpty })
        return allAddresses
            .filter { $0.lowercased().contains(query) && $0.lowercased() != query }
            .sorted()
    }

    func selectQuickAmount(_ amount: Int) {
        amountInput = "\(amount)"
        activeFocusField = .address
    }

    func attemptSave(context: ModelContext, existingEntries: [GiftEntry], force: Bool = false) {
        guard isFormValid else { return }
        
        let formattedName = nameInput.cleanedAndCapitalizedName
        guard let parsedAmount = parsedAmountPreview else { return }
        let cleanAddress = addressInput.cleanedWhitespace
        let cleanNote = noteInput.cleanedWhitespace

        if !force {
            if let dupReason = checkForDuplicates(
                name: formattedName,
                amount: parsedAmount,
                address: cleanAddress,
                entries: existingEntries
            ) {
                duplicateMessage = dupReason
                pendingSaveAction = { [weak self] in
                    self?.performSave(
                        context: context,
                        name: formattedName,
                        amount: parsedAmount,
                        address: cleanAddress,
                        note: cleanNote
                    )
                }
                showDuplicateAlert = true
                return
            }
        }

        performSave(
            context: context,
            name: formattedName,
            amount: parsedAmount,
            address: cleanAddress,
            note: cleanNote
        )
    }

    private func checkForDuplicates(name: String, amount: Double, address: String, entries: [GiftEntry]) -> String? {
        let lowerName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lowerAddress = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let duplicate = entries.first { entry in
            let matchName = entry.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowerName
            let matchAmount = abs(entry.amount - amount) < 0.01
            let matchAddress = entry.address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowerAddress
            return matchName && matchAmount && matchAddress
        }

        guard let match = duplicate else { return nil }

        let formattedAmount = SmartAmountParser.formatCurrency(amount)
        let addressPart = match.address.isEmpty ? "" : " from \"\(match.address)\""
        return "An entry for \"\(match.name)\" with \(formattedAmount)\(addressPart) already exists in the log."
    }

    private func performSave(
        context: ModelContext,
        name: String,
        amount: Double,
        address: String,
        note: String
    ) {
        let newEntry = GiftEntry(
            name: name,
            amount: amount,
            address: address,
            note: note,
            timestamp: Date()
        )
        
        context.insert(newEntry)
        try? context.save()

        lastSavedEntryID = newEntry.id
        lastSavedSnapshot = (name: nameInput, amount: amountInput, address: addressInput, note: noteInput)
        toastSavedName = name
        toastSavedAmount = SmartAmountParser.formatCurrency(amount)

        nameInput = ""
        amountInput = ""
        addressInput = ""
        noteInput = ""
        activeFocusField = .name

        showSaveSuccessCheck = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showSaveSuccessCheck = false
        }

        triggerUndoToast()
    }

    private func triggerUndoToast() {
        undoTimerTask?.cancel()
        showUndoToast = true
        
        undoTimerTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled {
                showUndoToast = false
            }
        }
    }

    func performUndo(context: ModelContext, entries: [GiftEntry]) {
        guard let targetID = lastSavedEntryID,
              let entryToDelete = entries.first(where: { $0.id == targetID }) else {
            showUndoToast = false
            return
        }

        if let snapshot = lastSavedSnapshot {
            nameInput = snapshot.name
            amountInput = snapshot.amount
            addressInput = snapshot.address
            noteInput = snapshot.note
        }

        context.delete(entryToDelete)
        try? context.save()

        showUndoToast = false
        lastSavedEntryID = nil
        lastSavedSnapshot = nil
        activeFocusField = .name
    }

    func startEditing(_ entry: GiftEntry) {
        editingEntry = entry
        showEditSheet = true
    }

    func saveEditedEntry(context: ModelContext, updatedName: String, updatedAmount: Double, updatedAddress: String, updatedNote: String) {
        guard let entry = editingEntry else { return }
        entry.name = updatedName.cleanedAndCapitalizedName
        entry.amount = updatedAmount
        entry.address = updatedAddress.cleanedWhitespace
        entry.note = updatedNote.cleanedWhitespace
        
        try? context.save()
        editingEntry = nil
        showEditSheet = false
    }

    func deleteEntry(_ entry: GiftEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }
}
