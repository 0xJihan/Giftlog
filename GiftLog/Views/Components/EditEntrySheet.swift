import SwiftUI
import SwiftData

struct EditEntrySheet: View {
    let entry: GiftEntry
    @ObservedObject var viewModel: GiftLogViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var address: String = ""
    @State private var note: String = ""

    private var parsedAmount: Double? {
        SmartAmountParser.parse(amountText)
    }

    private var isValid: Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return false }
        guard let amt = parsedAmount, amt > 0 else { return false }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Edit Gift Entry", systemImage: "pencil.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guest Name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Amount")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if let amt = parsedAmount, amt > 0 {
                            Text(SmartAmountParser.formatCurrency(amt))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    TextField("Amount", text: $amountText)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Address")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Address", text: $address)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Note (Optional)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Note", text: $note)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Divider()

            HStack {
                Button("Cancel") {
                    viewModel.showEditSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    if let amt = parsedAmount {
                        viewModel.saveEditedEntry(
                            context: modelContext,
                            updatedName: name,
                            updatedAmount: amt,
                            updatedAddress: address,
                            updatedNote: note
                        )
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear {
            name = entry.name
            amountText = String(format: "%.0f", entry.amount)
            address = entry.address
            note = entry.note
        }
    }
}
