import SwiftUI

struct StatsBarView: View {
    let entries: [GiftEntry]
    @Binding var isPrivacyEnabled: Bool

    private var totalAmount: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    private var guestCount: Int {
        entries.count
    }

    private var highestGift: Double {
        entries.map { $0.amount }.max() ?? 0
    }

    private var averageGift: Double {
        guard guestCount > 0 else { return 0 }
        return totalAmount / Double(guestCount)
    }

    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Amount",
                value: SmartAmountParser.formatCurrency(totalAmount),
                maskedValue: "••••••••",
                icon: "banknote.fill",
                accentColor: .green,
                isMasked: isPrivacyEnabled
            )

            StatCard(
                title: "Total Guests",
                value: "\(guestCount)",
                maskedValue: "•••",
                icon: "person.2.fill",
                accentColor: .blue,
                isMasked: isPrivacyEnabled
            )

            StatCard(
                title: "Highest Gift",
                value: SmartAmountParser.formatCurrency(highestGift),
                maskedValue: "••••••",
                icon: "sparkles",
                accentColor: .orange,
                isMasked: isPrivacyEnabled
            )

            StatCard(
                title: "Average Gift",
                value: SmartAmountParser.formatCurrency(averageGift),
                maskedValue: "••••••",
                icon: "chart.bar.fill",
                accentColor: .purple,
                isMasked: isPrivacyEnabled
            )

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPrivacyEnabled.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPrivacyEnabled ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isPrivacyEnabled ? "Show Stats" : "Hide Stats")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isPrivacyEnabled ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06))
                .foregroundColor(isPrivacyEnabled ? .orange : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isPrivacyEnabled ? Color.orange.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(isPrivacyEnabled ? "Show financial metrics (⌘P)" : "Hide financial metrics for privacy (⌘P)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let maskedValue: String
    let icon: String
    let accentColor: Color
    let isMasked: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(isMasked ? maskedValue : value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
    }
}
