import SwiftUI

struct RenewalBadgeView: View {
    @EnvironmentObject private var theme: ThemeManager

    let daysUntilRenewal: Int

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}

private extension RenewalBadgeView {
    var title: String {
        if daysUntilRenewal <= 0 {
            return "今日更新"
        }
        return "あと \(daysUntilRenewal)日"
    }

    var backgroundColor: Color {
        if daysUntilRenewal <= 0 {
            return .red.opacity(0.15)
        } else if daysUntilRenewal <= 7 {
            return theme.current.primaryLight
        } else {
            return theme.current.primaryXLight
        }
    }

    var foregroundColor: Color {
        if daysUntilRenewal <= 0 {
            return .red
        } else if daysUntilRenewal <= 7 {
            return theme.current.primaryDark
        } else {
            return theme.current.primary
        }
    }
}

#Preview {
    VStack {
        RenewalBadgeView(daysUntilRenewal: 0)
        RenewalBadgeView(daysUntilRenewal: 3)
        RenewalBadgeView(daysUntilRenewal: 14)
    }
    .environmentObject(ThemeManager())
    .padding()
}
