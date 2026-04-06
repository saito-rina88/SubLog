import SwiftUI

struct GradientHeaderView<Content: View>: View {
    @EnvironmentObject private var theme: ThemeManager

    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [
                        theme.current.primary,
                        theme.current.primaryDark,
                        theme.current.primaryDeep
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    GradientHeaderView {
        Text("プレビュー")
            .foregroundStyle(.white)
            .font(.title)
    }
    .environmentObject(ThemeManager())
}
