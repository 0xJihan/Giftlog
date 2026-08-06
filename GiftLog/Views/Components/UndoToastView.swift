import SwiftUI
import SwiftData

struct UndoToastView: View {
    @ObservedObject var viewModel: GiftLogViewModel
    let entries: [GiftEntry]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if viewModel.showUndoToast {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Saved")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.toastSavedName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Text(viewModel.toastSavedAmount)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 12)

                Button {
                    withAnimation(.easeInOut) {
                        viewModel.performUndo(context: modelContext, entries: entries)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 13))
                        Text("Undo")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
