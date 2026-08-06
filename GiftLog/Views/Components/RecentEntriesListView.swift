import SwiftUI
import SwiftData

struct RecentEntriesListView: View {
    let entries: [GiftEntry]
    @ObservedObject var viewModel: GiftLogViewModel
    @FocusState private var isSearchFocused: Bool
    @Environment(\.modelContext) private var modelContext

    private var filteredEntries: [GiftEntry] {
        let sorted = entries.sorted { $0.timestamp > $1.timestamp }
        let query = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !query.isEmpty else { return sorted }

        return sorted.filter { entry in
            entry.name.lowercased().contains(query) ||
            entry.address.lowercased().contains(query) ||
            entry.note.lowercased().contains(query) ||
            SmartAmountParser.formatCurrency(entry.amount).contains(query) ||
            String(Int(entry.amount)).contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Recent Gift Logs (\(filteredEntries.count))", systemImage: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("Search name, address, amount... (⌘F)", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .focused($isSearchFocused)

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSearchFocused ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: 1)
                )
                .frame(width: 240)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))

            Divider()

            if filteredEntries.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(viewModel.searchText.isEmpty ? "No gifts recorded yet today" : "No entries matching \"\(viewModel.searchText)\"")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(viewModel.searchText.isEmpty ? "Fill out the form on the left to add your first gift." : "Try searching for a different name, address, or amount.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEntries, id: \.id) { entry in
                            EntryRowView(
                                entry: entry,
                                isPrivacyEnabled: viewModel.isPrivacyEnabled,
                                onEdit: {
                                    viewModel.startEditing(entry)
                                },
                                onDelete: {
                                    viewModel.deleteEntry(entry, context: modelContext)
                                }
                            )
                        }
                    }
                    .padding(12)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onChange(of: viewModel.activeFocusField) { field in
            if field == .search {
                isSearchFocused = true
            }
        }
    }
}

private struct EntryRowView: View {
    let entry: GiftEntry
    let isPrivacyEnabled: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Text(String(entry.name.prefix(1)).capitalized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(isPrivacyEnabled ? anonymizeName(entry.name) : entry.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    if !entry.note.isEmpty {
                        Text("• \(entry.note)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 8) {
                    if !entry.address.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                            Text(entry.address)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.secondary)
                    } else {
                        Text("No address recorded")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))

                    Text(entry.formattedTime)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(isPrivacyEnabled ? "••••••" : entry.formattedAmount)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isPrivacyEnabled ? .secondary : .green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isPrivacyEnabled ? Color.secondary.opacity(0.1) : Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hover
            }
        }
        .onTapGesture(count: 2) {
            onEdit()
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Entry", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Entry", systemImage: "trash")
            }
        }
    }

    private func anonymizeName(_ name: String) -> String {
        let parts = name.components(separatedBy: " ")
        return parts.map { part in
            guard let first = part.first else { return "" }
            return "\(first)..."
        }.joined(separator: " ")
    }
}
