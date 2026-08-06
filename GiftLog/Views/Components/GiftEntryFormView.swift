import SwiftUI
import SwiftData

struct GiftEntryFormView: View {
    @ObservedObject var viewModel: GiftLogViewModel
    @FocusState private var focusedField: FormField?
    let existingEntries: [GiftEntry]
    @Environment(\.modelContext) private var modelContext

    private let quickAmounts = [500, 1000, 1500, 2000, 3000, 5000, 10000]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("New Gift Entry", systemImage: "plus.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Spacer()

                if viewModel.showSaveSuccessCheck {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Saved")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            Divider()

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Name")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    TextField("e.g. Rahim Choudhury", text: $viewModel.nameInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            focusedField = .amount
                        }
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Amount")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                        
                        Spacer()

                        if let preview = viewModel.formattedAmountPreview {
                            HStack(spacing: 2) {
                                Text("Parsed:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(preview)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    TextField("e.g. 500, 1k, 1.5k, 2.75k, 10,000", text: $viewModel.amountInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .amount)
                        .onSubmit {
                            focusedField = .address
                        }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Text("Quick:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            ForEach(quickAmounts, id: \.self) { amount in
                                Button {
                                    viewModel.selectQuickAmount(amount)
                                    focusedField = .address
                                } label: {
                                    Text("৳\(amount)")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            viewModel.amountInput == "\(amount)"
                                            ? Color.accentColor.opacity(0.2)
                                            : Color.primary.opacity(0.06)
                                        )
                                        .foregroundColor(
                                            viewModel.amountInput == "\(amount)"
                                            ? .accentColor
                                            : .primary
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Address")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("e.g. Dhanmondi, Dhaka", text: $viewModel.addressInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .address)
                        .onSubmit {
                            if viewModel.isFormValid {
                                saveAction()
                            } else {
                                focusedField = .note
                            }
                        }

                    let suggestions = viewModel.addressSuggestions(from: existingEntries)
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                
                                ForEach(suggestions.prefix(4), id: \.self) { sug in
                                    Button {
                                        viewModel.addressInput = sug
                                    } label: {
                                        Text(sug)
                                            .font(.system(size: 11))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Note (Optional)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("e.g. Groom's Uncle / Side gift", text: $viewModel.noteInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .note)
                        .onSubmit {
                            saveAction()
                        }
                }
            }

            Spacer(minLength: 8)

            Button {
                saveAction()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Save Entry")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("↵ Return")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .opacity(0.7)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(viewModel.isFormValid ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isFormValid)
            .keyboardShortcut(.defaultAction)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onChange(of: viewModel.activeFocusField) { newValue in
            focusedField = newValue
        }
        .onChange(of: focusedField) { newValue in
            viewModel.activeFocusField = newValue
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .name
            }
        }
    }

    private func saveAction() {
        viewModel.attemptSave(
            context: modelContext,
            existingEntries: existingEntries
        )
    }
}
