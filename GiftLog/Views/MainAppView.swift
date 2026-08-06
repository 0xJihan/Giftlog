import SwiftUI
import SwiftData

struct MainAppView: View {
    @StateObject private var viewModel = GiftLogViewModel()
    @Query(sort: \GiftEntry.timestamp, order: .reverse) private var entries: [GiftEntry]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 14) {
                StatsBarView(
                    entries: entries,
                    isPrivacyEnabled: $viewModel.isPrivacyEnabled
                )

                HSplitView {
                    GiftEntryFormView(
                        viewModel: viewModel,
                        existingEntries: entries
                    )
                    .frame(minWidth: 320, idealWidth: 350, maxWidth: 400)
                    .layoutPriority(1)

                    RecentEntriesListView(
                        entries: entries,
                        viewModel: viewModel
                    )
                    .frame(minWidth: 420)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))

            UndoToastView(
                viewModel: viewModel,
                entries: entries
            )
            .padding(.bottom, 24)
        }
        .frame(minWidth: 840, minHeight: 560)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isPrivacyEnabled.toggle()
                    }
                } label: {
                    Label(
                        viewModel.isPrivacyEnabled ? "Privacy Mode Active" : "Privacy Mode Off",
                        systemImage: viewModel.isPrivacyEnabled ? "lock.shield.fill" : "lock.shield"
                    )
                    .foregroundColor(viewModel.isPrivacyEnabled ? .orange : .primary)
                }
                .help("Toggle Privacy Mode (⌘P)")

                Button {
                    viewModel.activeFocusField = .search
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .help("Focus Search (⌘F)")

                Menu {
                    Button {
                        ExportService.exportCSV(entries: entries)
                    } label: {
                        Label("Export as CSV...", systemImage: "doc.text")
                    }

                    Button {
                        ExportService.exportJSON(entries: entries)
                    } label: {
                        Label("Export as JSON...", systemImage: "curlybraces")
                    }

                    Divider()

                    Button {
                        ExportService.exportPDF(entries: entries)
                    } label: {
                        Label("Export Printable PDF Summary...", systemImage: "doc.richtext")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export Entries (⌘E)")
            }
        }
        .background(
            KeyboardShortcutHandlerView(
                onTogglePrivacy: {
                    viewModel.isPrivacyEnabled.toggle()
                },
                onFocusSearch: {
                    viewModel.activeFocusField = .search
                },
                onExportCSV: {
                    ExportService.exportCSV(entries: entries)
                },
                onFocusName: {
                    viewModel.activeFocusField = .name
                }
            )
        )
        .alert("Possible Duplicate Entry", isPresented: $viewModel.showDuplicateAlert) {
            Button("Continue (Save Anyway)") {
                viewModel.pendingSaveAction?()
                viewModel.pendingSaveAction = nil
            }
            Button("Cancel", role: .cancel) {
                viewModel.pendingSaveAction = nil
                viewModel.activeFocusField = .name
            }
        } message: {
            Text(viewModel.duplicateMessage)
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            if let entry = viewModel.editingEntry {
                EditEntrySheet(
                    entry: entry,
                    viewModel: viewModel
                )
            }
        }
    }
}

private struct KeyboardShortcutHandlerView: View {
    let onTogglePrivacy: () -> Void
    let onFocusSearch: () -> Void
    let onExportCSV: () -> Void
    let onFocusName: () -> Void

    var body: some View {
        ZStack {
            Button("") { onTogglePrivacy() }
                .keyboardShortcut("p", modifiers: [.command])
                .opacity(0)

            Button("") { onFocusSearch() }
                .keyboardShortcut("f", modifiers: [.command])
                .opacity(0)

            Button("") { onExportCSV() }
                .keyboardShortcut("e", modifiers: [.command])
                .opacity(0)

            Button("") { onFocusName() }
                .keyboardShortcut("n", modifiers: [.command])
                .opacity(0)
        }
        .frame(width: 0, height: 0)
    }
}
